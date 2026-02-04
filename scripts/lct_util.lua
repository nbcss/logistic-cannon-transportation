local lct_util = {}

---@param a MapPosition
---@param b MapPosition
---@return number
function lct_util.distance(a, b)
    return math.sqrt(math.pow(a.x - b.x, 2) - math.pow(a.y - b.y, 2))
end

return lct_util