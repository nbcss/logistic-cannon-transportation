local launcher_gui = require("scripts.gui.launcher_gui")
local receiver_gui = require("scripts.gui.receiver_gui")
local bonus_control = require("scripts.bonus_control")
local lct_util = require("scripts.lct_util")
local ScheduledDelivery = require("scripts.scheduled_delivery")
local LauncherStation  = require("scripts.launcher_station")
local launcher_computed_values = require("scripts.launcher_computed_values")


local migrations = {}

---@param event ConfigurationChangedData
function migrations.on_configuration_changed(event)
    for _, force in pairs(game.forces) do
        bonus_control.update_bonus(force)
    end
    local this_mod_change = event.mod_changes[script.mod_name]
    if this_mod_change and this_mod_change.old_version then
        -- Destroy open GUIs, so they are recreated on the next refresh.
        for _, player in pairs(game.players) do
            launcher_gui.destroy(player)
            receiver_gui.destroy(player)
        end

        -- Run version-specific migrations.
        for version, func in pairs(migrations.this_mod_migrations) do
            if helpers.compare_versions(this_mod_change.old_version, version) < 0 then
                log("Run migrations for v"..version)
                func()
            end
        end
    end
end

---@package
---@type table<string, fun()>
migrations.this_mod_migrations = {
    ["0.2.0"] = function()
        -- Add distance field to deliveries.
        for delivery in ScheduledDelivery.all() do
            local source = delivery.launcher:valid() and delivery.launcher:position() or {0, 0}
            local target = delivery.receiver:valid() and delivery.receiver:position() or delivery.position
            delivery.distance = lct_util.math2d.distance(source, target)
        end
        -- Divide payload_size and max_range fields in launchers to computed_ and effective_ variants.
        for launcher in LauncherStation.all() do
            ---@diagnostic disable-next-line: inject-field
            launcher.payload_size = nil
            launcher.computed_payload_size = launcher_computed_values.compute_payload_size(launcher.ammo_name, launcher.ammo_quality)
            launcher.effective_payload_size = launcher_computed_values.with_override(launcher.computed_payload_size, launcher.settings.payload_size_override)
            ---@diagnostic disable-next-line: inject-field
            launcher.max_range = nil
            launcher.computed_max_range = launcher_computed_values.compute_max_range(launcher.inventory_entity.name, launcher.inventory_entity.quality, launcher.inventory_entity.force--[[@as LuaForce]], launcher.ammo_name)
            launcher.effective_max_range = launcher_computed_values.with_override(launcher.computed_max_range, launcher.settings.range_override)
        end
    end
}

commands.add_command("lct_migrate", nil, function(command)
    local print = command.player_index and game.get_player(command.player_index).print or game.print
    if not command.parameter or not migrations.this_mod_migrations[command.parameter] then
        print("No migrations run.")
        return
    end
    print("Run migrations for v"..command.parameter)
    migrations.this_mod_migrations[command.parameter]()
end)

return migrations