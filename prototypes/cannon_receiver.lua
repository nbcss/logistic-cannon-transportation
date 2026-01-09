local constants = require("constants")
local sounds = require("__base__/prototypes/entity/sounds")
local item_sounds = require("__base__.prototypes.item_sounds")
local icon = "__base__/graphics/icons/requester-chest.png"
local health = 400
local inventory_size = 59

local container_animation = {
    layers = {
        {
            filename = "__logistic-cannon-transportation__/graphics/entity/receiver-base.png",
            priority = "extra-high",
            width = 192,
            height = 230,
            shift = util.by_pixel(0, -9.5),
            scale = 0.5
        },
    }
}

data:extend {
    {
        type = "item",
        name = constants.item_receiver,
        icon = icon,
        icon_size = 64,
        subgroup = constants.item_subgroup,
        order = "b[receiver]",
        place_result = constants.entity_receiver_inventory,
        inventory_move_sound = item_sounds.mechanical_large_inventory_move,
        pick_sound = item_sounds.mechanical_large_inventory_pickup,
        drop_sound = item_sounds.mechanical_large_inventory_move,
        stack_size = 5,
    },
    {
        type = "recipe",
        name = constants.item_receiver,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "steel-plate",        amount = 20 },
            { type = "item", name = "concrete",           amount = 10 },
            { type = "item", name = "electronic-circuit", amount = 10 },
            { type = "item", name = "iron-stick",         amount = 2 },
        },
        results = {
            { type = "item", name = constants.item_receiver, amount = 1 },
        }
    },
    {
        type = "container",
        name = constants.entity_receiver_inventory,
        icon = icon,
        flags = { "player-creation", "placeable-player" },
        map_color = { 0.1, 0.8, 0.9 },
        minable = { mining_time = 1.0, result = constants.item_receiver },
        placeable_by = { item = constants.item_receiver, count = 1 },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        default_status = "working",
        max_health = health,
        inventory_type = "with_bar",
        inventory_size = inventory_size,
        quality_affects_inventory_size = true,
        render_not_in_network_icon = false,
        is_military_target = false,
        circuit_wire_max_distance = 9,
        circuit_connector = {
            points = {
                wire = { red = util.by_pixel(37, 25), green = util.by_pixel(30, 28) },
                shadow = { red = util.by_pixel(57, 45), green = util.by_pixel(50, 48) },
            },
        },
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = sounds.mech_large_open,
        close_sound = sounds.mech_large_close,
        picture = container_animation,
        created_effect = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = "create-logistic-cannon-receiver",
                }
            }
        },
    },
    {
        type = "proxy-container",
        name = constants.entity_receiver_gui_proxy,
        icon = icon,
        flags = { "not-on-map", "placeable-off-grid", "no-automated-item-removal", "no-automated-item-insertion" },
        localised_name = { "entity-name." .. constants.entity_receiver_inventory },
        localised_description = { "entity-description." .. constants.entity_receiver_inventory },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        collision_mask = { layers = {} },
        quality_indicator_scale = 0,
        draw_inventory_content = false,
        is_military_target = false,
        selectable_in_game = false,
        hidden = true,
        max_health = health,
        open_sound = sounds.mech_large_open,
        close_sound = sounds.mech_large_close,
        picture = container_animation,
    },
}
