function GravyUINode:scale(x, y)
    if y == nil then y = x end
    return self:resize(x * self.rect.width, y * self.rect.height)
end

function GravyUINode:resize(width, height)
    local vec = vec2(width/2, height/2)
    return self:child(Rect(self.rect.center - vec, self.rect.center + vec))
end

----@overload fun(self: GravyIONode, left: number, top: number, right: number, bottom: number)
----@overload fun(node: GravyIONode, leftRight: number, topBottom: number)
----@overload fun(node: GravyIONode, allSides: number)
function GravyUINode:pad(a, b, c, d)
    local topLeft, bottomRight

    if d ~= nil then
        if math.abs(a) <= 1 then a = a * self.rect.width end
        if math.abs(b) <= 1 then b = b * self.rect.height end
        if math.abs(c) <= 1 then c = c * self.rect.width end
        if math.abs(d) <= 1 then d = d * self.rect.height end
        topLeft = vec2(a, b)
        bottomRight = vec2(c, d)
    elseif b ~= nil then
        if math.abs(a) <= 1 then a = a * self.rect.width end
        if math.abs(b) <= 1 then b = b * self.rect.height end
        topLeft = vec2(a, b)
        bottomRight = vec2(a, b)
    elseif a ~= nil then
        if math.abs(a) <= 1 then 
            topLeft = vec2(a * self.rect.width, a * self.rect.height)
        else
            topLeft = vec2(a, a)
        end
        bottomRight = topLeft
    else
        error("Invalid number of arugments to pad")
    end

    local newRect = Rect(self.rect.topLeft + topLeft, self.rect.bottomRight - bottomRight)
    return self:child(newRect)
end

return GravyUINode
