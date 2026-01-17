local constants = require("constants")
local bonus_control = {}

---@param force LuaForce
function bonus_control.update_bonus(force)
    local range_bonus = bonus_control.get_launcher_range_bonus(force) * 100
    local consumption_modifier = bonus_control.get_launcher_energy_consumption_modifier(force) * 100
    local capacity_modifier = bonus_control.get_launcher_energy_capacity_modifier(force) * 100
    local texts = {}
    if range_bonus ~= 0 then
        table.insert(texts, { "logistic-cannon-transportation.launcher-range-bonus", range_bonus })
    end
    if consumption_modifier ~= 0 then
        table.insert(texts, { "logistic-cannon-transportation.launcher-energy-consumption-modifier", consumption_modifier })
    end
    if capacity_modifier ~= 0 then
        table.insert(texts, { "logistic-cannon-transportation.launcher-energy-capacity-modifier", capacity_modifier })
    end
    if #texts > 0 then
        remote.call("custom-bonus-gui", "set", force, {
            mod_name = constants.mod_name,
            name = "cannon-launcher-bonus",
            icons = {
                {
                    type = "item",
                    name = constants.item_launcher,
                }
            },
            texts = texts
        })
    else
        remote.call("custom-bonus-gui", "remove", force, "cannon-launcher-bonus")
    end
end

---@param force LuaForce
---@return number
function bonus_control.get_launcher_range_bonus(force)
    return force.get_ammo_damage_modifier(constants.range_upgrade_bonus)
end

---@param force LuaForce
---@return number
function bonus_control.get_launcher_energy_capacity_modifier(force)
    return force.get_ammo_damage_modifier(constants.energy_capacity_modifier)
end

---@param force LuaForce
---@return number
function bonus_control.get_launcher_energy_consumption_modifier(force)
    return force.get_ammo_damage_modifier(constants.energy_consumption_modifier)
end

return bonus_control
