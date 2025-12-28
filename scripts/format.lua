local format = {}

---@param energy number
function format.energy(energy)
    if energy < 1e3 then
        return string.format("%.0f J", energy)
    elseif energy < 1e5 then
        return string.format("%.1f kJ", energy / 1e3)
    elseif energy < 1e6 then
        return string.format("%.0f kJ", energy / 1e3)
    elseif energy < 1e8 then
        return string.format("%.1f MJ", energy / 1e6)
    elseif energy < 1e9 then
        return string.format("%.0f MJ", energy / 1e6)
    elseif energy < 1e11 then
        return string.format("%.1f GJ", energy / 1e9)
    elseif energy < 1e12 then
        return string.format("%.0f GJ", energy / 1e9)
    else
        return string.format("%.1f TJ", energy / 1e12)
    end
end

return format