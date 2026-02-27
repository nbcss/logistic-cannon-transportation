local constants = require("constants")
local launcher_icon = "__logistic-cannon-assets__/graphics/icons/launcher.png"
local launcher_bonus_icon = "__logistic-cannon-assets__/graphics/technology/launcher-bonus.png"

local function launcher_range_bonus_effect(modifier)
    return {
        {
            type = "ammo-damage",
            ammo_category = constants.range_upgrade_bonus,
            icons = {
                {
                    icon = launcher_icon,
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
            modifier = modifier,
        }
    }
end

local function energy_efficiency_icon(technology_icon)
    return {
        {
            icon = technology_icon,
            icon_size = 256,
        },
        {
            icon = "__core__/graphics/icons/technology/constants/constant-battery.png",
            icon_size = 128,
            scale = 0.5,
            shift = { 50, 50 },
            floating = true
        }
    }
end

local function launcher_energy_efficiency_effect(consumption_modifier, capacity_modifier)
    return {
        {
            type = "ammo-damage",
            ammo_category = constants.energy_consumption_modifier,
            icons = {
                {
                    icon = launcher_icon,
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
            modifier = consumption_modifier,
        },
        {
            type = "ammo-damage",
            ammo_category = constants.energy_capacity_modifier,
            icons = {
                {
                    icon = launcher_icon,
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
            modifier = capacity_modifier,
        },
    }
end

local function capsule_productivity_effect(modifier)
    local effects = {}
    for ammo, _ in pairs(data.raw["mod-data"][constants.data_capsule_properties].data) do
        table.insert(effects, {
            type = "change-recipe-productivity",
            recipe = ammo,
            change = modifier,
        })
    end
    return effects
end

data:extend {
    {
        type = "technology",
        name = "logistic-cannon",
        icon = "__logistic-cannon-assets__/graphics/technology/logistic-cannon.png",
        icon_size = 256,
        effects = {
            { type = "unlock-recipe", recipe = constants.item_launcher },
            { type = "unlock-recipe", recipe = constants.item_receiver },
            { type = "unlock-recipe", recipe = constants.item_receiver_small },
            { type = "unlock-recipe", recipe = constants.item_capsule_basic },
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
    {
        type = "technology",
        name = "reinforced-cannon-capsule",
        icons = util.technology_icon_constant_capacity("__logistic-cannon-assets__/graphics/technology/capsule-reinforced.png"),
        icon_size = 256,
        effects = {
            { type = "unlock-recipe", recipe = constants.item_capsule_reinforced },
        },
        prerequisites = { "logistic-cannon", "low-density-structure" },
        order = "reinforced-cannon-capsule",
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
        name = "propelled-cannon-capsule",
        icons = util.technology_icon_constant_movement_speed("__logistic-cannon-assets__/graphics/technology/capsule-propelled.png"),
        icon_size = 256,
        effects = {
            { type = "unlock-recipe", recipe = constants.item_capsule_propelled },
        },
        prerequisites = { "reinforced-cannon-capsule", "rocket-fuel", "utility-science-pack" },
        order = "propelled-cannon-capsule",
        unit = {
            count = 500,
            time = 30,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 },
            }
        },
    },
    -- range bonus researches
    {
        type = "technology",
        name = "cannon-launcher-range-upgrade-1",
        icons = util.technology_icon_constant_range(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_range_bonus_effect(0.1),
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
        icons = util.technology_icon_constant_range(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_range_bonus_effect(0.1),
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
        icons = util.technology_icon_constant_range(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_range_bonus_effect(0.1),
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
        icons = util.technology_icon_constant_range(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_range_bonus_effect(0.1),
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
        icons = util.technology_icon_constant_range(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_range_bonus_effect(0.1),
        prerequisites = { "cannon-launcher-range-upgrade-4", "space-science-pack" },
        max_level = "infinite",
        upgrade = true,
        order = "logistic-cannon-range-5",
        unit = {
            count_formula = "1.5^(L-5)*1000",
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
    -- energy efficiency researches
    {
        type = "technology",
        name = "cannon-launcher-energy-efficiency-upgrade-1",
        icons = energy_efficiency_icon(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_energy_efficiency_effect(-0.05, 0.1),
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
        icons = energy_efficiency_icon(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_energy_efficiency_effect(-0.1, 0.2),
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
        icons = energy_efficiency_icon(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_energy_efficiency_effect(-0.1, 0.2),
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
        icons = energy_efficiency_icon(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_energy_efficiency_effect(-0.1, 0.2),
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
        icons = energy_efficiency_icon(launcher_bonus_icon),
        icon_size = 64,
        effects = launcher_energy_efficiency_effect(-0.15, 0.3),
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
    -- capsule productivity researches
    {
        type = "technology",
        name = "cannon-capsule-productivity-upgrade-1",
        icons = util.technology_icon_constant_recipe_productivity("__logistic-cannon-assets__/graphics/technology/capsules.png"),
        icon_size = 64,
        effects = capsule_productivity_effect(0.1),
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
        icons = util.technology_icon_constant_recipe_productivity("__logistic-cannon-assets__/graphics/technology/capsules.png"),
        icon_size = 64,
        effects = capsule_productivity_effect(0.1),
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
        icons = util.technology_icon_constant_recipe_productivity("__logistic-cannon-assets__/graphics/technology/capsules.png"),
        icon_size = 64,
        effects = capsule_productivity_effect(0.1),
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
        icons = util.technology_icon_constant_recipe_productivity("__logistic-cannon-assets__/graphics/technology/capsules.png"),
        icon_size = 64,
        effects = capsule_productivity_effect(0.1),
        prerequisites = { "cannon-capsule-productivity-upgrade-3", "space-science-pack" },
        max_level = "infinite",
        upgrade = true,
        order = "logistic-cannon-capsule-productivity-4",
        unit = {
            count_formula = "1.5^(L-4)*500",
            time = 60,
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
}
