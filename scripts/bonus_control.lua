local constants = require("constants")
local bonus_control = {}

---@param force LuaForce
function bonus_control.update_bonus(force)
    local launcher_range_bonus = bonus_control.get_launcher_range_bonus(force) * 100
    if launcher_range_bonus > 0 then
        remote.call("custom-bonus-gui", "set", force, {
            mod_name = constants.mod_name,
            name = "cannon-launcher-bonus",
            icons = {
                {
                    type = "item",
                    name = "logistic-cannon-launcher"
                }
            },
            texts = {
                { "logistic-cannon-transportation.launcher-range-bonus", launcher_range_bonus },
            }
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

return bonus_control