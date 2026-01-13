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
local launcher_simulation = [[
    game.simulation.camera_zoom = 2
    game.simulation.camera_position = {0.5, -0.25}
    local proxy = game.surfaces[1].create_entity{name = "]] .. constants.entity_launcher_turret .. [[", 
        position = {0.5, 0.5}, force = "player", direction = defines.direction.east}
]]

local base_animation = {
    north = {
        layers = {
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-base-0.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-connector.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
        },
    },
    east = {
        layers = {
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-base-1.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-connector.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
        },
    },
    south = {
        layers = {
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-base-2.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-connector.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
        },
    },
    west = {
        layers = {
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-base-3.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
            {
                filename = "__logistic-cannon-transportation__/graphics/entity/launcher-connector.png",
                priority = "high",
                width = 384,
                height = 384,
                shift = util.by_pixel(0, -29),
                scale = 0.5,
            },
        },
    },
} --[[@as data.Animation4Way]]

local launcher_raising_animation = {
    filename = "__logistic-cannon-transportation__/graphics/entity/launcher-raising.png",
    priority = "very-low",
    width = 384,
    height = 384,
    frame_count = 15,
    direction_count = 8,
    shift = util.by_pixel(0, -29),
    scale = 0.5,
} --[[@as data.RotatedAnimation]]

local launcher_shooting_animation = {
    filename = "__logistic-cannon-transportation__/graphics/entity/launcher-shooting.png",
    priority = "very-low",
    width = 384,
    height = 384,
    direction_count = 64,
    line_length = 8,
    shift = util.by_pixel(0, -29),
    scale = 0.5,
} --[[@as data.RotatedAnimation]]

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
        energy_required = 10,
        ingredients = {
            { type = "item", name = "radar",           amount = 1 },
            { type = "item", name = "steel-plate",     amount = 20 },
            { type = "item", name = "concrete",        amount = 10 },
            { type = "item", name = "iron-gear-wheel", amount = 10 },
            { type = "item", name = "engine-unit",     amount = 5 },
        },
        results = {
            { type = "item", name = constants.item_launcher, amount = 1 },
        }
    },
    {
        type = "container",
        name = constants.entity_launcher_inventory,
        icon = icon,
        flags = { "player-creation", "placeable-player", "no-automated-item-removal", "not-rotatable" },
        map_color = { 0.9, 0.1, 0.1 },
        minable = { mining_time = 1.0, result = constants.item_launcher },
        placeable_by = { item = constants.item_launcher, count = 1 },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        max_health = health,
        circuit_wire_max_distance = 9,
        circuit_connector = {
            points = {
                wire = { red = util.by_pixel(35, 9), green = util.by_pixel(30, 12) },
                shadow = { red = util.by_pixel(55, 29), green = util.by_pixel(50, 32) },
            },
        },
        inventory_type = "with_filters_and_bar",
        inventory_size = inventory_size,
        quality_affects_inventory_size = true,
        render_not_in_network_icon = false,
        is_military_target = false,
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = { filename = "__base__/sound/open-close/silo-open.ogg", volume = 0.7 },
        close_sound = { filename = "__base__/sound/open-close/silo-close.ogg", volume = 0.7 },
        integration_patch_render_layer = "object-under",
        integration_patch = base_animation,
        factoriopedia_simulation = { init = launcher_simulation },
    },
    {
        type = "proxy-container",
        name = constants.entity_launcher_gui_proxy,
        icon = icon,
        flags = { "not-on-map", "placeable-off-grid", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion" },
        localised_name = { "entity-name." .. constants.entity_launcher_inventory },
        localised_description = { "entity-description." .. constants.entity_launcher_inventory },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        collision_mask = { layers = {} },
        quality_indicator_scale = 0,
        draw_inventory_content = false,
        is_military_target = false,
        selectable_in_game = false,
        hidden = true,
        selection_priority = 50,
        max_health = health,
        open_sound = { filename = "__base__/sound/open-close/silo-open.ogg", volume = 0.7 },
        close_sound = { filename = "__base__/sound/open-close/silo-close.ogg", volume = 0.7 },
        stateless_visualisation = {
            render_layer = "zero",
            animation = {
                sheets = {
                    util.merge { base_animation.north.layers[1], {
                        variation_count = 1,
                        frame_count = 1,
                        repeat_count = 64,
                        animation_speed = 0.35,
                    } },
                    util.merge { base_animation.north.layers[2], {
                        variation_count = 1,
                        frame_count = 1,
                        repeat_count = 64,
                        animation_speed = 0.35,
                    } },
                    util.merge { launcher_shooting_animation, {
                        variation_count = 1,
                        frame_count = 64,
                        animation_speed = 0.35,
                    } },
                }
            }
        },
    },
    {
        type = "proxy-container",
        name = constants.entity_launcher_ammo_proxy,
        icon = icon,
        flags = { "not-on-map", "placeable-off-grid", "hide-alt-info" },
        localised_name = { "entity-name." .. constants.entity_launcher_inventory },
        localised_description = { "entity-description." .. constants.entity_launcher_inventory },
        selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        quality_indicator_scale = 0,
        draw_inventory_content = false,
        is_military_target = false,
        selectable_in_game = false,
        hidden = true,
        selection_priority = 1,
        max_health = health,
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
        prepare_range = 1,
        attack_target_mask = { constants.entity_target },
        rotation_speed = 0.3 / 60,
        preparing_speed = 0.08,
        preparing_sound = sounds.gun_turret_activate,
        folding_sound = sounds.gun_turret_deactivate,
        folding_speed = 0.08,
        attacking_speed = 0.08,
        ending_attack_speed = 0.08,
        inventory_size = 1,
        automated_ammo_count = 5,
        alert_when_attacking = false,
        turret_base_has_direction = true,
        gun_animation_render_layer = "above-inserters",
        can_retarget_while_starting_attack = true,
        allow_turning_when_starting_attack = true,
        folded_animation = {
            layers = {
                launcher_shooting_animation,
            }
            -- layers = {
            --     util.merge{launcher_raising_animation, {
            --         frame_count = 1,
            --         line_length = 1,
            --     }}
            -- }
        },
        -- starting_attack_animation = {
        --     layers = {
        --         launcher_raising_animation,
        --     }
        -- },
        -- ending_attack_animation = {
        --     layers = {
        --         util.merge{launcher_raising_animation, {
        --             run_mode = "backward",
        --         }}
        --     }
        -- },
        prepared_animation = {
            layers = {
                launcher_shooting_animation
            }
        },
        graphics_set = {
            base_visualisation = {
                render_layer = "object",
                animation = base_animation
            }
        },
        attack_parameters = {
            type = "projectile",
            ammo_category = constants.ammo_category,
            cooldown = 60,
            movement_slow_down_factor = 0,
            health_penalty = 0,
            rotate_penalty = 0,
            ammo_consumption_modifier = 0,
            range = 0,
            sound = sounds.tank_gunshot
        },
        call_for_help_radius = 0,
    },
}
