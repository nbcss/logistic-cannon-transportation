local constants = require("constants")
local LauncherStation ---@module "scripts.launcher_station"
local ReceiverStation ---@module "scripts.receiver_station"

local signal_condition = {}
function signal_condition.load_deps()
    LauncherStation = require("scripts.launcher_station")
    ReceiverStation = require("scripts.receiver_station")
end

-- Definition of a enable/disable circuit condition.
-- Can represent all states required by GUI.
-- Can be converted to the built-in CircuitCondition.
---@class (exact) ModCircuitCondition
---@field comparator ModCircuitCondition.comparator
---@field first_signal SignalID?
---@field second_signal SignalID? Must not coexist with `constant`.
---@field constant int? If exists, means user has selected "constant" for RHS, if not, means user has selected "signal" even when `second_signal` is nil.

---@enum ModCircuitCondition.comparator
signal_condition.comparators = {
    [1] = ">",
    [2] = "<",
    [3] = "=",
    [4] = "≥",
    [5] = "≤",
    [6] = "≠",
}
signal_condition.default_comparator_index = 2

signal_condition.default_value = {
    comparator = signal_condition.comparators[signal_condition.default_comparator_index],
    constant = 0,
} --[[@as ModCircuitCondition]]

local compare_functions = {
    [">"] = function (first_value, second_value) return first_value > second_value end,
    ["<"] = function (first_value, second_value) return first_value < second_value end,
    ["="] = function (first_value, second_value) return first_value == second_value end,
    ["≥"] = function (first_value, second_value) return first_value >= second_value end,
    ["≤"] = function (first_value, second_value) return first_value <= second_value end,
    ["≠"] = function (first_value, second_value) return first_value ~= second_value end,
}

---@param condition ModCircuitCondition
---@param entity LuaEntity
---@param red_connected boolean
---@param green_connected boolean
---@return boolean
function signal_condition.evaluate(condition, entity, red_connected, green_connected)
    if not condition.first_signal or (not condition.constant and not condition.second_signal) then return false end

    ---@param signal SignalID
    local function get_signal(signal)
        if red_connected then
            if green_connected then
                return entity.get_signal(signal, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            else
                return entity.get_signal(signal, defines.wire_connector_id.circuit_red)
            end
        else
            if green_connected then
                return entity.get_signal(signal, defines.wire_connector_id.circuit_green)
            else
                return 0
            end
        end
    end

    local first_value = get_signal(condition.first_signal)
    local second_value = condition.second_signal and get_signal(condition.second_signal) or condition.constant
    -- game.print(string.format("%s:%s", first_value, second_value))
    -- FIXME signal will double count between wires
    return compare_functions[condition.comparator](first_value, second_value)
end

---@param parent LuaGuiElement
function signal_condition.create_gui(parent)
    local element = parent.add {
        type = "flow",
        name = "enable_condition",
        direction = "vertical",
    }
    element.style.vertical_spacing = 0
    element.add {
        type = "checkbox",
        name = "checkbox",
        style = "caption_checkbox",
        caption = { "gui-control-behavior-modes.enable-disable" },
        tooltip = { "gui-control-behavior-modes.enable-disable-description" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "signal_condition.on_changed",
            },
        },
    }
    element.add {
        type = "flow",
        name = "condition_type",
        style = "player_input_horizontal_flow",
    }
    element.condition_type.add {
        type = "radiobutton",
        name = "constant",
        caption = { "logistic-cannon-transportation.circuit_constant" },
        tooltip = { "logistic-cannon-transportation.circuit_constant_description" },
        state = true,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "signal_condition.on_changed",
            },
        },
    }
    element.condition_type.add {
        type = "radiobutton",
        name = "signal",
        caption = { "logistic-cannon-transportation.circuit_signal" },
        tooltip = { "logistic-cannon-transportation.circuit_signal_description" },
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "signal_condition.on_changed",
            },
        },
    }
    element.add {
        type = "flow",
        name = "condition_values",
        style = "player_input_horizontal_flow",
    }
    element.condition_values.add {
        type = "choose-elem-button",
        name = "left_signal",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_elem_changed = "signal_condition.on_changed",
            },
        },
    }
    element.condition_values.add {
        type = "drop-down",
        name = "comparator",
        style = "circuit_condition_comparator_dropdown",
        items = signal_condition.comparators,
        selected_index = 2,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_selection_state_changed = "signal_condition.on_changed",
            },
        },
    }
    element.condition_values.add {
        type = "textfield",
        name = "right_constant",
        style = "lct_constant_condition_textbox",
        text = "0",
        numeric = true,
        allow_decimal = false,
        allow_negative = true,
        lose_focus_on_confirm = true,
        visible = true,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_text_changed = "signal_condition.on_changed",
            },
        },
    }
    element.condition_values.add {
        type = "choose-elem-button",
        name = "right_signal",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        visible = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_elem_changed = "signal_condition.on_changed",
            },
        },
    }
