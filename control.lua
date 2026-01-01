local constants = require("constants")
local BucketSet = require("scripts.bucket_set")
local CannonNetwork = require("scripts.cannon_network")
local LauncherStation = require("scripts.launcher_station")
local ScheduledDelivery = require("scripts.scheduled_delivery")
local ReceiverStation = require("scripts.receiver_station")
local inventory_tool = require("scripts.inventory_tool")
local launcher_gui = require("scripts.gui.launcher_gui")
local receiver_gui = require("scripts.gui.receiver_gui")
local bonus_control = require("scripts.bonus_control")
local visualization_control = require("scripts.visualization_control")

LauncherStation.load_deps()
ReceiverStation.load_deps()
visualization_control.load_deps()

script.register_metatable("BucketSet.prototype", BucketSet.prototype)
script.register_metatable("CannonNetwork.prototype", CannonNetwork.prototype)
script.register_metatable("LauncherStation.prototype", LauncherStation.prototype)
script.register_metatable("ReceiverStation.prototype", ReceiverStation.prototype)
script.register_metatable("ScheduledDelivery.prototype", ScheduledDelivery.prototype)

script.on_init(function()
    CannonNetwork.on_init()
    LauncherStation.on_init()
    ReceiverStation.on_init()
    ScheduledDelivery.on_init()
    visualization_control.on_init()
end)

script.on_configuration_changed(function()
    CannonNetwork.on_init()
    LauncherStation.on_init()
    ReceiverStation.on_init()
    ScheduledDelivery.on_init()
    visualization_control.on_init()
    for _, force in pairs(game.forces) do
        bonus_control.update_bonus(force)
    end
end)

-- script.on_event(defines.events.on_player_driving_changed_state, function (event)
--     if event.entity and event.entity.valid and event.entity.name == "logistic-cannon-launcher-entity" then
--         local player = game.players[event.player_index]
--         event.entity.set_passenger(player)
--     end
-- end)

local function on_cannon_launched(event)
    if event.source_position and event.source_entity and event.source_entity.valid then
        local launcher = LauncherStation.get(event.source_entity)
        if launcher then
            launcher:launch(event.source_position)
        end
    end
end

local function on_capsule_landed(event)
    if event.cause_entity and event.cause_entity.valid and event.cause_entity.name == "cannon-capsule-storage" then
        local delivery = ScheduledDelivery.get(event.cause_entity.unit_number)
        if delivery then
            delivery:deliver()
        end
    end
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "create-logistic-cannon-launcher" then
        -- LauncherStation.create(event.target_entity)
    elseif event.effect_id == "create-logistic-cannon-receiver" then
        ReceiverStation.create(event.target_entity)
    elseif event.effect_id == "logistic-cannon-capsule-launched" then
        on_cannon_launched(event)
    elseif event.effect_id == "logistic-cannon-capsule-landed" then
        on_capsule_landed(event)
    end
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    if event.type == defines.target_type.entity and event.useful_id then
        LauncherStation.on_object_destroyed(event.useful_id)
        ReceiverStation.on_object_destroyed(event.useful_id)
        ScheduledDelivery.on_object_destroyed(event.useful_id)
    end
end)

script.on_event({
        defines.events.on_built_entity,
        defines.events.on_robot_built_entity,
        defines.events.on_space_platform_built_entity,
    },
    ---@param event
    ---| EventData.on_built_entity
    ---| EventData.on_robot_built_entity
    ---| EventData.on_space_platform_built_entity
    function(event)
        if event.entity.name == constants.entity_launcher_inventory then
            LauncherStation.create(event.entity, event.player_index)
        end
    end)

