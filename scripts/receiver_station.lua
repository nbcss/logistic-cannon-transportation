local constants = require("constants")
local util = require("util")

local ReceiverStation = {}

---Represents a cannon receiver in storage, lifetime synchronized with associated entities.
---@class ReceiverStation
---@field proxy_entity LuaEntity The proxy container.
---@field station_entity LuaEntity The chest.
---@field launchers_in_range uint64[]
---@field scheduled_deliveries uint64[] Anticipated deliveries to this receiver.
---@field settings ReceiverStationSettings
ReceiverStation.prototype = {}
ReceiverStation.prototype.__index = ReceiverStation.prototype

---User-configurable settings of a cannon receiver, POD.
---@class (exact) ReceiverStationSettings
---@field delivery_requests {name: string, quality: string, count: uint32}[]
ReceiverStation.default_settings = {
    delivery_requests = {},
}


function ReceiverStation.on_init()
    ---@type table<uint64, ReceiverStation?> ReceiverStation's indexed by station_entity.unit_number.
    storage.receiver_stations = {}
    ---@type table<uint64, uint64?> Index of ReceiverStation proxy_entity.unit_number to station_entity.unit_number.
    storage.receiver_stations_index_proxy_entity = {}
end

---Create a ReceiverStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@return ReceiverStation
function ReceiverStation.create(entity)
    assert(entity.name == constants.entity_receiver)

    if storage.receiver_stations[entity.unit_number] then
        error()
    end

    local station_entity = entity.surface.create_entity {
        name = constants.entity_receiver_entity,
        position = entity.position,
        force = entity.force,
        quality = entity.quality
    } or error()

    local instance = setmetatable({
        proxy_entity = entity,
        station_entity = station_entity,
        launchers_in_range = {},
        scheduled_deliveries = {},
        settings = util.table.deepcopy(ReceiverStation.default_settings),
    } --[[@as ReceiverStation]], ReceiverStation.prototype)

    -- Configure receiver entities
    script.register_on_object_destroyed(instance.proxy_entity)
    script.register_on_object_destroyed(instance.station_entity)
    station_entity.destructible = false
    instance.proxy_entity.proxy_target_entity = station_entity
    instance.proxy_entity.proxy_target_inventory = defines.inventory.chest

    storage.receiver_stations[instance:id()] = instance
    storage.receiver_stations_index_proxy_entity[instance.proxy_entity.unit_number] = instance:id()
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
function ReceiverStation.destroy(unit_number)
    local instance = ReceiverStation.get(unit_number)
    if not instance then return end

    if instance.proxy_entity.valid then
        instance.proxy_entity.destroy()
        storage.receiver_stations_index_proxy_entity[instance.proxy_entity.unit_number] = nil
    end
    storage.receiver_stations_index_proxy_entity[unit_number] = nil

    if instance.station_entity.valid then
        instance.station_entity.destroy()
        storage.receiver_stations[instance.station_entity.unit_number] = nil
    end
    storage.receiver_stations[unit_number] = nil
end

---@return uint64
function ReceiverStation.prototype:id()
    return self.station_entity.unit_number
end

---@param delivery ScheduledDelivery
function ReceiverStation.prototype:on_delivery_scheduled(delivery)
    table.insert(self.scheduled_deliveries, delivery)
end

---@return boolean
function ReceiverStation.prototype:is_ready(receiver_station_id, item, amount)
    -- todo check item capacity
    return true
end

---@return MapPosition
function ReceiverStation.prototype:position()
    return self.station_entity.position
end

return ReceiverStation
