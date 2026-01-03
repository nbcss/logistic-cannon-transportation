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
-- Enable auto-load ammo from inventory?
-- Read ammo (circuit)
-- Read inventory (circuit)
-- Enable/disable (circuit)

local ammo_slot_options = {
    empty_sprite = "utility/empty_ammo_slot",
    empty_tooltip = { "", { "gui.ammo" } },
} --[[@as GuiInventorySlot.Options]]
for ammo, _ in pairs(prototypes.mod_data[constants.data_capsule_properties].data) do
    table.insert(ammo_slot_options.empty_tooltip --[[@as table]], "\n[item=" .. ammo .. "] ")
    table.insert(ammo_slot_options.empty_tooltip --[[@as table]], prototypes.item[ammo].localised_name)
end

local projectile_properties = prototypes.mod_data[constants.data_projectile_properties]
    .data --[[@as table<string, ProjectileProperties>]]

---@param player LuaPlayer
---@param entity LuaEntity
function launcher_gui.on_gui_opened(player, entity)
    if player.gui.relative[name] then
        player.gui.relative[name].destroy()
    end
    if entity.name ~= constants.entity_launcher_gui_proxy then
        return
    end

    local frame = player.gui.relative.add {
        type = "frame",
        name = name,
        direction = "vertical",
        style = "lct_config_frame",
        caption = "\xE2\x80\x8B", --ZWSP
        anchor = {
            gui = defines.relative_gui_type.proxy_container_gui,
            name = constants.entity_launcher_gui_proxy,
            position = defines.relative_gui_position.right,
        },
    }
    frame.add {
        type = "frame",
        name = "station",
        style = "inside_shallow_frame_with_padding_and_vertical_spacing",
        direction = "vertical",
    }
    -- header
    frame.station.add {
        type = "frame",
        name = "header",
        style = "lct_subheader_frame",
        direction = "horizontal",
    }
    frame.station.header.add {
        type = "label",
        name = "display_name",
        style = "subheader_caption_label",
    }
    frame.station.header.add {
        type = "textfield",
        name = "edit_name_field",
        style = "textbox",
        visible = false,
        icon_selector = true,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_confirmed = "launcher_gui.on_confirm_display_name",
            },
        },
    }
    frame.station.header.add {
        type = "sprite-button",
        name = "edit_name_button",
        sprite = "utility/rename_icon",
        style = "mini_button_aligned_to_text_vertically_when_centered",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_click = "launcher_gui.on_edit_display_name",
            },
        },
    }
    frame.station.header.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    -- ammo/energy
    frame.station.add {
        type = "flow",
        name = "ammo_and_energy",
        direction = "horizontal",
        style = "lct_player_input",
    }
    inventory_slot.create { parent = frame.station.ammo_and_energy, name = "ammo_slot" }.tags = {
        [constants.gui_tag_event_handlers] = {
            on_gui_click = "launcher_gui.on_click_ammo_slot",
        },
    }
    frame.station.ammo_and_energy.add {
        type = "progressbar",
        name = "energy_bar",
        style = "lct_energy_bar",
    }
    frame.station.add {
        type = "line",
        style = "inside_shallow_frame_with_padding_line",
    }
    -- range
    frame.station.add {
        type = "flow",
        name = "range",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.range.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-range" }, " [img=info]" },
        tooltip = { "logistic-cannon-transportation.launcher-range-tooltip" },
    }
    frame.station.range.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.range.add {
        type = "label",
        name = "value_label",
    }
    -- charging speed
    frame.station.add {
        type = "flow",
        name = "charging_speed",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.charging_speed.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-charging-speed" }, },
    }
    frame.station.charging_speed.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.charging_speed.add {
        type = "label",
        name = "value_label",
    }
    -- connected receivers
    frame.station.add {
        type = "flow",
        name = "connected_receivers",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.connected_receivers.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-connected-receivers" }, },
    }
    frame.station.connected_receivers.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.connected_receivers.add {
        type = "label",
        name = "value_label",
    }
    -- payload size
    frame.station.add {
        type = "flow",
        name = "payload_size",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.payload_size.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-payload-size" }, },
    }
    frame.station.payload_size.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.payload_size.add {
        type = "sprite-button",
        name = "edit_button",
        sprite = "utility/rename_icon",
        style = "mini_button_aligned_to_text_vertically_when_centered",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_click = "launcher_gui.begin_edit_payload_override",
            },
        },
    }
    frame.station.payload_size.add {
        type = "label",
        name = "value_label",
    }
    -- energy consumption
    frame.station.add {
        type = "flow",
        name = "energy_consumption",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.energy_consumption.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-energy-consumption" }, " [img=info]" },
        tooltip = { "logistic-cannon-transportation.launcher-energy-consumption-tooltip" },
    }
    frame.station.energy_consumption.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.energy_consumption.add {
        type = "label",
        name = "value_label",
    }
    -- projectile speed
    frame.station.add {
        type = "flow",
        name = "projectile_speed",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.projectile_speed.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-projectile-speed" }, },
    }
    frame.station.projectile_speed.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.projectile_speed.add {
        type = "label",
        name = "value_label",
    }
    -- network
    frame.station.add {
        type = "flow",
        name = "network",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.network.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.network" }, " [img=info]" },
        tooltip = { "logistic-cannon-transportation.network-tooltip" },
    }
    frame.station.network.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.network.add {
        type = "choose-elem-button",
        name = "value_signal",
        elem_type = "signal",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_elem_changed = "launcher_gui.on_set_network",
            },
        },
    }
    -- Circuit header
    frame.add {
        type = "frame",
        name = "circuit",
        style = "inside_shallow_frame_with_padding_and_vertical_spacing",
        direction = "vertical",
    }
    frame.circuit.add {
        type = "frame",
        name = "header",
        style = "lct_subheader_frame",
        direction = "horizontal",
    }
    frame.circuit.header.add {
        type = "label",
        name = "title",
        style = "subheader_label",
        caption = { "logistic-cannon-transportation.circuit-control" }
    }
    -- Read ammo
    frame.circuit.add {
        type = "checkbox",
        name = "read_ammo",
        style = "caption_checkbox",
        caption = { "gui-control-behavior-modes.read-ammo" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_read_ammo_state_changed",
            },
        },
    }
    -- Read contents
    frame.circuit.add {
        type = "checkbox",
        name = "read_contents",
        style = "caption_checkbox",
        caption = { "gui-control-behavior-modes.read-contents" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_read_contents_state_changed",
            },
        },
    }

    launcher_gui.refresh(player, entity)
