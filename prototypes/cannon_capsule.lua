local constants = require("constants")
local capsule_payload_size = 1
local capsule_speed = 35      -- tile per second
local launch_consumption = 25000 -- J per tile

data:extend {
    {
        type = "mod-data",
        name = constants.name_prefix .. "payload-sizes",
        data = {
            ["basic-logistic-cannon-capsule"] = capsule_payload_size,
        },
    },
    {
        type = "mod-data",
        name = constants.name_prefix .. "launch-consumptions",
        data = {
            ["basic-logistic-cannon-capsule"] = launch_consumption,
        },
    },
    {
        type = "ammo",
        name = "basic-logistic-cannon-capsule",
        ammo_category = "logistic-cannon-capsule",
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = "ammo",
        stack_size = 5,
        custom_tooltip_fields = {
            {
                name = { "logistic-cannon-transportation.capsule-payload-size" },
                value = { "logistic-cannon-transportation.stack", tostring(capsule_payload_size) },
                order = 200,
            },
            {
                name = { "logistic-cannon-transportation.capsule-speed" },
                value = { "logistic-cannon-transportation.meter-per-second", tostring(capsule_speed) },
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
        type = "projectile",
        name = "logistic-cannon-capsule-tracker",
        max_speed = capsule_speed / 60,
        acceleration = 99999999,
        map_color = { 0.4, 1.0, 0.4, 0.8 },
        flags = {},
        hidden = true,
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
    },
    {
        type = "stream",
        name = "logistic-cannon-capsule-projectile",
        flags = { "not-on-map" },
        hidden = true,
        oriented_particle = true,
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
        smoke_sources = {
            {
                name = "smoke-fast",
                deviation = { 0.15, 0.15 },
                frequency = 1,
                position = { 0, 0 },
                starting_frame = 3,
                starting_frame_deviation = 5
            }
        },
        -- map_color = { 1, 0, 0 },
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
        particle_start_scale = 1,
        particle_vertical_acceleration = 0.004,
        progress_to_create_smoke = 0.03,
    }
}
