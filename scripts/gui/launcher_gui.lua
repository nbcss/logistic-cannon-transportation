local constants = require("constants")
local format = require("scripts.format")
local inventory_slot = require("scripts.gui.inventory_slot")
local signal_condition = require("scripts.gui.signal_condition")
local LauncherStation = require("scripts.launcher_station")
local shared_gui      = require("scripts.gui.shared_gui")
local launcher_gui = {}

local ammo_slot_options = {
    empty_sprite = "utility/empty_ammo_slot",
    empty_tooltip = { "", { "gui.ammo" } },
} --[[@as GuiInventorySlot.Options]]
for ammo, _ in pairs(prototypes.mod_data[constants.data_capsule_properties].data) do
    table.insert(ammo_slot_options.empty_tooltip --[[@as table]], "\n[item=" .. ammo .. "] ")
    table.insert(ammo_slot_options.empty_tooltip --[[@as table]], prototypes.item[ammo].localised_name)
end

---@param player LuaPlayer
---@return LuaGuiElement
function launcher_gui.get_or_create(player)
    local frame = player.gui.relative[constants.gui_launcher]
    if frame then
        return frame
    end

    --frame
    frame = player.gui.relative.add {
        type = "frame",
        name = constants.gui_launcher,
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
        name = "energy",
        style = "lct_caption_progressbar",
    }
    frame.station.add {
        type = "checkbox",
        name = "auto_load_ammo",
        style = "caption_checkbox",
        caption = { "logistic-cannon-transportation.launcher-auto-load-ammo" },
        tooltip = { "logistic-cannon-transportation.launcher-auto-load-ammo-tooltip" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_auto_load_ammo_state_changed",
            },
        },
    }
    frame.station.add {
        type = "checkbox",
        name = "side_load_ammo",
        style = "caption_checkbox",
        caption = { "logistic-cannon-transportation.launcher-enable-side-load-ammo" },
        tooltip = { "logistic-cannon-transportation.launcher-enable-side-load-ammo-tooltip" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_side_load_ammo_state_changed",
            },
        },
    }
    -- line
    frame.station.add {
        type = "line",
        style = "inside_shallow_frame_with_padding_line",
    }
    -- range
    frame.station.add {
        type = "frame",
        name = "range",
        style = "invisible_frame",
        direction = "vertical",
    }
    frame.station.range.add {
        type = "flow",
        name = "info",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.range.info.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-range" }, " [img=info]" },
        tooltip = { "logistic-cannon-transportation.launcher-range-tooltip" },
    }
    frame.station.range.info.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.range.info.add {
        type = "sprite-button",
        name = "edit_button",
        sprite = "utility/rename_icon",
        style = "lct_configuration_select_button",
        tooltip = { "logistic-cannon-transportation.launcher-edit-range-override" },
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_click = "launcher_gui.on_edit_range_override",
            },
        },
    }
    frame.station.range.info.add {
        type = "label",
        name = "value_label",
    }
    frame.station.range.add {
        type = "flow",
        name = "override",
        direction = "horizontal",
        style = "lct_player_input",
        visible = false,
    }
    frame.station.range.override.add {
        type = "checkbox",
        name = "checkbox",
        style = "checkbox",
        caption = {"", { "logistic-cannon-transportation.override" }, " [img=info]"},
        tooltip = { "logistic-cannon-transportation.override-range-info" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_toggle_override",
            },
        },
    }
    frame.station.range.override.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.range.override.add {
        type = "textfield",
        name = "input_text",
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        style = "slider_value_textfield",
        text = "1",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_confirmed = "launcher_gui.on_edit_range_override"
            },
        },
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
        raise_hover_events = true,
        tags = {
            [constants.gui_tag_tracked_hover_state] = false,
            [constants.gui_tag_event_handlers] = {
                on_gui_hover = "launcher_gui.on_lazy_tooltip_hover",
            },
        },
    }
    -- payload size
    frame.station.add {
        type = "frame",
        name = "payload_size",
        style = "invisible_frame",
        direction = "vertical",
    }
    frame.station.payload_size.add {
        type = "flow",
        name = "info",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.payload_size.info.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.launcher-payload-size" }, },
    }
    frame.station.payload_size.info.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.payload_size.info.add {
        type = "sprite-button",
        name = "edit_button",
        sprite = "utility/rename_icon",
        style = "lct_configuration_select_button",
        tooltip = { "logistic-cannon-transportation.launcher-edit-payload-size-override" },
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_click = "launcher_gui.on_edit_payload_override",
            },
        },
    }
    frame.station.payload_size.info.add {
        type = "label",
        name = "value_label",
    }
    frame.station.payload_size.add {
        type = "flow",
        name = "override",
        direction = "horizontal",
        style = "lct_player_input",
        visible = false,
    }
    frame.station.payload_size.override.add {
        type = "checkbox",
        name = "checkbox",
        style = "checkbox",
        caption = {"", { "logistic-cannon-transportation.override" }, " [img=info]"},
        tooltip = { "logistic-cannon-transportation.override-payload-size-info" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_toggle_override",
            },
        },
    }
    frame.station.payload_size.override.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.payload_size.override.add {
        type = "textfield",
        name = "input_text",
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        style = "slider_value_textfield",
        text = "1",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_confirmed = "launcher_gui.on_edit_payload_override"
            },
        },
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
    shared_gui.circuit_control_header.create(frame.circuit, "header", "launcher_gui.on_lazy_tooltip_hover")
    -- Enable/disable
    signal_condition.create_gui(frame.circuit)
    frame.circuit.add {
        type = "line",
        style = "inside_shallow_frame_with_padding_line",
    }
    -- Read ammo
    frame.circuit.add {
        type = "checkbox",
        name = "read_ammo",
        style = "caption_checkbox",
        caption = { "gui-control-behavior-modes.read-ammo" },
        tooltip = { "logistic-cannon-transportation.read-ammo-description" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_read_ammo_state_changed",
            },
        },
    }
    frame.circuit.add {
        type = "line",
        style = "inside_shallow_frame_with_padding_line",
    }
    -- Read contents
    frame.circuit.add {
        type = "checkbox",
        name = "read_contents",
        style = "caption_checkbox",
        caption = { "gui-control-behavior-modes.read-contents" },
        tooltip = { "logistic-cannon-transportation.read-contents-description" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "launcher_gui.on_read_contents_state_changed",
            },
        },
    }

    return frame
