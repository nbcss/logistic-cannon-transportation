local constants = require "constants"
local receiver_gui = {}
local name = "logistic-cannon-receiver-requests"

---@param player LuaPlayer
---@param entity LuaEntity
function receiver_gui.on_gui_opened(player, entity)
    if player.gui.relative[name] then
        player.gui.relative[name].destroy()
    end
    if entity.name ~= "logistic-cannon-receiver-entity" then
        return
    end

    local outer_frame = player.gui.relative.add {
        type = "frame",
        name = name,
        caption = { "logistic-cannon-transportation.cannon-requests" },
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.right,
        },
    }
    local inner_frame = outer_frame.add {
        type = "frame",
        name = "inner_frame",
        style = "inside_shallow_frame_with_padding_and_vertical_spacing",
        direction = "vertical",
    }

    inner_frame.add{
        type = "label",
        caption = {"logistic-cannon-transportation.cannon-requests"},
    }
    inner_frame.add{
        type = "flow",
        name = "requests_flow",
        direction = "vertical",
    }

    receiver_gui.refresh(player, entity)
end

---@param player LuaPlayer
---@param entity LuaEntity
function receiver_gui.refresh(player, entity)
    local data = storage.cannon_receiver_stations[entity.unit_number]
    local gui = player.gui.relative[name] ---@type LuaGuiElement

    local requests_flow_children = gui.inner_frame.requests_flow.children
    for i = 1, math.max(#requests_flow_children, #data.delivery_requests + 1) do
        local request = data.delivery_requests[i]
        local element = requests_flow_children[i]
        if request or i == #data.delivery_requests + 1 then
            if not element then
                element = gui.inner_frame.requests_flow.add{
                    type = "flow",
                    name = tostring(i),
                    direction = "horizontal",
                    style = "player_input_horizontal_flow",
                }
                element.add{
                    type = "choose-elem-button",
                    name = "choose_elem",
                    elem_type = "item-with-quality",
                    tags = {
                        [constants.gui_tag_event_handlers] = {
                            on_gui_elem_changed = "receiver_gui.on_request_modified",
                        },
                    },
                }
                element.add{
                    type = "textfield",
                    name = "request_number",
                    numeric = true,
                    allow_decimal = false,
                    allow_negative = false,
                    style = "short_number_textfield",
                    text = "0",
                    tags = {
                        [constants.gui_tag_event_handlers] = {
                            on_gui_text_changed = "receiver_gui.on_request_modified",
                        },
                    },
                }
            end
            if request then
                element.choose_elem.elem_value = {name = request.name, quality = request.quality}
                element.request_number.visible = true
                element.request_number.text = tostring(request.amount)
            else
                element.choose_elem.elem_value = nil
                element.request_number.visible = false
                element.request_number.text = "0"
            end
        else
            if element then
                element.destroy()
            end
        end
    end
end

---@param player LuaPlayer
---@param event EventData.on_gui_elem_changed | EventData.on_gui_text_changed
function receiver_gui.on_request_modified(player, event)
    local index = tonumber(event.element.parent.name) or error()
    local element = player.gui.relative[name]--[[@as LuaGuiElement]].inner_frame.requests_flow.children[index] or error()
    local entity = player.opened--[[@as LuaEntity]]
    local data = storage.cannon_receiver_stations[entity.unit_number]

    if element.choose_elem.elem_value then
        data.delivery_requests[index] = {
            name = element.choose_elem.elem_value.name,
            quality = element.choose_elem.elem_value.quality,
            amount = tonumber(event.text) or 0, -- reset to 0 when choose_elem changes
        }
    else
        table.remove(data.delivery_requests, index)
    end

    receiver_gui.refresh(player, entity)
end

return receiver_gui
