local constants = require("constants")
local util = require("util")
local math2d = require("math2d")
local format = require("scripts.format")
local bonus_control = require("scripts.bonus_control")
local visualization_control = require("scripts.visualization_control")
local signal_condition = require("scripts.gui.signal_condition")
local lct_util         = require("scripts.lct_util")
local settings_cache   = require("scripts.settings_cache")
local CannonNetwork ---@module "scripts.cannon_network"
local ScheduledDelivery ---@module "scripts.scheduled_delivery"
local inventory_tool = require("scripts.inventory_tool")
local launcher_computed_values = require("scripts.launcher_computed_values")

local LauncherStation = {}
function LauncherStation.load_deps()
    CannonNetwork = require("scripts.cannon_network")
    ScheduledDelivery = require("scripts.scheduled_delivery")
end

---Represents a cannon launcher in storage, lifetime synchronized with associated entities.
---@class LauncherStation
---@field inventory_entity LuaEntity The inventory container.
---@field turret_entity LuaEntity The cannon launcher turret.
---@field base_entity LuaEntity The base of the launcher.
---@field electric_interface LuaEntity The power interface.
---@field proxy_entity LuaEntity? The proxy container for gui.
---@field target_entity LuaEntity? The target entity for shoot.
---@field ammo_proxy_entity LuaEntity? The ammo proxy entity of the launcher.
---@field station_id uint64 The unit number of inventory entity.
---@field turret_id uint64 The unit number of turret entity.
---@field ammo_name string Prototype name of the loaded ammo, empty string means no ammo.
---@field ammo_quality LuaQualityPrototype? Quality of loaded ammo, nil if no ammo.
---@field overflow_energy number The amount of overflow energy
---@field computed_max_range uint32 The max range of the cannon launcher, without override.
---@field effective_max_range uint32 The max range of the cannon launcher, affected by override.
---@field computed_payload_size uint32 The capsule payload size of the cannon launcher, without override.
---@field effective_payload_size uint32 The capsule payload size of the cannon launcher, affected by override.
---@field energy_consumption number? The energy consumption of the cannon launcher
---@field network CannonNetwork The netowrk that the station belongs to
---@field scheduled_delivery ScheduledDelivery? The delivery being scheduled for launch.
---@field settings LauncherStationSettings
LauncherStation.prototype = {}
LauncherStation.prototype.__index = LauncherStation.prototype

---User-configurable settings of a cannon launcher, POD.
---@class (exact) LauncherStationSettings
---@field name string? Custom name of the station.
---@field range_override uint? Override launcher range.
---@field payload_size_override uint? Override payload size (stack).
---@field network_signal SignalID? Signal for network.
---@field direction defines.direction Direction of the launcher.
---@field enable_ammo_proxy boolean
---@field load_capsule_from_inventory boolean
---@field circuit_read_ammo boolean
---@field circuit_enable_condition ModCircuitCondition

function LauncherStation.make_default_settings()
    return {
        name = nil,
        range_override = nil,
        payload_size_override = nil,
        network_signal = nil,
        direction = defines.direction.north,
        enable_ammo_proxy = not not settings_cache.global[constants.setting_default_launcher_side_load],
        load_capsule_from_inventory = not not settings_cache.global[constants.setting_default_launcher_auto_load],
        circuit_read_ammo = true,
        circuit_enable_condition = signal_condition.default_value,
    } --[[@as LauncherStationSettings]]
end

local launcher_properties = prototypes.mod_data[constants.data_launcher_properties]
    .data --[[@as table<string, LauncherProperties?>]]
local capsule_properties = prototypes.mod_data[constants.data_capsule_properties]
    .data --[[@as table<string, CapsuleProperties?>]]
local clone_blacklist = {
    [constants.entity_launcher_ammo_proxy] = true,
    [constants.entity_target] = true,
}
for _, properties in pairs(launcher_properties) do
    clone_blacklist[properties.turret_name] = true
    clone_blacklist[properties.base_name] = true
    clone_blacklist[properties.electric_interface_name] = true
    clone_blacklist[properties.gui_proxy_name] = true
