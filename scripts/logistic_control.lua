local constants = require("constants")
local math2d = require("__core__.lualib.math2d")
local logistic_control = {}

function logistic_control.on_init()
    storage.proxy_to_station_id = storage.proxy_to_station_id or {}
    storage.cannon_launcher_stations = storage.cannon_launcher_stations or {}
    storage.cannon_receiver_stations = storage.cannon_receiver_stations or {}
    storage.scheduled_deliveries = storage.scheduled_deliveries or {}
    -- storage.update_task = storage.next_update_tick or {}
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
            local driver = proxy_container.surface.create_entity { name = "logistic-cannon-driver", position = proxy_container.position, force = proxy_container.force }
            station_entity.set_driver(driver)
            station_entity.driver_is_gunner = true
            station_entity.destructible = false
            storage.cannon_launcher_stations[station_entity.unit_number] = {
                proxy_entity = proxy_container,
                station_entity = station_entity,
                current_ammo = "",
                payload_size = nil,
                dirty = true,
                receivers_in_range = {},
                loaded_ammo = nil,
                scheduled_delivery = nil,
            }
            storage.proxy_to_station_id[proxy_container.unit_number] = station_entity.unit_number
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
            storage.cannon_receiver_stations[station_entity.unit_number] = {
                proxy_entity = proxy_container,
                station_entity = station_entity,
                delivery_requests = {},
                launchers_in_range = {},
                scheduled_deliveries = {},
            }
            storage.proxy_to_station_id[proxy_container.unit_number] = station_entity.unit_number
        else
            proxy_container.die()
        end
    end
end

-- function logistic_control.on_tick(tick)
--     local tasks = storage.update_task[tick]
--     if tasks then
--         for _, func in ipairs(tasks) do
--             func(tick)
--         end
--         storage.update_task[tick] = nil
--     end
-- end

---@param src LuaInventory
---@param dst LuaInventory
---@param item PrototypeWithQuality
---@param count uint
---@return uint transferred
local function transfer_items(src, dst, item, count)
    if not item.quality then item.quality = "normal" end
    local src_i = 1
    local dst_i = 1
    local transferred = 0

    while transferred < count and src_i <= #src and dst_i <= #dst do
        -- Find matching source stack
        local src_stack = src[src_i] ---@type LuaItemStack
        if
            not src_stack.valid_for_read or
            src_stack.name ~= item.name or src_stack.quality.name ~= item.quality
        then
            src_i = src_i + 1
            goto continue
        end

        local dst_stack = dst[dst_i] ---@type LuaItemStack
        -- Try transferring to destination stack
        local src_count_before = src_stack.count
        dst_stack.transfer_stack(src_stack, count - transferred)
        transferred = transferred + (src_count_before - src_stack.count)
        if src_stack.count == 0 then
            src_i = src_i + 1
            if dst_stack.count >= dst_stack.prototype.stack_size then
                dst_i = dst_i + 1
            end
        else
            dst_i = dst_i + 1
        end
        ::continue::
    end
    return transferred
end

---@param src LuaInventory
---@param dst LuaInventory
local function dump_items(src, dst)
    for i = 1, #src do
        local src_stack = src[i]
        if src_stack.valid_for_read then
            src_stack.count = src_stack.count - dst.insert(src_stack)
        end
    end
end

