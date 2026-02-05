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
local signal_condition = require("scripts.gui.signal_condition")
local migrations       = require("scripts.migrations")

LauncherStation.load_deps()
ReceiverStation.load_deps()
visualization_control.load_deps()
signal_condition.load_deps()

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

script.on_configuration_changed(function(event)
    CannonNetwork.on_init()
    LauncherStation.on_init()
    ReceiverStation.on_init()
    ScheduledDelivery.on_init()
    visualization_control.on_init()
    migrations.on_configuration_changed(event)
end)

script.on_event(defines.events.on_research_finished, function(event) bonus_control.update_bonus(event.research.force) end)
script.on_event(defines.events.on_research_reversed, function(event) bonus_control.update_bonus(event.research.force) end)
script.on_event(defines.events.on_force_reset, function(event) bonus_control.update_bonus(event.force) end)

local trigger_effect_functions = {
    [constants.capsule_launched_effect_id] = function(event)
        if event.source_position and event.source_entity and event.source_entity.valid then
            local launcher = LauncherStation.get(event.source_entity)
            if launcher then launcher:launch() end
        end
    end,
    [constants.capsule_landed_effect_id] = function(event)
        if not event.cause_entity or not event.cause_entity.valid then return end
        if event.cause_entity.name == constants.entity_capsule_inventory then
            local delivery = ScheduledDelivery.get(event.cause_entity.unit_number)
            if delivery then delivery:deliver() end
        end
    end,
}
script.on_event(defines.events.on_script_trigger_effect, function(event)
    local func = trigger_effect_functions[event.effect_id]
    if func then func(event) end
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    if event.type == defines.target_type.entity then
        if event.useful_id then
            LauncherStation.on_object_destroyed(event.useful_id)
            ReceiverStation.on_object_destroyed(event.useful_id)
        end
        ScheduledDelivery.on_object_destroyed(event.registration_number, event.useful_id)
    end
end)

script.on_event({
        defines.events.on_built_entity,
        defines.events.on_robot_built_entity,
        defines.events.on_space_platform_built_entity,
        defines.events.script_raised_revive,
    },
    ---@param event
    ---| EventData.on_built_entity
    ---| EventData.on_robot_built_entity
    ---| EventData.on_space_platform_built_entity
    ---| EventData.script_raised_revive
    function(event)
        if event.entity.name == constants.entity_launcher_inventory then
            local settings = LauncherStation.read_settings(event.tags)
            LauncherStation.create(event.entity, settings)
        end
        if event.entity.name == constants.entity_receiver_inventory then
            local settings = ReceiverStation.read_settings(event.tags)
            ReceiverStation.create(event.entity, settings)
        end
    end)

local function transfer_ammo(station, ammo_inventory, target)
    local force = station.turret_entity.force
    station.turret_entity.force = "enemy"
    inventory_tool.dump_items(ammo_inventory, target)
    station.turret_entity.force = force
