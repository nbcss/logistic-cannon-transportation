local constants = require("constants")
local util = require("util")
local ScheduledDelivery = require("scripts.scheduled_delivery")
local LauncherStation = require("scripts.launcher_station")

local ReceiverStation = {}

---Represents a cannon receiver in storage, lifetime synchronized with associated entities.
---@class ReceiverStation
---@field proxy_entity LuaEntity The proxy container.
---@field station_entity LuaEntity The regular container.
---@field proxy_id uint64 The unit number of proxy container
---@field station_id uint64 The unit number of station entity
---@field launchers_in_range uint64[]
---@field scheduled_deliveries uint64[] Anticipated deliveries to this receiver.
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

    local instance = setmetatable({
        proxy_entity = entity,
        station_entity = station_entity,
        proxy_id = entity.unit_number,
        station_id = station_entity.unit_number,
        launchers_in_range = {},
        scheduled_deliveries = {},
        settings = util.table.deepcopy(ReceiverStation.default_settings),
    } --[[@as ReceiverStation]], ReceiverStation)

    script.register_on_object_destroyed(instance.proxy_entity)
    script.register_on_object_destroyed(instance.station_entity)

    instance.station_entity.destructible = false
    instance.proxy_entity.proxy_target_entity = instance.station_entity
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
    -- TODO rebuild index
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

function ReceiverStation.prototype:update()
    local inventory = self:get_inventory()
    for _, request in ipairs(self.settings.delivery_requests) do
        local demand = request.amount - inventory.get_item_count_filtered { name = request.name, quality = request.quality }
        if demand < 0 then
            goto continue
        end
        local incoming = 0
        -- TODO can be optimized
        for _, delivery_id in pairs(self.scheduled_deliveries) do
            local delivery = ScheduledDelivery.get(delivery_id)
            if delivery and delivery.item == request.name and delivery.quality == request.quality then
                incoming = incoming + delivery.amount
            end
        end
        if demand - incoming < 0 then
            goto continue
        end
        for _, launcher_station_id in ipairs(self.launchers_in_range) do
            local launcher = LauncherStation.get(launcher_station_id)
            if launcher and launcher:is_ready() then
                local payload_size = launcher:get_max_payload_size()
                local inventory = launcher:get_inventory()
                local available_count = inventory.get_item_count_filtered { name = request.name, quality = request.quality }
                local payload_count = payload_size * prototypes.item[request.name].stack_size
                local item = { name = request.name, quality = request.quality }
                if available_count >= payload_count and payload_count <= demand - incoming and self:is_ready() then
                    local delivery = ScheduledDelivery.create(launcher, self, item, payload_count)
                    table.insert(self.scheduled_deliveries, delivery:id())
                    launcher:set_delivery(delivery)
                    incoming = incoming + payload_count
                end
            end
        end
        ::continue::
    end
end

---@return LuaInventory
function ReceiverStation.prototype:get_inventory()
    return self.station_entity.get_inventory(defines.inventory.chest) --[[@as LuaInventory]]
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

---@return uint64
function ReceiverStation.prototype:id()
    return self.station_entity.unit_number
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
