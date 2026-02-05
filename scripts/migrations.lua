local launcher_gui = require("scripts.gui.launcher_gui")
local receiver_gui = require("scripts.gui.receiver_gui")
local bonus_control = require("scripts.bonus_control")
local lct_util = require("scripts.lct_util")
local ScheduledDelivery = require("scripts.scheduled_delivery")


local migrations = {}

---@param event ConfigurationChangedData
function migrations.on_configuration_changed(event)
    log(serpent.block(event))
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
    ["0.1.6"] = function()
        for delivery in ScheduledDelivery.all() do
            -- Add distance field to deliveries.
            local source = delivery.launcher:valid() and delivery.launcher:position() or {0, 0}
            local target = delivery.receiver:valid() and delivery.receiver:position() or delivery.position
            delivery.distance = lct_util.math2d.distance(source, target)
        end
    end
}

return migrations