local constants = require("constants")
local util = require("util")
local visualization_control = require("scripts.visualization_control")
local signal_condition = require("scripts.gui.signal_condition")
local CannonNetwork ---@module "scripts.cannon_network"

local ReceiverStation = {}
function ReceiverStation.load_deps()
    CannonNetwork = require("scripts.cannon_network")
end

---Represents a cannon receiver in storage, lifetime synchronized with associated entities.
---@class ReceiverStation
---@field inventory_entity LuaEntity The inventory container.
---@field proxy_entity LuaEntity? The proxy container.
---@field station_id uint64 The unit number of station entity
---@field network CannonNetwork The netowrk that the station belongs to
---@field scheduled_deliveries table<uint64, ScheduledDelivery> Anticipated deliveries to this receiver.
---@field settings ReceiverStationSettings
ReceiverStation.prototype = {}
ReceiverStation.prototype.__index = ReceiverStation.prototype

---User-configurable settings of a cannon receiver, POD.
---@class (exact) ReceiverStationSettings
---@field name string? Custom name of the station.
---@field network_signal SignalID? Signal for network.
---@field delivery_requests {name: string, quality: string, amount: uint32}[]
---@field overflow_protection boolean
---@field circuit_enable_condition ModCircuitCondition
ReceiverStation.default_settings = {
    name = nil,
    network_signal = nil,
    delivery_requests = {},
    overflow_protection = true,
    circuit_enable_condition = signal_condition.default_value,
}

local clone_blacklist = {
    [constants.entity_receiver_gui_proxy] = true,
}

function ReceiverStation.on_init()
    ---@type table<uint64, ReceiverStation?> ReceiverStation's indexed by station_entity.unit_number.
    storage.receiver_stations = storage.receiver_stations or {}
end

---Create a ReceiverStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@param from_settings ReceiverStationSettings?
---@return ReceiverStation
function ReceiverStation.create(entity, from_settings)
    assert(entity.name == constants.entity_receiver_inventory)
    local surface = entity.surface
    local force = entity.force --[[@as LuaForce]]

    local receiver_settings = from_settings or util.table.deepcopy(ReceiverStation.default_settings)

    local instance = setmetatable({
        inventory_entity = entity,
        station_id = entity.unit_number,
        network = CannonNetwork.get_or_create(force, surface, receiver_settings.network_signal),
        scheduled_deliveries = {},
        settings = receiver_settings,
    } --[[@as ReceiverStation]], ReceiverStation.prototype)

    script.register_on_object_destroyed(instance.inventory_entity)

    storage.receiver_stations[instance:id()] = instance
    instance.network:add_receiver(instance)
    -- redirect opened GUI
    for _, player in ipairs(game.connected_players) do
        if player.opened == instance.inventory_entity then
            player.opened = instance:get_gui_proxy()
        end
    end

    return instance
end

---Get a ReceiverStation from storage.
---@param entity LuaEntity | uint64 An associated entity or a unit number thereof.
---@return ReceiverStation?
function ReceiverStation.get(entity)
    local unit_number
    if type(entity) == "number" then
        unit_number = entity
    elseif entity.name == constants.entity_receiver_gui_proxy then
        unit_number = entity.proxy_target_entity.unit_number
    else
        unit_number = entity.unit_number
    end
    return storage.receiver_stations[unit_number]
end

---@param tags Tags
---@param receiver_settings ReceiverStationSettings
function ReceiverStation.write_settings(tags, receiver_settings)
    tags["cannon_receiver_settings"] = receiver_settings
end

---@param tags Tags
function ReceiverStation.read_settings(tags)
    return tags and tags["cannon_receiver_settings"] or nil
end

---@param source LuaEntity
---@param destination LuaEntity
function ReceiverStation.on_entity_cloned(source, destination)
    if clone_blacklist[destination.name] then destination.destroy() end
    if destination.name ~= constants.entity_receiver_inventory then return end
    local src_receiver = ReceiverStation.get(source)
    local des_receiver = ReceiverStation.create(destination, src_receiver and src_receiver.settings)
    -- nothing to further clone
end

---@param entity LuaEntity
function ReceiverStation.on_entity_teleported(entity)
    if entity.name ~= constants.entity_receiver_inventory then return end
    local receiver = ReceiverStation.get(entity)
    if not receiver or not receiver:valid() then return end
    local position = entity.position
    if receiver.proxy_entity and receiver.proxy_entity.valid then
        receiver.proxy_entity.teleport(position)
    end
    receiver.network:update_receiver_connections(receiver)
