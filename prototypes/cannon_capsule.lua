local constants = require("constants")
local capsule_payload_size = 1
local projectile_speed = "1"
local launch_consumption = 25000 -- J per tile

data.raw["mod-data"][constants.data_capsule_properties].data[constants.item_capsule_basic] = {
    speed_tier = projectile_speed,
    payload_size = capsule_payload_size,
    energy_consumption = launch_consumption,
}--[[@as CannonCapsuleProperties]]

data:extend {
    {
        type = "ammo",
        name = constants.item_capsule_basic,
        ammo_category = constants.ammo_category,
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = constants.item_subgroup,
        order = "c1[capsule]",
        stack_size = 5,
        custom_tooltip_fields = {
            {
                name = { "logistic-cannon-transportation.capsule-payload-size" },
                value = { "logistic-cannon-transportation.stack", tostring(capsule_payload_size) },
                order = 200,
            },
            {
                name = { "logistic-cannon-transportation.capsule-speed" },
                value = data.raw["mod-data"][constants.data_projectile_properties].data[projectile_speed].locale_string,
                order = 201,
            },
            {
                name = { "logistic-cannon-transportation.launch-consumption" },
                value = { "logistic-cannon-transportation.kj-per-meter", string.format("%.0f", launch_consumption / 1000) },
                order = 202,
            },
        },
        ammo_type = {
            target_type = "direction",
            consumption_modifier = 0,
            action = {
                type = "direct",
                action_delivery = {
                    {
                        type = "instant",
                        target_effects = {
                            {
                                type = "script",
                                effect_id = "logistic-cannon-capsule-launched",
                            }
                        }
                    }
                }
            },
        }
    },
    {
        type = "recipe",
        name = constants.item_capsule_basic,
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "steel-plate", amount = 5 },
        },
        results = {
            { type = "item", name = constants.item_capsule_basic, amount = 1 },
        }
    },
}
