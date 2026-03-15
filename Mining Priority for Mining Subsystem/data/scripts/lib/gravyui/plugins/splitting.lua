function GravyUINode:cols(splits, margin)
    margin = margin or 0
    if math.abs(margin) <= 1 then margin = (margin * self.rect.width) end
    local numSplits
    if type(splits) == "number" then
        numSplits = splits
        splits = {}
        for i = 1,numSplits do table.insert(splits, 1/numSplits) end
    else
        numSplits = #splits
    end
    local availableSize = self.rect.width - margin * (numSplits - 1)
    for i = 1,numSplits do
        if math.abs(splits[i]) > 1 then
            availableSize = availableSize - splits[i]
        end
    end
    local nodes = {}
    local offset = 0
    for i = 1,numSplits do
        local split = splits[i]
        if math.abs(split) <= 1 then
            split = (split * availableSize)
        end
        local topLeft = self.rect.topLeft + vec2((i - 1) * margin + offset, 0)
        local bottomRight = topLeft + vec2(split , self.rect.height)
        table.insert(nodes, self:child(Rect(topLeft, bottomRight)))
        offset = offset + split
    end
    return unpack(nodes)
end

function GravyUINode:rows(splits, margin)
    margin = margin or 0
    if math.abs(margin) <= 1 then margin = (margin * self.rect.height) end 
    local numSplits
    if type(splits) == "number" then
        numSplits = splits
        splits = {}
        for i = 1,numSplits do table.insert(splits, 1/numSplits) end
    else
        numSplits = #splits
    end
    local availableSize = self.rect.height - margin * (numSplits - 1)
    for i = 1,numSplits do
        if math.abs(splits[i]) > 1 then
            availableSize = availableSize - splits[i]
        end
    end
    local nodes = {}
    local offset = 0
    for i = 1,numSplits do
        local split = splits[i]
        if math.abs(split) <= 1 then
            split = (split * availableSize)
        end
        local topLeft = self.rect.topLeft + vec2(0, (i - 1) * margin + offset)
        local bottomRight = topLeft + vec2(self.rect.width, split)
        table.insert(nodes, self:child(Rect(topLeft, bottomRight)))
        offset = offset + split
    end
    return unpack(nodes)
end

function GravyUINode:grid(rowSplits, colSplits, rowMargin, colMargin)
    local nodes = {}
    for _, rowNode in ipairs({self:rows(rowSplits, rowMargin)}) do
        table.insert(nodes, {rowNode:cols(colSplits, colMargin)})
    end
    return unpack(nodes)
end

return GravyUINode
