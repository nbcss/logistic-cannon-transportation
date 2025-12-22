data.extend {
    {
        type = "ammo-category",
        name = "logistic-cannon-capsule",
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = "ammo-category",
    },
    {
        type = "ammo-category",
        name = "logistic-cannon-launcher-energy-buffer",
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = "ammo-category",
    },
    {
        type = "font",
        name = "no-percent",
        size = 14,
        from = "test-no-percent",
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
        type = "delayed-active-trigger",
        name = "reset-shooting-state",
        delay = 1,
        action = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    {
                        type = "script",
                        effect_id = "logistic-cannon-launcher-reset",
                    }
                },
            }
        },
    },
    {
        type = "character",
        name = "logistic-cannon-controller",
        hidden = true,
        mining_speed = 0,
        running_speed = 0,
        distance_per_frame = 0,
        maximum_corner_sliding_distance = 0,
        inventory_size = 0,
        guns_inventory_size = 1,
        build_distance = 0,
        drop_item_distance = 0,
        reach_distance = 0,
        reach_resource_distance = 0,
        item_pickup_distance = 0,
        loot_pickup_distance = 0,
        ticks_to_keep_gun = 0,
        ticks_to_keep_aiming_direction = 0,
        ticks_to_stay_in_combat = 0,
        damage_hit_tint = { 0, 0, 0 },
        mining_with_tool_particles_animation_positions = {},
        running_sound_animation_positions = {},
        moving_sound_animation_positions = {},
        animations = data.raw["character"]["character"].animations,
    },
}
