local lct_command = {}

---@class (exact) lct_command.SubcommandData
---@field parameter string
---@field player LuaPlayer
---@field tick uint32
---@field print fun(message: LocalisedString, print_settings: PrintSettings?)

---@type table<string, fun(command: lct_command.SubcommandData)?>
lct_command.subcommands = {}

commands.add_command("lct", nil, function(command)
    local player = game.get_player(command.player_index) --[[@as LuaPlayer]]
    local print = command.player_index and player.print or game.print
    if not command.parameter then
        print("Invalid subcommand.")
        return
    end
    local space_start, space_end = command.parameter:find("%s+")
    local subcommand = command.parameter:sub(1, space_start and space_start - 1 or nil)
    if not lct_command.subcommands[subcommand] then
        print("Invalid subcommand.")
        return
    end
    lct_command.subcommands[subcommand]{
        parameter = command.parameter:sub((space_end or 0) + 1),
        player = player,
        tick = command.tick,
        print = print,
    }
end)

return lct_command