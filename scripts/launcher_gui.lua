local launcher_gui = {}
local name = "logistic-cannon-launcher"

---@param player LuaPlayer
---@param entity LuaEntity
function launcher_gui.on_gui_opened(player, entity)
    if player.gui.relative[name] then
        player.gui.relative[name].destroy()
    end
    if entity.name ~= "logistic-cannon-launcher-entity" then
        return
    end

    local energy_frame = player.gui.relative.add {
        type = "frame",
        name = name,
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.car_gui,
            position = defines.relative_gui_position.right,
        },
    }
end

return launcher_gui