end

function LauncherStation.on_init()
    ---@type table<uint64, LauncherStation?> LauncherStation's indexed by inventory entity's unit number
    storage.launcher_stations = storage.launcher_stations or {}
    ---@type table<uint64, LauncherStation?> Index of LauncherStation turret_entity.unit_number to LauncherStation
    storage.launcher_stations_turret_index = storage.launcher_stations_turret_index or {}
end

---Create a LauncherStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@param from_settings LauncherStationSettings?
---@return LauncherStation
function LauncherStation.create(entity, from_settings)
    assert(LauncherStation.is_station_entity(entity.name))
    local surface = entity.surface
    local position = entity.position
    local force = entity.force --[[@as LuaForce]]
    local properties = launcher_properties[entity.name] or error()

    local inventory_entity = entity

    local turret_entity = surface.create_entity {
        name = properties.turret_name,
        position = position,
        force = force,
        quality = entity.quality,
    } or error()

    local base_entity = surface.create_entity {
        name = properties.base_name,
        position = position,
        force = force,
    } or error()

    local electric_interface = surface.create_entity {
        name = properties.electric_interface_name,
        position = position,
        force = force,
        quality = entity.quality,
    } or error()

    local launcher_settings = from_settings or LauncherStation.make_default_settings()

    local instance = setmetatable({
        inventory_entity = inventory_entity,
        turret_entity = turret_entity,
        base_entity = base_entity,
        electric_interface = electric_interface,
        station_id = inventory_entity.unit_number,
        turret_id = turret_entity.unit_number,
        ammo_name = "",
        overflow_energy = 0,
        computed_max_range = 0,
        effective_max_range = 0,
        computed_payload_size = 0,
        effective_payload_size = 0,
        network = CannonNetwork.get_or_create(force, surface, launcher_settings.network_signal),
        scheduled_delivery = nil,
        settings = launcher_settings,
    } --[[@as LauncherStation]], LauncherStation.prototype)

    script.register_on_object_destroyed(instance.inventory_entity)
    script.register_on_object_destroyed(instance.turret_entity)

    instance.turret_entity.destructible = false
    instance.base_entity.destructible = false
    instance.electric_interface.destructible = false
    instance.computed_max_range = launcher_computed_values.compute_max_range(inventory_entity.name, inventory_entity.quality, force)
    instance.effective_max_range = launcher_computed_values.with_override(instance.computed_max_range, instance.settings.range_override)
    instance.base_entity.direction = instance.settings.direction
    instance.turret_entity.direction = instance.settings.direction
    instance.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]].read_ammo =
        instance.settings.circuit_read_ammo
    instance.turret_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
        .connect_to(instance.inventory_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)--[[@as LuaWireConnector]],
            false, defines.wire_origin.script)
    instance.turret_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true)
        .connect_to(instance.inventory_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true)--[[@as LuaWireConnector]],
            false, defines.wire_origin.script)
    instance:update_ammo_proxy()

    storage.launcher_stations[instance:id()] = instance
    storage.launcher_stations_turret_index[instance.turret_id] = instance
    instance.network:add_launcher(instance)

    -- redirect opened GUI
    for _, player in ipairs(game.connected_players) do
        if player.opened == instance.inventory_entity then
            player.opened = instance:get_gui_proxy()
        end
    end

    return instance
end

---@param name string name of entity
---@return boolean
function LauncherStation.is_station_entity(name)
    return name == constants.entity_launcher_inventory
end

---@return string[]
function LauncherStation.get_station_entities()
    return { constants.entity_launcher_inventory }
end

---@param name string name of entity
---@return boolean
function LauncherStation.is_gui_entity(name)
    return name == constants.entity_launcher_gui_proxy
end

---@return string[]
function LauncherStation.get_gui_entities()
    return { constants.entity_launcher_gui_proxy }
end

