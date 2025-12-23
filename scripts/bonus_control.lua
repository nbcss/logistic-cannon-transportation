local bonus_control = {}

---@param force LuaForce
function bonus_control.update_bonus(force)
    local capacity_bonus = bonus_control.get_launcher_energy_capacity_bonus(force) * 100
    if capacity_bonus > 0 then
        remote.call("custom-bonus-gui", "set", force, {
            mod_name = "logistic-cannon-transportation",
            name = "cannon-launcher-energy-capacity",
            icons = {
                {
                    type = "item",
                    name = "logistic-cannon-launcher"
                }
            },
            texts = {
                { "logistic-cannon-transportation.energy-capacity-bonus", capacity_bonus },
            }
        })
    else
        remote.call("custom-bonus-gui", "remove", force, "cannon-launcher-energy-capacity")
    end
end

---@param force LuaForce
---@return number
function bonus_control.get_launcher_energy_capacity_bonus(force)
    return force.get_ammo_damage_modifier("logistic-cannon-launcher-energy-buffer")
end

return bonus_control