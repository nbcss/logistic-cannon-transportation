local constants = require("constants")
local CannonNetwork = require("scripts.cannon_network")
local LauncherStation = require("scripts.launcher_station")
local ScheduledDelivery = require("scripts.scheduled_delivery")
local ReceiverStation = require("scripts.receiver_station")
local inventory_tool = require("scripts.inventory_tool")
local launcher_gui = require("scripts.gui.launcher_gui")
local receiver_gui = require("scripts.gui.receiver_gui")
local bonus_control = require("scripts.bonus_control")

LauncherStation.load_deps()
ReceiverStation.load_deps()

script.register_metatable("CannonNetwork.prototype", CannonNetwork.prototype)
script.register_metatable("LauncherStation.prototype", LauncherStation.prototype)
script.register_metatable("ReceiverStation.prototype", ReceiverStation.prototype)
script.register_metatable("ScheduledDelivery.prototype", ScheduledDelivery.prototype)

script.on_init(function()
    CannonNetwork.on_init()
    LauncherStation.on_init()
    ReceiverStation.on_init()
    ScheduledDelivery.on_init()
end)

script.on_configuration_changed(function()
    CannonNetwork.on_init()
    LauncherStation.on_init()
    ReceiverStation.on_init()
    ScheduledDelivery.on_init()
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
    if event.source_position and event.source_entity and event.source_entity.valid
        and event.source_entity.name == "logistic-cannon-launcher-entity" then
        local launcher = LauncherStation.get(event.source_entity)
        if launcher then
            launcher:launch(event.source_position)
        end
    end
end

local function on_capsule_landed(event)
    if event.target_entity and event.target_entity.valid and event.target_entity.name == "cannon-capsule-storage" then
        local delivery = ScheduledDelivery.get(event.target_entity.unit_number)
        if delivery then
            delivery:deliver()
        end
    end
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "create-logistic-cannon-launcher" then
        LauncherStation.create(event.target_entity)
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

script.on_event(defines.events.on_space_platform_pre_mined, function(event)
    if event.entity.name == constants.entity_receiver then
        local station = ReceiverStation.get(event.entity)
        if station then
            local target = event.platform.hub.get_inventory(defines.inventory.hub_main) --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
        end
    elseif event.entity.name == constants.entity_launcher then
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
    if event.entity.name == constants.entity_receiver then
        local station = ReceiverStation.get(event.entity)
        if station then
            local target = player.get_main_inventory() --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
        end
    elseif event.entity.name == constants.entity_launcher then
        local station = LauncherStation.get(event.entity)
        if station then
            local target = player.get_main_inventory() --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
            inventory_tool.dump_items(station:get_ammo_inventory(), target)
        end
    end
end)
script.on_event(defines.events.on_robot_pre_mined, function(event)
    if event.entity.name == constants.entity_receiver then
        local station = ReceiverStation.get(event.entity)
        if station then
            -- FIXME only able to dispatch single bot at a time
            local target = event.robot.get_inventory(defines.inventory.robot_cargo) --[[@as LuaInventory]]
            inventory_tool.dump_items(station:get_inventory(), target)
        end
    elseif event.entity.name == constants.entity_launcher then
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

script.on_event(defines.events.on_tick, function(event)
    -- update station custom states
    for _, player in ipairs(game.connected_players) do
        if player.selected and player.selected.name == constants.entity_launcher then
            local launcher = LauncherStation.get(player.selected)
            if launcher and launcher:valid() then
                launcher:update_diode_status()
            end
        end
        if player.opened and player.opened.type == "car" and player.opened.name == constants.entity_launcher_entity then
            local launcher = LauncherStation.get(player.opened --[[@as LuaEntity]])
            if launcher then
                launcher:update_diode_status()
            end
        end
    end
    -- update network schedules
    for network in CannonNetwork.all() do
        network:update_deliveries(event.tick)
    end
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid then
        launcher_gui.on_gui_opened(game.players[event.player_index], event.entity)
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
            else
                error("Invalid GUI event handler: " .. handler_name)
            end
        end
    end)
