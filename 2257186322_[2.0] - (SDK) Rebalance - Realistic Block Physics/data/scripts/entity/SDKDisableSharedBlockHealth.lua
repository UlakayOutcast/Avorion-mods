package.path = package.path .. ";data/scripts/lib/?.lua"

SDKEntityInterface = {}

function initialize()

    local e = Entity()

    -- Don't use this for the following Entities, they might break...
    if string.match(e.name, "The AI") then return end             
    if string.match(e.name, "Big Brother") then return end

    e:setValue("SDKBlockHealth", "Individual")
    e:setAccumulatingBlockHealth(false)

end

return SDKEntityInterface
