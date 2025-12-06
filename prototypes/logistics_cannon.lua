local sounds = require("__base__/prototypes/entity/sounds")
local logistic_cannon_health = 600
local turret_shift_y = 12

data:extend {
    {
        type = "item",
        name = "logistic-cannon",
        icon = "__base__/graphics/icons/tank-cannon.png",
        icon_size = 64,
        subgroup = "transport",
        -- order = "b[turret]-a[gun-turret]-a",
        place_result = "logistic-cannon-container",
        stack_size = 10
    },
    {
        type = "gun",
        name = "logistic-cannon-gun",
        icon = "__base__/graphics/icons/tank-cannon.png",
        hidden = true,
        auto_recycle = false,
        subgroup = "gun",
        order = "z[tank]-a[cannon]",
        stack_size = 1,
        attack_parameters = {
            type = "projectile",
            ammo_categories = { "logistic-cannon-capsule" },
            cooldown = 60,
            movement_slow_down_factor = 0,
            projectile_creation_distance = 1.15,
            projectile_center = { 0, -0.85 },
            health_penalty = 0,
            rotate_penalty = 0,
            range = 100,
            sound = sounds.tank_gunshot
        },
    },
    {
        type = "car",
        name = "logistic-cannon-entity",
        icon = "__base__/graphics/icons/tank-cannon.png",
        auto_sort_inventory = false,
        equipment_grid = nil,
        inventory_size = 50,
        trash_inventory_size = 0,
        turret_rotation_speed = 0.35 / 60,
        turret_return_timeout = 4294967295,
        flags = { "not-on-map", "not-rotatable", "placeable-player" },
        guns = { "logistic-cannon-gun" },
        allow_passengers = true, -- required for auto-control turret
        allow_remote_driving = false,
        is_military_target = false,
        max_health = logistic_cannon_health,
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { 0, 0 }, { 0, 0 } },
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        -- hidden = true,
        turret_animation = {
            layers = {
                {
                    filename = "__base__/graphics/entity/tank/tank-turret.png",
                    priority = "low",
                    line_length = 8,
                    width = 179,
                    height = 132,
                    direction_count = 64,
                    shift = util.by_pixel(2.25 - 2, -40.5 + turret_shift_y),
                    animation_speed = 8,
                    scale = 0.5
                },
                {
                    filename = "__base__/graphics/entity/tank/tank-turret-mask.png",
                    priority = "low",
                    line_length = 8,
                    width = 72,
                    height = 66,
                    apply_runtime_tint = true,
                    direction_count = 64,
                    shift = util.by_pixel(2 - 2, -41.5 + turret_shift_y),
                    scale = 0.5
                },
                {
                    filename = "__base__/graphics/entity/tank/tank-turret-shadow.png",
                    priority = "low",
                    line_length = 8,
                    width = 193,
                    height = 134,
                    draw_as_shadow = true,
                    direction_count = 64,
                    shift = util.by_pixel(58.25 - 2, 0.5 + turret_shift_y),
                    scale = 0.5
                }
            }
        },
        animation = {
            layers = {
                {
                    filename = "__base__/graphics/entity/logistic-chest/passive-provider-chest.png",
                    priority = "extra-high",
                    width = 66,
                    height = 74,
                    frame_count = 7,
                    shift = util.by_pixel(0, -2),
                    scale = 1.5
                },
                {
                    filename = "__base__/graphics/entity/logistic-chest/logistic-chest-shadow.png",
                    priority = "extra-high",
                    width = 112,
                    height = 46,
                    repeat_count = 7,
                    shift = util.by_pixel(0, 4.5),
                    draw_as_shadow = true,
                    scale = 1.5
                }
            }
        },
        -- created_effect = {
        --     type = "direct",
        --     action_delivery = {
        --         type = "instant",
        --         target_effects = {
        --             type = "script",
        --             effect_id = "create-logistic-cannon",
        --         }
        --     }
        -- },
        -- unused properties
        effectivity = 1.0,
        consumption = "0W",
        rotation_speed = 0,
        rotation_snap_angle = 0.01,
        energy_source = { type = "void" },
        weight = 1000,
        braking_power = "1J",
        friction = 1.0,
        energy_per_hit_point = 1.0,
    },
    {
        type = "proxy-container",
        name = "logistic-cannon-container",
        draw_inventory_content = true,
        is_military_target = false,
        max_health = logistic_cannon_health,
        icon = "__base__/graphics/icons/tank-cannon.png",
        minable = { mining_time = 1.0, result = "logistic-cannon" },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        circuit_wire_max_distance = default_circuit_wire_max_distance,
        created_effect = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = "create-logistic-cannon",
                }
            }
        },
    },
}
