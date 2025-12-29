local constants = require("constants")

data.extend {
    {
        type = "ammo-category",
        name = "logistic-cannon-capsule",
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = "ammo-category",
    },
    {
        type = "simple-entity-with-owner",
        name = constants.entity_target,
        is_military_target = true,
        flags = { "placeable-off-grid", "not-selectable-in-game" },
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
}
