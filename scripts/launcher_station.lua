local constants = require("constants")
local util = require("util")
local math2d = require("math2d")
local format = require("scripts.format")
local bonus_control = require("scripts.bonus_control")
local visualization_control = require("scripts.visualization_control")
local signal_condition = require("scripts.gui.signal_condition")
local CannonNetwork ---@module "scripts.cannon_network"
local ScheduledDelivery ---@module "scripts.scheduled_delivery"
local inventory_tool = require("scripts.inventory_tool")

local LauncherStation = {}
function LauncherStation.load_deps()
    CannonNetwork = require("scripts.cannon_network")
    ScheduledDelivery = require("scripts.scheduled_delivery")
end

---Represents a cannon launcher in storage, lifetime synchronized with associated entities.
---@class LauncherStation
---@field inventory_entity LuaEntity The inventory container.
---@field turret_entity LuaEntity The cannon launcher turret.
---@field electric_interface LuaEntity The power interface.
---@field proxy_entity LuaEntity? The proxy container for gui.
---@field target_entity LuaEntity? The target entity for shoot.
---@field ammo_proxy_entity LuaEntity? The ammo proxy entity of the launcher.
---@field station_id uint64 The unit number of inventory entity.
---@field turret_id uint64 The unit number of turret entity.
---@field ammo_name string Prototype name of the loaded ammo, empty string means no ammo.
---@field ammo_quality LuaQualityPrototype? Quality of loaded ammo, nil if no ammo.
---@field overflow_energy number The amount of overflow energy
---@field max_range number The max range of the cannon launcher, affect by override
---@field payload_size number? The capsule payload size of the cannon launcher, not affect by override
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
---@field circuit_enable_enabled boolean
---@field circuit_enable_condition ModCircuitCondition
LauncherStation.default_settings = {
    name = nil,
    range_override = nil,
    payload_size_override = nil,
    network_signal = nil,
    direction = defines.direction.north,
    enable_ammo_proxy = true,
    load_capsule_from_inventory = true,
    circuit_read_ammo = true,
    circuit_enable_enabled = false,
    circuit_enable_condition = signal_condition.default_value,
}

local launcher_properties = prototypes.mod_data[constants.data_launcher_properties]
    .data --[[@as table<string, LauncherProperties>]]
local capsule_properties = prototypes.mod_data[constants.data_capsule_properties]
    .data --[[@as table<string, CannonCapsuleProperties?>]]
local clone_blacklist = {
    [constants.entity_launcher_turret] = true,
    [constants.entity_launcher_energy_interface] = true,
    [constants.entity_launcher_gui_proxy] = true,
    [constants.entity_launcher_ammo_proxy] = true,
    [constants.entity_target] = true,
}

---@param force LuaForce
---@param ammo_name string
---@param ammo_quality LuaQualityPrototype?
---@return number?
local function compute_energy_consumption(force, ammo_name, ammo_quality)
    local data = capsule_properties[ammo_name]
    local consumption = data and data.energy_consumption or 0
    if consumption == 0 then return nil end
    local quality_modifier = ammo_quality and 1 / ammo_quality.range_multiplier or 1
    local modifier = 1.0 + bonus_control.get_launcher_energy_consumption_modifier(force)
    return consumption * quality_modifier * modifier
end

---@param ammo_name string
---@param ammo_quality LuaQualityPrototype?
---@return number?
local function compute_payload_size(ammo_name, ammo_quality)
    local data = capsule_properties[ammo_name]
    local payload_size = data and data.payload_size or 0
    if payload_size == 0 then return nil end
    local quality_modifier = ammo_quality and ammo_quality.default_multiplier or 1
    return math.floor(0.5 + (payload_size * quality_modifier))
end

