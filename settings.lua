local constants = require("constants")

data:extend{
    {
        type = "bool-setting",
        name = constants.coloring_projectile_smoke,
        order = "aa",
        setting_type = "startup",
        default_value = true,
    },
    {
        type = "int-setting",
        name = constants.entity_update_interval_setting,
        order = "ba",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 300,
        default_value = 30,
    },
    {
        type = "int-setting",
        name = constants.gui_update_interval_setting,
        order = "bb",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 60,
        default_value = 2,
    },
    {
        type = "string-setting",
        name = constants.range_visualization_mode,
        order = "ca",
        setting_type = "runtime-per-user",
        default_value = "edge",
        allowed_values = { "filled", "edge" },
    },
}