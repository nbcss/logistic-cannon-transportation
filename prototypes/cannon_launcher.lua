local constants = require("constants")
local format = require("scripts.format")
local util = require("util")
local item_sounds = require("__base__.prototypes.item_sounds")
local sounds = require("__base__/prototypes/entity/sounds")
local icon = "__base__/graphics/icons/tank-cannon.png"
local health = 600
local range = 80
local inventory_size = 39
local energy_consumption = 200 * 1000 -- in W
local integration_patch = {
    sheets = {
        {
            filename = "__base__/graphics/entity/logistic-chest/active-provider-chest.png",
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

data.raw["mod-data"][constants.data_launcher_properties].data[constants.entity_launcher_inventory] = {
    range = range,
    energy_consumption = energy_consumption,
} --[[@as LauncherProperties]]

data:extend {
    {
        type = "item",
        name = constants.item_launcher,
        icon = icon,
        icon_size = 64,
        subgroup = constants.item_subgroup,
        order = "a[launcher]",
        place_result = constants.entity_launcher_inventory,
        inventory_move_sound = item_sounds.mechanical_large_inventory_move,
        pick_sound = item_sounds.mechanical_large_inventory_pickup,
        drop_sound = item_sounds.mechanical_large_inventory_move,
        stack_size = 5,
        custom_tooltip_fields = {
            {
                name = { "description.range" },
                value = { "", tostring(range) },
                quality_base_value = range,
                quality_multiplier = "range_multiplier",
                order = 1,
            },
            {
                name = { "description.max-energy-consumption" },
                value = { "", format.energy(energy_consumption, "W") },
                quality_base_value = energy_consumption,
                quality_multiplier = "default_multiplier",
                quality_formatting = setmetatable({}, { __call = function(self, value) return format.energy(value, "W") end }),
                order = 2,
            },
        },
    },
    {
        type = "recipe",
        name = constants.item_launcher,
        enabled = true,
        energy_required = 10,
        ingredients = {
            { type = "item", name = "radar",           amount = 1 },
            { type = "item", name = "steel-plate",     amount = 20 },
            { type = "item", name = "stone-brick",     amount = 10 },
            { type = "item", name = "iron-gear-wheel", amount = 10 },
            { type = "item", name = "engine-unit",     amount = 5 },
        },
        results = {
            { type = "item", name = constants.item_launcher, amount = 1 },
        }
    },
    -- {
    --     type = "lamp",
    --     name = constants.entity_launcher_placement,
    --     icon = "__base__/graphics/icons/tank-cannon.png",
    --     flags = { "player-creation", "placeable-player", "not-on-map" },
    --     localised_name = { "entity-name.logistic-cannon-launcher" },
    --     localised_description = { "entity-description.logistic-cannon-launcher" },
    --     energy_usage_per_tick = "1W",
    --     energy_source = {type = "void"},
    --     always_on = true,
    --     picture_on = {
    --         layers = {
    --             {
    --                 filename = "__base__/graphics/entity/logistic-chest/passive-provider-chest.png",
    --                 priority = "extra-high",
    --                 width = 66,
    --                 height = 74,
    --                 shift = util.by_pixel(0, -2),
    --                 scale = 1.5,
    --                 premul_alpha = false,
    --             }
    --         }
    --     },
    --     quality_affects_inventory_size = true,
    --     selectable_in_game = false,
    --     is_military_target = false,
    --     inventory_type = "normal",
    --     max_health = logistic_cannon_health,
    --     fast_replaceable_group = constants.entity_launcher,
    --     create_ghost_on_death = false,
    --     alert_when_damaged = false,
    --     collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    --     selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    --     -- minable = { mining_time = 1.0, result = "logistic-cannon-launcher" },
    --     -- placeable_by = { item = "logistic-cannon-launcher", count = 1 },
    --     created_effect = {
    --         type = "direct",
    --         action_delivery = {
    --             type = "instant",
    --             target_effects = {
    --                 type = "script",
    --                 effect_id = "create-logistic-cannon-launcher",
    --             }
    --         }
    --     },
    -- },
    {
        type = "container",
        name = constants.entity_launcher_inventory,
        icon = icon,
        flags = { "player-creation", "placeable-player" },
        map_color = { 0.9, 0.1, 0.1 },
        minable = { mining_time = 1.0, result = constants.item_launcher },
        placeable_by = { item = constants.item_launcher, count = 1 },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        max_health = health,
        circuit_wire_max_distance = 9,
        inventory_type = "with_filters_and_bar",
        inventory_size = inventory_size,
        quality_affects_inventory_size = true,
        render_not_in_network_icon = false,
        is_military_target = false,
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = { filename = "__base__/sound/open-close/silo-open.ogg", volume = 0.7 },
        close_sound = { filename = "__base__/sound/open-close/silo-close.ogg", volume = 0.7 },
        integration_patch_render_layer = "lower-object",
        integration_patch = integration_patch,
        -- stateless_visualisation = {
        --     animation = {
        --         sheets = {
        --             {
        --                 filename = "__base__/graphics/entity/logistic-chest/active-provider-chest.png",
        --                 frame_count = 7,
        --                 animation_speed = 7 / 60,
        --                 variation_count = 1,
        --                 priority = "extra-high",
        --                 width = 66,
        --                 height = 74,
        --                 shift = util.by_pixel(0, -2),
        --                 scale = 1.5
        --             },
        --         }
        --     },
        --     render_layer = "object-under",
        --     -- period = 7,
        --     begin_scale = 1.0,
        --     end_scale = 0,
        --     can_lay_on_the_ground = false,
        -- },
        -- draw_stateless_visualisations_in_ghost = true,
    },
    {
        type = "proxy-container",
        name = constants.entity_launcher_gui_proxy,
        icon = icon,
        flags = { "not-on-map", "placeable-off-grid", "hide-alt-info" },
        localised_name = { "entity-name." .. constants.entity_launcher_inventory },
        localised_description = { "entity-description." .. constants.entity_launcher_inventory },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        collision_mask = {layers = {}},
        quality_indicator_scale = 0,
        draw_inventory_content = false,
        is_military_target = false,
        selectable_in_game = false,
        hidden = true,
        max_health = health,
        open_sound = { filename = "__base__/sound/open-close/silo-open.ogg", volume = 0.7 },
        close_sound = { filename = "__base__/sound/open-close/silo-close.ogg", volume = 0.7 },
        integration_patch_render_layer = "zero",
        integration_patch = integration_patch,
    },
    {
        type = "electric-energy-interface",
        name = constants.entity_launcher_energy_interface,
        icon = icon,
        flags = { "not-on-map", "placeable-off-grid", "hide-alt-info" },
        localised_name = { "entity-name." .. constants.entity_launcher_inventory },
        localised_description = { "entity-description." .. constants.entity_launcher_inventory },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        quality_indicator_scale = 0,
        selectable_in_game = false,
        hidden = true,
        selection_priority = 1,
        energy_source = {
            type = "electric",
            buffer_capacity = "0J",
            usage_priority = "secondary-input",
            input_flow_limit = energy_consumption .. "W",
            output_flow_limit = "0W",
            -- drain = "50kW",
        }
    },
    {
        type = "ammo-turret",
        name = constants.entity_launcher_turret,
        icon = icon,
        -- icon_size = 64,
        flags = { "not-on-map", "placeable-off-grid", "hide-alt-info" },
        localised_name = { "entity-name.logistic-cannon-launcher" },
        localised_description = { "entity-description.logistic-cannon-launcher" },
        quality_indicator_scale = 0,
        selectable_in_game = false,
        is_military_target = false,
        shoot_in_prepare_state = true,
        hidden = true,
        max_health = health,
        circuit_wire_max_distance = 1,
        draw_circuit_wires = false,
        prepare_range = 2,
        attack_target_mask = { constants.entity_target },
        rotation_speed = 0.15 / 60,
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
                    filename = "__base__/graphics/entity/tank/tank-turret.png",
                    priority = "low",
                    line_length = 8,
                    width = 179,
                    height = 132,
                    direction_count = 64,
                    shift = util.by_pixel(2.25 - 2, -40.5 +4),
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
                    shift = util.by_pixel(2 - 2, -41.5 +4),
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
                    shift = util.by_pixel(58.25 - 2, 0.5 +4),
                    scale = 0.5
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
            ammo_category = constants.ammo_category,
            cooldown = 60,
            movement_slow_down_factor = 0,
            projectile_creation_distance = 1.15,
            projectile_center = { 0, -1 },
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
    -- {
    --     type = "decider-combinator",
    --     name = "test-combinator",
    --     flags = { "placeable-player", "player-creation", "hide-alt-info" },
    --     icon = "__base__/graphics/icons/tank-cannon.png",
    --     -- minable = { mining_time = 1.0, result = "logistic-cannon-launcher" },
    --     -- placeable_by = { item = "logistic-cannon-launcher", count = 1 },
    --     energy_source = { type = "void" },
    --     active_energy_usage = "1W",
    --     collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    --     selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    --     input_connection_bounding_box = { { 0, 1 }, { 0, 1 } },
    --     output_connection_bounding_box = { { -1.5, -1.5 }, { 1.5, 1.532 } },
    --     input_connection_points = {
    --         { wire = {}, shadow = {} },
    --         { wire = {}, shadow = {} },
    --         { wire = {}, shadow = {} },
    --         { wire = {}, shadow = {} },
    --     },
    --     output_connection_points = {
    --         { wire = {}, shadow = {} },
    --         { wire = {}, shadow = {} },
    --         { wire = {}, shadow = {} },
    --         { wire = {}, shadow = {} },
    --     },
    --     circuit_wire_max_distance = 9,
    --     activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
    --     screen_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
    --     activity_led_hold_time = 0,
    --     equal_symbol_sprites = integration_patch,
    --     greater_symbol_sprites = integration_patch,
    --     less_symbol_sprites = integration_patch,
    --     not_equal_symbol_sprites = integration_patch,
    --     greater_or_equal_symbol_sprites = integration_patch,
    --     less_or_equal_symbol_sprites = integration_patch,
    -- },
}