end

---@param player LuaPlayer
function launcher_gui.destroy(player)
    local frame = player.gui.relative[constants.gui_launcher]
    if frame then
        frame.destroy()
    end
end

---@param player LuaPlayer
---@param launcher LauncherStation
function launcher_gui.refresh(player, launcher)
    if not launcher:valid() then return end
    local frame = launcher_gui.get_or_create(player)

    local station_frame = frame.station
    station_frame.header.display_name.caption = launcher.settings.name or
        { "logistic-cannon-transportation.launcher-default-name" }
    inventory_slot.refresh {
        element = station_frame.ammo_and_energy.ammo_slot,
        target = launcher:get_ammo_inventory()[1],
        options = ammo_slot_options,
    }
    local energy = format.energy(launcher:get_stored_energy())
    local capacity = format.energy(launcher:get_energy_capacity())
    local energy_ratio = launcher:get_stored_energy() > 0 and
        math.min(1.0, launcher:get_stored_energy() / launcher:get_energy_capacity()) or 0
    station_frame.ammo_and_energy.energy.value = energy_ratio
    station_frame.ammo_and_energy.energy.caption = { "", { "logistic-cannon-transportation.launcher-energy", energy, capacity } }
    station_frame.auto_load_ammo.state = launcher.settings.load_capsule_from_inventory
    station_frame.side_load_ammo.state = launcher.settings.enable_ammo_proxy
    station_frame.range.info.value_label.caption = { "",
        string.format("%.0f", launcher:get_current_range()),
        launcher.settings.range_override and "[color=yellow]" or "[color=#ffffff]",
        string.format("/%.0f", launcher:get_max_range()),
        "[/color]",
    }
    station_frame.charging_speed.value_label.caption = format.energy(launcher:get_charging_speed(), "W")
    local payload_size = launcher:get_max_payload_size()
    station_frame.payload_size.info.edit_button.visible = payload_size ~= nil
    station_frame.payload_size.info.value_label.caption = { "",
        launcher.settings.payload_size_override and "[color=yellow]" or "[color=#ffffff]",
        payload_size and { "logistic-cannon-transportation.stack", payload_size } or "-",
        "[/color]",
    }
    local energy_consumption = launcher:get_launch_consumption()
    station_frame.energy_consumption.value_label.caption = energy_consumption and
        format.energy(energy_consumption, "J/m") or "-"
    local projectile_speed = launcher:get_projectile_speed()
    station_frame.projectile_speed.value_label.caption = projectile_speed and
        { "logistic-cannon-transportation.meter-per-second", tostring(projectile_speed) } or "-"
    local connected_count = launcher.network:get_connection_count(launcher:id())
    if connected_count > 0 then
        station_frame.connected_receivers.value_label.caption = string.format("%s [img=info]", connected_count)
        if station_frame.connected_receivers.value_label.tags[constants.gui_tag_tracked_hover_state] then
            local unamed_count = 0
            local names = {}
            for receiver in launcher.network:connected_receivers(launcher) do
                if receiver.settings.name then
                    table.insert(names, receiver.settings.name)
                else
                    unamed_count = unamed_count + 1
                end
            end
            station_frame.connected_receivers.value_label.tooltip = { "",
                unamed_count > 0 and { "logistic-cannon-transportation.launcher-connected-receivers-unamed-count", unamed_count } or nil,
                unamed_count > 0 and #names > 0 and "\n" or nil,
                table.concat(names, "\n"),
            }
        end
    else
        station_frame.connected_receivers.value_label.caption = "0"
        station_frame.connected_receivers.value_label.tooltip = nil
    end
    station_frame.network.value_signal.elem_value = launcher.network.signal
    -- circuit refresh
    local circuit_frame = frame.circuit
    shared_gui.circuit_control_header.refresh(circuit_frame.header, launcher)
    local circuit_connected = launcher:is_circuit_connected(true)
    circuit_frame.read_ammo.enabled = circuit_connected
    circuit_frame.read_ammo.state = launcher.settings.circuit_read_ammo
    circuit_frame.read_contents.enabled = circuit_connected
    circuit_frame.read_contents.state = launcher.inventory_entity.get_or_create_control_behavior()
        .read_contents --[[@as boolean]]
    signal_condition.refresh(circuit_connected, launcher.settings.circuit_enable_condition, circuit_frame.enable_condition)
