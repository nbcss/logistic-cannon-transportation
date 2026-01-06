local constants = require("constants")
local format = require("scripts.format")

local capsule_properties = data.raw["mod-data"][constants.data_capsule_properties]
    .data --[[@as table<string, CannonCapsuleProperties>]]
capsule_properties[constants.item_capsule_basic] = {
    speed = 40,
    payload_size = 1,
    energy_consumption = 30000, -- J per tile
} --[[@as CannonCapsuleProperties]]
capsule_properties[constants.item_capsule_reinforced] = {
    speed = 30,
    payload_size = 8,
    energy_consumption = 100000, -- J per tile
} --[[@as CannonCapsuleProperties]]
capsule_properties[constants.item_capsule_propelled] = {
    speed = 75,
    payload_size = 3,
    energy_consumption = 50000, -- J per tile
} --[[@as CannonCapsuleProperties]]

---@param capsule_item string
---@return data.CustomTooltipField[]
local function custom_tooltip_fields(capsule_item)
    local capsule = capsule_properties[capsule_item]
    return {
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
end

---@return data.AmmoType
local function ammo_type()
    return {
        target_type = "direction",
        consumption_modifier = 0,
        action = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    type = "script",
                    effect_id = "logistic-cannon-capsule-launched",
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
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = constants.item_subgroup,
        order = "c1[capsule]",
        stack_size = 20,
        custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_basic),
        ammo_type = ammo_type(),
    },
    {
        type = "recipe",
        name = constants.item_capsule_basic,
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
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = constants.item_subgroup,
        order = "c2[capsule]",
        stack_size = 10,
        custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_reinforced),
        ammo_type = ammo_type(),
    },
    {
        type = "recipe",
        name = constants.item_capsule_reinforced,
        energy_required = 2,
        ingredients = {
            { type = "item", name = "low-density-structure", amount = 1 },
            { type = "item", name = "explosives",  amount = 4 },
        },
        results = {
            { type = "item", name = constants.item_capsule_reinforced, amount = 4 },
        }
    },
    -- propelled capsule
    {
        type = "ammo",
        name = constants.item_capsule_propelled,
        ammo_category = constants.ammo_category,
        icon = "__base__/graphics/icons/rocket-part.png",
        subgroup = constants.item_subgroup,
        order = "c3[capsule]",
        stack_size = 10,
        custom_tooltip_fields = custom_tooltip_fields(constants.item_capsule_propelled),
        ammo_type = ammo_type(),
    },
    {
        type = "recipe",
        name = constants.item_capsule_propelled,
        energy_required = 2,
        ingredients = {
            { type = "item", name = "low-density-structure", amount = 1 },
            { type = "item", name = "explosives",  amount = 1 },
            { type = "item", name = "rocket-fuel",  amount = 1 },
        },
        results = {
            { type = "item", name = constants.item_capsule_propelled, amount = 4 },
        }
    },
}