---@param inventory_entity LuaEntity
---@param direction defines.direction
local function compute_ammo_proxy_position(inventory_entity, direction)
    local opposite = util.oppositedirection(direction)
    local distance = inventory_entity.tile_height / 2 - 0.5
    return util.moveposition(inventory_entity.position, opposite, distance)
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
    assert(entity.name == constants.entity_launcher_inventory)
    local surface = entity.surface
    local position = entity.position
    local force = entity.force --[[@as LuaForce]]

    local inventory_entity = entity

    local turret_entity = surface.create_entity {
        name = constants.entity_launcher_turret,
        position = math2d.position.add(position, { 0, 0.001 }), -- to fix overlap sprite issue
        force = force,
        quality = entity.quality,
    } or error()

    local electric_interface = surface.create_entity {
        name = constants.entity_launcher_energy_interface,
        position = position,
        force = force,
        quality = entity.quality,
    } or error()

    local launcher_settings = from_settings or util.table.deepcopy(LauncherStation.default_settings)

    local instance = setmetatable({
        inventory_entity = inventory_entity,
        turret_entity = turret_entity,
        electric_interface = electric_interface,
        station_id = inventory_entity.unit_number,
        turret_id = turret_entity.unit_number,
        ammo_name = "",
        overflow_energy = 0,
        max_range = 0,
        network = CannonNetwork.get_or_create(force, surface, launcher_settings.network_signal),
        scheduled_delivery = nil,
        settings = launcher_settings,
    } --[[@as LauncherStation]], LauncherStation.prototype)

    script.register_on_object_destroyed(instance.inventory_entity)
    script.register_on_object_destroyed(instance.turret_entity)

    instance.turret_entity.destructible = false
    instance.electric_interface.destructible = false
    instance.max_range = instance:get_max_range(true)
    instance.turret_entity.direction = instance.settings.direction
    instance.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]].read_ammo =
        instance.settings.circuit_read_ammo
    instance.turret_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
        .connect_to(instance.inventory_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true),
            false, defines.wire_origin.script)
    instance.turret_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true)
        .connect_to(instance.inventory_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true),
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

---Get a LauncherStation from storage.
---@param entity LuaEntity | uint64 An associated entity or a unit number thereof.
---@return LauncherStation?
function LauncherStation.get(entity)
    local unit_number
    if type(entity) == "number" then
        unit_number = entity
    elseif entity.name == constants.entity_launcher_gui_proxy then
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
function LauncherStation.read_settings(tags)
    return tags and tags["cannon_launcher_settings"] or nil
end

---@param source LuaEntity
---@param destination LuaEntity
function LauncherStation.on_entity_cloned(source, destination)
    if clone_blacklist[destination.name] then destination.destroy() end
    if destination.name ~= constants.entity_launcher_inventory then return end
    local src_launcher = LauncherStation.get(source)
    local des_launcher = LauncherStation.create(destination, src_launcher and src_launcher.settings)
    if not src_launcher then return end
    des_launcher.turret_entity.orientation = src_launcher.turret_entity.orientation
    des_launcher:get_ammo_inventory()[1].set_stack(src_launcher:get_ammo_inventory()[1])
    des_launcher:charge_energy(src_launcher:get_stored_energy())
end

---@param entity LuaEntity
function LauncherStation.on_entity_teleported(entity)
    if entity.name ~= constants.entity_launcher_inventory then return end
    local launcher = LauncherStation.get(entity)
    if not launcher or not launcher:valid() then return end
    local position = entity.position
    launcher.turret_entity.teleport(math2d.position.add(position, { 0, 0.001 }))
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
    if instance.electric_interface.valid then
        instance.electric_interface.destroy()
    end
    if instance.proxy_entity and instance.proxy_entity.valid then
        instance.proxy_entity.destroy()
    end
    if instance.target_entity and instance.target_entity.valid then
        instance.target_entity.destroy()
    end
    if instance.ammo_proxy_entity and instance.ammo_proxy_entity.valid then
        instance.ammo_proxy_entity.destroy()
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

---@param launcher_name string
---@param launcher_quality LuaQualityPrototype
---@param force LuaForce
---@param ammo_name string? Used ammo
---@return uint32
function LauncherStation.compute_max_range(launcher_name, launcher_quality, force, ammo_name)
    local range = launcher_properties[launcher_name].range --[[@as number]]
    local quality_modifier = launcher_quality.range_multiplier
    local tech_modifier = 1.0 + bonus_control.get_launcher_range_bonus(force)
    local capsule = ammo_name and capsule_properties[ammo_name]
    return range * quality_modifier * tech_modifier * (capsule and capsule.range_modifier or 1.0)
end

