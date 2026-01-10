local constants = require("constants")

data:extend{
    {
        type = "int-setting",
        name = constants.entity_update_interval_setting,
        order = "a",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 300,
        default_value = 30,
    },
    {
        type = "int-setting",
        name = constants.gui_update_interval_setting,
        order = "b",
        setting_type = "runtime-global",
        minimum_value = 1,
        maximum_value = 60,
        default_value = 2,
    },
    {
        type = "string-setting",
        name = constants.range_visualization_mode,
        order = "c",
        setting_type = "runtime-per-user",
        default_value = "edge",
        allowed_values = { "filled", "edge" },
    },
}