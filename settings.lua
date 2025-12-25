local constants = require("constants")

data:extend{
    {
        type = "int-setting",
        name = constants.update_interval_setting,
        order = "a",
        setting_type = "runtime-global",
        minimum_value = 1,
        default_value = 60,
    },
}