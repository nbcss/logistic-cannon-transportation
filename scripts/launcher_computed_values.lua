local constants = require("constants")
local lct_util = require("scripts.lct_util")
local bonus_control = require("scripts.bonus_control")

local launcher_computed_values = {}

local launcher_properties = prototypes.mod_data[constants.data_launcher_properties]
    .data --[[@as table<string, LauncherProperties>]]
local capsule_properties = prototypes.mod_data[constants.data_capsule_properties]
    .data --[[@as table<string, CapsuleProperties?>]]

---@param force LuaForce
---@param ammo_name string
---@param ammo_quality LuaQualityPrototype?
---@return number?
function launcher_computed_values.compute_energy_consumption(force, ammo_name, ammo_quality)
    local data = capsule_properties[ammo_name]
    local consumption = data and data.energy_consumption or 0
    if consumption == 0 then return nil end
    local quality_modifier = ammo_quality and 1 / ammo_quality.range_multiplier or 1
    local modifier = 1.0 + bonus_control.get_launcher_energy_consumption_modifier(force)
    return consumption * quality_modifier * modifier
end

---@param ammo_name string
---@param ammo_quality LuaQualityPrototype?
---@return uint32
function launcher_computed_values.compute_payload_size(ammo_name, ammo_quality)
    local data = capsule_properties[ammo_name]
    local payload_size = data and data.payload_size or 0
    local quality_modifier = ammo_quality and ammo_quality.default_multiplier or 1
    return lct_util.round(payload_size * quality_modifier)
end

---@param inventory_entity LuaEntity
---@param direction defines.direction
function launcher_computed_values.compute_ammo_proxy_position(inventory_entity, direction)
    local opposite = util.oppositedirection(direction)
    local distance = inventory_entity.tile_height / 2 - 0.5
    return util.moveposition(inventory_entity.position, opposite, distance)
end

---@param launcher_name string
---@param launcher_quality LuaQualityPrototype
---@param force LuaForce
---@param ammo_name string? Used ammo
---@return uint32
function launcher_computed_values.compute_max_range(launcher_name, launcher_quality, force, ammo_name)
    local range = launcher_properties[launcher_name].range --[[@as number]]
    local quality_modifier = launcher_quality.range_multiplier
    local tech_modifier = 1.0 + bonus_control.get_launcher_range_bonus(force)
    local capsule = ammo_name and capsule_properties[ammo_name]
    return range * quality_modifier * tech_modifier * (capsule and capsule.range_modifier or 1.0)
end

---@generic T
---@param computed T
---@param override T?
---@return T
function launcher_computed_values.with_override(computed, override)
    return override and math.min(computed, override) or computed
end

return launcher_computed_values