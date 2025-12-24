local constants = require("constants")
local util = require("util")
local math2d = require("math2d")
local bonus_control = require("scripts.bonus_control")
local CannonNetwork ---@module "scripts.cannon_network"
local ReceiverStation ---@module "scripts.receiver_station"
local ScheduledDelivery ---@module "scripts.scheduled_delivery"
local inventory_tool = require("scripts.inventory_tool")

local LauncherStation = {}
function LauncherStation.load_deps()
    CannonNetwork = require("scripts.cannon_network")
    ReceiverStation = require("scripts.receiver_station")
    ScheduledDelivery = require("scripts.scheduled_delivery")
end

---Represents a cannon launcher in storage, lifetime synchronized with associated entities.
---@class LauncherStation
---@field proxy_entity LuaEntity The proxy container.
---@field station_entity LuaEntity The tank.
---@field electric_interface LuaEntity The power interface.
---@field proxy_id uint64 The unit number of proxy container.
---@field station_id uint64 The unit number of station entity.
---@field name string Custom name of the station.
---@field loaded_ammo string Prototype name of the loaded ammo, empty string means no ammo.
---@field overflow_energy number The amount of overflow energy
---@field range_visualization LuaRenderObject[]
---@field network CannonNetwork The netowrk that the station belongs to
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
        quality = entity.quality,
    } or error()

    local electric_interface = entity.surface.create_entity {
        name = "cannon-launcher-energy-interface",
        position = entity.position,
        force = entity.force,
        quality = entity.quality,
    } or error()

    local range_visualization = {
        rendering.draw_circle {
            color = { 0.02, 0.08, 0.02, 0 },
            radius = 0,
            filled = true,
            target = station_entity,
            surface = station_entity.surface,
            players = {},
            draw_on_ground = true,
            render_mode = "game",
        },
        rendering.draw_circle {
            color = { 0.02, 0.08, 0.02, 0 },
            radius = 0,
            filled = true,
            target = station_entity,
            surface = station_entity.surface,
            players = {},
            draw_on_ground = true,
            render_mode = "chart",
        }
    }

    local network = CannonNetwork.get_or_create(entity.force --[[@as LuaForce]], entity.surface)

    local instance = setmetatable({
        proxy_entity = entity,
        station_entity = station_entity,
        electric_interface = electric_interface,
        proxy_id = entity.unit_number,
        station_id = station_entity.unit_number,
        name = "",
        loaded_ammo = "",
        overflow_energy = 0,
        range_visualization = range_visualization,
        network = network,
        scheduled_delivery = nil,
        settings = util.table.deepcopy(LauncherStation.default_settings),
    } --[[@as LauncherStation]], LauncherStation.prototype)

    script.register_on_object_destroyed(instance.proxy_entity)
    script.register_on_object_destroyed(instance.station_entity)

    instance.station_entity.destructible = false
    instance.electric_interface.destructible = false
    instance.proxy_entity.proxy_target_entity = instance.station_entity
    instance.proxy_entity.proxy_target_inventory = defines.inventory.car_trunk
    instance.station_entity.driver_is_gunner = true
    instance:set_aiming(nil) -- initialize driver

    storage.launcher_stations[instance:id()] = instance
    storage.launcher_stations_index_proxy_entity[instance.proxy_entity.unit_number] = instance:id()
    network:add_launcher(instance)
    for _, visualization in ipairs(range_visualization) do
        visualization.radius = instance:get_max_range()
    end
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
            driver.destroy() -- TODO add driver to storage?
        end
        instance.station_entity.destroy()
    end
    if instance.electric_interface.valid then
        instance.electric_interface.destroy()
    end
    for _, visualization in ipairs(instance.range_visualization) do
        if visualization.valid then
            visualization.destroy()
        end
    end
    instance.network:remove_launcher(instance.station_id)
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

---@return boolean if the state been changed
function LauncherStation.prototype:update_state()
    if not self:valid() then return false end
    local ammo_slot = self:get_ammo_inventory()[1]
    -- TODO consider ammo quality
    local current_ammo = ""
    if ammo_slot.valid_for_read then
        current_ammo = ammo_slot.name
    end
    local range = self:get_max_range()
    if current_ammo == self.loaded_ammo and range == self.range_visualization[1].radius then
        return false
    end
    -- cancel ongoing delivery if ammo changed
    if self.loaded_ammo ~= current_ammo and self.scheduled_delivery and self.scheduled_delivery:valid() then
        self.scheduled_delivery:destroy()
        self.scheduled_delivery = nil
    end
    self.loaded_ammo = current_ammo
    -- transfer overflow energy
    self.overflow_energy = self.overflow_energy + self.electric_interface.energy
    self.electric_interface.energy = 0
    self.electric_interface.electric_buffer_size = range * self:get_launch_consumption()
    local transfer = math.min(self.overflow_energy, self.electric_interface.electric_buffer_size)
    self.overflow_energy = self.overflow_energy - transfer
    self.electric_interface.energy = transfer
    -- update range visualization
    for _, visualization in ipairs(self.range_visualization) do
        visualization.radius = range
    end
    return true
end

function LauncherStation.prototype:get_max_range()
    if not self:valid() then return 0 end
    local range = self.station_entity.prototype.indexed_guns[1].attack_parameters.range
    local quality_modifier = self.station_entity.quality.range_multiplier
    local tech_modifier = 1.0 + bonus_control.get_launcher_range_bonus(self.station_entity.force --[[@as LuaForce]])
    return range * quality_modifier * tech_modifier
end

