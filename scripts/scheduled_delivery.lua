local constants = require("constants")
local ReceiverStation = require("scripts.receiver_station")
local inventory_tool = require("scripts.inventory_tool")

local ScheduledDelivery = {}

---Represents a scheduled or ongoing delivery.
---@class ScheduledDelivery
---@field delivery_id uint64 Id of the delivery
---@field capsule_entity LuaEntity Temporary container containing items in the delivery.
---@field launcher LauncherStation
---@field receiver ReceiverStation
---@field ammo_name string Prototype name of ammo used.
---@field ammo_quality LuaQualityPrototype? Quality of ammo used.
---@field created_time MapTick When the delivery was created.
---@field position MapPosition Target position
---@field item string Name of the item delivered.
---@field quality string? Quality of the item delivered.
---@field amount uint32 Number of items delivered.
ScheduledDelivery.prototype = {}
ScheduledDelivery.prototype.__index = ScheduledDelivery.prototype

local alert_icon = {
    type = "virtual",
    name = "signal-alert",
}
local alert_message = {"", { "gui-alert-tooltip.capsule-delivery-failed" }}

function ScheduledDelivery.on_init()
    ---@type table<uint64, ScheduledDelivery?> ScheduledDelivery's indexed by capsule_entity.unit_number.
    storage.scheduled_deliveries = storage.scheduled_deliveries or {}
end

---Create a CannonDelivery in storage and its associated entities.
---@param launcher LauncherStation
---@param receiver ReceiverStation
---@param item ItemWithQualityCount
---@param capsule_size uint
---@return ScheduledDelivery
function ScheduledDelivery.create(launcher, receiver, item, capsule_size)
    local capsule_entity = receiver.inventory_entity.surface.create_entity {
        name = constants.entity_capsule_container,
        position = receiver:position(),
        force = launcher.network.force
    } or error()

    local instance = setmetatable({
        delivery_id = capsule_entity.unit_number,
        capsule_entity = capsule_entity,
        launcher = launcher,
        receiver = receiver,
        ammo_name = launcher.ammo_name,
        ammo_quality = launcher.ammo_quality,
        created_time = game.tick,
        position = receiver:position(),
        item = item.name,
        quality = item.quality,
        amount = item.count,
    } --[[@as ScheduledDelivery]], ScheduledDelivery.prototype)

    script.register_on_object_destroyed(capsule_entity)
    instance.capsule_entity.set_inventory_size_override(defines.inventory.chest, capsule_size)
    instance.capsule_entity.destructible = false

    storage.scheduled_deliveries[instance:id()] = instance
    return instance
end

---@param unit_number uint64 Unit number of the destroyed entity.
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

---@param ammo_slot LuaItemStack
---@return boolean
function ScheduledDelivery.prototype:is_matching_ammo(ammo_slot)
    return ammo_slot.valid_for_read and self.ammo_name == ammo_slot.name and self.ammo_quality == ammo_slot.quality
end

function ScheduledDelivery.prototype:deliver()
    local surface = self.capsule_entity.surface
    local capsule_inventory = self:get_inventory()
    local receiver_entity = surface.find_entities_filtered {
        name = constants.entity_receiver_inventory,
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
        local force = self.capsule_entity.force
        local items = surface.spill_inventory { position = self.position, inventory = capsule_inventory }
        surface.create_entity {
            name = "medium-explosion",
            position = self.position,
        }
        for _, item in ipairs(items) do
            item.order_deconstruction(force)
        end
        for _, player in ipairs(force.players) do
            player.add_custom_alert(self.capsule_entity, alert_icon, alert_message, true)
        end
    end
    self:destroy()
end

function ScheduledDelivery.prototype:destroy()
    self.capsule_entity.destroy()
end

return ScheduledDelivery
