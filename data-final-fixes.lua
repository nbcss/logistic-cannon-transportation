local constants = require("constants")

local tooltip_postprocessing = {
    item = { constants.item_launcher },
    ammo = {},
}
local default_quality_multipliers = {
    default_multiplier = function (level) return 1 + 0.3 * level end,
    range_multiplier = function (level) return math.min(1 + 0.1 * level, 3) end,
    inventory_size_multiplier = function (level) return 1 + 0.3 * level end,
}

for ammo, _ in pairs(data.raw["mod-data"][constants.data_capsule_properties].data) do
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

if feature_flags["space_travel"] then
    data.raw["container"][constants.entity_launcher_inventory].surface_conditions = { { property = "gravity", min = 1 } }
    data.raw["container"][constants.entity_receiver_inventory].surface_conditions = { { property = "gravity", min = 1 } }
end