function LauncherStation.prototype:get_range()
    local consumption = self:get_launch_consumption()
    if consumption == 0 then return 0 end
    return math.min(self:get_max_range(), self:get_stored_energy() / consumption)
end

---@param player LuaPlayer
function LauncherStation.prototype:add_visualization_viewer(player)
    for _, p in ipairs(self.range_visualization[1].players) do
        if player == p then return end
    end
    for _, visualization in ipairs(self.range_visualization) do
        table.insert(visualization.players, player)
    end
end

---@param player LuaPlayer
function LauncherStation.prototype:remove_visualization_viewer(player)
    for index, p in ipairs(self.range_visualization[1].players) do
        if player == p then
            for _, visualization in ipairs(self.range_visualization) do
                table.remove(visualization.players, index)
            end
            return
        end
    end
end

function LauncherStation.prototype:update_diode_status()
    if not self:valid() then return end
    local status = "logistic-cannon-transportation.status-ready"
    local diode = defines.entity_status_diode.green --[[@as defines.entity_status_diode]]
    if self.loaded_ammo == "" then
        status = "logistic-cannon-transportation.status-no-capsule"
        diode = defines.entity_status_diode.red
    elseif self.scheduled_delivery then
        status = "logistic-cannon-transportation.status-preparing"
        diode = defines.entity_status_diode.yellow
    elseif self.electric_interface.electric_buffer_size - self.electric_interface.energy > 1.0 then
        status = "logistic-cannon-transportation.status-charging"
        diode = defines.entity_status_diode.yellow
    end
    local range = tostring(self:get_max_range())
    if range ~= "0" then
        range = tostring(string.format("%.0f", self:get_range())) .. "/" .. range
    end
    local current_charge = string.format("%.1f", self:get_stored_energy() / 1000)
    local buffer_size = string.format("%.1f", self.electric_interface.electric_buffer_size / 1000)
    self.station_entity.custom_status = {
        diode = diode,
        label = { "", { status } }
    }
    self.proxy_entity.custom_status = {
        diode = diode,
        label = { "", { status },
            "\n", { "logistic-cannon-transportation.energy-info", current_charge, buffer_size },
            "\n", { "logistic-cannon-transportation.range-info", range },
        }
    }
end

---@param receiver ReceiverStation
---@param item ItemIDAndQualityIDPair
---@param amount uint32
---@return ScheduledDelivery?
function LauncherStation.prototype:schedule_delivery(receiver, item, amount)
    local inventory = self:get_inventory()
    local available_count = inventory.get_item_count_filtered { name = item.name, quality = item.quality }
    local payload_count = self:get_max_payload_size() * prototypes.item[item.name].stack_size
    if available_count < payload_count or payload_count > amount then
        return nil
    end
    local deliver_item = { name = item.name, quality = item.quality, count = payload_count }
    local delivery = ScheduledDelivery.create(self, receiver, deliver_item)
    --todo check timeout
    self.scheduled_delivery = delivery
    self:set_aiming(delivery.position)
    return delivery
end

---@param position MapPosition
---@return boolean
function LauncherStation.prototype:is_ready(position)
    if self.loaded_ammo == "" or self.scheduled_delivery ~= nil then
        return false
    end
    local distance = math2d.position.distance(self:position(), position)
    return self:get_range() >= distance
end

---@return LuaInventory
function LauncherStation.prototype:get_inventory()
    return self.station_entity.get_inventory(defines.inventory.car_trunk) --[[@as LuaInventory]]
end

---@return LuaInventory
function LauncherStation.prototype:get_ammo_inventory()
    return self.station_entity.get_inventory(defines.inventory.car_ammo) --[[@as LuaInventory]]
end

---@return number
function LauncherStation.prototype:get_stored_energy()
    return self.overflow_energy + self.electric_interface.energy
end

---Consume given amount of energy; if no enough energy to consume, extra energy cost is ignored
---@param energy number
function LauncherStation.prototype:consume_energy(energy)
    local cost = math.max(0, energy - self.overflow_energy)
    self.overflow_energy = math.max(0, self.overflow_energy - energy)
    self.electric_interface.energy = math.max(0, self.electric_interface.energy - cost)
end

---@param source_position MapPosition
function LauncherStation.prototype:launch(source_position)
    self:set_aiming(nil)
    local delivery = self.scheduled_delivery
    if not self:valid() or not delivery then return end
    self.scheduled_delivery = nil -- reset delivery state for launcher
    local ammo_item = self:get_ammo_inventory()[1]
    if delivery:valid() and ammo_item.valid_for_read and ammo_item.name == delivery.delivery_ammo then
        local energy_cost = math2d.position.distance(self:position(), delivery.position) * self:get_launch_consumption()
        if self:get_stored_energy() >= energy_cost then
            local capsule = delivery:get_inventory()
            local trunk = self:get_inventory()
            local amount = inventory_tool.transfer_items(trunk, capsule,
                { name = delivery.item, quality = delivery.quality },
                delivery.amount)
            if amount > 0 then
                self:consume_energy(energy_cost)
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

---@return number
function LauncherStation.prototype:get_launch_consumption()
    if not self:valid() or self.loaded_ammo == "" then return 0 end
    return prototypes.mod_data[constants.name_prefix .. "launch-consumptions"].data[self.loaded_ammo] --[[@as number]]
end

---@return uint64
function LauncherStation.prototype:id()
    return self.station_id
end

---@return boolean
function LauncherStation.prototype:valid()
    return self.proxy_entity.valid and self.station_entity.valid and self.electric_interface.valid
end

---@return MapPosition
function LauncherStation.prototype:position()
    return self.station_entity.position
end

return LauncherStation
