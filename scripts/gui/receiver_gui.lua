local constants = require("constants")
local util = require("util")
local format = require("scripts.format")
local signal_condition = require("scripts.gui.signal_condition")
local ReceiverStation = require("scripts.receiver_station")


local receiver_gui = {}

local item_bar_base_color = util.color "2e703b"
local item_bar_top_color = util.color "3ccd5a"

---@param player LuaPlayer
---@param entity LuaEntity
function receiver_gui.on_gui_opened(player, entity)
    if player.gui.relative[constants.gui_receiver] then
        player.gui.relative[constants.gui_receiver].destroy()
    end
    if entity.name ~= constants.entity_receiver_gui_proxy then
        return
    end
    --frame
    local frame = player.gui.relative.add {
        type = "frame",
        name = constants.gui_receiver,
        direction = "vertical",
        style = "lct_config_frame",
        -- visible = false,
        caption = "\xE2\x80\x8B", --ZWSP
        anchor = {
            gui = defines.relative_gui_type.proxy_container_gui,
            name = constants.entity_receiver_gui_proxy,
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
                on_gui_confirmed = "receiver_gui.on_confirm_display_name",
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
                on_gui_click = "receiver_gui.on_edit_display_name",
            },
        },
    }
    frame.station.header.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    -- connected receivers
    frame.station.add {
        type = "flow",
        name = "connected_launchers",
        style = "lct_player_input",
        direction = "horizontal",
    }
    frame.station.connected_launchers.add {
        type = "label",
        caption = { "", { "logistic-cannon-transportation.receiver-connected-launchers" }, },
    }
    frame.station.connected_launchers.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    frame.station.connected_launchers.add {
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
                on_gui_elem_changed = "receiver_gui.on_set_network",
            },
        },
    }
    frame.station.add {
        type = "line",
        style = "inside_shallow_frame_with_padding_line",
    }
    --requests
    frame.station.add {
        type = "label",
        caption = { "logistic-cannon-transportation.receiver-requests" },
    }
    frame.station.add {
        type = "scroll-pane",
        name = "requests",
        style = "lct_request_shallow_scroll",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy = "auto",
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
    -- Enable/disable
    signal_condition.create_gui(frame.circuit)
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
        state = false,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_checked_state_changed = "receiver_gui.on_read_contents_state_changed",
            },
        },
    }
    receiver_gui.refresh(player, entity)
end

---@package
---@param parent LuaGuiElement
---@param index integer
---@return LuaGuiElement
function receiver_gui.create_request_list_item(parent, index)
    local element = parent.add {
        type = "frame",
        style = "invisible_frame",
        direction = "vertical",
        tags = {
            request_index = index,
        },
    }
    element.add {
        type = "flow",
        name = "item",
        direction = "horizontal",
        style = "lct_player_input",
    }
    element.item.add {
        type = "choose-elem-button",
        name = "choose_elem",
        elem_type = "item-with-quality",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_elem_changed = "receiver_gui.on_request_elem_changed",
            },
            request_index = index,
        },
    }
    element.item.add {
        type = "flow",
        name = "info",
        direction = "vertical",
    }
    element.item.info.add {
        type = "flow",
        name = "top",
        direction = "horizontal",
    }.style.vertical_align = "center"
    element.item.info.top.add {
        type = "label",
        name = "item_text",
    }
    element.item.info.top.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    element.item.info.top.add {
        type = "sprite-button",
        name = "edit_button",
        sprite = "utility/rename_icon",
        style = "lct_configuration_select_button",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_click = "receiver_gui.on_request_editor_toggled",
            },
            request_index = index,
        },
    }
    element.item.info.add {
        type = "flow",
        name = "progress",
        style = "lct_overlay_progressbar_flow",
        direction = "vertical",
    }
    element.item.info.progress.add {
        type = "progressbar",
        name = "base",
        style = "lct_overlay_progressbar_base",
        value = 0
    }.style.color = item_bar_base_color
    element.item.info.progress.add {
        type = "progressbar",
        name = "top",
        style = "lct_overlay_progressbar_top",
        value = 0
    }.style.color = item_bar_top_color
    -- extra settings
    element.item.info.top.edit_button.tooltip = {
        "logistic-cannon-transportation.receiver-edit-request-amount"
    }
    return element