---Get a LauncherStation from storage.
---@param entity LuaEntity | uint64 An associated entity or a unit number thereof.
---@return LauncherStation?
function LauncherStation.get(entity)
    local unit_number
    if type(entity) == "number" then
        unit_number = entity
    elseif LauncherStation.is_gui_entity(entity.name) then
        unit_number = entity.proxy_target_entity.unit_number
    else
        unit_number = entity.unit_number
    end
    return storage.launcher_stations[unit_number]
        or storage.launcher_stations_turret_index[unit_number]
end

---@param tags Tags
---@param launcher_settings LauncherStationSettings
function LauncherStation.write_settings(tags, launcher_settings)
    tags["cannon_launcher_settings"] = launcher_settings
end

---@param tags Tags
---@return LauncherStationSettings?
function LauncherStation.read_settings(tags)
    return tags and tags["cannon_launcher_settings"] --[[@as LauncherStationSettings?]] or nil
end

---@param source LuaEntity
---@param destination LuaEntity
function LauncherStation.on_entity_cloned(source, destination)
    if clone_blacklist[destination.name] then destination.destroy() end
    if not LauncherStation.is_station_entity(destination.name) then return end
    local src_launcher = LauncherStation.get(source)
    local des_launcher = LauncherStation.create(destination, src_launcher and src_launcher.settings)
    if not src_launcher or not src_launcher:valid() then return end
    des_launcher.turret_entity.orientation = src_launcher.turret_entity.orientation
    des_launcher:get_ammo_inventory()[1].set_stack(src_launcher:get_ammo_inventory()[1])
    des_launcher:charge_energy(src_launcher:get_stored_energy())
end

---@param entity LuaEntity
function LauncherStation.on_entity_teleported(entity)
    if not LauncherStation.is_station_entity(entity.name) then return end
    local launcher = LauncherStation.get(entity)
    if not launcher or not launcher:valid() then return end
    local position = entity.position
    launcher.turret_entity.teleport(position)
    launcher.base_entity.teleport(position)
    launcher.electric_interface.teleport(position)
    if launcher.proxy_entity and launcher.proxy_entity.valid then
        launcher.proxy_entity.teleport(position)
    end
    if launcher.target_entity and launcher.target_entity.valid then
        launcher.target_entity.destroy()
    end
    if launcher.scheduled_delivery and launcher.scheduled_delivery:valid() then
        launcher.scheduled_delivery:destroy()
    end
    if launcher.ammo_proxy_entity and launcher.ammo_proxy_entity.valid then
        launcher.ammo_proxy_entity.destroy()
        launcher:update_ammo_proxy()
    end
    launcher.scheduled_delivery = nil
    launcher.network:update_launcher_connections(launcher)
end

---Destroy a ReceiverStation following the destruction an associated entity.
---@param unit_number uint64 Unit number of the destroyed entity.
function LauncherStation.on_object_destroyed(unit_number)
    local instance = LauncherStation.get(unit_number)
    if not instance then return end

    storage.launcher_stations[instance.station_id] = nil
    storage.launcher_stations_turret_index[instance.turret_id] = nil
    if instance.inventory_entity.valid then
        instance.inventory_entity.destroy()
    end
    if instance.turret_entity.valid then
        instance.turret_entity.destroy()
    end
    if instance.base_entity.valid then
        instance.base_entity.destroy()
    end
    if instance.electric_interface.valid then
        instance.electric_interface.destroy()
    end
    if instance.proxy_entity then
        instance.proxy_entity.destroy()
    end
    if instance.target_entity then
        instance.target_entity.destroy()
    end
    if instance.ammo_proxy_entity then
        instance.ammo_proxy_entity.destroy()
    end
    if instance.scheduled_delivery then
        instance.scheduled_delivery:destroy()
    end
    instance.network:remove_launcher(instance:id())
    visualization_control.on_station_remove(instance:id())
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

