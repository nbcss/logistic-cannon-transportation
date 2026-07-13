local constants = require("constants")
local format = require("scripts.format")
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
---@field enabled boolean
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
    enabled = false,
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
---@param get_signal fun(signal: SignalID):uint32
---@return boolean
function signal_condition.evaluate(condition, get_signal)
    if not condition.first_signal or (not condition.constant and not condition.second_signal) then return false end

    local first_value = get_signal(condition.first_signal)
    local second_value = condition.second_signal and get_signal(condition.second_signal) or condition.constant

    return compare_functions[condition.comparator](first_value, second_value)
end

---@param parent LuaGuiElement
function signal_condition.create_gui(parent)
    local element = parent.add {
        type = "flow",
        name = "enable_condition",
        direction = "vertical",
    }
    element.style.vertical_spacing = 2
    element.add {
        type = "checkbox",
        name = "checkbox",
        style = "caption_checkbox",
        caption = { "gui-control-behavior-modes.enable-if" },
        tooltip = { "gui-control-behavior-modes.enable-if-description" },
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
        caption = { "logistic-cannon-transportation.circuit-constant" },
        tooltip = { "logistic-cannon-transportation.circuit-constant-description" },
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
        caption = { "logistic-cannon-transportation.circuit-signal" },
        tooltip = { "logistic-cannon-transportation.circuit-signal-description" },
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
        name = "left",
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
        selected_index = signal_condition.default_comparator_index,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_selection_state_changed = "signal_condition.on_changed",
            },
        },
    }
    element.condition_values.add {
        type = "choose-elem-button",
        name = "right",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_elem_changed = "signal_condition.on_changed",
                on_gui_click = "signal_condition.on_right_button_clicked",
            },
        },
    }
    element.condition_values.right.add{
        type = "label",
        name = "constant_display",
        style = "lct_constant_condition_label",
    }
    element.condition_values.add {
        type = "textfield",
        name = "right_constant_text",
        style = "slider_value_textfield",
        numeric = true,
        allow_decimal = false,
        allow_negative = true,
        lose_focus_on_confirm = true,
        visible = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_confirmed = "signal_condition.on_constant_confirmed",
            },
        },
    }
    element.condition_values.add {
        type = "sprite-button",
        name = "right_constant_confirm",
        style = "item_and_count_select_confirm",
        visible = false,
        sprite = "utility/confirm_slot",
        tooltip = { "logistic-cannon-transportation.circuit-condition-confirm-constant" },
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_click = "signal_condition.on_constant_confirmed",
            },
        },
    }
end

---@param element LuaGuiElement
---@return LuaGuiElement?
function signal_condition.find_root_element(element)
    while element and element.name ~= "enable_condition" do
        element = element.parent
    end
    return element
end

---@param circuit_connected boolean
---@param circuit_condition ModCircuitCondition
---@param element LuaGuiElement
function signal_condition.refresh(circuit_connected, circuit_condition, element)

    local checkbox = element.checkbox
    local radio_constant = element.condition_type.constant
    local radio_signal = element.condition_type.signal
    local comparator_menu = element.condition_values.comparator
    local left_value_button = element.condition_values.left
    local right_value_button = element.condition_values.right
    local right_constant_text = element.condition_values.right_constant_text
    local right_constant_confirm = element.condition_values.right_constant_confirm
    local right_constant_display = right_value_button.constant_display

    checkbox.enabled = circuit_connected
    checkbox.state = circuit_condition.enabled

    -- Enable/disable input elements
    radio_constant.enabled = circuit_connected and circuit_condition.enabled
    radio_signal.enabled = circuit_connected and circuit_condition.enabled
    left_value_button.enabled = circuit_connected and circuit_condition.enabled
    comparator_menu.enabled = circuit_connected and circuit_condition.enabled
    right_value_button.enabled = circuit_connected and circuit_condition.enabled

    -- Close editor of constant when irrelavant
    if not (circuit_connected and circuit_condition.enabled and circuit_condition.constant) then
        right_value_button.visible = true
        right_constant_text.visible = false
        right_constant_confirm.visible = false
    end

    -- Condition type
    radio_constant.state = circuit_condition.constant ~= nil
    radio_signal.state = circuit_condition.constant == nil

    -- Left side
    left_value_button.elem_value = circuit_condition.first_signal

    -- Right-side
    right_value_button.elem_value = circuit_condition.second_signal
    local right_value_tags = right_value_button.tags
    right_value_tags.constant_value = circuit_condition.constant or 0
    right_value_button.tags = right_value_tags
    if circuit_condition.constant then
        right_value_button.locked = true
        right_constant_display.caption = format.number(circuit_condition.constant or 0)
    else
        right_value_button.locked = false
        right_constant_display.caption = ""
    end

    -- Comparator
    for i, s in ipairs(signal_condition.comparators) do
        if s == circuit_condition.comparator then
            comparator_menu.selected_index = i
            break
        end
    end
