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
        type = "ammo-category",
        name = constants.ammo_category,
        icon = "__base__/graphics/icons/rocket-part.png",
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
        is_military_target = true,
        flags = { "placeable-off-grid", "not-selectable-in-game" },
        trigger_target_mask = { constants.entity_target },
        hidden = true,
    },
    {
        type = "ammo-category",
        name = constants.range_upgrade_bonus,
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = "ammo-category",
        hidden = true,
    },
    {
        type = "ammo-category",
        name = constants.energy_capacity_modifier,
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = "ammo-category",
        hidden = true,
    },
    {
        type = "ammo-category",
        name = constants.energy_consumption_modifier,
        icon = "__base__/graphics/icons/rocket-part.png",
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
                    effect_id = "logistic-cannon-capsule-landed"
                }
            }
        },
    },
    {
        type = "temporary-container",
        name = constants.entity_capsule_container,
        inventory_size = 100,
        time_to_live = 60 * 60 * 60, -- 1 hour
        destroy_on_empty = false,
        hidden = true,
        flags = { "not-on-map", "hide-alt-info" },
        selectable_in_game = false,
    },
    {
        type = "mod-data",
        name = constants.data_capsule_properties,
        ---@class CannonCapsuleProperties
        ---@field speed number
        ---@field payload_size uint
        ---@field energy_consumption number
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
