local format = {}

---@param energy number
function format.energy(energy)
    if energy < 1000 then
        return string.format("%.0f J", energy)
    elseif energy < 100000 then
        return string.format("%.1f kJ", energy / 1000)
    elseif energy < 1000000 then
        return string.format("%.0f kJ", energy / 1000)
    elseif energy < 100000000 then
        return string.format("%.1f MJ", energy / 1000000)
    elseif energy < 1000000000 then
        return string.format("%.0f MJ", energy / 1000000)
    elseif energy < 100000000000 then
        return string.format("%.1f GJ", energy / 1000000000)
    elseif energy < 1000000000000 then
        return string.format("%.0f GJ", energy / 1000000000)
    else
        return string.format("%.1f TJ", energy / 1000000000000)
    end
end

return format