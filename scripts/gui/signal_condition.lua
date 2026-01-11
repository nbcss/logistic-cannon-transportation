local constants = require("constants")

local signal_condition = {}

---@param parent LuaGuiElement
function signal_condition.create_enable_condition(parent)
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
                on_gui_checked_state_changed = nil,
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
                on_gui_checked_state_changed = nil,
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
                on_gui_checked_state_changed = nil,
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
                on_gui_elem_changed = nil,
            },
        },
    }
    element.condition_values.add {
        type = "drop-down",
        name = "comparator",
        style = "circuit_condition_comparator_dropdown",
        items = { ">", "<", "=", "≥", "≤", "≠" },
        selected_index = 2,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_selection_state_changed = nil,
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
                on_gui_confirmed = nil,
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
                on_gui_elem_changed = nil,
            },
        },
    }
end

function signal_condition.refresh(condition_element)

end

return signal_condition
