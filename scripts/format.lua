local format = {}

---@param energy number
function format.energy(energy, suffix)
    if not suffix then
        suffix = "J"
    end
    if energy < 1e3 then
        return string.format("%.0f %s", energy, suffix)
    elseif energy < 1e5 then
        return string.format("%.1f k%s", energy / 1e3, suffix)
    elseif energy < 1e6 then
        return string.format("%.0f k%s", energy / 1e3, suffix)
    elseif energy < 1e8 then
        return string.format("%.1f M%s", energy / 1e6, suffix)
    elseif energy < 1e9 then
        return string.format("%.0f M%s", energy / 1e6, suffix)
    elseif energy < 1e11 then
        return string.format("%.1f G%s", energy / 1e9, suffix)
    elseif energy < 1e12 then
        return string.format("%.0f G%s", energy / 1e9, suffix)
    else
        return string.format("%.1f T%s", energy / 1e12, suffix)
    end
end

return format