function logistic_control.update_delivery()
    for launcher_station_id, launcher_station_data in pairs(storage.cannon_launcher_stations) do
        if launcher_station_data.station_entity.valid then
            local ammo_slot = launcher_station_data.station_entity.get_inventory(defines.inventory.car_ammo)[1]
            local current_ammo = ""
            if ammo_slot.valid_for_read then
                current_ammo = ammo_slot.name
            end
            if current_ammo == launcher_station_data.current_ammo and not launcher_station_data.dirty then
                goto continue
            end
            launcher_station_data.current_ammo = current_ammo
            launcher_station_data.dirty = false
            if current_ammo ~= "" then
                launcher_station_data.payload_size = prototypes.mod_data[constants.name_prefix .. "payload-sizes"].data
                    [current_ammo]
            else
                launcher_station_data.payload_size = -1
            end
            for _, receiver_station_id in ipairs(launcher_station_data.receivers_in_range) do
                storage.cannon_receiver_stations[receiver_station_id].launchers_in_range[launcher_station_id] = nil
            end
            launcher_station_data.receivers_in_range = {}
            --todo get range from ammo / turret state
            local maximum_range = 300 * 300
            if maximum_range > 0 then
                for receiver_station_id, receiver_station_data in pairs(storage.cannon_receiver_stations) do
                    if receiver_station_data.station_entity.surface == launcher_station_data.station_entity.surface then
                        local d = math2d.position.distance_squared(receiver_station_data.station_entity.position,
                            launcher_station_data.station_entity.position)
                        if d <= maximum_range then
                            table.insert(launcher_station_data.receivers_in_range, receiver_station_id)
                            table.insert(receiver_station_data.launchers_in_range, launcher_station_id)
                        end
                    end
                end
            end
        end
        ::continue::
    end
    for receiver_station_id, receiver_station_data in pairs(storage.cannon_receiver_stations) do
        local receiver_inventory = receiver_station_data.station_entity.get_inventory(defines.inventory.chest)
        for _, request_data in ipairs(receiver_station_data.delivery_requests) do
            local demand = request_data.amount -
            receiver_inventory.get_item_count_filtered { name = request_data.name, quality = request_data.quality }
            if demand < 0 then
                goto continue_reciver
            end
            local incoming = 0
            for _, delivery in pairs(receiver_station_data.scheduled_deliveries) do
                if delivery.item == request_data.name and delivery.quality == request_data.quality then
                    incoming = incoming + delivery.count
                end
            end
            if demand - incoming < 0 then
                goto continue_reciver
            end
            for _, launcher_station_id in ipairs(receiver_station_data.launchers_in_range) do
                local payload_size = storage.cannon_launcher_stations[launcher_station_id].payload_size
                if logistic_control.is_launcher_station_ready(launcher_station_id) then
                    local inventory = storage.cannon_launcher_stations[launcher_station_id].station_entity.get_inventory(
                        defines.inventory.car_trunk)
                    local available_count = inventory.get_item_count_filtered { name = request_data.name, quality = request_data.quality }
                    local payload_count = payload_size * prototypes.item[request_data.name].stack_size
                    if available_count >= payload_count and payload_count <= demand - incoming and
                        logistic_control.is_receiver_station_ready(receiver_station_id, request_data.name, request_data.quality, payload_count) then
                        logistic_control.schedule_delivery(launcher_station_id, receiver_station_id, request_data.name,
                            request_data.quality, payload_count)
                        incoming = incoming + payload_count
                    end
                end
            end
            ::continue_reciver::
        end
    end
end

function logistic_control.is_launcher_station_ready(launcher_station_id)
    local station = storage.cannon_launcher_stations[launcher_station_id]
    if station.current_ammo == "" or station.scheduled_delivery ~= nil then
        return false
    end
    -- todo check buffer_capacity
    return true
end

function logistic_control.is_receiver_station_ready(receiver_station_id, item_name, quality, count)
    -- todo check item capacity
    return true
end

function logistic_control.schedule_delivery(launcher_station_id, receiver_station_id, item_name, quality, count)
    local launcher_data = storage.cannon_launcher_stations[launcher_station_id]
    local receiver_data = storage.cannon_receiver_stations[receiver_station_id]
    local position = receiver_data.station_entity.position
    -- local delivery_id = tostring(launcher_station_id) .. "." .. tostring(game.tick) -- I should use capsule id?
    local capsule_storage = receiver_data.station_entity.surface.create_entity {
        name = "cannon-capsule-storage",
        position = position,
    }
    local delivery_id = capsule_storage.unit_number
    local delivery_data = {
        id = delivery_id,
        capsule_entity = capsule_storage,
        receiver = receiver_data,
        delivery_ammo = launcher_data.current_ammo,
        schedule_time = game.tick,
        item = item_name,
        count = count,
        quality = quality,
    }
    -- game.print(serpent.block(delivery_data))
    --todo check timeout
    storage.scheduled_deliveries[delivery_id] = delivery_data
    launcher_data.scheduled_delivery = delivery_data
    receiver_data.scheduled_deliveries[delivery_id] = delivery_data
    local driver = launcher_data.station_entity.get_driver()
    if driver and driver.name == "logistic-cannon-driver" then
        driver.shooting_state = { state = defines.shooting.shooting_selected, position = position }
    end
end

