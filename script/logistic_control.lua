local logistic_control = {}

function logistic_control.on_init()
    storage.cannon_launcher_stations = storage.cannon_launcher_stations or {}
    storage.cannon_receiver_stations = storage.cannon_receiver_stations or {}
end

function logistic_control.on_launcher_station_created(proxy_container, station_entity)
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
    }
end

function logistic_control.on_receiver_station_created(proxy_container, station_entity)
    script.register_on_object_destroyed(proxy_container)
    station_entity.destructible = false
    proxy_container.proxy_target_entity = station_entity
    proxy_container.proxy_target_inventory = defines.inventory.chest
    storage.cannon_receiver_stations[proxy_container.unit_number] = {
        proxy_entity = proxy_container,
        station_entity = station_entity,
    }
end

-- problem: item will vanish if deconstruct by player or robot
function logistic_control.on_station_destroyed(proxy_container_id)
    if storage.cannon_launcher_stations[proxy_container_id] then
        local station_entity = storage.cannon_launcher_stations[proxy_container_id].station_entity
        if station_entity and station_entity.valid then
            local driver = station_entity.get_driver()
            if driver and driver.valid then
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
