local constants = require("constants")
local item_sounds = require("__base__.prototypes.item_sounds")

local capsule_properties = data.raw["mod-data"][constants.data_capsule_properties]
    .data --[[@as table<string, CapsuleProperties>]]
capsule_properties[constants.item_capsule_basic] = {
    speed = 40,                 -- tile per second
    payload_size = 1,           -- stack
    energy_consumption = 30000, -- J per tile
    projectile_name = "capsule-basic",
} --[[@as CapsuleProperties]]
capsule_properties[constants.item_capsule_reinforced] = {
    speed = 30,                  -- tile per second
    payload_size = 8,            -- stack
    energy_consumption = 100000, -- J per tile
    projectile_name = "capsule-reinforced",
    smoke_color = { 0.9, 0.375, 0.375, 0.375 },
} --[[@as CapsuleProperties]]
capsule_properties[constants.item_capsule_propelled] = {
    speed = 75,                 -- tile per second
    payload_size = 3,           -- stack
    energy_consumption = 50000, -- J per tile
    range_modifier = 2.0,
    projectile_name = "capsule-propelled",
    smoke_color = { 0.2, 0.9, 0.9, 0.375 },
} --[[@as CapsuleProperties]]

if settings.startup[constants.setting_capsule_consumption_mode].value == "no-consumption" then
    for _, capsule_data in pairs(capsule_properties) do
        capsule_data.energy_consumption = capsule_data.energy_consumption *
            constants.capsule_no_consumption_energy_modifier
    end
end

---@return data.AmmoType
local function ammo_type()
    return {
        target_type = "direction",
        action = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = constants.capsule_launched_effect_id,
                }
            }
        },
    }
end

data:extend {
    -- basic capsule
    {
        type = "ammo",
        name = constants.item_capsule_basic,
        ammo_category = constants.ammo_category,
        icon = "__logistic-cannon-assets__/graphics/icons/capsule-basic.png",
        subgroup = constants.item_subgroup,
        order = "c1[capsule]",
        stack_size = 25,
        inventory_move_sound = item_sounds.ammo_large_inventory_move,
        pick_sound = item_sounds.ammo_large_inventory_pickup,
        drop_sound = item_sounds.ammo_large_inventory_move,
        -- custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_basic),
        ammo_type = ammo_type(),
    },
    {
        type = "recipe",
        name = constants.item_capsule_basic,
        enabled = false,
        energy_required = 1,
        ingredients = {
            { type = "item", name = "steel-plate", amount = 1 },
            { type = "item", name = "explosives",  amount = 1 },
        },
        results = {
            { type = "item", name = constants.item_capsule_basic, amount = 4 },
        }
    },
    -- reinforced capsule
    {
        type = "ammo",
        name = constants.item_capsule_reinforced,
        ammo_category = constants.ammo_category,
        icon = "__logistic-cannon-assets__/graphics/icons/capsule-reinforced.png",
        subgroup = constants.item_subgroup,
        order = "c2[capsule]",
        stack_size = 5,
        inventory_move_sound = item_sounds.ammo_large_inventory_move,
        pick_sound = item_sounds.ammo_large_inventory_pickup,
        drop_sound = item_sounds.ammo_large_inventory_move,
        -- custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_reinforced),
        ammo_type = ammo_type(),
    },
    {
        type = "recipe",
        name = constants.item_capsule_reinforced,
        enabled = false,
        energy_required = 2,
        ingredients = {
            { type = "item", name = "low-density-structure", amount = 1 },
            { type = "item", name = "explosives",            amount = 4 },
        },
        results = {
            { type = "item", name = constants.item_capsule_reinforced, amount = 2 },
        }
    },
    -- propelled capsule
    {
        type = "ammo",
        name = constants.item_capsule_propelled,
        ammo_category = constants.ammo_category,
        icon = "__logistic-cannon-assets__/graphics/icons/capsule-propelled.png",
        subgroup = constants.item_subgroup,
        order = "c3[capsule]",
        stack_size = 10,
        inventory_move_sound = item_sounds.ammo_large_inventory_move,
        pick_sound = item_sounds.ammo_large_inventory_pickup,
        drop_sound = item_sounds.ammo_large_inventory_move,
        -- custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_propelled),
        ammo_type = ammo_type(),
    },
    {
        type = "recipe",
        name = constants.item_capsule_propelled,
        enabled = false,
        energy_required = 2,
        ingredients = {
            { type = "item", name = "low-density-structure", amount = 1 },
            { type = "item", name = "explosives",            amount = 1 },
            { type = "item", name = "rocket-fuel",           amount = 1 },
        },
        results = {
            { type = "item", name = constants.item_capsule_propelled, amount = 2 },
        }
    },
}
