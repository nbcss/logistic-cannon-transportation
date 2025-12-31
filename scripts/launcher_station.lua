local constants = require("constants")
local util = require("util")
local math2d = require("math2d")
local format = require("scripts.format")
local bonus_control = require("scripts.bonus_control")
local visualization_control = require("scripts.visualization_control")
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
---@field station_id uint64 The unit number of inventory entity.
---@field turret_id uint64 The unit number of turret entity.
---@field ammo_name string Prototype name of the loaded ammo, empty string means no ammo.
---@field ammo_quality LuaQualityPrototype? Quality of loaded ammo, nil if no ammo.
---@field overflow_energy number The amount of overflow energy
---@field launcher_range number The range of the cannon launcher
---@field network CannonNetwork The netowrk that the station belongs to
---@field scheduled_delivery ScheduledDelivery? The delivery being scheduled for launch.-- FIXME
---@field settings LauncherStationSettings
LauncherStation.prototype = {}
LauncherStation.prototype.__index = LauncherStation.prototype

---User-configurable settings of a cannon launcher, POD.
---@class (exact) LauncherStationSettings
---@field name string Custom name of the station.
---@field load_capsule_from_inventory boolean
LauncherStation.default_settings = {
    name = "",
    load_capsule_from_inventory = true,
}

local launcher_properties = prototypes.mod_data[constants.data_launcher_properties].data--[[@as table<string, LauncherProperties>]]
local capsule_properties = prototypes.mod_data[constants.data_capsule_properties].data--[[@as table<string, CannonCapsuleProperties?>]]

function LauncherStation.on_init()
    ---@type table<uint64, LauncherStation?> LauncherStation's indexed by inventory entity's unit number
    storage.launcher_stations = storage.launcher_stations or {}
    ---@type table<uint64, LauncherStation?> Index of LauncherStation turret_entity.unit_number to LauncherStation
    storage.launcher_stations_turret_index = storage.launcher_stations_turret_index or {}
end

---Create a LauncherStation in storage and associated entities for a newly placed entity.
---@param entity LuaEntity Entity the user has placed.
---@param player_index uint32? The player that placed the entity.
---@return LauncherStation
function LauncherStation.create(entity, player_index)
    assert(entity.name == constants.entity_launcher_inventory)
    local surface = entity.surface
    local position = entity.position
    local force = entity.force --[[@as LuaForce]]

    local turret_entity = surface.create_entity {
        name = constants.entity_launcher_turret,
        position = math2d.position.add(position, { 0, 0.001 }), -- to fix overlap sprite issue
        force = force,
        quality = entity.quality,
    } or error()

    local inventory_entity = entity

    -- local inventory_entity = surface.create_entity {
    --     name = constants.entity_launcher_inventory,
    --     position = position,
    --     force = force,
    --     quality = entity.quality,
    -- } or error()

    local electric_interface = surface.create_entity {
        name = constants.entity_launcher_energy_interface,
        position = position,
        force = force,
        quality = entity.quality,
    } or error()

    local network = CannonNetwork.get_or_create(force, surface)

    local instance = setmetatable({
        inventory_entity = inventory_entity,
        turret_entity = turret_entity,
        electric_interface = electric_interface,
        station_id = inventory_entity.unit_number,
        turret_id = turret_entity.unit_number,
        ammo_name = "",
        overflow_energy = 0,
        launcher_range = 0,
        network = network,
        scheduled_delivery = nil,
        settings = util.table.deepcopy(LauncherStation.default_settings),
    } --[[@as LauncherStation]], LauncherStation.prototype)

    script.register_on_object_destroyed(instance.inventory_entity)
    script.register_on_object_destroyed(instance.turret_entity)

    instance.turret_entity.destructible = false
    instance.electric_interface.destructible = false
    instance.launcher_range = instance:get_max_range()

    storage.launcher_stations[instance:id()] = instance
    storage.launcher_stations_turret_index[instance.turret_id] = instance
    network:add_launcher(instance)
    -- hide placement entity
    -- placement_entity.render_to_forces = { "enemy" }
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
    local ammo_slot = self:get_ammo_inventory()[1]
    local ammo_name = ""
    local ammo_quality = nil
    if not ammo_slot.valid_for_read and self.settings.load_capsule_from_inventory then
        inventory_tool.transfer_to_slot(self:get_inventory(), ammo_slot)
    end
    if ammo_slot.valid_for_read then
        ammo_name = ammo_slot.name
        ammo_quality = ammo_slot.quality
    end
    local range = self:get_max_range()
    if ammo_name == self.ammo_name and ammo_quality == self.ammo_quality and range == self.launcher_range then
        return
    end
    -- cancel ongoing delivery if ammo changed
    if self.ammo_name ~= ammo_name or self.ammo_quality ~= ammo_quality then
        if self.scheduled_delivery and self.scheduled_delivery:valid() then
            self.scheduled_delivery:destroy()
            self.scheduled_delivery = nil
        end
    end
    self.ammo_name = ammo_name
    self.ammo_quality = ammo_quality
    -- transfer overflow energy
    self.overflow_energy = self.overflow_energy + self.electric_interface.energy
    self.electric_interface.energy = 0
    self.electric_interface.electric_buffer_size = range * self:get_launch_consumption()
    local transfer = math.min(self.overflow_energy, self.electric_interface.electric_buffer_size)
    self.overflow_energy = self.overflow_energy - transfer
    self.electric_interface.energy = transfer
    if range ~= self.launcher_range then
        self.network:update_launcher_connections(self)
    end
    self.launcher_range = range
