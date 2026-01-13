local format = {}

---@param value number
function format.energy(value, suffix)
    if not suffix then
        suffix = "J"
    end
    if value < 1e3 then
        return string.format("%.0f %s", value, suffix)
    elseif value < 1e5 then
        return string.format("%.1f k%s", value / 1e3, suffix)
    elseif value < 1e6 then
        return string.format("%.0f k%s", value / 1e3, suffix)
    elseif value < 1e8 then
        return string.format("%.1f M%s", value / 1e6, suffix)
    elseif value < 1e9 then
        return string.format("%.0f M%s", value / 1e6, suffix)
    elseif value < 1e11 then
        return string.format("%.1f G%s", value / 1e9, suffix)
    elseif value < 1e12 then
        return string.format("%.0f G%s", value / 1e9, suffix)
    else
        return string.format("%.1f T%s", value / 1e12, suffix)
    end
end

---@param value number
function format.number(value)
    if value < 1e3 then
        return string.format("%.0f", value)
    elseif value < 1e4 then
        return string.format("%.1fk", value / 1e3)
    elseif value < 1e6 then
        return string.format("%.0fk", value / 1e3)
    elseif value < 1e7 then
        return string.format("%.1fM", value / 1e6)
    elseif value < 1e9 then
        return string.format("%.0fM", value / 1e6)
    elseif value < 1e10 then
        return string.format("%.1fG", value / 1e9)
    elseif value < 1e12 then
        return string.format("%.0fG", value / 1e9)
    else
        return string.format("%.1fT", value / 1e12)
    end
end

---@param item_name string
---@param item_quality string
---@return string
function format.encode_item(item_name, item_quality)
    return item_name .. ":" .. item_quality
end

return format