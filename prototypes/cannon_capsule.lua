local constants = require("constants")
local item_sounds = require("__base__.prototypes.item_sounds")
local format = require("scripts.format")

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

---@param capsule_item string
---@return data.CustomTooltipField[]
local function custom_tooltip_fields(capsule_item)
    local capsule = capsule_properties[capsule_item]
    local tooltip_fields = {
        {
            name = { "logistic-cannon-transportation.capsule-payload-size" },
            value = { "logistic-cannon-transportation.stack", tostring(capsule.payload_size) },
            quality_base_value = capsule.payload_size,
            quality_multiplier = "default_multiplier",
            quality_formatting = setmetatable({}, {
                __call = function(self, value)
                    return { "logistic-cannon-transportation.stack", tostring(math.floor(0.5 + value)) }
                end
            }),
            order = 1,
        },
        {
            name = { "logistic-cannon-transportation.capsule-energy-consumption" },
            value = { "", format.energy(capsule.energy_consumption, "J/m") },
            quality_header = "quality-tooltip.reduced-energy",
            quality_base_value = 1,
            quality_multiplier = "range_multiplier",
            quality_formatting = setmetatable({}, {
                __call = function(self, value)
                    return { "", format.energy(capsule.energy_consumption / value, "J/m") }
                end
            }),
            order = 2,
        },
        {
            name = { "logistic-cannon-transportation.capsule-speed" },
            value = { "logistic-cannon-transportation.meter-per-second", tostring(capsule.speed) },
            order = 3,
        },
    }
    if capsule.range_modifier then
        table.insert(tooltip_fields, {
            name = { "description.range-modifier" },
            value = { "", string.format("%.0f%%", capsule.range_modifier * 100) },
            order = 4,
        })
    end
    return tooltip_fields
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
        custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_basic),
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
        custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_reinforced),
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
        custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_propelled),
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

if settings.startup[constants.setting_capsule_consumption_mode].value == "no-consumption" then
    for ammo, _ in pairs(capsule_properties) do
        data.raw["ammo"][ammo].stack_size = 1
        local capsule_recipe = data.raw["recipe"][ammo]
        local modifier = math.ceil(40 / capsule_recipe.results[1].amount)
        capsule_recipe.results[1].amount = 1
        capsule_recipe.energy_required = capsule_recipe.energy_required * 4
        for _, ingredient in ipairs(capsule_recipe.ingredients) do
            ingredient.amount = ingredient.amount * modifier
        end
    end
end