end

---@param player LuaPlayer
---@param event
---| EventData.on_gui_checked_state_changed
---| EventData.on_gui_elem_changed
---| EventData.on_gui_confirmed
---| EventData.on_gui_selection_state_changed
---| EventData.on_gui_click
function signal_condition.on_changed(player, event)
    if not player.opened or player.opened.object_name ~= "LuaEntity" then return end
    local entity = player.opened--[[@as LuaEntity]]
    local station = nil
    if LauncherStation.is_gui_entity(entity.name) then
        station = LauncherStation.get(entity)
    elseif ReceiverStation.is_gui_entity(entity.name) then
        station = ReceiverStation.get(entity)
    end
    local element = signal_condition.find_root_element(event.element)
    if not station or not element then return end

    -- Read settings from GUI input
    local settings_condition = {
        enabled = element.checkbox.state,
        comparator = signal_condition.comparators[element.condition_values.comparator.selected_index] or signal_condition.default_comparator,
        first_signal = element.condition_values.left.elem_value--[[@as SignalID?]],
    }

    -- Read signal condition depending on type
    -- Type is selected by radio buttons
    if
        event.element == element.condition_type.constant or
        event.element ~= element.condition_type.signal and
        element.condition_type.constant.state
    then
        settings_condition.constant = element.condition_values.right.tags.constant_value or 0
    else
        settings_condition.second_signal = element.condition_values.right.elem_value--[[@as SignalID?]]
    end

    -- Reject meta signals
    signal_condition.reject_meta_signals(settings_condition)

    -- Save to entity
    station.settings.circuit_enable_condition = settings_condition

    signal_condition.refresh(true, settings_condition, element)
    
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function signal_condition.on_right_button_clicked(player, event)
    local element = signal_condition.find_root_element(event.element)
    if not element then return end

    if element.condition_type.constant.state then
        if event.button == defines.mouse_button_type.left then
            -- Show constant editor and initialize textfield
            element.condition_values.right.visible = false
            element.condition_values.right_constant_text.visible = true
            element.condition_values.right_constant_confirm.visible = true
            element.condition_values.right_constant_text.text = tostring(element.condition_values.right.tags.constant_value or 0)
            element.condition_values.right_constant_text.focus()
            element.condition_values.right_constant_text.select_all()
        elseif event.button == defines.mouse_button_type.right then
            -- Clear constant
            element.condition_values.right.tags = util.merge{element.condition_values.right.tags, {
                constant_value = 0,
            }}
            signal_condition.on_changed(player, event)
        end
    end
end

---@param player LuaPlayer
---@param event EventData.on_gui_confirmed | EventData.on_gui_click
function signal_condition.on_constant_confirmed(player, event)
    local element = signal_condition.find_root_element(event.element)
    if not element then return end

    -- Copy constant value to tag and close constant editor
    element.condition_values.right.tags = util.merge{element.condition_values.right.tags, {
        constant_value = tonumber(element.condition_values.right_constant_text.text) or 0,
    }}
    element.condition_values.right.visible = true
    element.condition_values.right_constant_text.visible = false
    element.condition_values.right_constant_confirm.visible = false

    signal_condition.on_changed(player, event)
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