end

---@param launcher LauncherStation
---@param frame LuaGuiElement
local function set_display_name(launcher, frame)
    if frame.station.header.edit_name_field.text ~= "" then
        launcher.settings.name = frame.station.header.edit_name_field.text
    else
        launcher.settings.name = nil
    end
    frame.station.header.display_name.caption = launcher.settings.name or
        { "logistic-cannon-transportation.launcher-default-name" }
    frame.station.header.edit_name_field.visible = false
    frame.station.header.display_name.visible = true
end

---@param player LuaPlayer
---@param event EventData.on_gui_hover
function launcher_gui.on_lazy_tooltip_hover(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    launcher_gui.refresh(player, launcher)
end

---@param player LuaPlayer
---@param event EventData.on_gui_confirmed
function launcher_gui.on_confirm_display_name(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    local frame = player.gui.relative[constants.gui_launcher] ---@type LuaGuiElement
    set_display_name(launcher, frame)
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_edit_display_name(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    local frame = player.gui.relative[constants.gui_launcher] ---@type LuaGuiElement
    if frame.station.header.edit_name_field.visible then
        set_display_name(launcher, frame)
    else
        frame.station.header.edit_name_field.text = launcher.settings.name or ""
        frame.station.header.edit_name_field.visible = true
        frame.station.header.display_name.visible = false
        frame.station.header.edit_name_field.focus()
    end
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_click_ammo_slot(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    inventory_slot.click {
        element = event.element,
        target = launcher:get_ammo_inventory()[1],
        options = ammo_slot_options,
        player = player,
        button = event.button,
    }
end

function launcher_gui.on_toggle_override(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    event.element.parent.input_text.enabled = event.element.state
end

function launcher_gui.on_edit_range_override(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    local frame = player.gui.relative[constants.gui_launcher] ---@type LuaGuiElement
    local range = launcher:get_max_range(true)
    local override = launcher.settings.range_override
    if frame.station.range.override.visible then
        -- Commit and save change
        if frame.station.range.override.checkbox.state then
            local value = tonumber(frame.station.range.override.input_text.text) or range
            launcher.settings.range_override = math.max(1, math.min(range, value))
        else
            launcher.settings.range_override = nil
        end
        -- Hide override panel
        frame.station.range.info.edit_button.style = "lct_configuration_select_button"
        frame.station.range.info.edit_button.tooltip = {
            "logistic-cannon-transportation.launcher-edit-range-override"
        }
        frame.station.range.style = "invisible_frame"
        frame.station.range.override.visible = false
    else
        frame.station.range.override.checkbox.state = override ~= nil
        frame.station.range.override.input_text.enabled = override ~= nil
        frame.station.range.override.input_text.text = tostring(override or range)
        frame.station.range.info.edit_button.style = "lct_configuration_confirm_button"
        frame.station.range.info.edit_button.tooltip = {
            "logistic-cannon-transportation.launcher-confirm-range-override"
        }
        frame.station.range.style = "lct_configuration_deep_frame"
        frame.station.range.override.visible = true
    end
end

function launcher_gui.on_edit_payload_override(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    local frame = player.gui.relative[constants.gui_launcher] ---@type LuaGuiElement
    local payload_size = launcher:get_max_payload_size(true) or 1
    local override = launcher.settings.payload_size_override
    if frame.station.payload_size.override.visible then
        -- Commit and save change
        if frame.station.payload_size.override.checkbox.state then
            local value = tonumber(frame.station.payload_size.override.input_text.text) or payload_size
            launcher.settings.payload_size_override = math.max(1, math.min(payload_size, value))
        else
            launcher.settings.payload_size_override = nil
        end
        -- Hide override panel
        frame.station.payload_size.info.edit_button.style = "lct_configuration_select_button"
        frame.station.payload_size.info.edit_button.tooltip = {
            "logistic-cannon-transportation.launcher-edit-payload-size-override"
        }
        frame.station.payload_size.style = "invisible_frame"
        frame.station.payload_size.override.visible = false
    else
        frame.station.payload_size.override.checkbox.state = override ~= nil
        frame.station.payload_size.override.input_text.enabled = override ~= nil
        frame.station.payload_size.override.input_text.text = tostring(override or payload_size)
        frame.station.payload_size.info.edit_button.style = "lct_configuration_confirm_button"
        frame.station.payload_size.info.edit_button.tooltip = {
            "logistic-cannon-transportation.launcher-confirm-payload-size-override"
        }
        frame.station.payload_size.style = "lct_configuration_deep_frame"
        frame.station.payload_size.override.visible = true
    end
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function launcher_gui.on_set_network(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    local signal = event.element.elem_value --[[@as SignalID?]]
    launcher:set_network_signal(signal)
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function launcher_gui.on_auto_load_ammo_state_changed(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    launcher.settings.load_capsule_from_inventory = event.element.state
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function launcher_gui.on_side_load_ammo_state_changed(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    launcher.settings.enable_ammo_proxy = event.element.state
    launcher:update_ammo_proxy()
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function launcher_gui.on_read_ammo_state_changed(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    launcher:set_read_ammo(event.element.state)
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function launcher_gui.on_read_contents_state_changed(player, event)
    local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
    if not launcher or not launcher:valid() then return end
    local control = launcher.inventory_entity.get_or_create_control_behavior() --[[@as LuaContainerControlBehavior]]
    control.read_contents = event.element.state
end

return launcher_gui
