local logistic_control = require("script.logistic_control")

script.on_init(function()
    logistic_control.on_init()
end)

script.on_configuration_changed(function()
    logistic_control.on_init()
end)

-- script.on_event(defines.events.on_player_driving_changed_state, function (event)
--     if event.entity and event.entity.valid and event.entity.name == "logistic-cannon-entity" then
--         local player = game.players[event.player_index]
--         player.set_driving(false, true)
--     end
-- end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "create-logistic-cannon-launcher" then
        local proxy = event.target_entity
        if proxy and proxy.valid and proxy.name == "logistic-cannon-launcher" then
            local launcher = proxy.surface.create_entity { name = "logistic-cannon-launcher-entity", position = proxy.position, force = proxy.force, quality = proxy.quality }
            if launcher then
                logistic_control.on_launcher_station_created(proxy, launcher)
            else
                proxy.die()
            end
        end
    elseif event.effect_id == "create-logistic-cannon-receiver" then
        local proxy = event.target_entity
        if proxy and proxy.valid and proxy.name == "logistic-cannon-receiver" then
            local receiver = proxy.surface.create_entity { name = "logistic-cannon-receiver-entity", position = proxy.position, force = proxy.force, quality = proxy.quality }
            if receiver then
                logistic_control.on_receiver_station_created(proxy, receiver)
            else
                proxy.die()
            end
        end
    elseif event.effect_id == "logistic-cannon-capsule-launched" then
        if event.source_entity and event.source_entity.valid and event.source_entity.name == "logistic-cannon-launcher-entity" then
            local ammo_item = event.source_entity.get_inventory(defines.inventory.car_ammo)[1]
            if ammo_item.count > 0 and event.target_position and event.source_position then
                if ammo_item.count == 1 then
                    ammo_item.clear()
                    -- TODO still auto load ammo from truck
                else
                    ammo_item.drain_ammo(1)
                end
                local projectile = event.source_entity.surface.create_entity {
                    name = "logistic-cannon-capsule-projectile",
                    position = event.source_position,
                    direction = event.source_entity.direction,
                    quality = event.source_entity.quality,
                    force = event.source_entity.force,
                    source = event.source_entity,
                    target = event.target_position,
                    cause = event.source_entity,
                }
                -- local driver = event.source_entity.get_driver()
                -- if driver and driver.name == "character" then
                --     driver.player.set_controller{type = defines.controllers.cutscene, waypoints={
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --         { target=projectile, transition_time=0, time_to_wait=10},
                --     } }
                -- end
            end
        end
    elseif event.effect_id == "logistic-cannon-capsule-landed" then
        game.print("landed")
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
