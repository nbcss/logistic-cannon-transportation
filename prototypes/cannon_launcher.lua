local util = require("__core__.lualib.util")
local sounds = require("__base__/prototypes/entity/sounds")
local logistic_cannon_health = 600
local turret_shift_y = 12
local delivery_range = 100
local storage_size = 50
local container_animation = {
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
            shift = util.by_pixel(12, 4.5),
            draw_as_shadow = true,
            scale = 1.5
        }
    }
}

data:extend {
    {
        type = "item",
        name = "logistic-cannon-launcher",
        icon = "__base__/graphics/icons/tank-cannon.png",
        icon_size = 64,
        subgroup = "transport",
        -- order = "b[turret]-a[gun-turret]-a",
        place_result = "logistic-cannon-launcher",
        stack_size = 5,
        custom_tooltip_fields = {
            {
                name = { "description.range" },
                value = { "", tostring(delivery_range) },
                quality_base_value = delivery_range,
                quality_multiplier = "range_multiplier",
            },
            {
                name = { "description.storage-size" },
                value = { "", tostring(storage_size) },
            }
        },
    },
    {
        type = "recipe",
        name = "logistic-cannon-launcher",
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "steel-plate", amount = 5 },
        },
        results = {
            { type = "item", name = "logistic-cannon-launcher", amount = 1 },
        }
    },
    {
        type = "gun",
        name = "logistic-cannon-gun",
        icon = "__base__/graphics/icons/tank-cannon.png",
        localised_name = {"item-name.logistic-cannon-launcher"},
        localised_description = {"item-description.logistic-cannon-launcher"},
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
            range = delivery_range,
            sound = sounds.tank_gunshot
        },
    },
    {
        type = "car",
        name = "logistic-cannon-launcher-entity",
        icon = "__base__/graphics/icons/tank-cannon.png",
        localised_name = {"entity-name.logistic-cannon-launcher"},
        localised_description = {"entity-description.logistic-cannon-launcher"},
        auto_sort_inventory = false,
        equipment_grid = nil,
        inventory_size = storage_size,
        trash_inventory_size = 0,
        turret_rotation_speed = 0.35 / 60,
        turret_return_timeout = 4294967295,
        flags = { "not-on-map", "not-rotatable", "placeable-player", "placeable-off-grid" },
        guns = { "logistic-cannon-gun" },
        allow_passengers = true, -- required for auto-control turret
        allow_remote_driving = false,
        is_military_target = false,
        max_health = logistic_cannon_health,
        collision_box = { { 0, 0 }, { 0, 0 } },
        selection_box = { { 0, 0 }, { 0, 0 } },
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        quality_indicator_scale = 0,
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
        animation = container_animation,
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
        name = "logistic-cannon-launcher",
        draw_inventory_content = true,
        is_military_target = false,
        max_health = logistic_cannon_health,
        icon = "__base__/graphics/icons/tank-cannon.png",
        minable = { mining_time = 1.0, result = "logistic-cannon-launcher" },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        collision_mask = { layers = { item = true, meltable = true, object = true, player = true, water_tile = true, is_object = true, is_lower_object = true } },
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        circuit_wire_max_distance = 9,
        picture = container_animation,
        created_effect = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = "create-logistic-cannon-launcher",
                }
            }
        },
    },
}
