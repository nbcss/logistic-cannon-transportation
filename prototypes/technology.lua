local constants = require("constants")

data:extend {
    {
        type = "technology",
        name = "logistic-cannon",
        icon = "__base__/graphics/technology/artillery.png",
        icon_size = 64,
        effects = {
            { type = "unlock-recipe", recipe = constants.item_launcher},
            { type = "unlock-recipe", recipe = constants.item_receiver},
            { type = "unlock-recipe", recipe = constants.item_capsule_basic},
        },
        prerequisites = { "explosives", "radar" },
        order = "logistic-cannon",
        unit = {
            count = 150,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-1",
        icons = util.technology_icon_constant_range("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.range_upgrade_bonus,
                -- icon = "__base__/graphics/icons/rocket-part.png",
                icons = {
                    {
                        icon = "__base__/graphics/icons/battery.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-range.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.1,
            }
        },
        prerequisites = { "logistic-cannon", "chemical-science-pack" },
        upgrade = true,
        order = "logistic-cannon-range-1",
        unit = {
            count = 300,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
            }
        },
    },
}
