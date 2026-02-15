local constants = require("constants")
local bonus_control = {}

---@class BonusModifier
---@field range_modifier number
---@field consumption_modifier number
---@field capacity_modifier number

function bonus_control.on_init()
    ---@type table<uint64, BonusModifier?>
    storage.force_bonus = storage.force_bonus or {}
end

---@param event EventData.on_forces_merging
function bonus_control.on_forces_merging(event)
    storage.force_bonus[event.source.index] = nil
end

---@param force LuaForce
---@param update boolean?
local function get_bonus(force, update)
    local bonus = storage.force_bonus[force.index]
    if not bonus then
        bonus = {
            range_modifier = force.get_ammo_damage_modifier(constants.range_upgrade_bonus),
            consumption_modifier = force.get_ammo_damage_modifier(constants.range_upgrade_bonus),
            capacity_modifier = force.get_ammo_damage_modifier(constants.energy_consumption_modifier),
        }
        storage.force_bonus[force.index] = bonus
    elseif update then
        bonus.range_modifier = force.get_ammo_damage_modifier(constants.range_upgrade_bonus)
        bonus.consumption_modifier = force.get_ammo_damage_modifier(constants.range_upgrade_bonus)
        bonus.capacity_modifier = force.get_ammo_damage_modifier(constants.energy_consumption_modifier)
    end
    return bonus
end

---@param force LuaForce
function bonus_control.update_bonus(force)
    local bonus = get_bonus(force, true)
    local texts = {}
    if bonus.range_modifier ~= 0 then
        table.insert(texts, { "logistic-cannon-transportation.launcher-range-bonus", bonus.range_modifier * 100 })
    end
    if bonus.consumption_modifier ~= 0 then
        table.insert(texts, { "logistic-cannon-transportation.launcher-energy-consumption-modifier", bonus.consumption_modifier * 100 })
    end
    if bonus.capacity_modifier ~= 0 then
        table.insert(texts, { "logistic-cannon-transportation.launcher-energy-capacity-modifier", bonus.capacity_modifier * 100 })
    end
    if #texts > 0 then
        remote.call("custom-bonus-gui", "set", force, {
            mod_name = script.mod_name,
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
    return get_bonus(force).range_modifier
end

---@param force LuaForce
---@return number
function bonus_control.get_launcher_energy_capacity_modifier(force)
    return get_bonus(force).capacity_modifier
end

---@param force LuaForce
---@return number
function bonus_control.get_launcher_energy_consumption_modifier(force)
    return get_bonus(force).consumption_modifier
end

return bonus_control