function LauncherStation.prototype:update_state()
    if not self:valid() then return false end

    local disabled = self:is_disabled()
    local ammo_slot = self:get_ammo_inventory()[1]
    local ammo_name = ""
    local ammo_quality = nil
    if ammo_slot.valid_for_read then
        ammo_name = ammo_slot.name
        ammo_quality = ammo_slot.quality
    end
    local ammo_changed = self.ammo_name ~= ammo_name or self.ammo_quality ~= ammo_quality
    self.ammo_name = ammo_name
    self.ammo_quality = ammo_quality

    -- auto reload ammo for active launcher only
    if self.settings.load_capsule_from_inventory and not ammo_slot.valid_for_read and not disabled then
        inventory_tool.transfer_to_slot(self:get_inventory(), ammo_slot)
    end

    -- cancel ongoing delivery if ammo changed/disabled
    if ammo_changed or disabled then
        if self.scheduled_delivery and self.scheduled_delivery:valid() then
            self.scheduled_delivery:destroy()
            self.scheduled_delivery = nil
        end
    end

    -- update payload size
    if ammo_changed then
        self.computed_payload_size = launcher_computed_values.compute_payload_size(ammo_name, ammo_quality)
    end
    self.effective_payload_size = launcher_computed_values.with_override(self.computed_payload_size, self.settings.payload_size_override)

    local force = self.inventory_entity.force --[[@as LuaForce]]

    -- update max range
    self.computed_max_range = launcher_computed_values.compute_max_range(self.inventory_entity.name, self.inventory_entity.quality, force, ammo_name)
    local effective_max_range = launcher_computed_values.with_override(self.computed_max_range, self.settings.range_override)
    local max_range_changed = self.effective_max_range ~= effective_max_range
    self.effective_max_range = effective_max_range

    -- update energy consumption
    local energy_consumption = launcher_computed_values.compute_energy_consumption(force, ammo_name, ammo_quality)
    local energy_consumption_changed = energy_consumption ~= self.energy_consumption
    self.energy_consumption = energy_consumption

    -- resize energy capacity
    if max_range_changed or energy_consumption_changed then
        local energy = self:get_stored_energy()
        self.overflow_energy = 0
        self.electric_interface.energy = 0
        -- assume capacity modifer change corelate to consumption modifer
        local capacity_modifier = 1.0 + bonus_control.get_launcher_energy_capacity_modifier(force)
        self.electric_interface.electric_buffer_size = effective_max_range * (energy_consumption or 0) * capacity_modifier
        self:charge_energy(energy)
    end

    -- update connections if range changed
    if max_range_changed then
        self.network:update_launcher_connections(self)
    end
end

---@param launcher_settings LauncherStationSettings
function LauncherStation.prototype:set_settings(launcher_settings)
    self.settings = util.table.deepcopy(launcher_settings)
    self.settings.direction = self.base_entity.direction -- Don't use direction settings
    self.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]].read_ammo =
        self.settings.circuit_read_ammo
    self:update_ammo_proxy()
    self:set_network_signal(self.settings.network_signal)
end

---@param ignore_override boolean?
---@return uint32
function LauncherStation.prototype:get_max_range(ignore_override)
    return ignore_override and self.computed_max_range or self.effective_max_range
end

---@return number
function LauncherStation.prototype:get_current_range()
    if not self.energy_consumption then return 0 end
    return math.min(self:get_max_range(), self:get_stored_energy() / self.energy_consumption)
end

---@return number #W
function LauncherStation.prototype:get_charging_speed()
    local quality = self.electric_interface.quality
    return 60 * self.electric_interface.get_electric_input_flow_limit(quality) --[[@as number]]
end

---@param ignore_override boolean?
---@return uint32
function LauncherStation.prototype:get_payload_size(ignore_override)
    return ignore_override and self.computed_payload_size or self.effective_payload_size
end

---@return number?
function LauncherStation.prototype:get_launch_consumption()
    return self.energy_consumption
end

---@return number?
function LauncherStation.prototype:get_projectile_speed()
    local data = capsule_properties[self.ammo_name]
    return data and data.speed
end

---@return LuaInventory
function LauncherStation.prototype:get_inventory()
    return self.inventory_entity.get_inventory(defines.inventory.chest) --[[@as LuaInventory]]
