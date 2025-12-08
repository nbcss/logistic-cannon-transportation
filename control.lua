local logistic_control = require("scripts.logistic_control")

script.on_init(function()
    logistic_control.on_init()
end)

script.on_configuration_changed(function()
    logistic_control.on_init()
end)

-- script.on_event(defines.events.on_player_driving_changed_state, function (event)
--     if event.entity and event.entity.valid and event.entity.name == "logistic-cannon-launcher-entity" then
--         local player = game.players[event.player_index]
--         player.set_driving(false, true)
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
        logistic_control.on_cannon_landed(event)
    end
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    if event.type == defines.target_type.entity and event.useful_id then
        logistic_control.on_station_destroyed(event.useful_id)
    end
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid then
        if event.entity.name == "logistic-cannon-launcher" or event.entity.name == "logistic-cannon-receiver" then
            game.players[event.player_index].opened = event.entity.proxy_target_entity
        end
    end
end)
