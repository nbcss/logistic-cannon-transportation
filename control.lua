-- script.on_event(defines.events.on_player_driving_changed_state, function (event)
--     if event.entity and event.entity.valid and event.entity.name == "logistic-cannon-entity" then
--         local player = game.players[event.player_index]
--         player.set_driving(false, true)
--     end
-- end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "create-logistic-cannon" then
        local container = event.target_entity
        if container and container.valid and container.name == "logistic-cannon-container" then
            local cannon = container.surface.create_entity { name = "logistic-cannon-entity", position = container.position, force = container.force }
            if cannon then
                script.register_on_object_destroyed(container)
                container.proxy_target_entity = cannon
                container.proxy_target_inventory = defines.inventory.car_trunk
                local driver = container.surface.create_entity { name = "character", position = cannon.position, force = cannon.force }
                cannon.set_driver(driver)
                cannon.driver_is_gunner = true
                -- local passenger = container.surface.create_entity { name = "character", position = cannon.position, force = cannon.force }
                -- cannon.set_passenger(passenger)
            else
                container.die()
            end
        end
    end
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    --todo
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid and event.entity.name == "logistic-cannon-container" then
        game.players[event.player_index].opened = event.entity.proxy_target_entity
    end
end)