end
script.on_event(defines.events.on_space_platform_pre_mined, function(event)
    if event.entity.name == constants.entity_launcher_inventory then
        local station = LauncherStation.get(event.entity)
        if station then
            local ammo_inventory = station:get_ammo_inventory()
            if not ammo_inventory.is_empty() then
                local target = event.platform.hub.get_inventory(defines.inventory.hub_main) --[[@as LuaInventory]]
                transfer_ammo(station, ammo_inventory, target)
            end
        end
    end
end)
script.on_event(defines.events.on_pre_player_mined_item, function(event)
    local player = game.players[event.player_index]
    if event.entity.name == constants.entity_launcher_inventory then
        local station = LauncherStation.get(event.entity)
        if station then
            local ammo_inventory = station:get_ammo_inventory()
            if not ammo_inventory.is_empty() then
                local target = player.get_main_inventory() --[[@as LuaInventory]]
                transfer_ammo(station, ammo_inventory, target)
            end
        end
    end
end)
script.on_event(defines.events.on_robot_pre_mined, function(event)
    if event.entity.name == constants.entity_launcher_inventory then
        local station = LauncherStation.get(event.entity)
        if station then
            local ammo_inventory = station:get_ammo_inventory()
            if not ammo_inventory.is_empty() then
                local target = event.robot.get_inventory(defines.inventory.robot_cargo) --[[@as LuaInventory]]
                transfer_ammo(station, ammo_inventory, target)
            end
        end
    end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    -- Launcher
    local launcher_settings = nil
    if event.source.name == constants.entity_launcher_inventory then
        local source = LauncherStation.get(event.source)
        if source then
            launcher_settings = source.settings
        end
    end
    if event.source.name == "entity-ghost" and event.source.ghost_name == constants.entity_launcher_inventory then
        launcher_settings = LauncherStation.read_settings(event.source.tags)
    end
    if launcher_settings then
        if event.destination.name == constants.entity_launcher_inventory then
            local destination = LauncherStation.get(event.destination)
            if destination then
                destination:set_settings(launcher_settings)
            end
        end
        if event.destination.name == "entity-ghost" and event.destination.ghost_name == constants.entity_launcher_inventory then
            local tags = event.destination.tags or {}
            LauncherStation.write_settings(tags, launcher_settings)
            event.destination.tags = tags
        end
    end
    -- Receiver
    local receiver_settings = nil
    if event.source.name == constants.entity_receiver_inventory then
        local source = ReceiverStation.get(event.source)
        if source then
            receiver_settings = source.settings
        end
    end
    if event.source.name == "entity-ghost" and event.source.ghost_name == constants.entity_receiver_inventory then
        receiver_settings = ReceiverStation.read_settings(event.source.tags)
    end
    if receiver_settings then
        if event.destination.name == constants.entity_receiver_inventory then
            local destination = ReceiverStation.get(event.destination)
            if destination then
                destination:set_settings(receiver_settings)
            end
        end
        if event.destination.name == "entity-ghost" and event.destination.ghost_name == constants.entity_receiver_inventory then
            local tags = event.destination.tags or {}
            ReceiverStation.write_settings(tags, receiver_settings)
            event.destination.tags = tags
        end
    end
end)
script.on_event(defines.events.on_post_entity_died, function(event)
    if not event.ghost then return end
    -- Launcher
    if event.ghost.ghost_name == constants.entity_launcher_inventory then
        local launcher = LauncherStation.get(event.unit_number)
        if launcher then
            local tags = event.ghost.tags or {}
            LauncherStation.write_settings(tags, launcher.settings)
            event.ghost.tags = tags
        end
    end
    -- Receiver
    if event.ghost.ghost_name == constants.entity_receiver_inventory then
        local receiver = ReceiverStation.get(event.unit_number)
        if receiver then
            local tags = event.ghost.tags or {}
            ReceiverStation.write_settings(tags, receiver.settings)
            event.ghost.tags = tags
        end
    end
end)
script.on_event(defines.events.on_player_setup_blueprint, function(event)
    local blueprint = event.stack or event.record
    if not blueprint then return end
    local entities = blueprint.get_blueprint_entities() --[[@as BlueprintEntity[]]
    if not entities then return end
    local updated = false
    for index, entity in ipairs(entities) do
        -- Launcher
        if entity.name == constants.entity_launcher_inventory then
            local source = event.mapping.get()[index] --[[@as LuaEntity?]]
            if source then
                local launcher_settings = nil
                if source.name == "entity-ghost" then
                    launcher_settings = LauncherStation.read_settings(source.tags)
                else
                    local launcher = LauncherStation.get(source)
                    launcher_settings = launcher and launcher.settings
                end
                if launcher_settings then
                    local tags = entity.tags or {}
                    LauncherStation.write_settings(tags, launcher_settings)
                    entity.tags = tags
                    updated = true
                end
            end
        end
        -- Receiver
        if entity.name == constants.entity_receiver_inventory then
            local source = event.mapping.get()[index] --[[@as LuaEntity?]]
            if source then
                local receiver_settings = nil
                if source.name == "entity-ghost" then
                    receiver_settings = ReceiverStation.read_settings(source.tags)
                else
                    local receiver = ReceiverStation.get(source)
                    receiver_settings = receiver and receiver.settings
                end
                if receiver_settings then
                    local tags = entity.tags or {}
                    ReceiverStation.write_settings(tags, receiver_settings)
                    entity.tags = tags
                    updated = true
                end
            end
        end
    end
    if updated then blueprint.set_blueprint_entities(entities) end
end)

script.on_event(defines.events.on_entity_cloned, function(event)
    LauncherStation.on_entity_cloned(event.source, event.destination)
    ReceiverStation.on_entity_cloned(event.source, event.destination)
    ScheduledDelivery.on_entity_cloned(event.source, event.destination)
end)
script.on_event(defines.events.script_raised_teleported, function(event)
    LauncherStation.on_entity_teleported(event.entity)
    ReceiverStation.on_entity_teleported(event.entity)
end)

---@param event EventData.CustomInputEvent
script.on_event({ constants.rotate_input_event, constants.reverse_rotate_input_event }, function(event)
    local player = game.players[event.player_index]
    if (player.cursor_stack and player.cursor_stack.valid_for_read) or player.cursor_ghost then return end
    if player.selected and player.selected.name == constants.entity_launcher_inventory then
        local launcher = LauncherStation.get(player.selected)
        if launcher and launcher:valid() and launcher.network.force == player.force then
            launcher:rotate(player, event.input_name == constants.reverse_rotate_input_event)
        end
    end
end)

script.on_event(defines.events.on_forces_merging, function(event)
    for network in CannonNetwork.all() do
        if network.force == event.source then
            local target_network = CannonNetwork.get_or_create(event.destination, network.surface, network.signal)
            for launcher in network.launchers:all() do
                launcher:set_network(target_network)
            end
            for receiver in network.receivers:all() do
                receiver:set_network(target_network)
            end
        end
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting_type == "runtime-global" and event.setting == constants.setting_entity_update_interval then
        CannonNetwork.resize_buckets()
    end
end)

---@param player LuaPlayer
local function update_player_selected_diode_status(player)
    if player.selected then
        if player.selected.name == constants.entity_launcher_inventory then
            local launcher = LauncherStation.get(player.selected)
            if launcher then launcher:update_diode_status() end
        elseif player.selected.name == constants.entity_receiver_inventory then
            local receiver = ReceiverStation.get(player.selected)
            if receiver then receiver:update_diode_status() end
        end
    end
end
script.on_event(defines.events.on_tick, function(event)
    -- update network schedules
    for network in CannonNetwork.all() do
        network:update(event.tick)
    end
    local tick_index = event.tick % settings.global[constants.setting_gui_update_interval].value
    -- update station custom states
    for _, player in ipairs(game.connected_players) do
        update_player_selected_diode_status(player)
        if tick_index == 0 and player.opened and player.opened.object_name == "LuaEntity" then
            if player.opened.name == constants.entity_launcher_gui_proxy then
                local entity = player.opened --[[@as LuaEntity]]
                local launcher = LauncherStation.get(entity)
                if launcher then
                    launcher:update_diode_status()
                    launcher_gui.refresh(player, launcher)
                end
            end
            if player.opened.name == constants.entity_receiver_gui_proxy then
                local entity = player.opened --[[@as LuaEntity]]
                local receiver = ReceiverStation.get(entity)
                if receiver then
                    receiver:update_diode_status()
                    receiver_gui.refresh(player, receiver)
                end
            end
        end
    end
end)

-- Visualization control events
script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    visualization_control.on_cursor_stack_changed(event)
end)
script.on_event(defines.events.on_selected_entity_changed, function(event)
    visualization_control.on_selected_entity_changed(event)
    update_player_selected_diode_status(game.players[event.player_index])
end)
script.on_event(defines.events.on_player_left_game, function(event)
    visualization_control.on_player_left_game(event)
end)

