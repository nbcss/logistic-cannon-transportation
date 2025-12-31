local constants = require "constants"
local format = require("scripts.format")
local inventory_slot = require("scripts.gui.inventory_slot")
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
-- Map view
-- X stations in range (include a button to show list of stations)

-- Settings:
-- Change name (top)
-- Network
-- Payload size override?
-- Enable auto-load ammo from trunk?
-- Read ammo (circuit)
-- Read inventory (circuit)
-- Enable/disable (circuit)

---@param player LuaPlayer
---@param entity LuaEntity
function launcher_gui.on_gui_opened(player, entity)
    if player.gui.relative[name] then
        player.gui.relative[name].destroy()
    end
    if entity.name ~= constants.entity_launcher_gui_proxy then
        return
    end

    local outer_frame = player.gui.relative.add {
        type = "frame",
        name = name,
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.proxy_container_gui,
            name = constants.entity_launcher_gui_proxy,
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
    inventory_slot.create(inner_frame, "ammo_slot").tags = {
        [constants.gui_tag_event_handlers] = {
            on_gui_click = "launcher_gui.on_click_ammo_slot",
        },
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
    inventory_slot.refresh(gui.inner_frame.ammo_slot, data:get_ammo_inventory()[1])
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_click_ammo_slot(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data then return end
    inventory_slot.click(event.element, data:get_ammo_inventory()[1], player, event.button)
end

return launcher_gui
