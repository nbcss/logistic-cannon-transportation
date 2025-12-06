
data:extend{
    {
        type = "ammo-category",
        name = "logistic-cannon-capsule",
        icon = "__base__/graphics/icons/fish-entity.png",
        subgroup = "ammo-category",
    },
    {
        type = "ammo",
        name = "basic-logistic-cannon-capsule",
        ammo_category = "logistic-cannon-capsule",
        icon = "__base__/graphics/icons/fish-entity.png",
        subgroup = "ammo",
        stack_size = 5,
        ammo_type = {
            target_type = "entity",
            consumption_modifier = 0,
            action = {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    target_effects = {
                        {
                            type = "script",
                            effect_id = "logistic-cannon-launch",
                        }
                    },
                }
            },
        }
    },
    {
        type = "recipe",
        name = "basic-logistic-cannon-capsule",
        enabled = true,
        energy_required = 5,
        ingredients = {
            {type = "item", name = "steel-plate", amount = 5},
        },
        results = {
            {type = "item", name = "basic-logistic-cannon-capsule", amount = 1},
        }
    },
}