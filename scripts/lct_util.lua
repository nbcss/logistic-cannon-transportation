local lct_util = {}

---@param x number
---@return number
function lct_util.round(x)
    return math.floor(x + 0.5)
end

lct_util.math2d = {}

---@param a MapPosition
---@param b MapPosition
---@return number
function lct_util.math2d.distance(a, b)
    return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2))
end

return lct_util