end

---@param circuit_enabled boolean
---@param station LauncherStation | ReceiverStation
---@param element LuaGuiElement
function signal_condition.refresh(circuit_enabled, station, element)
    local settings_enabled = station.settings.circuit_enable_enabled
    local settings_condition = station.settings.circuit_enable_condition

    element.checkbox.enabled = circuit_enabled
    element.checkbox.state = settings_enabled

    -- Enable/disable input elements
    element.condition_type.constant.enabled = circuit_enabled and settings_enabled
    element.condition_type.signal.enabled = circuit_enabled and settings_enabled
    element.condition_values.left_signal.enabled = circuit_enabled and settings_enabled
    element.condition_values.comparator.enabled = circuit_enabled and settings_enabled
    element.condition_values.right_constant.enabled = circuit_enabled and settings_enabled
    element.condition_values.right_signal.enabled = circuit_enabled and settings_enabled

    -- Condition type
    if settings_condition.constant then
        element.condition_type.constant.state = true
        element.condition_type.signal.state = false
        element.condition_values.right_constant.visible = true
        element.condition_values.right_signal.visible = false
    else
        element.condition_type.constant.state = false
        element.condition_type.signal.state = true
        element.condition_values.right_constant.visible = false
        element.condition_values.right_signal.visible = true
    end

    -- Signals
    element.condition_values.left_signal.elem_value = settings_condition.first_signal
    element.condition_values.right_signal.elem_value = settings_condition.second_signal

    -- Comparator
    for i, s in ipairs(signal_condition.comparators) do
        if s == settings_condition.comparator then
            element.condition_values.comparator.selected_index = i
            break
        end
    end

    -- Constant: set textbox content only when the numeric value differs,
    -- to preserve intermeiary input like "-" and ""
    if
        settings_condition.constant ~=
        (tonumber(element.condition_values.right_constant.text) or 0)
    then
        element.condition_values.right_constant.text = tostring(settings_condition.constant or 0)
    end
end

---@param player LuaPlayer
---@param event
---| EventData.on_gui_checked_state_changed
---| EventData.on_gui_elem_changed
---| EventData.on_gui_text_changed
---| EventData.on_gui_selection_state_changed
function signal_condition.on_changed(player, event)
    if not player.opened or player.opened.object_name ~= "LuaEntity" then return end
    local entity = player.opened--[[@as LuaEntity]]
    local station, frame = nil, nil
    if entity.name == constants.entity_launcher_gui_proxy then
        station = LauncherStation.get(entity)
        frame = player.gui.relative[constants.gui_launcher] --[[@as LuaGuiElement?]]
    elseif entity.name == constants.entity_receiver_gui_proxy then
        station = ReceiverStation.get(entity)
        frame = player.gui.relative[constants.gui_receiver] --[[@as LuaGuiElement?]]
    end
    if not station or not frame then return end
    local element = frame.circuit.enable_condition

    -- Read settings from GUI input
    local settings_enabled = element.checkbox.state
    local settings_condition = {
        comparator = signal_condition.comparators[element.condition_values.comparator.selected_index] or signal_condition.default_comparator,
        first_signal = element.condition_values.left_signal.elem_value--[[@as SignalID?]],
    }

    -- Read signal condition depending on type
    -- Type is selected by radio buttons
    if
        element.condition_type.constant.state and
        not (
            element.condition_type.signal.state and -- if both are true
            event.element == element.condition_type.signal -- see which's just been clicked
        )
    then
        settings_condition.constant = tonumber(element.condition_values.right_constant.text) or 0
    else
        settings_condition.second_signal = element.condition_values.right_signal.elem_value--[[@as SignalID?]]
    end

    -- Reject meta signals
    signal_condition.reject_meta_signals(settings_condition)

    -- Save to entity
    station.settings.circuit_enable_enabled = settings_enabled
    station.settings.circuit_enable_condition = settings_condition

    signal_condition.refresh(true, station, element)
end

---Remove meta signals that may not exist in a circuit condition.
---@param condition ModCircuitCondition
function signal_condition.reject_meta_signals(condition)
    -- First signal: allow "every" and "any"
    if
        condition.first_signal and
        condition.first_signal.type == "virtual" and
        condition.first_signal.name == "signal-each"
    then
        condition.first_signal = nil
    end
    -- Second signal: allow none
    if
        condition.second_signal and
        condition.second_signal.type == "virtual" and
        (
            condition.second_signal.name == "signal-each" or
            condition.second_signal.name == "signal-everything" or
            condition.second_signal.name == "signal-anything"
        )
    then
        condition.second_signal = nil
    end
end

return signal_condition
