local constants = require("constants")
local util = require("util")
local math2d = require("math2d")
local ScheduledDelivery = require("scripts.scheduled_delivery")

local LauncherStation = {}

---Represents a cannon launcher in storage, lifetime synchronized with associated entities.
---@class LauncherStation
---@field proxy_entity LuaEntity The proxy container.
---@field station_entity LuaEntity The tank.
---@field loaded_ammo string Prototype name of the loaded ammo, empty string means no ammo.
---@field receivers_in_range uint64[]
---@field scheduled_delivery uint64? The delivery being scheduled for launch.-- FIXME
---@field settings LauncherStationSettings
LauncherStation.prototype = {}
LauncherStation.prototype.__index = LauncherStation.prototype

---User-configurable settings of a cannon launcher, POD.
---@class (exact) LauncherStationSettings
LauncherStation.default_settings = {}


function LauncherStation.on_init()
    ---@type table<uint64, LauncherStation?> LauncherStation's indexed by station_entity.unit_number.
    storage.launcher_stations = {}
    ---@type table<uint64, uint64?> Index of LauncherStation proxy_entity.unit_number to station_entity.unit_number.
    storage.launcher_stations_index_proxy_entity = {}
end

---Create a LauncherStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@return LauncherStation
function LauncherStation.create(entity)
    assert(entity.name == constants.entity_launcher)

    if storage.launcher_stations[entity.unit_number] then
        error()
    end

    local station_entity = entity.surface.create_entity {
        name = constants.entity_launcher_entity,
        position = entity.position,
        force = entity.force,
        quality = entity.quality,
    } or error()

    local instance = setmetatable({
        proxy_entity = entity,
        station_entity = station_entity,
        loaded_ammo = "",
        receivers_in_range = {},
        scheduled_delivery = nil,
        settings = util.table.deepcopy(LauncherStation.default_settings),
    }--[[@as LauncherStation]], LauncherStation.prototype)

    -- Configure launcher entities
    script.register_on_object_destroyed(instance.proxy_entity)
    script.register_on_object_destroyed(instance.station_entity)
    instance.proxy_entity.proxy_target_entity = station_entity
    instance.proxy_entity.proxy_target_inventory = defines.inventory.car_trunk
    instance:get_or_create_driver()

    storage.launcher_stations[instance:id()] = instance
    storage.launcher_stations_index_proxy_entity[instance.proxy_entity.unit_number] = instance:id()
    return instance
end

---Get a LauncherStation from storage.
---@param entity LuaEntity | uint64 An associated entity or a unit number thereof.
---@return LauncherStation?
function LauncherStation.get(entity)
    local unit_number = type(entity) == "number" and entity or entity.unit_number
    return storage.launcher_stations[unit_number] or
        storage.launcher_stations[storage.launcher_stations_index_proxy_entity[unit_number]]
end

---Destroy a LauncherStation following the destruction an associated entity.
---@param unit_number uint64 Unit number of the destroyed entity.
function LauncherStation.destroy(unit_number)
    local instance = LauncherStation.get(unit_number)
    if not instance then return end

    if instance.proxy_entity.valid then
        instance.proxy_entity.destroy()
        storage.launcher_stations_index_proxy_entity[instance.proxy_entity.unit_number] = nil
    end
    storage.launcher_stations_index_proxy_entity[unit_number] = nil

    if instance.station_entity.valid then
        instance.station_entity.destroy()
        storage.launcher_stations[instance.station_entity.unit_number] = nil
    end
    storage.launcher_stations[unit_number] = nil
end

---@return uint64
function LauncherStation.prototype:id()
    return self.station_entity.unit_number
end

function LauncherStation.prototype:update()
    --FIXME check valid?
    local ammo_slot = self.station_entity.get_inventory(defines.inventory.car_ammo)[1]
    local current_ammo = ""
    if ammo_slot.valid_for_read then
        current_ammo = ammo_slot.name
    end
    if current_ammo == self.loaded_ammo then
        return
    end
    self.current_ammo = current_ammo
    for _, receiver_station_id in ipairs(self.receivers_in_range) do
        -- todo move to receiver's function?
        storage.cannon_receiver_stations[receiver_station_id].launchers_in_range[self:id()] = nil
    end
    self.receivers_in_range = {}
    --todo get range from ammo / turret state
    local maximum_range = 300 * 300
    if maximum_range > 0 then
        for receiver_station_id, receiver_station_data in pairs(storage.cannon_receiver_stations) do
            if receiver_station_data.station_entity.surface == self.station_entity.surface then
                local d = math2d.position.distance_squared(receiver_station_data.station_entity.position, self.station_entity.position)
                if d <= maximum_range then
                    table.insert(self.receivers_in_range, receiver_station_id)
                    table.insert(receiver_station_data.launchers_in_range, self:id())
                end
            end
        end
    end
end

---@param receiver ReceiverStation
---@param item PrototypeWithQuality
---@param amount uint32
function LauncherStation.prototype:schedule_delivery(receiver, item, amount)
    local delivery = ScheduledDelivery.create(self, receiver, item, amount)

    --todo check timeout
    self.scheduled_delivery = delivery:id()
    receiver:on_delivery_scheduled(delivery)

    local driver = self:get_or_create_driver()
    driver.shooting_state = { state = defines.shooting.shooting_selected, position = receiver:position() }
end

---@return boolean
function LauncherStation.prototype:is_ready()
    if self.loaded_ammo == "" or self.scheduled_delivery ~= nil then
        return false
    end
    -- todo check buffer_capacity
    return true
end

---@return LuaEntity
function LauncherStation.prototype:get_or_create_driver()
    local driver = self.station_entity.get_driver()--[[@as LuaEntity]]
    if driver and driver.name == "logistic-cannon-controller" then
        return driver
    end

    driver = self.station_entity.surface.create_entity {
        name = "logistic-cannon-controller",
        position = self.station_entity.position,
        force = self.station_entity.force
    } or error()
    self.station_entity.set_driver(driver)
    self.station_entity.driver_is_gunner = true
    self.station_entity.destructible = false
    return driver
end

---@return uint32?
function LauncherStation.prototype:get_max_payload_size()
    return prototypes.mod_data[constants.name_prefix .. "payload-sizes"].data[self.loaded_ammo]--[[@as integer?]]
end

return LauncherStation
