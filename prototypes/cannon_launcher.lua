local constants = require("constants")
local util = require("util")
local sounds = require("__base__/prototypes/entity/sounds")
local logistic_cannon_health = 600
local delivery_range = 100
local storage_size = 80
local integration_patch = {
    sheets = {
        {
            filename = "__base__/graphics/entity/logistic-chest/passive-provider-chest.png",
            priority = "extra-high",
            width = 66,
            height = 74,
            shift = util.by_pixel(0, -2),
            scale = 1.5
        },
    }
}
local container_animation = {
    layers = {
        {
            filename = "__base__/graphics/entity/logistic-chest/passive-provider-chest.png",
            priority = "extra-high",
            width = 66,
            height = 74,
            shift = util.by_pixel(0, -2),
            scale = 1.5
        },
        {
            filename = "__base__/graphics/entity/logistic-chest/logistic-chest-shadow.png",
            priority = "extra-high",
            width = 112,
            height = 46,
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
        place_result = constants.entity_launcher_placement,
        stack_size = 5,
        custom_tooltip_fields = {
            {
                name = { "description.range" },
                value = { "", tostring(delivery_range) },
                quality_base_value = delivery_range,
                quality_multiplier = "range_multiplier",
            },
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
        type = "container",
        name = constants.entity_launcher_placement,
        icon = "__base__/graphics/icons/tank-cannon.png",
        flags = { "placeable-player" },
        localised_name = { "entity-name.logistic-cannon-launcher" },
        localised_description = { "entity-description.logistic-cannon-launcher" },
        inventory_size = storage_size,
        picture = container_animation,
        quality_affects_inventory_size = true,
        inventory_type = "normal",
        max_health = logistic_cannon_health,
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { 0, 0 }, { 0, 0 } },
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
    {
        type = "container",
        name = constants.entity_launcher_inventory,
        icon = "__base__/graphics/icons/tank-cannon.png",
        flags = { "placeable-player", "placeable-off-grid" },
        localised_name = { "entity-name.logistic-cannon-launcher" },
        localised_description = { "entity-description.logistic-cannon-launcher" },
        map_color = { 0.9, 0.1, 0.1 },
        minable = { mining_time = 1.0, result = "logistic-cannon-launcher" },
        mined_sound = sounds.deconstruct_large(0.8),
        placeable_by = { item = "logistic-cannon-launcher", count = 1 },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        circuit_wire_max_distance = 9,
        -- logistic_mode = "passive-provider",
        inventory_size = storage_size,
        render_not_in_network_icon = false,
        integration_patch_render_layer = "zero",
        integration_patch = integration_patch,
        quality_affects_inventory_size = true,
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        inventory_type = "normal",
        is_military_target = false,
        quality_indicator_scale = 0,
    },
    {
        type = "proxy-container",
        name = constants.entity_launcher_gui_proxy,
        draw_inventory_content = true,
        is_military_target = false,
        max_health = logistic_cannon_health,
        flags = { "player-creation", "not-selectable-in-game" },
        localised_name = { "entity-name.logistic-cannon-launcher" },
        localised_description = { "entity-description.logistic-cannon-launcher" },
        -- map_color = { 0.9, 0.1, 0.1 },
        icon = "__base__/graphics/icons/tank-cannon.png",
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        integration_patch_render_layer = "zero",
        integration_patch = integration_patch,
    },
    {
        type = "electric-energy-interface",
        name = constants.entity_launcher_energy_interface,
        icon = "__base__/graphics/icons/tank-cannon.png",
        localised_name = { "entity-name.logistic-cannon-launcher" },
        localised_description = { "entity-description.logistic-cannon-launcher" },
        hidden = true,
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        selection_priority = 1,
        flags = { "not-on-map", "not-rotatable", "not-blueprintable", "placeable-player", "placeable-off-grid", "not-selectable-in-game" },
        energy_source = {
            type = "electric",
            buffer_capacity = "0kJ",
            usage_priority = "secondary-input",
            input_flow_limit = "200kW",
            output_flow_limit = "0W",
            -- drain = "50kW",
        }
    },
    {
        type = "ammo-turret",
        name = constants.entity_launcher_turret,
        icon = "__base__/graphics/icons/tank-cannon.png",
        -- icon_size = 64,
        flags = { "placeable-player", "placeable-off-grid" },
        localised_name = { "entity-name.logistic-cannon-launcher" },
        localised_description = { "entity-description.logistic-cannon-launcher" },
        max_health = logistic_cannon_health,
        is_military_target = false,
        shoot_in_prepare_state = true,
        prepare_range = 2,
        -- collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { 2, 0 }, { 3, 1 } }, -- FIXME remove this after gui complete
        rotation_speed = 0.1 / 60,
        preparing_speed = 0.08,
        preparing_sound = sounds.gun_turret_activate,
        folding_sound = sounds.gun_turret_deactivate,
        folding_speed = 0.08,
        inventory_size = 1,
        automated_ammo_count = 5,
        alert_when_attacking = false,
        turret_base_has_direction = true,
        folded_animation = {
            layers = {
                {
                    filename = "__aai-vehicles-ironclad__/graphics/entity/mortar-turret/mortar-turret.png",
                    priority = "low",
                    line_length = 16,
                    width = 2048 / 16,
                    height = 448 / 4,
                    frame_count = 1,
                    direction_count = 64,
                    shift = util.by_pixel(0, -28),
                    animation_speed = 8,
                    scale = 0.65
                },
                {
                    filename = "__aai-vehicles-ironclad__/graphics/entity/mortar-turret/mortar-turret-mask.png",
                    priority = "low",
                    line_length = 16,
                    width = 2048 / 16,
                    height = 448 / 4,
                    frame_count = 1,
                    apply_runtime_tint = true,
                    direction_count = 64,
                    shift = util.by_pixel(0, -28),
                    scale = 0.65
                },
                {
                    filename = "__aai-vehicles-ironclad__/graphics/entity/mortar-turret/mortar-turret-shadow.png",
                    priority = "low",
                    line_length = 4,
                    width = 672 / 4,
                    height = 1472 / 16,
                    frame_count = 1,
                    draw_as_shadow = true,
                    direction_count = 64,
                    shift = util.by_pixel(20, -3.5),
                    scale = 0.65
                }
            }
        },
        graphics_set = {
            base_visualisation = {
                animation = container_animation
            }
        },
        attack_parameters = {
            type = "projectile",
            ammo_category = "logistic-cannon-capsule",
            cooldown = 60,
            movement_slow_down_factor = 0,
            projectile_creation_distance = 1.15,
            projectile_center = { 0, -0.85 },
            health_penalty = 0,
            rotate_penalty = 0,
            range = 0,
            sound = sounds.tank_gunshot
        },
        call_for_help_radius = 0,
        water_reflection = {
            pictures = {
                filename = "__base__/graphics/entity/gun-turret/gun-turret-reflection.png",
                priority = "extra-high",
                width = 20,
                height = 32,
                shift = util.by_pixel(0, 40),
                variation_count = 1,
                scale = 5
            },
            rotate = false,
            orientation_to_variation = false
        },
    },
}