end

---@return LuaInventory
function LauncherStation.prototype:get_ammo_inventory()
    return self.turret_entity.get_inventory(defines.inventory.turret_ammo) --[[@as LuaInventory]]
end

---@return number
function LauncherStation.prototype:get_stored_energy()
    return self.overflow_energy + self.electric_interface.energy
end

---@return number
function LauncherStation.prototype:get_energy_capacity()
    return self.electric_interface.electric_buffer_size
end

---@param energy number?
function LauncherStation.prototype:charge_energy(energy)
    local total_energy = self:get_stored_energy() + (energy or 0)
    local stored = math.min(total_energy, self:get_energy_capacity())
    self.overflow_energy = total_energy - stored
    self.electric_interface.energy = stored
end

---Consume given amount of energy; if no enough energy to consume, extra energy cost is ignored
---@param energy number
function LauncherStation.prototype:consume_energy(energy)
    local cost = math.max(0, energy - self.overflow_energy)
    self.overflow_energy = math.max(0, self.overflow_energy - energy)
    self.electric_interface.energy = math.max(0, self.electric_interface.energy - cost)
end

---@param player LuaPlayer
---@param reverse boolean
function LauncherStation.prototype:rotate(player, reverse)
    if self.base_entity.rotate { by_player = player, reverse = reverse } then
        self.settings.direction = self.base_entity.direction
        self:update_ammo_proxy()
        visualization_control.on_launcher_update(self)
    end
end

function LauncherStation.prototype:update_ammo_proxy()
    if not self.settings.enable_ammo_proxy then
        if self.ammo_proxy_entity and self.ammo_proxy_entity.valid then
            self.ammo_proxy_entity.destroy()
        end
        self.ammo_proxy_entity = nil
        return
    end
    -- for reset inserter targets
    local last_pos = self.inventory_entity.position
    self.inventory_entity.teleport(constants.out_of_map_position, nil, false)
    self.inventory_entity.teleport(last_pos, nil, false)
    -- update ammo proxy position
    local position = launcher_computed_values.compute_ammo_proxy_position(self.inventory_entity, self.base_entity.direction)
    if self.ammo_proxy_entity and self.ammo_proxy_entity.valid then
        self.ammo_proxy_entity.teleport(position)
    else
        local surface = self.inventory_entity.surface
        self.ammo_proxy_entity = surface.create_entity {
            name = constants.entity_launcher_ammo_proxy,
            position = position,
            force = self.inventory_entity.force,
        } or error()
        self.ammo_proxy_entity.proxy_target_entity = self.turret_entity
        self.ammo_proxy_entity.proxy_target_inventory = defines.inventory.turret_ammo
        self.ammo_proxy_entity.destructible = false
    end
end

function LauncherStation.prototype:update_diode_status()
    if not self:valid() then return end
    local capacity = self:get_energy_capacity()
    local energy = self:get_stored_energy()
    local status = "entity-status.fully-charged"
    local diode = defines.entity_status_diode.green --[[@as defines.entity_status_diode]]
    if self.scheduled_delivery then
        status = "entity-status.working"
        diode = defines.entity_status_diode.green
    elseif self:is_disabled() then
        status = "entity-status.disabled"
        diode = defines.entity_status_diode.red
    elseif self.ammo_name == "" then
        status = "entity-status.no-ammo"
        diode = defines.entity_status_diode.red
    elseif not self.electric_interface.is_connected_to_electric_network() then
        status = "entity-status.not-plugged-in-electric-network"
        diode = defines.entity_status_diode.red
    elseif energy <= capacity / 3 then
        status = "entity-status.low-power"
        diode = defines.entity_status_diode.yellow
    elseif capacity - energy > 1.0 then
        status = "entity-status.charging"
        diode = defines.entity_status_diode.green
    end
    local range = tostring(self:get_max_range())
    if range ~= "0" then
        range = tostring(string.format("%.0f", self:get_current_range())) .. "/" .. range
    end
    local connected = self.network:get_connection_count(self:id())
    local formatted_energy = format.energy(energy)
    local formatted_capacity = format.energy(capacity)
    if self.proxy_entity and self.proxy_entity.valid then
        self.proxy_entity.custom_status = {
            diode = diode,
            label = { "", { status } }
        }
    end
    self.inventory_entity.custom_status = {
        diode = diode,
        label = { "", { status },
            "\n", { "logistic-cannon-transportation.energy-info", formatted_energy, formatted_capacity },
            "\n", { "logistic-cannon-transportation.range-info",     range },
            "\n", { "logistic-cannon-transportation.connected-receivers-info", connected },
        }
    }
