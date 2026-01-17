local constants = require("constants")
local util = require("util")
local sounds = require("__base__/prototypes/entity/sounds")
local item_sounds = require("__base__.prototypes.item_sounds")
local icon = "__base__/graphics/icons/requester-chest.png"
local health = 500
local inventory_size = 59

local container_animation = {
    layers = {
        util.sprite_load("__logistic-cannon-transportation__/graphics/entity/receiver/receiver-base", {
            priority = "extra-high",
            scale = 0.5,
        }),
        util.sprite_load("__logistic-cannon-transportation__/graphics/entity/receiver/receiver-base-shadow", {
            draw_as_shadow = true,
            priority = "extra-high",
            scale = 0.5,
        }),
    }
} --[[@as data.Animation]]

data:extend {
    {
        type = "item",
        name = constants.item_receiver,
        icon = icon,
        icon_size = 64,
        subgroup = constants.item_subgroup,
        order = "b[receiver]",
        place_result = constants.entity_receiver_inventory,
        inventory_move_sound = item_sounds.turret_inventory_move,
        pick_sound = item_sounds.turret_inventory_pickup,
        drop_sound = item_sounds.turret_inventory_move,
        stack_size = 5,
    },
    {
        type = "recipe",
        name = constants.item_receiver,
        enabled = false,
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
        flags = { "player-creation", "placeable-player", "no-automated-item-insertion" },
        map_color = { 0.1, 0.8, 0.9 },
        minable = { mining_time = 0.5, result = constants.item_receiver },
        placeable_by = { item = constants.item_receiver, count = 1 },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        selection_priority = 50,
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
                wire = { red = util.by_pixel(35, 18), green = util.by_pixel(28, 19) },
                shadow = { red = util.by_pixel(55, 38), green = util.by_pixel(48, 39) },
            },
        },
        mined_sound = sounds.deconstruct_large(0.8),
        open_sound = { filename = "__base__/sound/open-close/silo-open.ogg", volume = 0.7 },
        close_sound = { filename = "__base__/sound/open-close/silo-close.ogg", volume = 0.7 },
        picture = container_animation,
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
        selection_priority = 1,
        draw_inventory_content = false,
        is_military_target = false,
        selectable_in_game = false,
        hidden = true,
        max_health = health,
        open_sound = { filename = "__base__/sound/open-close/silo-open.ogg", volume = 0.7 },
        close_sound = { filename = "__base__/sound/open-close/silo-close.ogg", volume = 0.7 },
        stateless_visualisation = {
            render_layer = "zero",
            animation = {
                layers = {
                    util.merge { container_animation.layers[2], {
                        draw_as_shadow = false,
                    }},
                    container_animation.layers[1],
                }
            }
        },
    },
}
