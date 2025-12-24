local ReceiverStation = require("scripts.receiver_station")
local inventory_tool = require("scripts.inventory_tool")

local ScheduledDelivery = {}

---Represents a scheduled or ongoing delivery.
---@class ScheduledDelivery
---@field delivery_id uint64 Id of the delivery
---@field capsule_entity LuaEntity Temporary container containing items in the delivery.
---@field launcher LauncherStation
---@field receiver ReceiverStation
---@field delivery_ammo string Prototype name of ammo used.
---@field created_time MapTick When the delivery was created.
---@field position MapPosition Target position
---@field item string Name of the item delivered.
---@field quality string? Quality of the item delivered.
---@field amount uint32 Number of items delivered.
ScheduledDelivery.prototype = {}
ScheduledDelivery.prototype.__index = ScheduledDelivery.prototype

function ScheduledDelivery.on_init()
    ---@type table<uint64, ScheduledDelivery?> ScheduledDelivery's indexed by capsule_entity.unit_number.
    storage.scheduled_deliveries = storage.scheduled_deliveries or {}
end

---Create a CannonDelivery in storage and its associated entities.
---@param launcher LauncherStation
---@param receiver ReceiverStation
---@param item ItemWithQualityCount
---@return ScheduledDelivery
function ScheduledDelivery.create(launcher, receiver, item)
    local capsule_storage = receiver.station_entity.surface.create_entity {
        name = "cannon-capsule-storage",
        position = receiver:position(),
    } or error()

    local instance = setmetatable({
        delivery_id = capsule_storage.unit_number,
        capsule_entity = capsule_storage,
        launcher = launcher,
        receiver = receiver,
        delivery_ammo = launcher.loaded_ammo,
        created_time = game.tick,
        position = receiver:position(),
        item = item.name,
        quality = item.quality,
        amount = item.count,
    } --[[@as ScheduledDelivery]], ScheduledDelivery.prototype)

    script.register_on_object_destroyed(capsule_storage)

    storage.scheduled_deliveries[instance:id()] = instance
    return instance
end

function ScheduledDelivery.on_object_destroyed(unit_number)
    local delivery = ScheduledDelivery.get(unit_number)
    if not delivery then return end
    storage.scheduled_deliveries[delivery:id()] = nil
    if delivery.receiver:valid() then
        delivery.receiver.scheduled_deliveries[delivery:id()] = nil
    end
    if delivery.launcher:valid() and delivery.launcher.scheduled_delivery == delivery then
        delivery.launcher.scheduled_delivery = nil
    end
end

---@param id uint64
---@return ScheduledDelivery?
function ScheduledDelivery.get(id)
    return storage.scheduled_deliveries[id]
end

---@return uint64
function ScheduledDelivery.prototype:id()
    return self.delivery_id
end

---@return boolean
function ScheduledDelivery.prototype:valid()
    return self.capsule_entity.valid
end

---@return LuaInventory
function ScheduledDelivery.prototype:get_inventory()
    return self.capsule_entity.get_inventory(defines.inventory.chest) --[[@as LuaInventory]]
end

function ScheduledDelivery.prototype:deliver()
    local capsule_inventory = self:get_inventory()
    local receiver_entity = self.capsule_entity.surface.find_entities_filtered{
        name = "logistic-cannon-receiver",
        position = self.position,
        limit = 1,
    }[1]
    if receiver_entity then
        local receiver = ReceiverStation.get(receiver_entity)
        if receiver and receiver:valid() then
            local receiver_inventory = receiver:get_inventory()
            inventory_tool.dump_items(capsule_inventory, receiver_inventory)
        end
    end
    if not capsule_inventory.is_empty() then
        -- TODO add alert/effect
        self.capsule_entity.surface.spill_inventory { position = self.position, inventory = capsule_inventory }
    end
    -- destroy capsule container TODO it should subscribe destroy event?
    self:destroy()
end

function ScheduledDelivery.prototype:destroy()
    self.capsule_entity.destroy()
end

return ScheduledDelivery