end

---@param network CannonNetwork
function LauncherStation.prototype:set_network(network)
    if network ~= self.network then
        self.network:remove_launcher(self:id())
        self.network = network
        self.network:add_launcher(self)
        self.settings.network_signal = network.signal
    end
end

---@param signal SignalID?
function LauncherStation.prototype:set_network_signal(signal)
    local force = self.inventory_entity.force --[[@as LuaForce]]
    local surface = self.inventory_entity.surface
    local network = CannonNetwork.get_or_create(force, surface, signal)
    self:set_network(network)
end

---@param receiver ReceiverStation
---@param item ItemIDAndQualityIDPair
---@param demand uint32
---@return ScheduledDelivery?
function LauncherStation.prototype:schedule_delivery(receiver, item, demand)
    if self.scheduled_delivery ~= nil or self.ammo_name == "" then
        return nil
    end

    -- Check demand < payload_item_count early because it prunes most invocations
    local capsule_size = self:get_payload_size()
    local payload_item_count = capsule_size * prototypes.item[item.name].stack_size
    if demand < payload_item_count then return nil end

    -- Check valid late because it is slow
    if not self:valid() or self:is_disabled() then return nil end

    local distance = lct_util.math2d.distance(self:position(), receiver:position())
    if self:get_current_range() < distance then return nil end

    local available_count = self:get_inventory().get_item_count_filtered { name = item.name, quality = item.quality }
    if capsule_size <= 0 or available_count < payload_item_count then return nil end

    local deliver_item = { name = item.name, quality = item.quality, count = payload_item_count }
    local delivery = ScheduledDelivery.create(self, receiver, distance, deliver_item, capsule_size)
    self.scheduled_delivery = delivery
    self:set_aiming(delivery.position)
    return delivery
end

function LauncherStation.prototype:launch()
    if not self:valid() then return end
    self:set_aiming(nil)
    local delivery = self.scheduled_delivery
    if not delivery then return end
    self.scheduled_delivery = nil -- reset delivery state for launcher
    local ammo_slot = self:get_ammo_inventory()[1]
    if not self:is_disabled() and delivery:valid() and delivery:is_matching_ammo(ammo_slot) then
        local energy_cost = self:get_launch_consumption() * (delivery.distance or 0)
        if self:get_stored_energy() >= energy_cost then
            local capsule = delivery:get_inventory()
            local inventory = self:get_inventory()
            local amount = inventory_tool.transfer_items(inventory, capsule,
                { name = delivery.item, quality = delivery.quality },
                delivery.amount)
            if amount > 0 then
                self:consume_energy(energy_cost)
                self.network:update_launcher_storage(self)
                delivery.amount = amount
                -- auto reload from inventory
                if ammo_slot.count <= 1 and self.settings.load_capsule_from_inventory then
                    inventory_tool.transfer_to_slot(inventory, ammo_slot)
                end
                if settings_cache.startup[constants.setting_capsule_consumption_mode] ~= "no-consumption" then
                    ammo_slot.drain_ammo(1)
                end
                local source_offset = math2d.vector.from_orientation(self.turret_entity.orientation, 1.9)
                local base_position = self:position()
                local source_position = { base_position.x + source_offset.x,
                    base_position.y - 1.8 + source_offset.y * math2d.projection_constant }
                delivery:launch_capsule(
                    capsule_properties[self.ammo_name] or error(),
                    self.turret_entity.surface,
                    self.turret_entity.force,
                    source_position
                )
                return
            end
        end
    end
    delivery:destroy()
