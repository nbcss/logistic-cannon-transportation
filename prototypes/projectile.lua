local constants = require("constants")
local vertical_acceleration_coefficient = 150
local particle_path = "__logistic-cannon-assets__/graphics/entity/projectile/%s.png"
local shadow_path = "__logistic-cannon-assets__/graphics/entity/projectile/capsule-shadow.png"
local capsule_properties = data.raw["mod-data"][constants.data_capsule_properties]
    .data --[[@as table<string, CapsuleProperties?>]]

for _, capsule_data in pairs(capsule_properties) do
    local smoke_name = "smoke-fast"
    if settings.startup[constants.setting_coloring_projectile_smoke].value == true and capsule_data.smoke_color then
        smoke_name = capsule_data.projectile_name .. "-smoke"
        data:extend {
            util.merge { data.raw["trivial-smoke"]["smoke-fast"], {
                name = smoke_name,
                color = capsule_data.smoke_color,
            } }
        }
    end
    local base_speed = capsule_data.speed
    for speed = base_speed, base_speed + 50, 5 do
        data:extend { {
            type = "stream",
            name = string.format(constants.capsule_projectile_format, capsule_data.projectile_name, speed),
            flags = { "not-on-map" },
            hidden = true,
            oriented_particle = true,
            particle = {
                filename = string.format(particle_path, capsule_data.projectile_name),
                width = 64,
                height = 64,
                scale = 0.75,
            },
            shadow = {
                draw_as_shadow = true,
                filename = shadow_path,
                width = 64,
                height = 64,
                scale = 0.75,
            },
            ground_light = {
                color = { 0.8, 0.8, 0.3 },
                intensity = 0.3,
                size = 10
            },
            stream_light = {
                color = { 0.8, 0.8, 0.3 },
                intensity = 1,
                size = 3
            },
            smoke_sources = {
                {
                    name = smoke_name,
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
            progress_to_create_smoke = 1.2 / speed,
        } }
    end
end
