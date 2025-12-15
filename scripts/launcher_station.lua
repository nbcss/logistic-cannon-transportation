local constants = require("constants")
local util = require("util")
local math2d = require("math2d")
local ReceiverStation ---@module "scripts.receiver_station"
local ScheduledDelivery ---@module "scripts.scheduled_delivery"
local inventory_tool = require("scripts.inventory_tool")

local LauncherStation = {}
function LauncherStation.load_deps()
    ReceiverStation = require("scripts.receiver_station")
    ScheduledDelivery = require("scripts.scheduled_delivery")
end

---Represents a cannon launcher in storage, lifetime synchronized with associated entities.
---@class LauncherStation
---@field proxy_entity LuaEntity The proxy container.
---@field station_entity LuaEntity The tank.
---@field proxy_id uint64 The unit number of proxy container
---@field station_id uint64 The unit number of station entity
---@field loaded_ammo string Prototype name of the loaded ammo, empty string means no ammo.
---@field receivers_in_range ReceiverStation[]
---@field scheduled_delivery ScheduledDelivery? The delivery being scheduled for launch.-- FIXME
---@field settings LauncherStationSettings
LauncherStation.prototype = {}
LauncherStation.prototype.__index = LauncherStation.prototype

---User-configurable settings of a cannon launcher, POD.
---@class (exact) LauncherStationSettings
LauncherStation.default_settings = {}


function LauncherStation.on_init()
    ---@type table<uint64, LauncherStation?> LauncherStation's indexed by station_entity.unit_number.
    storage.launcher_stations = storage.launcher_stations or {}
    ---@type table<uint64, uint64?> Index of LauncherStation proxy_entity.unit_number to station_entity.unit_number.
    storage.launcher_stations_index_proxy_entity = storage.launcher_stations_index_proxy_entity or {}
end

---Create a LauncherStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@return LauncherStation
function LauncherStation.create(entity)
    assert(entity.name == constants.entity_launcher)

    if storage.launcher_stations_index_proxy_entity[entity.unit_number] then
        error()
    end

    local station_entity = entity.surface.create_entity {
        name = constants.entity_launcher_entity,
        position = entity.position,
        force = entity.force,
        quality = entity.quality
    } or error()

    local instance = setmetatable({
        proxy_entity = entity,
        station_entity = station_entity,
        proxy_id = entity.unit_number,
        station_id = station_entity.unit_number,
        loaded_ammo = "",
        receivers_in_range = {},
        scheduled_delivery = nil,
        settings = util.table.deepcopy(LauncherStation.default_settings),
    } --[[@as LauncherStation]], LauncherStation.prototype)

    script.register_on_object_destroyed(instance.proxy_entity)
    script.register_on_object_destroyed(instance.station_entity)

    instance.station_entity.destructible = false
    instance.proxy_entity.proxy_target_entity = instance.station_entity
    instance.proxy_entity.proxy_target_inventory = defines.inventory.car_trunk
    instance.station_entity.driver_is_gunner = true
    instance:set_aiming(nil) -- initialize driver

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
        storage.launcher_stations[storage.launcher_stations_index_proxy_entity[unit_number] or ""]
end

---Destroy a ReceiverStation following the destruction an associated entity.
---@param unit_number uint64 Unit number of the destroyed entity.
function LauncherStation.on_object_destroyed(unit_number)
    local instance = LauncherStation.get(unit_number)
    if not instance then return end

    storage.launcher_stations[instance.station_id] = nil
    storage.launcher_stations_index_proxy_entity[instance.proxy_id] = nil
    if instance.proxy_entity.valid then
        instance.proxy_entity.destroy()
    end
    if instance.station_entity.valid then
        local driver = instance.station_entity.get_driver()
        if driver and driver.valid and driver.name == "logistic-cannon-controller" then
            driver.destroy()
        end
        instance.station_entity.destroy()
    end
    -- TODO rebuild index
end

---Get an iterator over all LauncherStation's.
---@return fun():LauncherStation?
function LauncherStation.all()
    local key = nil
    return function()
        local value
        key, value = next(storage.launcher_stations, key)
        return value
    end
end

function LauncherStation.prototype:update()
    if not self:valid() then return end
    local ammo_slot = self:get_ammo_inventory()[1]
    local current_ammo = ""
    if ammo_slot.valid_for_read then
        current_ammo = ammo_slot.name
    end
    if current_ammo == self.loaded_ammo then
        return
    end
    self.loaded_ammo = current_ammo
    for _, receiver in pairs(self.receivers_in_range) do
        -- todo move to receiver's function?
        -- fixme it using the receivers' storage
        receiver.launchers_in_range[self:id()] = nil
    end
    self.receivers_in_range = {}
    --todo get range from ammo / turret state
    local maximum_range = 300 * 300
    if maximum_range > 0 then
        for receiver in ReceiverStation.all() do
            if receiver.station_entity.surface == self.station_entity.surface then
                local d = math2d.position.distance_squared(receiver:position(), self:position())
                if d <= maximum_range then
                    self.receivers_in_range[receiver:id()] = receiver
                    receiver.launchers_in_range[self:id()] = self
                end
            end
        end
    end