script.on_event(defines.events.on_space_platform_pre_mined, function(event)
    if event.entity.name == constants.entity_receiver_inventory then
        local station = ReceiverStation.get(event.entity)
        if station then
            local target = event.platform.hub.get_inventory(defines.inventory.hub_main) --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
        end
    elseif event.entity.name == constants.entity_launcher_inventory then
        local station = LauncherStation.get(event.entity)
        if station then
            local target = event.platform.hub.get_inventory(defines.inventory.hub_main) --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
            inventory_tool.dump_items(station:get_ammo_inventory(), target)
        end
    end
end)
script.on_event(defines.events.on_pre_player_mined_item, function(event)
    local player = game.players[event.player_index]
    if event.entity.name == constants.entity_receiver_inventory then
        local station = ReceiverStation.get(event.entity)
        if station then
            local target = player.get_main_inventory() --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
        end
    elseif event.entity.name == constants.entity_launcher_inventory then
        local station = LauncherStation.get(event.entity)
        if station then
            local target = player.get_main_inventory() --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
            inventory_tool.dump_items(station:get_ammo_inventory(), target)
        end
    end
end)
script.on_event(defines.events.on_robot_pre_mined, function(event)
    if event.entity.name == constants.entity_receiver_inventory then
        local station = ReceiverStation.get(event.entity)
        if station then
            -- FIXME only able to dispatch single bot at a time
            local target = event.robot.get_inventory(defines.inventory.robot_cargo) --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
        end
    elseif event.entity.name == constants.entity_launcher_inventory then
        local station = LauncherStation.get(event.entity)
        if station then
            local target = event.robot.get_inventory(defines.inventory.robot_cargo) --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
            inventory_tool.dump_items(station:get_ammo_inventory(), target)
        end
    end
end)

script.on_event(defines.events.on_research_finished, function(event) bonus_control.update_bonus(event.research.force) end)
script.on_event(defines.events.on_research_reversed, function(event) bonus_control.update_bonus(event.research.force) end)
script.on_event(defines.events.on_force_reset, function(event) bonus_control.update_bonus(event.force) end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting_type == "runtime-global" and event.setting == constants.update_interval_setting then
        CannonNetwork.resize_buckets()
    end
end)

script.on_event(defines.events.on_tick, function(event)
    -- update network schedules
    for network in CannonNetwork.all() do
        network:update(event.tick)
    end
    -- update station custom states
    for _, player in ipairs(game.connected_players) do
        if player.selected and player.selected.name == constants.entity_launcher_inventory then
            local launcher = LauncherStation.get(player.selected)
            if launcher then launcher:update_diode_status() end
        end
        if player.opened and player.opened.object_name == "LuaEntity" and player.opened.name == constants.entity_launcher_gui_proxy then
            local entity = player.opened --[[@as LuaEntity]]
            local launcher = LauncherStation.get(entity)
            if launcher then
                launcher:update_diode_status()
                launcher_gui.refresh(player, entity)
            end
        end
    end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    visualization_control.on_cursor_stack_changed(event)
end)
script.on_event(defines.events.on_selected_entity_changed, function(event)
    visualization_control.on_selected_entity_changed(event)
    local player = game.players[event.player_index]
    if player.selected and player.selected.name == constants.entity_launcher_inventory then
        local launcher = LauncherStation.get(player.selected)
        if launcher then launcher:update_diode_status() end
    end
end)
script.on_event(defines.events.on_player_left_game, function(event)
    visualization_control.on_player_left_game(event)
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid then
        launcher_gui.on_gui_opened(game.players[event.player_index], event.entity)
        receiver_gui.on_gui_opened(game.players[event.player_index], event.entity)
        if event.entity.name == constants.entity_receiver_inventory then
            local receiver = ReceiverStation.get(event.entity)
            if receiver and receiver:valid() then
                game.players[event.player_index].opened = receiver:get_gui_proxy()
            end
        end
        if event.entity.name == constants.entity_launcher_inventory then
            local launcher = LauncherStation.get(event.entity)
            if launcher and launcher:valid() then
                game.players[event.player_index].opened = launcher:get_gui_proxy()
            end
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
        local handlers = event.element.tags[constants.gui_tag_event_handlers] --[[@as {[string]: string?}]]
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
            local handler_module = string.sub(handler_name, 0, sep - 1)
            local handler_func = string.sub(handler_name, sep + 1)
            if handler_module == "receiver_gui" then
                receiver_gui[handler_func](game.get_player(event.player_index), event)
            elseif handler_module == "launcher_gui" then
                launcher_gui[handler_func](game.get_player(event.player_index), event)
            else
                error("Invalid GUI event handler: " .. handler_name)
            end
        end
    end)