end

---@package
---@param request_element LuaGuiElement
---@param request { name: string, quality: string, amount: uint }
function receiver_gui.create_request_editor_block(request_element, request)
    local index = tonumber(request_element.tags.request_index) or error()

    request_element.add {
        type = "flow",
        name = "editor",
        direction = "horizontal",
        style = "player_input_horizontal_flow",
    }
    request_element.editor.add {
        type = "slider",
        name = "input_slider",
        style = "notched_slider",
        discrete_values = true,
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_value_changed = "receiver_gui.on_request_editor_value_changed",
            },
            request_index = index,
        },
    }
    request_element.editor.input_slider.style.horizontally_stretchable = true
    request_element.editor.input_slider.style.horizontally_squashable = true
    request_element.editor.add {
        type = "textfield",
        name = "input_text",
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        style = "slider_value_textfield",
        text = "0",
        tags = {
            [constants.gui_tag_event_handlers] = {
                on_gui_text_changed = "receiver_gui.on_request_editor_value_changed",
                on_gui_confirmed = "receiver_gui.on_request_editor_toggled"
            },
            request_index = index,
        },
    }

    receiver_gui.refresh_request_editor_block(request_element, request)

    request_element.editor.input_slider.slider_value = request.amount
    request_element.editor.input_text.text = tostring(request.amount)

    request_element.editor.input_text.focus()
    request_element.editor.input_text.select_all()
    request_element.style = "lct_configuration_deep_frame"
    request_element.style.right_margin = -14
    request_element.style.right_padding = 14
    request_element.item.info.top.edit_button.style = "lct_configuration_confirm_button"
    request_element.item.info.top.edit_button.tooltip = {
        "logistic-cannon-transportation.receiver-confirm-request-amount"
    }
end

---@param request_element LuaGuiElement
---@param request { name: string, quality: string, amount: uint }
function receiver_gui.refresh_request_editor_block(request_element, request)
    if not request_element.editor then return end

    -- Set amount slider max value and step
    local stack_size = prototypes.item[request.name].stack_size
    request_element.editor.input_slider.set_slider_minimum_maximum(stack_size, stack_size * 10)
    request_element.editor.input_slider.set_slider_value_step(stack_size)
end

---@param request_element LuaGuiElement
function receiver_gui.close_request_editor_block(request_element)
    if request_element.editor then
        request_element.style = "invisible_frame"
        request_element.item.info.top.edit_button.style = "lct_configuration_select_button"
        request_element.item.info.top.edit_button.tooltip = {
            "logistic-cannon-transportation.receiver-edit-request-amount"
        }
        request_element.editor.destroy()
    end
end

---@param request_elements LuaGuiElement[]
function receiver_gui.close_all_request_editor_blocks(request_elements)
    for _, element in ipairs(request_elements) do
        receiver_gui.close_request_editor_block(element)
    end
end

