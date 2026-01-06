local constants = require("constants")
local vertical_acceleration_coefficient = 150

-- speed: tile per second
for speed = 30, 100, 5 do
    data:extend {
        {
            type = "stream",
            name = "logistic-cannon-capsule-projectile-" .. tostring(speed),
            flags = { "not-on-map" },
            hidden = true,
            oriented_particle = true,
            particle = {
                filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
                width = 64,
                height = 80,
                frame_count = 1,
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
            particle_buffer_size = 1,
            particle_end_alpha = 1,
            particle_fade_out_threshold = 1,
            particle_horizontal_speed = speed / 60,
            particle_horizontal_speed_deviation = 0,
            particle_loop_exit_threshold = 1,
            particle_loop_frame_count = 1,
            particle_spawn_interval = 0,
            particle_spawn_timeout = 1,
            particle_start_alpha = 1,
            particle_start_scale = 1,
            particle_vertical_acceleration = speed / vertical_acceleration_coefficient / 60,
            progress_to_create_smoke = 0.03,
        }
    }
end
