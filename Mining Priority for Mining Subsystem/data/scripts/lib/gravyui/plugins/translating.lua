--- Translates a node by a given x and y number of
--- pixels
--- @param x number
--- @param y number
--- @return GravyIONode
function GravyUINode:offset(x, y)
    if math.abs(x) <= 1 then x = x * self.rect.width end
    if math.abs(y) <= 1 then y = y * self.rect.height end
    local offset = vec2(x, y)
    return self:child(Rect(self.rect.topLeft + offset, self.rect.bottomRight + offset))
end

--- Translates a node by a given angle and
--- distance.
--- @param angle number
--- @param xDistance number
--- @param yDistance number
--- @return GravyIONode
--- @overload fun(angle: number, distance: number): GravyIONode
function GravyUINode:radial(angle, xDistance, yDistance)
    if yDistance == nil then yDistance = xDistance end
    if math.abs(xDistance) <= 1 then xDistance = xDistance * self.rect.width end
    if math.abs(yDistance) <= 1 then yDistance = yDistance * self.rect.width end
    
    local xs = xDistance * math.sin(angle)
    local ys = yDistance * math.cos(angle)
    return self:offset(xs, ys)
end

return GravyUINode
