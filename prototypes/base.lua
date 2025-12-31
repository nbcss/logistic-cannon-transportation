local constants = require("constants")

data.extend {
    util.merge{data.raw["highlight-box"]["highlight-box"], {
        name = "lct-highlight-box",
        hidden = true,
    }},
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
        type = "temporary-container",
        name = "cannon-capsule-storage",
        inventory_size = 100,
        time_to_live = 60 * 60 * 60, -- 1 hour
        destroy_on_empty = false,
        hidden = true,
        flags = { "not-on-map", "not-blueprintable", "not-selectable-in-game", "hide-alt-info" }, --review flags
    },
    {
        type = "mod-data",
        name = constants.data_capsule_properties,
        data = {},
    },
    {
        type = "mod-data",
        name = constants.data_projectile_properties,
        data = {},
    },
}

---@class CannonCapsuleProperties
---@field speed_tier string
---@field payload_size uint
---@field energy_consumption number