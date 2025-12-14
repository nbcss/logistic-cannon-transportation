local constants = require("constants")
local LauncherStation = require("scripts.launcher_station")
local ReceiverStation = require("scripts.receiver_station")
local ScheduledDelivery = require("scripts.scheduled_delivery")

local logistic_control = {}

function logistic_control.on_init()
    storage.proxy_to_station_id = storage.proxy_to_station_id or {}
    storage.launcher_stations = storage.launcher_stations or {}
    storage.cannon_receiver_stations = storage.cannon_receiver_stations or {}
    storage.scheduled_deliveries = storage.scheduled_deliveries or {}
    -- storage.update_task = storage.next_update_tick or {}
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
---@param amount uint
---@return uint transferred
local function transfer_items(src, dst, item, amount)
    if not item.quality then item.quality = "normal" end
    local src_i = 1
    local dst_i = 1
    local transferred = 0

    while transferred < amount and src_i <= #src and dst_i <= #dst do
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
        dst_stack.transfer_stack(src_stack, amount - transferred)
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
function logistic_control.dump_items(src, dst)
    for i = 1, #src do
        local src_stack = src[i]
        if src_stack.valid_for_read then
            src_stack.count = src_stack.count - dst.insert(src_stack)
        end
    end
end

function logistic_control.update_delivery()
    -- for launcher in LauncherStation.all() do
    --     launcher:update()
    -- end
    -- for receiver in ReceiverStation.all() do
    --     receiver:update()
    -- end
end

function logistic_control.on_cannon_launched(event)
    if event.source_entity and event.source_entity.valid and event.source_entity.name == "logistic-cannon-launcher-entity" then
        local launcher = LauncherStation.get(event.source_entity) or error()
        launcher:set_shooting(nil)
        local delivery = launcher:get_scheduled_delivery()
        if not delivery then return end
        
    end
    if event.source_entity and event.source_entity.valid and event.source_entity.name == "logistic-cannon-launcher-entity" then
        local driver = event.source_entity.get_driver()
        if driver and driver.name == "logistic-cannon-controller" then
            local next_driver = event.source_entity.surface.create_entity { name = "logistic-cannon-controller", position = event.source_entity.position, force = event.source_entity.force }
            event.source_entity.set_driver(next_driver)
            driver.destroy()
        end
        local launcher_data = storage.launcher_stations[event.source_entity.unit_number]
        if not launcher_data or not launcher_data.scheduled_delivery then
            return -- how?
        end
        local delivery = launcher_data.scheduled_delivery
        local ammo_item = event.source_entity.get_inventory(defines.inventory.car_ammo)[1]
        local delivery_failed = true
        launcher_data.scheduled_delivery = nil -- reset delivery state for launcher
        if ammo_item.valid_for_read and ammo_item.name == delivery.delivery_ammo and event.target_position and event.source_position then
            -- could become partial delivery
            local capsule = delivery.capsule_entity.get_inventory(defines.inventory.chest)
            local trunk = event.source_entity.get_inventory(defines.inventory.car_trunk)
            local amount = transfer_items(trunk, capsule, { name = delivery.item, quality = delivery.quality }, delivery.amount)
            if amount > 0 then
                delivery.amount = amount
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
                -- TODO add alert/effect
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
        if storage.launcher_stations[station_id] then
            local station_entity = storage.launcher_stations[station_id].station_entity
            if station_entity and station_entity.valid then
                local driver = station_entity.get_driver()
                if driver and driver.valid and driver.name == "logistic-cannon-controller" then
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
        LauncherStation.destroy(station_id)
        ReceiverStation.destroy(station_id)
    end
end

return logistic_control
