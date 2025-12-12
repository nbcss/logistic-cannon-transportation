local ScheduledDelivery = {}

---Represents a scheduled or ongoing delivery.
---@class ScheduledDelivery
---@field capsule_entity LuaEntity Temporary container containing items in the delivery.
---@field receiver uint64 ID of the receiver.
---@field delivery_ammo string Prototype name of ammo used.
---@field created_time MapTick When the delivery was created.
---@field item string Name of the item delivered.
---@field quality string? Quality of the item delivered.
---@field amount uint32 Number of items delivered.
ScheduledDelivery.prototype = {}
ScheduledDelivery.prototype.__index = ScheduledDelivery.prototype


function ScheduledDelivery.on_init()
    ---@type table<uint64, ScheduledDelivery?> ScheduledDelivery's indexed by capsule_entity.unit_number.
    storage.scheduled_deliveries = {}
end

---Create a CannonDelivery in storage and its associated entities.
---@param launcher LauncherStation
---@param receiver ReceiverStation
---@param item PrototypeWithQuality
---@param amount uint32
---@return ScheduledDelivery
function ScheduledDelivery.create(launcher, receiver, item, amount)

    local capsule_storage = receiver.station_entity.surface.create_entity {
        name = "cannon-capsule-storage",
        position = receiver:position(),
    } or error()

    local instance = setmetatable({
        capsule_entity = capsule_storage,
        receiver = receiver:id(),
        delivery_ammo = launcher.loaded_ammo,
        created_time = game.tick,
        item = item.name,
        quality = item.quality,
        amount = amount,
    }--[[@as ScheduledDelivery]], ScheduledDelivery.prototype)

    storage.scheduled_deliveries[instance:id()] = instance
    return instance
end

---@return uint64
function ScheduledDelivery.prototype:id()
    return self.capsule_entity.unit_number
end

return ScheduledDelivery