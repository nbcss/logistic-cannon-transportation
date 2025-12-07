local capsule_speed = 25 -- tile per second

data:extend {
    {
        type = "ammo",
        name = "basic-logistic-cannon-capsule",
        ammo_category = "logistic-cannon-capsule",
        icon = "__base__/graphics/icons/fish-entity.png",
        subgroup = "ammo",
        stack_size = 5,
        custom_tooltip_fields = {
            {
                name = { "logistic-cannon-transportation.capsule-payload" },
                value = { "", tostring(5) },
            }
        },
        ammo_type = {
            target_type = "direction",
            consumption_modifier = 0,
            action = {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    target_effects = {
                        {
                            type = "script",
                            effect_id = "logistic-cannon-capsule-launched",
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
            { type = "item", name = "steel-plate", amount = 5 },
        },
        results = {
            { type = "item", name = "basic-logistic-cannon-capsule", amount = 1 },
        }
    },
    {
        type = "stream",
        name = "logistic-cannon-capsule-projectile",
        flags = {},
        oriented_particle = true,
        action = {
            {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    target_effects = {
                        {
                            type = "script",
                            effect_id = "logistic-cannon-capsule-landed"
                        }
                    }
                }
            },
        },
        particle = {
            filename = "__base__/graphics/entity/grenade/grenade.png",
            width = 48,
            height = 54,
            animation_speed = 0.25,
            frame_count = 16,
            line_length = 8,
            shift = { 0.015625, 0.015625 },
            scale = 0.5,
        },
        shadow = {
            draw_as_shadow = true,
            filename = "__base__/graphics/entity/grenade/grenade-shadow.png",
            width = 50,
            height = 40,
            animation_speed = 0.25,
            frame_count = 16,
            line_length = 8,
            shift = { 0.0625, 0.1875 },
            scale = 0.5,
        },
        particle_buffer_size = 1,
        particle_end_alpha = 1,
        particle_fade_out_threshold = 1,
        particle_horizontal_speed = capsule_speed / 60,
        particle_horizontal_speed_deviation = 0,
        particle_loop_exit_threshold = 1,
        particle_loop_frame_count = 1,
        particle_spawn_interval = 0,
        particle_spawn_timeout = 1,
        particle_start_alpha = 1,
        particle_start_scale = 2,
        particle_vertical_acceleration = 0.0032,
        progress_to_create_smoke = 0.03,
    }
}
