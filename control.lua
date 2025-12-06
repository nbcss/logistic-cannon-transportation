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
            local cannon = proxy.surface.create_entity { name = "logistic-cannon-launcher-entity", position = proxy.position, force = proxy.force, quality = proxy.quality }
            if cannon then
                script.register_on_object_destroyed(proxy)
                proxy.proxy_target_entity = cannon
                proxy.proxy_target_inventory = defines.inventory.car_trunk
                local driver = proxy.surface.create_entity { name = "character", position = cannon.position, force = cannon.force }
                cannon.set_driver(driver)
                cannon.driver_is_gunner = true
                cannon.destructible = false
            else
                proxy.die()
            end
        end
    elseif event.effect_id == "create-logistic-cannon-receiver" then
        local proxy = event.target_entity
        if proxy and proxy.valid and proxy.name == "logistic-cannon-receiver" then
            local storage = proxy.surface.create_entity { name = "logistic-cannon-receiver-entity", position = proxy.position, force = proxy.force, quality = proxy.quality }
            if storage then
                script.register_on_object_destroyed(proxy)
                storage.destructible = false
                proxy.proxy_target_entity = storage
                proxy.proxy_target_inventory = defines.inventory.chest
            else
                proxy.die()
            end
        end
    elseif event.effect_id == "logistic-cannon-launch" then
        game.print("TODO")
    end
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    --todo
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid then
        if event.entity.name == "logistic-cannon-launcher" or event.entity.name == "logistic-cannon-receiver" then
            game.players[event.player_index].opened = event.entity.proxy_target_entity
        end
    end
end)