---@param player LuaPlayer
---@param entity LuaEntity
function receiver_gui.refresh(player, entity)
    local receiver = ReceiverStation.get(entity)
    if not receiver or not receiver:valid() then return end
    local frame = player.gui.relative[constants.gui_receiver] ---@type LuaGuiElement

    frame.station.header.display_name.caption = receiver.settings.name or
        { "logistic-cannon-transportation.receiver-default-name" }
    frame.station.connected_launchers.value_label.caption = receiver.network:get_connection_count(receiver:id())
    frame.station.network.value_signal.elem_value = receiver.network.signal

    local n_requests = #receiver.settings.delivery_requests
    ---@type table<string, {demand: integer, stored: integer, incoming: integer}>
    local item_counts = {}
    for _, request in ipairs(receiver.settings.delivery_requests) do
        local key = format.encode_item(request.name, request.quality)
        item_counts[key] = { demand = request.amount, stored = 0, incoming = 0 }
    end
    for _, item in ipairs(receiver:get_inventory().get_contents()) do
        local key = format.encode_item(item.name, item.quality)
        if item_counts[key] then
            item_counts[key].stored = item.count
        end
    end
    for _, delivery in pairs(receiver.scheduled_deliveries) do
        if delivery:valid() then
            local key = format.encode_item(delivery.item, delivery.quality)
            local item = item_counts[key]
            if item then
                item.incoming = item.incoming + delivery.amount
            end
        end
    end

    local requests_flow_children = frame.station.requests.children
    for i = 1, math.max(#requests_flow_children, n_requests + 1) do
        local request = receiver.settings.delivery_requests[i]
        local element = requests_flow_children[i]
        if request or i == n_requests + 1 then
            if not element then
                element = receiver_gui.create_request_list_item(frame.station.requests, i)
            end

            if request then
                -- Display info about a request
                local item = item_counts[format.encode_item(request.name, request.quality)]
                local incoming_text = item.incoming > 0 and
                    string.format("[color=gray] (+%s)[/color]", format.number(item.incoming)) or ""
                local item_text = string.format("%s%s / %s", format.number(item.stored), incoming_text,
                    format.number(item.demand))
                local base_value = math.min(1, item.incoming > 0 and
                    (item.stored + item.incoming) / item.demand or 0)
                local top_value = math.min(1, item.stored > 0 and item.stored / item.demand or 0)

                element.item.choose_elem.elem_value = { name = request.name, quality = request.quality }
                element.item.info.top.item_text.caption = item_text
                element.item.info.top.item_text.tooltip = { "",
                    { "logistic-cannon-transportation.receiver-item-tooltip-in-inventory", item.stored }, "\n",
                    { "logistic-cannon-transportation.receiver-item-tooltip-incoming",     item.incoming }, "\n",
                    { "logistic-cannon-transportation.receiver-item-tooltip-requested", item.demand },
                }
                element.item.info.top.edit_button.visible = true
                element.item.info.progress.visible = true
                element.item.info.progress.base.value = base_value
                element.item.info.progress.top.value = top_value
                receiver_gui.refresh_request_editor_block(element, request)
            else
                -- New request button
                element.item.choose_elem.elem_value = nil
                element.item.info.top.item_text.caption = { "logistic-cannon-transportation.receiver-add-request" }
                element.item.info.top.item_text.tooltip = nil
                element.item.info.top.edit_button.visible = false
                element.item.info.progress.visible = false
                element.item.info.progress.base.value = 0
                element.item.info.progress.top.value = 0
                receiver_gui.close_request_editor_block(element)
            end
        else
            if element then
                element.destroy()
            end
        end
    end
    -- circuit refresh
    signal_condition.refresh(receiver, frame.circuit.enable_condition)
    frame.circuit.read_contents.state = receiver.inventory_entity.get_or_create_control_behavior()
        .read_contents --[[@as boolean]]
end

---@param receiver ReceiverStation
---@param frame LuaGuiElement
local function set_display_name(receiver, frame)
    if frame.station.header.edit_name_field.text ~= "" then
        receiver.settings.name = frame.station.header.edit_name_field.text
    else
        receiver.settings.name = nil
    end
    frame.station.header.display_name.caption = receiver.settings.name or
        { "logistic-cannon-transportation.receiver-default-name" }
    frame.station.header.edit_name_field.visible = false
    frame.station.header.display_name.visible = true
end

---@param player LuaPlayer
---@param event EventData.on_gui_confirmed
function receiver_gui.on_confirm_display_name(player, event)
    local receiver = ReceiverStation.get(player.opened --[[@as LuaEntity]])
    if not receiver or not receiver:valid() then return end
    local frame = player.gui.relative[constants.gui_receiver] ---@type LuaGuiElement
    set_display_name(receiver, frame)
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function receiver_gui.on_edit_display_name(player, event)
    local receiver = ReceiverStation.get(player.opened --[[@as LuaEntity]])
    if not receiver or not receiver:valid() then return end
    local frame = player.gui.relative[constants.gui_receiver] ---@type LuaGuiElement
    if frame.station.header.edit_name_field.visible then
        set_display_name(receiver, frame)
    else
        frame.station.header.edit_name_field.text = receiver.settings.name or ""
        frame.station.header.edit_name_field.visible = true
        frame.station.header.display_name.visible = false
        frame.station.header.edit_name_field.focus()
    end
end

---@param player LuaPlayer
---@param event EventData.on_gui_click
function receiver_gui.on_set_network(player, event)
    local receiver = ReceiverStation.get(player.opened --[[@as LuaEntity]])
    if not receiver or not receiver:valid() then return end
    local signal = event.element.elem_value --[[@as SignalID?]]
    receiver:set_network_signal(signal)
end

---@param player LuaPlayer
---@param event EventData.on_gui_elem_changed
function receiver_gui.on_request_elem_changed(player, event)
    local index = tonumber(event.element.tags.request_index) or error()
    local frame = player.gui.relative[constants.gui_receiver] --[[@as LuaGuiElement]]
    local element = frame.station.requests.children[index] or error()
    local entity = player.opened --[[@as LuaEntity]]
    local receiver = ReceiverStation.get(entity) or error()

    receiver_gui.close_all_request_editor_blocks(frame.station.requests.children)

    local elem_value = element.item.choose_elem.elem_value --[[@as PrototypeWithQuality?]]
    if elem_value then
        local is_existing = false
        for existing_index, existing_request in ipairs(receiver.settings.delivery_requests) do
            if existing_request.name == elem_value.name and existing_request.quality == elem_value.quality then
                is_existing = true
                index = existing_index
                break
            end
        end
        receiver.settings.delivery_requests[index] = {
            name = elem_value.name,
            quality = elem_value.quality --[[@as string]],
            amount = 0,
        }

        if not is_existing then
            -- Create editor for newly added requests
            receiver_gui.create_request_editor_block(element, receiver.settings.delivery_requests[index])
        end
    else
        table.remove(receiver.settings.delivery_requests, index)
    end

    receiver_gui.refresh(player, entity)
end

---@param player LuaPlayer
---@param event EventData.on_gui_click | EventData.on_gui_confirmed
function receiver_gui.on_request_editor_toggled(player, event)
    local index = tonumber(event.element.tags.request_index) or error()
    local frame = player.gui.relative[constants.gui_receiver] --[[@as LuaGuiElement]]
    local element = frame.station.requests.children[index] or error()
    local entity = player.opened --[[@as LuaEntity]]
    local receiver = ReceiverStation.get(entity) or error()

    local request = receiver.settings.delivery_requests[index]
    if not request then return end

    if element.editor then
        -- Commit amount change and close editor
        local amount = tonumber(element.editor.input_text.text) or 0
        request.amount = amount
        receiver_gui.close_request_editor_block(element)
    else
        -- Create editor block for this request and close others'
        receiver_gui.close_all_request_editor_blocks(frame.station.requests.children)
        receiver_gui.create_request_editor_block(element, request)
    end

    receiver_gui.refresh(player, entity)
end

---@param player LuaPlayer
---@param event EventData.on_gui_text_changed | EventData.on_gui_value_changed
function receiver_gui.on_request_editor_value_changed(player, event)
    local index = tonumber(event.element.tags.request_index) or error()
    local frame = player.gui.relative[constants.gui_receiver] --[[@as LuaGuiElement]]
    local element = frame.station.requests.children[index] or error()

    local amount_slider = element.editor.input_slider
    local amount_text = element.editor.input_text

    -- Synchronize slider with textfield
    if event.element == amount_slider then
        amount_text.text = tostring(amount_slider.slider_value)
    elseif event.element == amount_text then
        amount_slider.slider_value = tonumber(amount_text.text) or 0
    end

    -- No refresh, values are commited on button click
end

---@param player LuaPlayer
---@param event EventData.on_gui_checked_state_changed
function receiver_gui.on_read_contents_state_changed(player, event)
    local receiver = ReceiverStation.get(player.opened --[[@as LuaEntity]])
    if not receiver or not receiver:valid() then return end
    local control = receiver.inventory_entity.get_or_create_control_behavior() --[[@as LuaContainerControlBehavior]]
    control.read_contents = event.element.state
end

return receiver_gui