end

---Assumes self is valid.
---@param target_position MapPosition?
function LauncherStation.prototype:set_aiming(target_position)
    if target_position then
        local self_position = self:position()
        local target_distance = lct_util.math2d.distance(target_position, self_position)
        local entity_position = {
            x = (target_position.x - self_position.x) / target_distance + self_position.x,
            y = (target_position.y - self_position.y) / target_distance + self_position.y,
        }
        if self.target_entity and self.target_entity.valid then
            if not self.target_entity.teleport(entity_position) then error() end
        else
            self.target_entity = self.turret_entity.surface.create_entity {
                name = constants.entity_target,
                position = entity_position,
                force = "enemy",
            } or error()
            self.target_entity.destructible = false
        end

        self.turret_entity.shooting_target = self.target_entity
    else
        self.turret_entity.shooting_target = nil
    end
end

---@return ScheduledDelivery?
function LauncherStation.prototype:get_scheduled_delivery()
    return self.scheduled_delivery
end

---@return uint64
function LauncherStation.prototype:id()
    return self.station_id
end

---@return boolean
function LauncherStation.prototype:valid()
    return self.inventory_entity.valid and self.turret_entity.valid and
        self.electric_interface.valid and self.base_entity.valid
end

---@return MapPosition
function LauncherStation.prototype:position()
    return self.inventory_entity.position
end

---@return boolean
function LauncherStation.prototype:is_disabled()
    if self.inventory_entity.to_be_deconstructed() then return true end
    if not self.settings.circuit_enable_condition.enabled then return false end

    local red_connected = self:is_circuit_connected(false, defines.wire_connector_id.circuit_red)
    local green_connected = self:is_circuit_connected(false, defines.wire_connector_id.circuit_green)

    return not signal_condition.evaluate(self.settings.circuit_enable_condition, function(signal)
        if red_connected then
            if green_connected then
                return self.inventory_entity.get_signal(signal, defines.wire_connector_id.circuit_red,
                    defines.wire_connector_id.circuit_green)
            else
                return self.inventory_entity.get_signal(signal, defines.wire_connector_id.circuit_red)
            end
        else
            if green_connected then
                return self.inventory_entity.get_signal(signal, defines.wire_connector_id.circuit_green)
            else
                return 0
            end
        end
    end)
end

---@param include_ghost boolean
---@param wire defines.wire_connector_id?
---@return boolean
function LauncherStation.prototype:is_circuit_connected(include_ghost, wire)
    if not wire then
        return
            self:is_circuit_connected(include_ghost, defines.wire_connector_id.circuit_red) or
            self:is_circuit_connected(include_ghost, defines.wire_connector_id.circuit_green)
    end
    local wire_connector = self.inventory_entity.get_wire_connector(wire, false)
    if not wire_connector then return false end
    local connection_count = wire_connector
    [include_ghost and "connection_count" or "real_connection_count"] --[[@as uint32]]
    return connection_count > 1
end

---@param state boolean
function LauncherStation.prototype:set_read_ammo(state)
    local control = self.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]]
    self.settings.circuit_read_ammo = state
    control.read_ammo = state
end

---@return string
function LauncherStation.prototype:get_gui_proxy_name()
    return launcher_properties[self.inventory_entity.name].gui_proxy_name or error()
end

---@return LuaEntity
function LauncherStation.prototype:get_gui_proxy()
    if self.proxy_entity and self.proxy_entity.valid then
        return self.proxy_entity
    end
    self.proxy_entity = self.inventory_entity.surface.create_entity {
        name = self:get_gui_proxy_name(),
        position = self.inventory_entity.position,
        force = self.inventory_entity.force,
    } or error()
    self.proxy_entity.destructible = false
    self.proxy_entity.proxy_target_entity = self.inventory_entity
    self.proxy_entity.proxy_target_inventory = defines.inventory.chest
    return self.proxy_entity
end

return LauncherStation
