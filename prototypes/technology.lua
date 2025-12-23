data:extend {
    {
        type = "technology",
        name = "logistic-cannon",
        icon = "__base__/graphics/technology/battery.png",
        effects = {
            { type = "unlock-recipe", recipe = "logistic-cannon-launcher"},
            { type = "unlock-recipe", recipe = "logistic-cannon-receiver"},
            { type = "unlock-recipe", recipe = "basic-logistic-cannon-capsule"},
        },
        prerequisites = { "logistic-science-pack" },
        order = "logistic-cannon",
        unit = {
            count = 150,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
            }
        }
    },
    {
        type = "technology",
        name = "cannon-energy-buffer-1",
        icons = util.technology_icon_constant_capacity("__base__/graphics/technology/battery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = "logistic-cannon-launcher-energy-buffer",
                -- icon = "__base__/graphics/icons/rocket-part.png",
                icons = {
                    {
                        icon = "__base__/graphics/icons/rocket-part.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        -- shift = { -16, -16 },
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.1,
            }
        },
        prerequisites = { "battery" },
        max_level = "infinite",
        upgrade = true,
        order = "za",
        unit = {
            count_formula = "2^(L-1)*500",
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "military-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 },
                { "space-science-pack",      1 },
            },
            time = 60,
        },
    },
}