end

---@param player LuaPlayer
---@param entity LuaEntity
function launcher_gui.refresh(player, entity)
    local data = LauncherStation.get(entity)
    if not data or not data:valid() then return end
    local frame = player.gui.relative[name] ---@type LuaGuiElement
    frame.station.header.display_name.caption = data.settings.name or
        { "logistic-cannon-transportation.launcher-default-name" }
    local energy_ratio = 0
    local energy = format.energy(data:get_stored_energy())
    local capacity = format.energy(data:get_energy_capacity())
    if data:get_energy_capacity() > 0 then
        energy_ratio = math.min(1.0, data:get_stored_energy() / data:get_energy_capacity())
    end
    inventory_slot.refresh {
        element = frame.station.ammo_and_energy.ammo_slot,
        target = data:get_ammo_inventory()[1],
        options = ammo_slot_options,
    }
    frame.station.ammo_and_energy.energy_bar.value = energy_ratio
    frame.station.ammo_and_energy.energy_bar.caption = { "", { "logistic-cannon-transportation.launcher-energy", energy, capacity } }
    frame.station.range.value_label.caption = string.format("%.0f/%.0f", data:get_range(), data.launcher_range)
    frame.station.charging_speed.value_label.caption = format.energy(data:get_charging_speed(), "W")
    local payload_size = data:get_max_payload_size()
    frame.station.payload_size.edit_button.visible = payload_size ~= nil
    frame.station.payload_size.value_label.caption = payload_size and
        { "logistic-cannon-transportation.stack", payload_size } or "-"
    local energy_consumption = data:get_launch_consumption()
    frame.station.energy_consumption.value_label.caption = energy_consumption and
        format.energy(energy_consumption, "J/m") or "-"
    local projectile_speed = projectile_properties[data:get_projectile_speed()]
    frame.station.projectile_speed.value_label.caption = projectile_speed and projectile_speed.locale_string or "-"
    frame.station.connected_receivers.value_label.caption = data.network:get_connection_count(data:id())
    frame.station.network.value_signal.elem_value = data.network.signal
    frame.circuit.read_ammo.state = data.turret_entity.get_or_create_control_behavior().read_ammo --[[@as boolean]]
    frame.circuit.read_contents.state = data.inventory_entity.get_or_create_control_behavior()
         .read_contents --[[@as boolean]]
end

---@param data LauncherStation
---@param frame LuaGuiElement
local function set_display_name(data, frame)
    if frame.station.header.edit_name_field.text ~= "" then
        data.settings.name = frame.station.header.edit_name_field.text
    else
        data.settings.name = nil
    end
    frame.station.header.display_name.caption = data.settings.name or
        { "logistic-cannon-transportation.launcher-default-name" }
    frame.station.header.edit_name_field.visible = false
    frame.station.header.display_name.visible = true
end

---@param player LuaPlayer
---@param event EventData.on_gui_confirmed
function launcher_gui.on_confirm_display_name(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data or not data:valid() then return end
    local frame = player.gui.relative[name] ---@type LuaGuiElement
    set_display_name(data, frame)
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_edit_display_name(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data or not data:valid() then return end
    local frame = player.gui.relative[name] ---@type LuaGuiElement
    if frame.station.header.edit_name_field.visible then
        set_display_name(data, frame)
    else
        frame.station.header.edit_name_field.text = data.settings.name or ""
        frame.station.header.edit_name_field.visible = true
        frame.station.header.display_name.visible = false
        frame.station.header.edit_name_field.focus()
    end
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_click_ammo_slot(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data or not data:valid() then return end
    inventory_slot.click {
        element = event.element,
        target = data:get_ammo_inventory()[1],
        options = ammo_slot_options,
        player = player,
        button = event.button,
    }
end

function launcher_gui.begin_edit_payload_override(player, event)

end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_set_network(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data or not data:valid() then return end
    local signal = event.element.elem_value --[[@as SignalID?]]
    data:set_network_signal(signal)
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function launcher_gui.on_read_ammo_state_changed(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data or not data:valid() then return end
    local control = data.turret_entity.get_or_create_control_behavior() --[[@as LuaTurretControlBehavior]]
    control.read_ammo = event.element.state
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function launcher_gui.on_read_contents_state_changed(player, event)
    local data = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not data or not data:valid() then return end
    local control = data.inventory_entity.get_or_create_control_behavior() --[[@as LuaContainerControlBehavior]]
    control.read_contents = event.element.state
end

return launcher_gui
