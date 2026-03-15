local function appendPackagePath(rule)
    if not package.path:find(rule, 1, true) then
        package.path = package.path .. ";" .. rule
    end
end

appendPackagePath("data/scripts/?.lua")
appendPackagePath("data/scripts/lib/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/lib/?.lua")

local info = debug.getinfo(1, "S")
local currentDir = info and info.source and info.source:match("^@(.+/)") or ""
if currentDir ~= "" then
    local modRootPath = currentDir .. "../?.lua"
    if not package.path:find(modRootPath, 1, true) then
        package.path = package.path .. ";" .. modRootPath
    end
end

include("randomext")
include("stringutility")
include("callable")

local Config = include("lib/hyperblockerconfig") or {
    rarityOrder = {},
    rangeByRarity = {},
    energyBase = 0,
    energyPerKm = 0,
    priceBase = 0,
    pricePerRarity = 0,
}

local hyperblockerButton
local vanillaInitUI = initUI

local vanillaOnSystemsButtonPressed = onSystemsButtonPressed

local function createHyperblockerTemplate(rarityId)
    local rarity = Rarity(rarityId)
    local template = SystemUpgradeTemplate("data/scripts/systems/hyperblocker.lua", rarity, random():createSeed())
    return template
end

function addHyperblockersToInventory()
    if onClient() then
        invokeServerFunction("addHyperblockersToInventory")
        return
    end

    local receiver = Player(callingPlayer)
    local inventory

    if receiver then
        inventory = receiver:getInventory()
    end

    if not inventory then
        local faction = Faction()
        if faction then
            inventory = faction:getInventory()
        end
    end

    if not inventory then
        print("[HyperBlocker] DebugSpawn: Нет доступного инвентаря.")
        return
    end

    local added = 0
    for _, entry in ipairs(Config.rarityOrder) do
        local template = createHyperblockerTemplate(entry.id)
        if template then
            inventory:addOrDrop(template)
            added = added + 1
        end
    end

    if receiver then
        receiver:sendChatMessage("HyperBlocker", ChatMessageType.Normal, string.format("Гиперпространственные блокаторы (%d стеков) были добавлены в ваш инвентарь.", added))
    end
end
callable(nil, "addHyperblockersToInventory")

function onSystemsButtonPressed(...)
    if vanillaOnSystemsButtonPressed then
        vanillaOnSystemsButtonPressed(...)
    end

    if onClient() then return end

    addHyperblockersToInventory()
end

function initUI(...)
    if vanillaInitUI then
        vanillaInitUI(...)
    end

    if window and not hyperblockerButton then
        local size = window.size or vec2(0, 0)
        local rect = Rect(vec2(size.x - 230, size.y - 55), vec2(size.x - 10, size.y - 20))
        hyperblockerButton = window:createButton(rect, "Hyperblocker", "onHyperblockerQuickSpawn")
        hyperblockerButton.tooltip = "Добавляет все редкости гиперпространственных блокаторов прямо в инвентарь."
    end
end

function onHyperblockerQuickSpawn()
    invokeServerFunction("addHyperblockersToInventory")
end
callable(nil, "onHyperblockerQuickSpawn")
