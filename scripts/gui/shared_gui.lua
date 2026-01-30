local constants = require("constants")

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
    }
    element.flow.add {
        type = "label",
        name = "green_network",
        visible = false,
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
    element.flow.red_network.visible = red_network ~= nil
    element.flow.red_network.caption = red_network and
        string.format("[color=red]%s[/color] [img=info]", red_network.network_id) or ""
    element.flow.green_network.visible = green_network ~= nil
    element.flow.green_network.caption = green_network and
        string.format("[color=green]%s[/color] [img=info]", green_network.network_id) or ""
end

return {
    circuit_control_header = circuit_control_header,
}