end

function LauncherStation.prototype:get_max_range()
    if not self:valid() then return 0 end
    local range = launcher_properties[self.inventory_entity.name].range --[[@as number]]
    local quality_modifier = self.turret_entity.quality.range_multiplier
    local tech_modifier = 1.0 + bonus_control.get_launcher_range_bonus(self.turret_entity.force --[[@as LuaForce]])
    return range * quality_modifier * tech_modifier
end

function LauncherStation.prototype:get_range()
    local consumption = self:get_launch_consumption()
    if consumption == 0 then return 0 end
    return math.min(self:get_max_range(), self:get_stored_energy() / consumption)
end

function LauncherStation.prototype:update_diode_status()
    if not self:valid() then return end
    local status = "logistic-cannon-transportation.status-ready"
    local diode = defines.entity_status_diode.green --[[@as defines.entity_status_diode]]
    if self.ammo_name == "" then
        status = "logistic-cannon-transportation.status-no-capsule"
        diode = defines.entity_status_diode.red
    elseif self.scheduled_delivery then
        status = "logistic-cannon-transportation.status-preparing"
        diode = defines.entity_status_diode.green
    elseif self.electric_interface.electric_buffer_size - self.electric_interface.energy > 1.0 then
        status = "logistic-cannon-transportation.status-charging"
        diode = defines.entity_status_diode.yellow
    end
    local range = tostring(self:get_max_range())
    if range ~= "0" then
        range = tostring(string.format("%.0f", self:get_range())) .. "/" .. range
    end
    local energy = format.energy(self:get_stored_energy())
    local capacity = format.energy(self:get_energy_capacity())
    if self.proxy_entity and self.proxy_entity.valid then
        self.proxy_entity.custom_status = {
            diode = diode,
            label = { "", { status } }
        }
    end
    self.inventory_entity.custom_status = {
        diode = diode,
        label = { "", { status },
            "\n", { "logistic-cannon-transportation.energy-info", energy, capacity },
            "\n", { "logistic-cannon-transportation.range-info", range },
        }
    }
end

---@param signal SignalID?
function LauncherStation.prototype:set_network_signal(signal)
    local force = self.inventory_entity.force --[[@as LuaForce]]
    local surface = self.inventory_entity.surface
    local network = CannonNetwork.get_or_create(force, surface, signal)
    if network ~= self.network then
        self.network:remove_launcher(self:id())
        self.network = network
        self.network:add_launcher(self)
    end
end

---@return string
function LauncherStation.prototype:get_display_name()
    if self.settings.name ~= "" then
        return self.settings.name
    end
    return string.format("Launcher [%.0f, %.0f]", self:position().x, self:position().y)
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
    local capsule_size = self:get_max_payload_size()
    local payload_count = capsule_size * prototypes.item[item.name].stack_size
    if available_count < payload_count or payload_count > amount then
        return nil
    end
    local deliver_item = { name = item.name, quality = item.quality, count = payload_count }
    local delivery = ScheduledDelivery.create(self, receiver, deliver_item)
    self.scheduled_delivery = delivery
    self:set_aiming(delivery.position)
    return delivery
end

---@param position MapPosition
---@return boolean
function LauncherStation.prototype:is_ready(position)
    if not self:valid() or self.inventory_entity.to_be_deconstructed() then
        return false
    end
    if self.ammo_name == "" or self.scheduled_delivery ~= nil then
        return false
    end
    local distance = math2d.position.distance(self:position(), position)
    return self:get_range() >= distance
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

function LauncherStation.prototype:get_energy_capacity()
    return self.electric_interface.electric_buffer_size
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
    local ammo_slot = self:get_ammo_inventory()[1]
    if delivery:valid() and delivery:is_matching_ammo(ammo_slot) then
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
                local speed = self:get_projectile_speed()
                self.turret_entity.surface.create_entity {
                    name = "logistic-cannon-capsule-projectile-" .. speed,
                    position = source_position,
                    direction = self.turret_entity.direction,
                    force = self.turret_entity.force,
                    source = source_position,
                    target = delivery.position,
                }
                self.turret_entity.surface.create_entity {
                    name = "logistic-cannon-capsule-tracker-" .. speed,
                    position = source_position,
                    direction = self.turret_entity.direction,
                    force = self.turret_entity.force,
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

---@return uint32?
function LauncherStation.prototype:get_max_payload_size()
    local data = capsule_properties[self.ammo_name]
    local payload_size = data and data.payload_size or 0
    local quality_modifier = self.ammo_quality and self.ammo_quality.default_multiplier or 1
    return math.floor(0.5 + (payload_size * quality_modifier))
end

---@return number
function LauncherStation.prototype:get_launch_consumption()
    local data = capsule_properties[self.ammo_name]
    local consumption = data and data.energy_consumption or 0
    local quality_modifier = self.ammo_quality and 1 / self.ammo_quality.default_multiplier or 1
    return consumption * quality_modifier
end

---@return string
function LauncherStation.prototype:get_projectile_speed()
    local data = capsule_properties[self.ammo_name]
    return data and data.speed_tier or "slow"
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
