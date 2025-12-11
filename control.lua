local constants = require("constants")
local logistic_control = require("scripts.logistic_control")
local receiver_gui = require("scripts.receiver_gui")

script.on_init(function()
    logistic_control.on_init()
end)

script.on_configuration_changed(function()
    logistic_control.on_init()
end)

-- script.on_event(defines.events.on_player_driving_changed_state, function (event)
--     if event.entity and event.entity.valid and event.entity.name == "logistic-cannon-launcher-entity" then
--         local player = game.players[event.player_index]
--         event.entity.set_passenger(player)
--     end
-- end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "create-logistic-cannon-launcher" then
        logistic_control.on_launcher_station_created(event)
    elseif event.effect_id == "create-logistic-cannon-receiver" then
        logistic_control.on_receiver_station_created(event)
    elseif event.effect_id == "logistic-cannon-capsule-launched" then
        logistic_control.on_cannon_launched(event)
    elseif event.effect_id == "logistic-cannon-capsule-landed" then
        game.print("land")
        logistic_control.on_capsule_landed(event)
    end
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    if event.type == defines.target_type.entity and event.useful_id then
        logistic_control.on_entity_destroyed(event.useful_id)
    end
end)

script.on_nth_tick(5, function (t)
    logistic_control.update_delivery()
end)

-- script.on_event(defines.events.on_tick, function (event)
--     logistic_control.on_tick(event.tick)
-- end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid then
        receiver_gui.on_gui_opened(game.players[event.player_index], event.entity)
        if event.entity.name == "logistic-cannon-launcher" or event.entity.name == "logistic-cannon-receiver" then
            game.players[event.player_index].opened = event.entity.proxy_target_entity
        end
    end
end)

script.on_event({
    defines.events.on_gui_click,
    defines.events.on_gui_elem_changed,
    defines.events.on_gui_text_changed,
},
---@param event
---| EventData.on_gui_click
---| EventData.on_gui_elem_changed
---| EventData.on_gui_text_changed
function(event)
    local handlers = event.element.tags[constants.gui_tag_event_handlers]--[[@as {[string]: string?}]]
    if not handlers then return end
    local handler_name
    for k, v in pairs(handlers) do
        if defines.events[k] == event.name then
            handler_name = v
            break
        end
    end
    if handler_name then
        local sep = string.find(handler_name, ".", 0, true)
        local handler_module = string.sub(handler_name, 0, sep-1)
        local handler_func = string.sub(handler_name, sep+1)
        if handler_module == "receiver_gui" then
            receiver_gui[handler_func](game.get_player(event.player_index), event)
        else
            error("Invalid GUI event handler: "..handler_name)
        end
    end
end)