function LauncherStation.prototype:update_state()
    if not self:valid() then return false end
    local ammo_slot = self:get_ammo_inventory()[1]
    local ammo_name = ""
    local ammo_quality = nil
    local disabled = self:is_disabled()
    -- auto reload ammo for active launcher only
    if not ammo_slot.valid_for_read and not disabled and self.settings.load_capsule_from_inventory then
        inventory_tool.transfer_to_slot(self:get_inventory(), ammo_slot)
    end
    if ammo_slot.valid_for_read then
        ammo_name = ammo_slot.name
        ammo_quality = ammo_slot.quality
    end
    local ammo_changed = self.ammo_name ~= ammo_name or self.ammo_quality ~= ammo_quality
    -- update payload size
    if ammo_changed then
        self.payload_size = compute_payload_size(ammo_name, ammo_quality)
    end
    -- cancel ongoing delivery if ammo changed/disabled
    if ammo_changed or disabled then
        if self.scheduled_delivery and self.scheduled_delivery:valid() then
            self.scheduled_delivery:destroy()
            self.scheduled_delivery = nil
        end
    end
    local force = self.inventory_entity.force --[[@as LuaForce]]
    local max_range = self:get_max_range(true, ammo_name)
    local effective_max_range = self.settings.range_override and
        math.min(self.settings.range_override, max_range) or max_range
    local consumption = compute_energy_consumption(force, ammo_name, ammo_quality)
    -- resize energy capacity
    if self.max_range ~= effective_max_range or consumption ~= self.energy_consumption then
        local energy = self:get_stored_energy()
        self.overflow_energy = 0
        self.electric_interface.energy = 0
        -- assume capacity modifer change corelate to consumption modifer
        local capacity_modifier = 1.0 + bonus_control.get_launcher_energy_capacity_modifier(force)
        self.electric_interface.electric_buffer_size = effective_max_range * (consumption or 0) * capacity_modifier
        self:charge_energy(energy)
    end
    -- update connections if range changed
    if self.max_range ~= effective_max_range then
        self.max_range = effective_max_range
        self.network:update_launcher_connections(self)
    end
    self.ammo_name = ammo_name
    self.ammo_quality = ammo_quality
    self.energy_consumption = consumption
end

---@param launcher_settings LauncherStationSettings
function LauncherStation.prototype:set_settings(launcher_settings)
    self.settings = util.table.deepcopy(launcher_settings)
    self.turret_entity.direction = self.settings.direction
    self.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]].read_ammo =
        self.settings.circuit_read_ammo
    self:update_ammo_proxy()
    self:set_network_signal(self.settings.network_signal)
end

---@param ignore_override boolean?
---@param ammo_name string?
---@return uint32
function LauncherStation.prototype:get_max_range(ignore_override, ammo_name)
    if ignore_override then
        local launcher_name = self.inventory_entity.name
        local launcher_quality = self.inventory_entity.quality
        local force = self.turret_entity.force --[[@as LuaForce]]
        local ammo = ammo_name or self.ammo_name
        return LauncherStation.compute_max_range(launcher_name, launcher_quality, force, ammo)
    end
    return self.max_range
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
---@return uint32?
function LauncherStation.prototype:get_max_payload_size(ignore_override)
    if ignore_override then return self.payload_size end
    local override = self.settings.payload_size_override
    local payload_size = self.payload_size
    return override and payload_size and math.min(override, payload_size) or payload_size
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
    if self.turret_entity.rotate { by_player = player, reverse = reverse } then
        self.settings.direction = self.turret_entity.direction
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
    self.inventory_entity.teleport(math2d.position.add(last_pos, { 10, 10 }), nil, false)
    self.inventory_entity.teleport(last_pos, nil, false)
    -- update ammo proxy position
    local position = compute_ammo_proxy_position(self.inventory_entity, self.turret_entity.direction)
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
            "\n", { "logistic-cannon-transportation.range-info", range },
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
---@param amount uint32
---@return ScheduledDelivery?
function LauncherStation.prototype:schedule_delivery(receiver, item, amount)
    if not self:is_ready(receiver:position()) then
        return nil
    end
    local inventory = self:get_inventory()
    local available_count = inventory.get_item_count_filtered { name = item.name, quality = item.quality }
    local capsule_size = self:get_max_payload_size() --[[@as number]]
    local payload_count = capsule_size * prototypes.item[item.name].stack_size
    if capsule_size <= 0 or available_count < payload_count or payload_count > amount then
        return nil
    end
    local deliver_item = { name = item.name, quality = item.quality, count = payload_count }
    local delivery = ScheduledDelivery.create(self, receiver, deliver_item, capsule_size)
    self.scheduled_delivery = delivery
    self:set_aiming(delivery.position)
    return delivery
