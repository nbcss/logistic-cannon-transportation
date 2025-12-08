local tooltip_postprocessing = { item = { "logistic-cannon-launcher" } }
local default_quality_multipliers = {
    range_multiplier = function (level) return math.min(1 + 0.1 * level, 3) end,
    inventory_size_multiplier = function (level) return 1 + 0.3 * level end,
}

for category, prototypes in pairs(tooltip_postprocessing) do
    for _, prototype_name in ipairs(prototypes) do
        local prototype = data.raw[category][prototype_name]
        for _, tooltip in ipairs(prototype.custom_tooltip_fields) do
            if tooltip["quality_base_value"] and tooltip["quality_multiplier"] then
                local base_value = tooltip["quality_base_value"]
                local multiplier = tooltip["quality_multiplier"]
                local quality_values = {}
                -- log(serpent.block(data.raw["quality"]))
                for quality_name, quality in pairs(data.raw["quality"]) do
                    local value = base_value;
                    if quality[multiplier] then
                        value = value * quality[multiplier]
                    elseif default_quality_multipliers[multiplier] then
                        value = value * default_quality_multipliers[multiplier](quality.level)
                    end
                    quality_values[quality_name] = { "", tostring(value) }
                end
                tooltip.quality_values = quality_values
            end
        end
    end
end

-- data.raw["projectile"]["rocket"].flags = {}
-- data.raw["projectile"]["rocket"].map_color = {1, 0, 0}
