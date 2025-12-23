local constants = require("constants")
local util = require("util")
local CannonNetwork ---@module "scripts.cannon_network"
local ScheduledDelivery ---@module "scripts.scheduled_delivery"
local LauncherStation ---@module "scripts.launcher_station"

local ReceiverStation = {}
function ReceiverStation.load_deps()
    CannonNetwork = require("scripts.cannon_network")
    LauncherStation = require("scripts.launcher_station")
    ScheduledDelivery = require("scripts.scheduled_delivery")
end

---Represents a cannon receiver in storage, lifetime synchronized with associated entities.
---@class ReceiverStation
---@field proxy_entity LuaEntity The proxy container.
---@field station_entity LuaEntity The regular container.
---@field proxy_id uint64 The unit number of proxy container
---@field station_id uint64 The unit number of station entity
---@field name string Custom name of the station.
---@field network CannonNetwork The netowrk that the station belongs to
---@field scheduled_deliveries table<uint64, ScheduledDelivery> Anticipated deliveries to this receiver.
---@field settings ReceiverStationSettings
ReceiverStation.prototype = {}
ReceiverStation.prototype.__index = ReceiverStation.prototype

---User-configurable settings of a cannon receiver, POD.
---@class (exact) ReceiverStationSettings
---@field delivery_requests {name: string, quality: string, amount: uint32}[]
ReceiverStation.default_settings = {
    delivery_requests = {},
}

function ReceiverStation.on_init()
    ---@type table<uint64, ReceiverStation?> ReceiverStation's indexed by station_entity.unit_number.
    storage.receiver_stations = storage.receiver_stations or {}
    ---@type table<uint64, uint64?> Index of ReceiverStation proxy_entity.unit_number to station_entity.unit_number.
    storage.receiver_stations_index_proxy_entity = storage.receiver_stations_index_proxy_entity or {}
end

---Create a ReceiverStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@return ReceiverStation
function ReceiverStation.create(entity)
    assert(entity.name == constants.entity_receiver)

    if storage.receiver_stations_index_proxy_entity[entity.unit_number] then
        error()
    end

    local station_entity = entity.surface.create_entity {
        name = constants.entity_receiver_entity,
        position = entity.position,
        force = entity.force,
        quality = entity.quality
    } or error()

    local network = CannonNetwork.get_or_create(entity.force --[[@as LuaForce]], entity.surface)
    
    local instance = setmetatable({
        proxy_entity = entity,
        station_entity = station_entity,
        proxy_id = entity.unit_number,
        station_id = station_entity.unit_number,
        name = "",
        network = network,
        scheduled_deliveries = {},
        settings = util.table.deepcopy(ReceiverStation.default_settings),
    } --[[@as ReceiverStation]], ReceiverStation.prototype)

    script.register_on_object_destroyed(instance.proxy_entity)
    script.register_on_object_destroyed(instance.station_entity)

    instance.station_entity.destructible = false
    instance.proxy_entity.proxy_target_entity = instance.station_entity
    instance.proxy_entity.proxy_target_inventory = defines.inventory.chest

    storage.receiver_stations[instance:id()] = instance
    storage.receiver_stations_index_proxy_entity[instance.proxy_entity.unit_number] = instance:id()
    network:add_receiver(instance)

    return instance
end

---Get a ReceiverStation from storage.
---@param entity LuaEntity | uint64 An associated entity or a unit number thereof.
---@return ReceiverStation?
function ReceiverStation.get(entity)
    local unit_number = type(entity) == "number" and entity or entity.unit_number
    return storage.receiver_stations[unit_number] or
        storage.receiver_stations[storage.receiver_stations_index_proxy_entity[unit_number]]
end

---Destroy a ReceiverStation following the destruction an associated entity.
---@param unit_number uint64 Unit number of the destroyed entity.
function ReceiverStation.on_object_destroyed(unit_number)
    local instance = ReceiverStation.get(unit_number)
    if not instance then return end

    storage.receiver_stations[instance.station_id] = nil
    storage.receiver_stations_index_proxy_entity[instance.proxy_id] = nil
    if instance.proxy_entity.valid then
        instance.proxy_entity.destroy()
    end
    if instance.station_entity.valid then
        instance.station_entity.destroy()
    end
    instance.network:remove_receiver(unit_number)
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

---@param delivery ScheduledDelivery
function ReceiverStation.prototype:add_delivery(delivery)
    self.scheduled_deliveries[delivery:id()] = delivery
end

---@return LuaInventory
function ReceiverStation.prototype:get_inventory()
    return self.station_entity.get_inventory(defines.inventory.chest) --[[@as LuaInventory]]
end

---@return uint64
function ReceiverStation.prototype:id()
    return self.station_id
end

---@return boolean
function ReceiverStation.prototype:valid()
    return self.proxy_entity.valid and self.station_entity.valid
end

---@return MapPosition
function ReceiverStation.prototype:position()
    return self.station_entity.position
end

return ReceiverStation