end

---@param position MapPosition
---@return boolean
function LauncherStation.prototype:is_ready(position)
    if not self:valid() or self.ammo_name == "" or self.scheduled_delivery ~= nil then
        return false
    end
    if self:is_disabled() then return false end
    local distance = math2d.position.distance(self:position(), position)
    return self:get_current_range() >= distance
end

---@param source_position MapPosition
function LauncherStation.prototype:launch(source_position)
    self:set_aiming(nil)
    local delivery = self.scheduled_delivery
    if not self:valid() or not delivery then return end
    self.scheduled_delivery = nil -- reset delivery state for launcher
    local ammo_slot = self:get_ammo_inventory()[1]
    if not self:is_disabled() and delivery:valid() and delivery:is_matching_ammo(ammo_slot) then
        local energy_cost = math2d.position.distance(self:position(), delivery.position) * self:get_launch_consumption()
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
                ammo_slot.drain_ammo(1)
                local data = capsule_properties[self.ammo_name] or error()
                self.turret_entity.surface.create_entity {
                    name = string.format(constants.capsule_projectile_format, data.projectile_name, data.speed),
                    position = source_position,
                    direction = self.turret_entity.direction,
                    force = self.turret_entity.force,
                    source = source_position,
                    target = delivery.position,
                }
                self.turret_entity.surface.create_entity {
                    name = constants.entity_tracker,
                    speed = data.speed / 60,
                    position = source_position,
                    direction = self.turret_entity.direction,
                    force = self.turret_entity.force,
                    source = source_position,
                    target = delivery.capsule_entity,
                    cause = delivery.capsule_entity,
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
    if self.target_entity and self.target_entity.valid then
        self.target_entity.destroy()
    end
    if position then
        local direction = math2d.position.get_normalised(math2d.position.subtract(position, self:position()))
        self.target_entity = self.turret_entity.surface.create_entity {
            name = constants.entity_target,
            position = math2d.position.add(self:position(), direction),
            force = "enemy",
        } or error()
        self.target_entity.destructible = false
    else
        self.target_entity = nil
    end
    self.turret_entity.shooting_target = self.target_entity
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
    return self.inventory_entity.valid and self.turret_entity.valid and self.electric_interface.valid
end

---@return MapPosition
function LauncherStation.prototype:position()
    return self.inventory_entity.position
end

---@return boolean
function LauncherStation.prototype:is_disabled()
    if self.inventory_entity.to_be_deconstructed() then return true end
    if not self.settings.circuit_enable_enabled then return false end
    return not signal_condition.evaluate(
        self.settings.circuit_enable_condition, self.inventory_entity,
        self:is_circuit_connected(defines.wire_connector_id.circuit_red, false),
        self:is_circuit_connected(defines.wire_connector_id.circuit_green, false)
    )
end

---@param wire defines.wire_connector_id?
---@param include_ghost boolean
---@return boolean
function LauncherStation.prototype:is_circuit_connected(wire, include_ghost)
    if not wire then
        return
            self:is_circuit_connected(defines.wire_connector_id.circuit_red, include_ghost) or
            self:is_circuit_connected(defines.wire_connector_id.circuit_green, include_ghost)
    end
    local wire_connector = self.inventory_entity.get_wire_connector(wire, false)
    local connection_count = wire_connector[include_ghost and "connection_count" or "real_connection_count"]--[[@as uint32]]
    return connection_count > 1
end

---@param state boolean
function LauncherStation.prototype:set_read_ammo(state)
    local control = self.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]]
    self.settings.circuit_read_ammo = state
    control.read_ammo = state
end

---@return LuaEntity
function LauncherStation.prototype:get_gui_proxy()
    if self.proxy_entity and self.proxy_entity.valid then
        return self.proxy_entity
    end
    self.proxy_entity = self.inventory_entity.surface.create_entity {
        name = constants.entity_launcher_gui_proxy,
        position = self.inventory_entity.position,
        force = self.inventory_entity.force,
    } or error()
    self.proxy_entity.destructible = false
    self.proxy_entity.proxy_target_entity = self.inventory_entity
    self.proxy_entity.proxy_target_inventory = defines.inventory.chest
    return self.proxy_entity
end

return LauncherStation
