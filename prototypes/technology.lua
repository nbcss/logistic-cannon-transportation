local constants = require("constants")

data:extend {
    {
        type = "technology",
        name = "logistic-cannon",
        icon = "__base__/graphics/technology/artillery.png",
        icon_size = 256,
        effects = {
            { type = "unlock-recipe", recipe = constants.item_launcher},
            { type = "unlock-recipe", recipe = constants.item_receiver},
            { type = "unlock-recipe", recipe = constants.item_capsule_basic},
        },
        prerequisites = { "explosives", "radar", "concrete" },
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
    -- Range bonus researches
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-1",
        icons = util.technology_icon_constant_range("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.range_upgrade_bonus,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
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
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-2",
        icons = util.technology_icon_constant_range("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.range_upgrade_bonus,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
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
        prerequisites = { "cannon-launcher-range-upgrade-1", "military-science-pack" },
        upgrade = true,
        order = "logistic-cannon-range-2",
        unit = {
            count = 400,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-3",
        icons = util.technology_icon_constant_range("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.range_upgrade_bonus,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
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
        prerequisites = { "cannon-launcher-range-upgrade-2", "utility-science-pack" },
        upgrade = true,
        order = "logistic-cannon-range-3",
        unit = {
            count = 500,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
                { "utility-science-pack",    1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-4",
        icons = util.technology_icon_constant_range("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.range_upgrade_bonus,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
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
        prerequisites = { "cannon-launcher-range-upgrade-3", "production-science-pack" },
        upgrade = true,
        order = "logistic-cannon-range-4",
        unit = {
            count = 750,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
                { "utility-science-pack",    1 },
                { "production-science-pack", 1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-5",
        icons = util.technology_icon_constant_range("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.range_upgrade_bonus,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
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
                modifier = 0.2,
            }
        },
        prerequisites = { "cannon-launcher-range-upgrade-4", "space-science-pack" },
        max_level = "infinite",
        upgrade = true,
        order = "logistic-cannon-range-5",
        unit = {
            count_formula = "2^(L-5)*1000",
            time = 60,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
                { "utility-science-pack",    1 },
                { "production-science-pack", 1 },
                { "space-science-pack",      1 },
            }
        },
    },
    -- capsule productivity researches
    {
        type = "technology",
        name = "cannon-capsule-productivity-upgrade-1",
        icons = util.technology_icon_constant_productivity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "change-recipe-productivity",
                recipe = constants.item_capsule_basic,
                change = 0.1,
            }
        },
        prerequisites = { "logistic-cannon", "chemical-science-pack" },
        upgrade = true,
        order = "logistic-cannon-capsule-productivity-1",
        unit = {
            count = 200,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-capsule-productivity-upgrade-2",
        icons = util.technology_icon_constant_productivity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "change-recipe-productivity",
                recipe = constants.item_capsule_basic,
                change = 0.1,
            }
        },
        prerequisites = { "cannon-capsule-productivity-upgrade-1", "military-science-pack" },
        upgrade = true,
        order = "logistic-cannon-capsule-productivity-2",
        unit = {
            count = 300,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-capsule-productivity-upgrade-3",
        icons = util.technology_icon_constant_productivity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "change-recipe-productivity",
                recipe = constants.item_capsule_basic,
                change = 0.1,
            }
        },
        prerequisites = { "cannon-capsule-productivity-upgrade-2", "production-science-pack" },
        upgrade = true,
        order = "logistic-cannon-capsule-productivity-3",
        unit = {
            count = 400,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
                { "production-science-pack", 1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-capsule-productivity-upgrade-4",
        icons = util.technology_icon_constant_productivity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "change-recipe-productivity",
                recipe = constants.item_capsule_basic,
                change = 0.1,
            }
        },
        prerequisites = { "cannon-capsule-productivity-upgrade-3", "space-science-pack" },
        max_level = "infinite",
        upgrade = true,
        order = "logistic-cannon-capsule-productivity-4",
        unit = {
            count_formula = "2^(L-4)*500",
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "military-science-pack",   1 },
                { "production-science-pack", 1 },
                { "space-science-pack",      1 },
            }
        },
    },
    -- energy efficiency research
    {
        type = "technology",
        name = "cannon-launcher-energy-efficiency-upgrade-1",
        icons = util.technology_icon_constant_capacity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.energy_consumption_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = -0.05,
            },
            {
                type = "ammo-damage",
                ammo_category = constants.energy_capacity_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.1,
            },
        },
        prerequisites = { "logistic-cannon" },
        upgrade = true,
        order = "logistic-cannon-energy-efficiency-1",
        unit = {
            count = 500,
            time = 60,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-energy-efficiency-upgrade-2",
        icons = util.technology_icon_constant_capacity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.energy_consumption_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = -0.1,
            },
            {
                type = "ammo-damage",
                ammo_category = constants.energy_capacity_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.2,
            },
        },
        prerequisites = { "cannon-launcher-energy-efficiency-upgrade-1", "chemical-science-pack" },
        upgrade = true,
        order = "logistic-cannon-energy-efficiency-2",
        unit = {
            count = 750,
            time = 60,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-energy-efficiency-upgrade-3",
        icons = util.technology_icon_constant_capacity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.energy_consumption_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = -0.1,
            },
            {
                type = "ammo-damage",
                ammo_category = constants.energy_capacity_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.2,
            },
        },
        prerequisites = { "cannon-launcher-energy-efficiency-upgrade-2", "utility-science-pack" },
        upgrade = true,
        order = "logistic-cannon-energy-efficiency-3",
        unit = {
            count = 1000,
            time = 60,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-energy-efficiency-upgrade-4",
        icons = util.technology_icon_constant_capacity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.energy_consumption_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = -0.1,
            },
            {
                type = "ammo-damage",
                ammo_category = constants.energy_capacity_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.2,
            },
        },
        prerequisites = { "cannon-launcher-energy-efficiency-upgrade-3", "production-science-pack" },
        upgrade = true,
        order = "logistic-cannon-energy-efficiency-4",
        unit = {
            count = 1500,
            time = 60,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 },
                { "production-science-pack", 1 },
            }
        },
    },
    {
        type = "technology",
        name = "cannon-launcher-energy-efficiency-upgrade-5",
        icons = util.technology_icon_constant_capacity("__base__/graphics/technology/artillery.png"),
        icon_size = 64,
        effects = {
            {
                type = "ammo-damage",
                ammo_category = constants.energy_consumption_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = -0.15,
            },
            {
                type = "ammo-damage",
                ammo_category = constants.energy_capacity_modifier,
                icons = {
                    {
                        icon = "__base__/graphics/icons/tank-cannon.png",
                        icon_size = 64,
                    },
                    {
                        icon = "__core__/graphics/icons/technology/effect-constant/effect-constant-battery.png",
                        icon_size = 64,
                        scale = 0.5,
                        floating = true
                    }
                },
                use_icon_overlay_constant = false,
                modifier = 0.3,
            },
        },
        prerequisites = { "cannon-launcher-energy-efficiency-upgrade-4", "space-science-pack" },
        upgrade = true,
        order = "logistic-cannon-energy-efficiency-5",
        unit = {
            count = 2000,
            time = 60,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 },
                { "production-science-pack", 1 },
                { "space-science-pack",      1 },
            }
        },
    },
}
