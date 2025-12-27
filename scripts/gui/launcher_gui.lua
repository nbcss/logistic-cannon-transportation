local constants = require "constants"
local format = require("scripts.format")
local LauncherStation = require("scripts.launcher_station")
local launcher_gui = {}
local name = "logistic-cannon-launcher-gui"

-- Info:
-- Energy (progressbar)
-- Range
-- Current capsule
---- Launch consumption
---- Payload size
---- Projectile speed?
-- Stations in range (number)
---- Station name, distance

-- Settings:
-- Change name (top)
-- Network
-- Enable auto-load ammo from trunk?
-- Read content (circuit)
-- Enable/disable (circuit)

---@param player LuaPlayer
---@param entity LuaEntity
function launcher_gui.on_gui_opened(player, entity)
    if player.gui.relative[name] then
        player.gui.relative[name].destroy()
    end
    if entity.name ~= "logistic-cannon-launcher-entity" then
        return
    end

    local outer_frame = player.gui.relative.add {
        type = "frame",
        name = name,
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.car_gui,
            position = defines.relative_gui_position.right,
        },
    }
    local inner_frame = outer_frame.add {
        type = "frame",
        name = "inner_frame",
        style = "inside_shallow_frame_with_padding_and_vertical_spacing",
        direction = "vertical",
    }
    inner_frame.add {
        type = "progressbar",
        name = "energy_bar",
        style = "production_progressbar",
    }
    launcher_gui.refresh(player, entity)
end

---@param player LuaPlayer
---@param entity LuaEntity
function launcher_gui.refresh(player, entity)
    local data = LauncherStation.get(entity)
    if not data then return end
    local gui = player.gui.relative[name] ---@type LuaGuiElement
    gui.caption = { "", data:get_display_name() }
    local energy_ratio = 0
    local energy = format.energy(data:get_stored_energy())
    local capacity = format.energy(data:get_energy_capacity())
    if data:get_energy_capacity() > 0 then
        energy_ratio = math.min(1.0, data:get_stored_energy() / data:get_energy_capacity())
    end
    gui.inner_frame.energy_bar.value = energy_ratio
    gui.inner_frame.energy_bar.caption = { "", string.format("Energy: %s/%s", energy, capacity) }
end

return launcher_gui
