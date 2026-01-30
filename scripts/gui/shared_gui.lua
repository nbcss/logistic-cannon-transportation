local constants = require("constants")
local format = require("scripts.format")

local circuit_control_header = {}

---@param parent LuaGuiElement
---@param name string
---@return LuaGuiElement
function circuit_control_header.create(parent, name)
    local element = parent.add {
        type = "frame",
        name = name,
        style = "lct_subheader_frame",
        direction = "horizontal",
    }
    element.add {
        type = "flow",
        name = "flow",
        style = "player_input_horizontal_flow",
        direction = "horizontal",
    }
    element.flow.add {
        type = "label",
        name = "title",
        style = "subheader_label",
        caption = { "logistic-cannon-transportation.circuit-control" },
    }
    element.flow.add {
        type = "label",
        name = "red_network",
        visible = false,
        raise_hover_events = true,
        tags = {
            [constants.gui_tag_tracked_hover_state] = false,
        },
    }
    element.flow.add {
        type = "label",
        name = "green_network",
        visible = false,
        raise_hover_events = true,
        tags = {
            [constants.gui_tag_tracked_hover_state] = false,
        },
    }
    element.flow.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = true
    return element
end

---@param element LuaGuiElement
---@param station LauncherStation | ReceiverStation
function circuit_control_header.refresh(element, station)
    local red_network = station:is_circuit_connected(false, defines.wire_connector_id.circuit_red)
        and station.inventory_entity.get_circuit_network(defines.wire_connector_id.circuit_red) or nil
    local green_network = station:is_circuit_connected(false, defines.wire_connector_id.circuit_green)
        and station.inventory_entity.get_circuit_network(defines.wire_connector_id.circuit_green) or nil
    element.flow.title.caption = { "",
        (red_network or green_network)
        and { "logistic-cannon-transportation.circuit-control-connected" }
        or { "logistic-cannon-transportation.circuit-control-unconnected" },
    }
    ---@param color string
    ---@param network LuaCircuitNetwork?
    ---@param label LuaGuiElement
    function network_label(color, network, label)
        if network then
            label.visible = true
            label.caption = string.format("[color=%s]%s[/color] [img=info]", color, network.network_id)
            if label.tags[constants.gui_tag_tracked_hover_state] then
                local tooltip = {}
                local signals = network.signals
                for i, signal in ipairs(signals or {}) do
                    local sprite_type
                    if signal.signal.type == nil then
                        sprite_type = "item"
                    elseif signal.signal.type == "virtual" then
                        sprite_type = "virtual-signal"
                    else
                        sprite_type = signal.signal.type
                    end
                    local quality = signal.signal.quality
                    local sep = i == #signals and "" or (i % 4 == 0 and "\n" or "\xe2\x80\x83"--[[em space]])
                    if quality == nil then
                        table.insert(tooltip, string.format("[img=%s/%s]%s%s",
                            sprite_type, signal.signal.name, format.number(signal.count), sep))
                    else
                        table.insert(tooltip, string.format("[img=%s/%s][img=quality/%s]%s%s",
                            sprite_type, signal.signal.name, quality, format.number(signal.count), sep))
                    end
                end
                label.tooltip = { "",
                    "[color=#fae8be][font=default-semibold]", { "description.signals" }, "[/font][/color]\n",
                    table.concat(tooltip) }
            else
                label.tooltip = nil
            end
        else
            label.visible = false
            label.caption = nil
            label.tooltip = nil
        end
    end
    network_label("red", red_network, element.flow.red_network)
    network_label("green", green_network, element.flow.green_network)
end

return {
    circuit_control_header = circuit_control_header,
}