end

---@param receiver ReceiverStation
---@param item PrototypeWithQuality
---@param amount uint32
---@return ScheduledDelivery?
function LauncherStation.prototype:schedule_delivery(receiver, item, amount)
    local inventory = self:get_inventory()
    local available_count = inventory.get_item_count_filtered { name = item.name, quality = item.quality }
    local payload_count = self:get_max_payload_size() * prototypes.item[item.name].stack_size
    if available_count < payload_count or payload_count > amount then
        return nil
    end
    local delivery = ScheduledDelivery.create(self, receiver, item, payload_count)
    --todo check timeout
    self.scheduled_delivery = delivery
    self:set_aiming(delivery.position)
    return delivery
end

---@return boolean
function LauncherStation.prototype:is_ready()
    if self.loaded_ammo == "" or self.scheduled_delivery ~= nil then
        return false
    end
    -- todo check buffer_capacity
    return true
end

---@return LuaInventory
function LauncherStation.prototype:get_inventory()
    return self.station_entity.get_inventory(defines.inventory.car_trunk) --[[@as LuaInventory]]
end

---@return LuaInventory
function LauncherStation.prototype:get_ammo_inventory()
    return self.station_entity.get_inventory(defines.inventory.car_ammo) --[[@as LuaInventory]]
end

---@param source_position MapPosition
function LauncherStation.prototype:launch(source_position)
    self:set_aiming(nil)
    local delivery = self.scheduled_delivery
    if not self:valid() or not delivery then
        return
    end
    self.scheduled_delivery = nil -- reset delivery state for launcher
    local ammo_item = self:get_ammo_inventory()[1]
    if delivery:valid() and ammo_item.valid_for_read and ammo_item.name == delivery.delivery_ammo then
        -- could become partial delivery
        local capsule = delivery:get_inventory()
        local trunk = self:get_inventory()
        local amount = inventory_tool.transfer_items(trunk, capsule,
            { name = delivery.item, quality = delivery.quality },
            delivery.amount)
        if amount > 0 then
            delivery.amount = amount
            if ammo_item.count == 1 then
                ammo_item.clear() -- TODO it still auto load ammo from trunk
            else
                ammo_item.drain_ammo(1)
            end
            self.station_entity.surface.create_entity {
                name = "logistic-cannon-capsule-projectile",
                position = source_position,
                direction = self.station_entity.direction,
                force = self.station_entity.force,
                source = source_position,
                target = delivery.position,
            }
            self.station_entity.surface.create_entity {
                name = "logistic-cannon-capsule-tracker",
                position = source_position,
                direction = self.station_entity.direction,
                force = self.station_entity.force,
                source = source_position,
                target = delivery.capsule_entity,
            }
            return
        end
    end
    delivery:destroy()
end

---@param position MapPosition?
function LauncherStation.prototype:set_aiming(position)
    if not self:valid() then return end
    local driver = self.station_entity.get_driver() --[[@as LuaEntity]]
    if position then
        if not driver or driver.name ~= "logistic-cannon-controller" then
            driver = self.station_entity.surface.create_entity {
                name = "logistic-cannon-controller",
                position = self.station_entity.position,
                force = self.station_entity.force
            } or error()
            self.station_entity.set_driver(driver)
        end
        driver.shooting_state = { state = defines.shooting.shooting_selected, position = position }
    else
        local replace_driver = self.station_entity.surface.create_entity {
            name = "logistic-cannon-controller",
            position = self.station_entity.position,
            force = self.station_entity.force
        } or error()
        self.station_entity.set_driver(replace_driver)
        if driver and driver.name == "logistic-cannon-controller" then
            driver.destroy()
        end
    end
end

---@return ScheduledDelivery?
function LauncherStation.prototype:get_scheduled_delivery()
    return self.scheduled_delivery
end

---@return uint32?
function LauncherStation.prototype:get_max_payload_size()
    return prototypes.mod_data[constants.name_prefix .. "payload-sizes"].data[self.loaded_ammo] --[[@as integer?]]
end

---@return uint64
function LauncherStation.prototype:id()
    return self.station_id
end

---@return boolean
function LauncherStation.prototype:valid()
    return self.proxy_entity.valid and self.station_entity.valid
end

---@return MapPosition
function LauncherStation.prototype:position()
    return self.station_entity.position
end

return LauncherStation
