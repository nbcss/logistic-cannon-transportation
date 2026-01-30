local constants = require("constants")

data.extend {
    util.merge { data.raw["highlight-box"]["highlight-box"], {
        name = "lct-highlight-box",
        hidden = true,
    } },
    {
        type = "font",
        name = "lct-negative-effect",
        from = "lct-negative-effect",
        size = 14
    },
    {
        type = "custom-input",
        name = constants.rotate_input_event,
        key_sequence = "",
        linked_game_control = "rotate",
    },
    {
        type = "custom-input",
        name = constants.reverse_rotate_input_event,
        key_sequence = "",
        linked_game_control = "reverse-rotate",
    },
    {
        type = "sound",
        name = constants.capsule_landed_sound,
        category = "environment",
        filename = "__logistic-cannon-transportation__/sounds/capsule-landed.ogg",
        volume = 0.4,
        aggregation = {
            max_count = 1,
            remove = false,
        }
    },
    {
        type = "ammo-category",
        name = constants.ammo_category,
        icon = "__logistic-cannon-transportation__/graphics/icons/capsule-category.png",
        subgroup = "ammo-category",
    },
    {
        type = "item-subgroup",
        name = constants.item_subgroup,
        group = "logistics",
        order = "z-cannon",
    },
    {
        type = "trigger-target-type",
        name = constants.entity_target,
    },
    {
        type = "simple-entity-with-owner",
        name = constants.entity_target,
        flags = { "not-on-map", "placeable-off-grid" },
        trigger_target_mask = { constants.entity_target },
        selectable_in_game = false,
        is_military_target = true,
        selection_priority = 1,
        hidden = true,
    },
    {
        type = "proxy-container",
        name = constants.entity_proxy_connector,
        flags = { "not-on-map", "placeable-off-grid", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion" },
        circuit_wire_max_distance = 1,
        selection_priority = 1,
        draw_circuit_wires = false,
        draw_inventory_content = false,
        selectable_in_game = false,
        hidden = true,
    },
    {
        type = "ammo-category",
        name = constants.range_upgrade_bonus,
        subgroup = "ammo-category",
        hidden = true,
    },
    {
        type = "ammo-category",
        name = constants.energy_capacity_modifier,
        subgroup = "ammo-category",
        hidden = true,
    },
    {
        type = "ammo-category",
        name = constants.energy_consumption_modifier,
        subgroup = "ammo-category",
        hidden = true,
    },
    {
        type = "artillery-projectile",
        name = constants.entity_tracker,
        flags = { "not-on-map" },
        map_color = { 0.4, 1.0, 0.4, 0.8 },
        reveal_map = false,
        hidden = true,
        chart_picture = {
            filename = "__base__/graphics/entity/artillery-projectile/artillery-shoot-map-visualization.png",
            -- filename = "__core__/graphics/empty.png",
            flags = { "icon" },
            width = 64,
            height = 64,
            priority = "high",
            tint = { 0, 0.9, 0 },
            scale = 0.2,
        },
        action = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = constants.capsule_landed_effect_id
                }
            }
        },
    },
    {
        type = "temporary-container",
        name = constants.entity_capsule_inventory,
        inventory_size = 100,
        time_to_live = 60 * 60 * 60, -- 1 hour
        flags = { "not-on-map", "hide-alt-info", "placeable-off-grid", "no-automated-item-removal", "no-automated-item-insertion" },
        selection_priority = 1,
        selectable_in_game = false,
        destroy_on_empty = false,
        hidden = true,
    },
    {
        type = "mod-data",
        name = constants.data_capsule_properties,
        ---@class CannonCapsuleProperties
        ---@field speed number
        ---@field payload_size uint
        ---@field energy_consumption number
        ---@field range_modifier number?
        ---@field projectile_name string
        ---@field smoke_color Color?
        data = {},
    },
    {
        type = "mod-data",
        name = constants.data_launcher_properties,
        ---@class LauncherProperties
        ---@field range number
        ---@field energy_consumption number
        data = {},
    },
}
