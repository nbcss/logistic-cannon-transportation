local logistic_control = {}

function logistic_control.on_init()
    storage.cannon_launcher_stations = storage.cannon_launcher_stations or {}
    storage.cannon_receiver_stations = storage.cannon_receiver_stations or {}
end

function logistic_control.update()
    for station_id, station_data in pairs(storage.cannon_launcher_stations) do
        if station_data.station_entity.valid then
            local current_ammo = station_data.station_entity.get_inventory(defines.inventory.car_ammo)[1]
        end
    end
end

function logistic_control.on_launcher_station_created(event)
    local proxy_container = event.target_entity
    if proxy_container and proxy_container.valid and proxy_container.name == "logistic-cannon-launcher" then
        local station_entity = proxy_container.surface.create_entity {
            name = "logistic-cannon-launcher-entity",
            position = proxy_container.position,
            force = proxy_container.force,
            quality = proxy_container.quality
        }
        if station_entity then
            script.register_on_object_destroyed(proxy_container)
            proxy_container.proxy_target_entity = station_entity
            proxy_container.proxy_target_inventory = defines.inventory.car_trunk
            -- local driver = proxy_container.surface.create_entity { name = "logistic-cannon-driver", position = proxy_container.position, force = proxy_container.force }
            -- station_entity.set_driver(driver)
            station_entity.driver_is_gunner = true
            station_entity.destructible = false
            storage.cannon_launcher_stations[proxy_container.unit_number] = {
                proxy_entity = proxy_container,
                station_entity = station_entity,
                loaded_ammo = nil,
                scheduled_delivery = nil,
            }
        else
            proxy_container.die()
        end
    end
end

function logistic_control.on_receiver_station_created(event)
    local proxy_container = event.target_entity
    if proxy_container and proxy_container.valid and proxy_container.name == "logistic-cannon-receiver" then
        local station_entity = proxy_container.surface.create_entity {
            name = "logistic-cannon-receiver-entity",
            position = proxy_container.position,
            force = proxy_container.force,
            quality = proxy_container.quality
        }
        if station_entity then
            script.register_on_object_destroyed(proxy_container)
            station_entity.destructible = false
            proxy_container.proxy_target_entity = station_entity
            proxy_container.proxy_target_inventory = defines.inventory.chest
            storage.cannon_receiver_stations[proxy_container.unit_number] = {
                proxy_entity = proxy_container,
                station_entity = station_entity,
                launchers_in_range = {},
                incoming_deliveries = {},
            }
        else
            proxy_container.die()
        end
    end
end

function logistic_control.on_cannon_launched(event)
    if event.source_entity and event.source_entity.valid and event.source_entity.name == "logistic-cannon-launcher-entity" then
        local ammo_item = event.source_entity.get_inventory(defines.inventory.car_ammo)[1]
        if ammo_item.count > 0 and event.target_position and event.source_position then
            if ammo_item.count == 1 then
                ammo_item.clear()
                -- TODO still auto load ammo from truck
            else
                ammo_item.drain_ammo(1)
            end
            local projectile = event.source_entity.surface.create_entity {
                name = "logistic-cannon-capsule-projectile",
                position = event.source_position,
                direction = event.source_entity.direction,
                quality = event.source_entity.quality,
                force = event.source_entity.force,
                source = event.source_entity,
                target = event.target_position,
                cause = event.source_entity,
            }
            local driver = event.source_entity.get_driver()
            if driver and driver.name == "logistic-cannon-driver" then
                driver.shooting_state = { state = defines.shooting.not_shooting, position = { 0, 0 } }
            end
        end
    end
end

function logistic_control.on_cannon_landed(event)

end

-- problem: item will vanish if deconstruct by player or robot
function logistic_control.on_station_destroyed(proxy_container_id)
    if storage.cannon_launcher_stations[proxy_container_id] then
        local station_entity = storage.cannon_launcher_stations[proxy_container_id].station_entity
        if station_entity and station_entity.valid then
            local driver = station_entity.get_driver()
            if driver and driver.valid and driver.name == "logistic-cannon-driver" then
                driver.destroy()
            end
            station_entity.destroy()
        end
    end
    if storage.cannon_receiver_stations[proxy_container_id] then
        local station_entity = storage.cannon_receiver_stations[proxy_container_id].station_entity
        if station_entity and station_entity.valid then
            station_entity.destroy()
        end
    end
end

return logistic_control
