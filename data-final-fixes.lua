local constants = require("constants")
local format = require("scripts.format")

local capsule_properties = data.raw["mod-data"][constants.data_capsule_properties]
    .data --[[@as table<string, CapsuleProperties>]]

---@param capsule_item string
---@return data.CustomTooltipField[]
local function ammo_tooltip_fields(capsule_item)
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

local default_quality_multipliers = {
    default_multiplier = function(level) return 1 + 0.3 * level end,
    range_multiplier = function(level) return math.min(1 + 0.1 * level, 3) end,
    inventory_size_multiplier = function(level) return 1 + 0.3 * level end,
}

local tooltip_postprocessing = {
    item = { constants.item_launcher },
    ammo = {},
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

for ammo, _ in pairs(data.raw["mod-data"][constants.data_capsule_properties].data) do
    data.raw["ammo"][ammo].custom_tooltip_fields = ammo_tooltip_fields(ammo)
    table.insert(tooltip_postprocessing.ammo, ammo)
end

for category, prototypes in pairs(tooltip_postprocessing) do
    for _, prototype_name in ipairs(prototypes) do
        local prototype = data.raw[category][prototype_name]
        for _, tooltip in ipairs(prototype.custom_tooltip_fields) do
            if tooltip["quality_base_value"] and tooltip["quality_multiplier"] then
                local base_value = tooltip["quality_base_value"]
                local multiplier = tooltip["quality_multiplier"]
                local formatting = tooltip["quality_formatting"]
                local quality_values = {}
                for quality_name, quality in pairs(data.raw["quality"]) do
                    local value = base_value;
                    if quality[multiplier] then
                        value = value * quality[multiplier]
                    elseif default_quality_multipliers[multiplier] then
                        value = value * default_quality_multipliers[multiplier](quality.level)
                    end
                    if formatting then
                        quality_values[quality_name] = formatting(value)
                    else
                        quality_values[quality_name] = { "", tostring(value) }
                    end
                end
                tooltip.quality_values = quality_values
                tooltip["quality_formatting"] = nil
            end
        end
    end
end