-- GUI events
script.on_event({
    defines.events.on_gui_opened,
    defines.events.on_gui_closed,
    defines.events.on_player_controller_changed,
    ---@param event
    ---| EventData.on_gui_opened
    ---| EventData.on_gui_closed
    ---| EventData.on_player_controller_changed
}, function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    receiver_gui.destroy(player)
    launcher_gui.destroy(player)
    if player.opened_gui_type ~= defines.gui_type.entity then return end
    local entity = player.opened --[[@as LuaEntity]]

    if entity.name == constants.entity_receiver_inventory then
        local receiver = ReceiverStation.get(entity)
        player.opened = receiver and receiver:valid() and receiver:get_gui_proxy() or nil
    elseif entity.name == constants.entity_launcher_inventory then
        local launcher = LauncherStation.get(entity)
        player.opened = launcher and launcher:valid() and launcher:get_gui_proxy() or nil
    elseif entity.name == constants.entity_receiver_gui_proxy then
        local receiver = ReceiverStation.get(entity)
        if receiver and receiver:valid() then
            receiver:update_diode_status()
            receiver_gui.refresh(player, receiver)
        end
    elseif entity.name == constants.entity_launcher_gui_proxy then
        local launcher = LauncherStation.get(entity)
        if launcher and launcher:valid() then
            launcher:update_diode_status()
            launcher_gui.refresh(player, launcher)
        end
    end
end)
---@param event
---| EventData.on_gui_click
---| EventData.on_gui_elem_changed
---| EventData.on_gui_text_changed
---| EventData.on_gui_confirmed
---| EventData.on_gui_checked_state_changed
---| EventData.on_gui_value_changed
---| EventData.on_gui_text_changed
---| EventData.on_gui_selection_state_changed
---| EventData.on_gui_hover
---| EventData.on_gui_leave
local function delegate_gui_event_handler(event)
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
        elseif handler_module == "signal_condition" then
            signal_condition[handler_func](game.get_player(event.player_index), event)
        else
            error("Invalid GUI event handler: " .. handler_name)
        end
    end
end
script.on_event({
    defines.events.on_gui_click,
    defines.events.on_gui_elem_changed,
    defines.events.on_gui_text_changed,
    defines.events.on_gui_confirmed,
    defines.events.on_gui_checked_state_changed,
    defines.events.on_gui_value_changed,
    defines.events.on_gui_text_changed,
    defines.events.on_gui_selection_state_changed,
}, delegate_gui_event_handler)

script.on_event({
    defines.events.on_gui_hover,
    defines.events.on_gui_leave,
    ---@param event
    ---| EventData.on_gui_hover
    ---| EventData.on_gui_leave
}, function(event)
    -- Track hover state in a tag if such tag already exists
    if event.element.tags[constants.gui_tag_tracked_hover_state] ~= nil then
        local tags = event.element.tags
        tags[constants.gui_tag_tracked_hover_state] = event.name == defines.events.on_gui_hover
        event.element.tags = tags
    end

    delegate_gui_event_handler(event)
end)