function logistic_control.on_cannon_launched(event)
    if event.source_entity and event.source_entity.valid and event.source_entity.name == "logistic-cannon-launcher-entity" then
        local driver = event.source_entity.get_driver()
        if driver and driver.name == "logistic-cannon-driver" then
            local next_driver = event.source_entity.surface.create_entity { name = "logistic-cannon-driver", position = event.source_entity.position, force = event.source_entity.force }
            event.source_entity.set_driver(next_driver)
            driver.destroy()
        end
        local launcher_data = storage.cannon_launcher_stations[event.source_entity.unit_number]
        if not launcher_data or not launcher_data.scheduled_delivery then
            game.print(launcher_data.scheduled_delivery)
            return -- how?
        end
        local delivery = launcher_data.scheduled_delivery
        local ammo_item = event.source_entity.get_inventory(defines.inventory.car_ammo)[1]
        local delivery_failed = true
        launcher_data.scheduled_delivery = nil -- reset delivery state for launcher
        if ammo_item.valid_for_read and ammo_item.name == delivery.delivery_ammo and event.target_position and event.source_position then
            game.print("L2")
            -- could become partial delivery
            local capsule = delivery.capsule_entity.get_inventory(defines.inventory.chest)
            local trunk = event.source_entity.get_inventory(defines.inventory.car_trunk)
            local count = transfer_items(trunk, capsule, { name = delivery.item, quality = delivery.quality },
                delivery.count)
            if count > 0 then
                delivery.count = count
                if ammo_item.count == 1 then
                    ammo_item.clear() -- TODO it still auto load ammo from truck
                else
                    ammo_item.drain_ammo(1)
                end
                event.source_entity.surface.create_entity {
                    name = "logistic-cannon-capsule-projectile",
                    position = event.source_position,
                    direction = event.source_entity.direction,
                    quality = event.source_entity.quality,
                    force = event.source_entity.force,
                    source = event.source_position,
                    target = event.target_position,
                }
                event.source_entity.surface.create_entity {
                    name = "logistic-cannon-capsule-tracker",
                    position = event.source_position,
                    direction = event.source_entity.direction,
                    quality = event.source_entity.quality,
                    force = event.source_entity.force,
                    source = event.source_position,
                    target = delivery.capsule_entity,
                }
                delivery_failed = false
            end
        end
        if delivery_failed then
            -- move to other method?
            delivery.capsule_entity.destroy()
            delivery.receiver.scheduled_deliveries[delivery.id] = nil
            storage.scheduled_deliveries[delivery.id] = nil
        end
    end
end

function logistic_control.on_capsule_landed(event)
    if event.target_entity and event.target_entity.valid and event.target_entity.name == "cannon-capsule-storage" then
        local capsule_inventory = event.target_entity.get_inventory(defines.inventory.chest)
        local delivery_id = event.target_entity.unit_number
        local proxy_receiver = event.target_entity.surface.find_entity("logistic-cannon-receiver",
            event.target_entity.position)
        local delivery = storage.scheduled_deliveries[delivery_id]
        -- clear delivery state
        if delivery then
            delivery.receiver.scheduled_deliveries[delivery_id] = nil
            storage.scheduled_deliveries[delivery_id] = nil
        end
        if proxy_receiver and storage.proxy_to_station_id[proxy_receiver.unit_number] then
            local receiver_data = storage.cannon_receiver_stations
                [storage.proxy_to_station_id[proxy_receiver.unit_number]]
            local container = receiver_data.station_entity.get_inventory(defines.inventory.chest)
            dump_items(capsule_inventory, container)
            if not capsule_inventory.is_empty() then
                event.target_entity.surface.spill_inventory{position=event.target_entity.position, inventory=capsule_inventory}
            end
        end
        -- destroy capsule container TODO it should subscribe destroy event?
        event.target_entity.destroy()
        -- game.print(event.target_position)
    end
end

-- problem: item will vanish if deconstruct by player or robot
function logistic_control.on_entity_destroyed(entity_id)
    local station_id = storage.proxy_to_station_id[entity_id]
    if station_id then
        if storage.cannon_launcher_stations[station_id] then
            local station_entity = storage.cannon_launcher_stations[station_id].station_entity
            if station_entity and station_entity.valid then
                local driver = station_entity.get_driver()
                if driver and driver.valid and driver.name == "logistic-cannon-driver" then
                    driver.destroy()
                end
                station_entity.destroy()
            end
        end
        if storage.cannon_receiver_stations[station_id] then
            local station_entity = storage.cannon_receiver_stations[station_id].station_entity
            if station_entity and station_entity.valid then
                station_entity.destroy()
            end
        end
    end
end

return logistic_control
