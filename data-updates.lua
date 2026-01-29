require("prototypes.projectile")

local constants = require("constants")

if feature_flags["space_travel"] then
    data.raw["container"][constants.entity_launcher_inventory].surface_conditions = { { property = "gravity", min = 1 } }
    data.raw["container"][constants.entity_receiver_inventory].surface_conditions = { { property = "gravity", min = 1 } }
end
if settings.startup[constants.setting_se_allow_in_space].value == true then
    data.raw["container"][constants.entity_launcher_inventory]["se_allow_in_space"] = true
    data.raw["container"][constants.entity_receiver_inventory]["se_allow_in_space"] = true
end