end

---Destroy a ReceiverStation following the destruction an associated entity.
---@param unit_number uint64 Unit number of the destroyed entity.
function ReceiverStation.on_object_destroyed(unit_number)
    local instance = ReceiverStation.get(unit_number)
    if not instance then return end

    storage.receiver_stations[instance.station_id] = nil
    if instance.inventory_entity.valid then
        instance.inventory_entity.destroy()
    end
    if instance.proxy_entity and instance.proxy_entity.valid then
        instance.proxy_entity.destroy()
    end
    instance.network:remove_receiver(instance.station_id)
    visualization_control.on_station_remove(instance:id())
end

---Get an iterator over all ReceiverStation's.
---@return fun():ReceiverStation?
function ReceiverStation.all()
    local key = nil
    return function()
        local value
        key, value = next(storage.receiver_stations, key)
        return value
    end
end

function ReceiverStation.prototype:update_diode_status()
    local status = "entity-status.working"
    local diode = defines.entity_status_diode.green --[[@as defines.entity_status_diode]]
    if self:is_disabled() then
        status = "entity-status.disabled"
        diode = defines.entity_status_diode.red
    end
    self.inventory_entity.custom_status = {
        diode = diode,
        label = { "", { status } }
    }
    if self.proxy_entity and self.proxy_entity.valid then
        self.proxy_entity.custom_status = self.inventory_entity.custom_status
    end
end

---@return boolean
function ReceiverStation.prototype:is_disabled()
    if self.inventory_entity.to_be_deconstructed() then return true end
    if not self.settings.circuit_enable_condition.enabled then return false end

    return not signal_condition.evaluate(self.settings.circuit_enable_condition, function(signal)
        return self.inventory_entity.get_signal(signal, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
    end)
end

---@param include_ghost boolean
---@param wire defines.wire_connector_id?
---@return boolean
function ReceiverStation.prototype:is_circuit_connected(include_ghost, wire)
    if not wire then
        return
            self:is_circuit_connected(include_ghost, defines.wire_connector_id.circuit_red) or
            self:is_circuit_connected(include_ghost, defines.wire_connector_id.circuit_green)
    end
    local wire_connector = self.inventory_entity.get_wire_connector(wire, false)
    if not wire_connector then return false end
    local connection_count = wire_connector[include_ghost and "connection_count" or "real_connection_count"]--[[@as uint32]]
    return connection_count > 0
end

---@param network CannonNetwork
function ReceiverStation.prototype:set_network(network)
    if network ~= self.network then
        self.network:remove_receiver(self:id())
        self.network = network
        self.network:add_receiver(self)
        self.settings.network_signal = network.signal
    end
end

---@param signal SignalID?
function ReceiverStation.prototype:set_network_signal(signal)
    local force = self.inventory_entity.force --[[@as LuaForce]]
    local surface = self.inventory_entity.surface
    local network = CannonNetwork.get_or_create(force, surface, signal)
    self:set_network(network)
end

---@param receiver_settings ReceiverStationSettings
function ReceiverStation.prototype:set_settings(receiver_settings)
    self.settings = util.table.deepcopy(receiver_settings)
    self:set_network_signal(self.settings.network_signal)
end

---@param delivery ScheduledDelivery
function ReceiverStation.prototype:add_delivery(delivery)
    self.scheduled_deliveries[delivery:id()] = delivery
end

---@return LuaInventory
function ReceiverStation.prototype:get_inventory()
    return self.inventory_entity.get_inventory(defines.inventory.chest) --[[@as LuaInventory]]
end

---@return uint64
function ReceiverStation.prototype:id()
    return self.station_id
end

---@return boolean
function ReceiverStation.prototype:valid()
    return self.inventory_entity.valid
end

---@return MapPosition
function ReceiverStation.prototype:position()
    return self.inventory_entity.position
end

---@return LuaEntity
function ReceiverStation.prototype:get_gui_proxy()
    if self.proxy_entity and self.proxy_entity.valid then
        return self.proxy_entity
    end
    self.proxy_entity = self.inventory_entity.surface.create_entity {
        name = constants.entity_receiver_gui_proxy,
        position = self.inventory_entity.position,
        force = self.inventory_entity.force,
    } or error()
    self.proxy_entity.destructible = false
    self.proxy_entity.proxy_target_entity = self.inventory_entity
    self.proxy_entity.proxy_target_inventory = defines.inventory.chest
    return self.proxy_entity
end

return ReceiverStation
