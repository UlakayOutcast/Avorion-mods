local function appendPackagePath(rule)
    if not package.path:find(rule, 1, true) then
        package.path = package.path .. ";" .. rule
    end
end

appendPackagePath("data/scripts/?.lua")
appendPackagePath("data/scripts/lib/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/lib/?.lua")

include("utility")
include("stringutility")

function initialize()
    if onServer() then
        local entity = Entity()
        local faction = Faction(entity.factionIndex)
        if faction then
            if faction.isPlayer then
                Player(entity.factionIndex):sendChatMessage(entity.name, 1, "Der Hyperraumblocker muss permanent installiert werden, um zu funktionieren.")
            elseif faction.isAlliance then
                Alliance(entity.factionIndex):sendChatMessage(entity.name, 1, "Der Hyperraumblocker muss permanent installiert werden, um zu funktionieren.")
            end
        end
    end
    terminate()
end