-- script.on_event(defines.events.on_player_setup_blueprint, function(event)
--     local blueprint = event.stack or event.record
--     if not blueprint then return end

--     -- Replace entity_launcher_inventory with placemnent entity
--     local entities = blueprint.get_blueprint_entities()
--     if not entities then return end
--     local relavant = false
--     for index, entity in ipairs(entities) do
--         if entity.name == constants.entity_launcher_inventory then
--             relavant = true
--             entity.name = constants.entity_launcher_placement
--             local source = event.mapping.get()[index] --[[@as LuaEntity?]]
--         end
--     end
--     if not relavant then return end
--     blueprint.set_blueprint_entities(entities)
-- end)

-- script.on_event(defines.events.on_marked_for_deconstruction, function(event)
--     if event.entity.name == constants.entity_launcher_placement then
--         local player = event.player_index and game.get_player(event.player_index)
--         local force = player and player.force_index or "neutral"
--         event.entity.cancel_deconstruction(force, player)
--         local station = LauncherStation.get(event.entity)
--         if station then
--             station.inventory_entity.order_deconstruction(force, player)
--         end
--     end
-- end)

-- script.on_event({
--     defines.events.on_undo_applied,
--     defines.events.on_redo_applied,
-- },
-- ---@param event
-- ---| EventData.on_undo_applied
-- ---| EventData.on_redo_applied
-- function(event)
--     local player = game.get_player(event.player_index)
--     if not player then return end

--     for _, action in ipairs(event.actions) do
--         if action.type == "built-entity" then
--             if action.target.name == constants.entity_launcher_inventory then
--                 local surface = game.get_surface(action.surface_index)
--                 if not surface then goto continue end
--                 local entity = surface.find_entities_filtered{
--                     ghost_name = constants.entity_launcher_placement,
--                     quality = action.target.quality,
--                     limit = 1,
--                 }[1]
--                 if not entity then goto continue end
--                 entity.destroy()
--             elseif action.target.name == constants.entity_launcher_placement then
--                 local surface = game.get_surface(action.surface_index)
--                 if not surface then goto continue end
--                 local entity = surface.find_entities_filtered{
--                     name = constants.entity_launcher_inventory,
--                     quality = action.target.quality,
--                     limit = 1,
--                 }[1]
--                 if not entity then goto continue end
--                 entity.order_deconstruction(player.force)
--             end
--         elseif action.type == "removed-entity" then
--             if action.target.name == constants.entity_launcher_inventory then
--                 local surface = game.get_surface(action.surface_index)
--                 if not surface then goto continue end
--                 local entity = surface.find_entities_filtered{
--                     ghost_name = constants.entity_launcher_inventory,
--                     quality = action.target.quality,
--                     limit = 1,
--                 }[1]
--                 if not entity then goto continue end
--                 local ret = surface.create_entity{
--                     name = "entity-ghost",
--                     inner_name = constants.entity_launcher_placement,
--                     quality = action.target.quality,
--                     force = player.force,
--                     tags = action.target.tags,
--                     position = action.target.position,
--                     direction = action.target.direction,
--                     fast_replace = true,
--                 }
--             elseif action.target.name == constants.entity_launcher_placement then
--                 local surface = game.get_surface(action.surface_index)
--                 if not surface then goto continue end
--                 local entity = surface.find_entities_filtered{
--                     name = constants.entity_launcher_inventory,
--                     quality = action.target.quality,
--                     limit = 1,
--                 }[1]
--                 if not entity then goto continue end
--                 entity.cancel_deconstruction(player.force)
--             end
--         end
--         ::continue::
--     end
-- end)
