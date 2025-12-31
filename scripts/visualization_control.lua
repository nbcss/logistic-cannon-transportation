local constants = require("constants")
local CannonNetwork ---@module "scripts.cannon_network"
local LauncherStation ---@module "scripts.launcher_station"
local ReceiverStation ---@module "scripts.receiver_station"

local Visualization = {}
function Visualization.load_deps()
    CannonNetwork = require("scripts.cannon_network")
    LauncherStation = require("scripts.launcher_station")
    ReceiverStation = require("scripts.receiver_station")
end

local range_color = { 0.02, 0.06, 0.02, 0 }
local items_to_view_stations = {
    [constants.item_launcher] = "launcher",
    [constants.item_receiver] = "receiver",
}

-- select a launcher: highlight connected receivers, show the launcher's range
-- select a receiver: show the connected launcher's range
-- holding a launcher/receiver: show everything in the surface

---@class Visualization
---@field mode string all / launcher / receiver
---@field target int64? unit number of station entity
---@field entities table<uint64, { [number]: LuaEntity | LuaRenderObject }>

function Visualization.on_init()
    ---@type table<uint64, Visualization?>
    storage.player_visualization = storage.player_visualization or {}
end

---@param player LuaPlayer
---@param launcher LauncherStation
---@return { [number]: LuaEntity | LuaRenderObject }
local function launcher_visaulization(player, launcher)
    if not launcher:valid() then
        return {}
    end
    local range = launcher:get_max_range()
    return {
        launcher.inventory_entity.surface.create_entity {
            name = "lct-highlight-box",
            position = launcher:position(),
            bounding_box = launcher.inventory_entity.selection_box,
            box_type = "logistics",
            render_player_index = player.index
        } or error(),
        rendering.draw_circle {
            color = range_color,
            radius = range,
            filled = true,
            target = launcher.inventory_entity,
            surface = launcher.inventory_entity.surface,
            players = { player },
            visible = true,
            draw_on_ground = true,
            render_mode = "game",
        } or error(),
        rendering.draw_circle {
            color = range_color,
            radius = range,
            filled = true,
            target = launcher.inventory_entity,
            surface = launcher.inventory_entity.surface,
            players = { player },
            visible = true,
            draw_on_ground = true,
            render_mode = "chart",
        } or error(),
    }
end

---@param player LuaPlayer
---@param receiver ReceiverStation
---@return { [number]: LuaEntity | LuaRenderObject }
local function receiver_visaulization(player, receiver)
    if not receiver:valid() then
        return {}
    end
    return {
        receiver.inventory_entity.surface.create_entity {
            name = "lct-highlight-box",
            position = receiver:position(),
            bounding_box = receiver.inventory_entity.selection_box,
            box_type = "logistics",
            render_player_index = player.index
        } or error(),
    }
end

---@param player LuaPlayer
local function update_visualization(player, force_update)
    local mode = nil
    local target = nil
    if player.selected then
        mode = items_to_view_stations[player.selected.name]
    end
    if player.cursor_stack and player.cursor_stack.valid_for_read then
        mode = items_to_view_stations[player.cursor_stack.name] and "all" or mode
    elseif player.cursor_ghost then
        mode = items_to_view_stations[player.cursor_ghost.name.name] and "all" or mode
    end
    if mode == "launcher" or mode == "receiver" then
        target = player.selected.unit_number
    end
    local player_visualization = storage.player_visualization[player.index]
    local previous_mode = player_visualization and player_visualization.mode
    local previous_target = player_visualization and player_visualization.target
    if previous_mode == mode and previous_target == target and not force_update then
        return
    end
    if player_visualization then
        for _, entities in pairs(player_visualization.entities) do
            for _, entity in ipairs(entities) do
                entity.destroy()
            end
        end
    end
    local entities = {}
    if mode == "all" then
        for network in CannonNetwork.all() do
            if network.force == player.force then
                for launcher in network.launchers:all() do
                    entities[launcher:id()] = launcher_visaulization(player, launcher)
                end
                for receiver in network.receivers:all() do
                    entities[receiver:id()] = receiver_visaulization(player, receiver)
                end
            end
        end
    elseif mode == "launcher" then
        local launcher = LauncherStation.get(player.selected)
        if launcher then
            entities[launcher:id()] = launcher_visaulization(player, launcher)
            for _, receiver in pairs(launcher.network.launcher_to_receivers[launcher:id()]) do
                entities[receiver:id()] = receiver_visaulization(player, receiver)
            end
        end
    elseif mode == "receiver" then
        local receiver = ReceiverStation.get(player.selected)
        if receiver then
            for _, launcher in pairs(receiver.network.receiver_to_launchers[receiver:id()]) do
                entities[launcher:id()] = launcher_visaulization(player, launcher)
            end
        end
    else
        storage.player_visualization[player.index] = nil
        return
    end
    storage.player_visualization[player.index] = {
        mode = mode,
        target = target,
        entities = entities,
    }
end

---@param event EventData.on_player_cursor_stack_changed
function Visualization.on_cursor_stack_changed(event)
    update_visualization(game.players[event.player_index])
end

---@param event EventData.on_selected_entity_changed
function Visualization.on_selected_entity_changed(event)
    update_visualization(game.players[event.player_index])
end

---@param event EventData.on_player_left_game
function Visualization.on_player_left_game(event)
    local player_visualization = storage.player_visualization[event.player_index]
    if not player_visualization then return end
    -- delete all visualization entities of the player
    for _, entities in pairs(player_visualization.entities) do
        for _, entity in ipairs(entities) do
            entity.destroy()
        end
    end
    storage.player_visualization[event.player_index] = nil
end

---@param station_id uint64
---@param network CannonNetwork
---@param launcher LauncherStation?
---@param receiver ReceiverStation?
local function update_station(station_id, network, launcher, receiver)
    -- loop over players, delete their visualization entity if presents, then join if necessary
    for player_index, visualization in pairs(storage.player_visualization) do
        local player = game.players[player_index]
        if visualization.target == station_id then
            update_visualization(player, true)
            goto continue
        end
        if visualization.entities[station_id] then
            for _, entity in ipairs(visualization.entities[station_id]) do
                entity.destroy()
            end
            visualization.entities[station_id] = nil
        end
        if visualization.mode == "all" and player.force == network.force then
            if launcher then
                visualization.entities[station_id] = launcher_visaulization(player, launcher)
            end
            if receiver then
                visualization.entities[station_id] = receiver_visaulization(player, receiver)
            end
        end
        if visualization.mode == "launcher" and receiver then
            local source_launcher = LauncherStation.get(visualization.target)
            if source_launcher and network:is_connected(source_launcher, receiver) then
                visualization.entities[station_id] = receiver_visaulization(player, receiver)
            end
        end
        if visualization.mode == "receiver" and launcher then
            local source_receiver = ReceiverStation.get(visualization.target)
            if source_receiver and network:is_connected(launcher, source_receiver) then
                visualization.entities[station_id] = launcher_visaulization(player, launcher)
            end
        end
        ::continue::
    end
end

---@param launcher LauncherStation
function Visualization.on_launcher_update(launcher)
    update_station(launcher:id(), launcher.network, launcher, nil)
end

---@param receiver ReceiverStation
function Visualization.on_receiver_update(receiver)
    update_station(receiver:id(), receiver.network, nil, receiver)
end

function Visualization.on_station_remove(station_id)
    for _, visualization in pairs(storage.player_visualization) do
        if visualization.entities[station_id] then
            for _, entity in ipairs(visualization.entities[station_id]) do
                entity.destroy()
            end
            visualization.entities[station_id] = nil
        end
    end
end

return Visualization
