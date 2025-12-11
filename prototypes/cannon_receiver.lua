local sounds = require("__base__/prototypes/entity/sounds")

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
        name = "logistic-cannon-receiver",
        icon = "__base__/graphics/icons/requester-chest.png",
        icon_size = 64,
        subgroup = "transport",
        -- order = "b[turret]-a[gun-turret]-a",
        place_result = "logistic-cannon-receiver",
        stack_size = 5,
        -- custom_tooltip_fields = { },
    },
    {
        type = "recipe",
        name = "logistic-cannon-receiver",
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "steel-plate", amount = 5 },
        },
        results = {
            { type = "item", name = "logistic-cannon-receiver", amount = 1 },
        }
    },
    {
        type = "container",
        name = "logistic-cannon-receiver-entity",
        icon = "__base__/graphics/icons/requester-chest.png",
        flags = {"placeable-player", "player-creation", "placeable-off-grid" },
        localised_name = {"entity-name.logistic-cannon-receiver"},
        localised_description = {"entity-description.logistic-cannon-receiver"},
        -- logistic_mode = "passive-provider",
        inventory_size = 50,
        render_not_in_network_icon = false,
        picture = container_animation,
        quality_affects_inventory_size = true,
        open_sound = sounds.metallic_chest_open,
        close_sound = sounds.metallic_chest_close,
        inventory_type = "normal",
        is_military_target = false,
        max_health = 600,
        collision_mask = {layers={}},
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { 0, 0 }, { 0, 0 } },
        selectable_in_game = false,
        quality_indicator_scale = 0,
    },
    {
        type = "proxy-container",
        name = "logistic-cannon-receiver",
        draw_inventory_content = true,
        is_military_target = false,
        max_health = 600,
        icon = "__base__/graphics/icons/requester-chest.png",
        minable = { mining_time = 1.0, result = "logistic-cannon-receiver" },
        collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
        selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
        -- collision_mask = { layers = { item = true, meltable = true, object = true, player = true, water_tile = true, is_object = true, is_lower_object = true } },
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
                    effect_id = "create-logistic-cannon-receiver",
                }
            }
        },
    },
}