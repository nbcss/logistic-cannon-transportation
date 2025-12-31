local constants = require("constants")
local sounds = require("__base__/prototypes/entity/sounds")
local icon = "__base__/graphics/icons/requester-chest.png"
local health = 400
local inventory_size = 100

local container_animation = {
    layers = {
        {
            filename = "__base__/graphics/entity/logistic-chest/requester-chest.png",
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

data:extend{
    {
        type = "item",
        name = constants.item_receiver,
        icon = icon,
        icon_size = 64,
        subgroup = constants.item_subgroup,
        order = "b[receiver]",
        place_result = constants.entity_receiver_inventory,
        stack_size = 5,
    },
    {
        type = "recipe",
        name = constants.item_receiver,
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "radar", amount = 1 },
            { type = "item", name = "steel-plate", amount = 20 },
            { type = "item", name = "stone-brick", amount = 10 },
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
        map_color = {0.1, 0.8, 0.9},
        minable = { mining_time = 1.0, result = constants.item_receiver },
        placeable_by = { item = constants.item_receiver, count = 1 },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        max_health = health,
        circuit_wire_max_distance = 9,
        inventory_type = "normal",
        inventory_size = inventory_size,
        quality_affects_inventory_size = true,
        render_not_in_network_icon = false,
        is_military_target = false,
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
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
        flags = { "not-on-map", "placeable-off-grid" },
        localised_name = {"entity-name." .. constants.entity_receiver_inventory},
        localised_description = {"entity-description." .. constants.entity_receiver_inventory},
        quality_indicator_scale = 0,
        draw_inventory_content = false,
        is_military_target = false,
        selectable_in_game = false,
        max_health = health,
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        picture = container_animation,
    },
}