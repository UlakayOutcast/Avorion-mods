local function appendPackagePath(rule)
    if not package.path:find(rule, 1, true) then
        package.path = package.path .. ";" .. rule
    end
end

appendPackagePath("data/scripts/?.lua")
appendPackagePath("data/scripts/lib/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/lib/?.lua")

include("randomext")
include("utility")

local Hook = {}
local Config = include("lib/hyperblockerconfig") or {}
local hyperblockerScript = "data/scripts/systems/hyperblocker.lua"
local guaranteedSlotEnabled = false
local rngChance = 0
local generatorReady = false

local function updateConfigFlag()
    local settings = Config.equipmentDock or {}
    guaranteedSlotEnabled = settings.guaranteedSlot == true
    rngChance = tonumber(settings.rngReplacementChance) or 0
    if rngChance < 0 then rngChance = 0 end
    if rngChance > 1 then rngChance = 1 end
end

local function ensureGenerator()
    if generatorReady and UpgradeGenerator then
        return true
    end

    UpgradeGenerator = UpgradeGenerator or include("upgradegenerator")
    generatorReady = UpgradeGenerator ~= nil
    return generatorReady
end

local function shouldActivate()
    return guaranteedSlotEnabled or rngChance > 0
end

local function hasHyperblocker(soldItems)
    if type(soldItems) ~= "table" then return false end

    for _, sellable in ipairs(soldItems) do
        local item = sellable and (sellable.item or sellable)
        if item and item.script == hyperblockerScript then
            return true
        end
    end

    return false
end

local function ensureRarityTable(generator)
    local x, y = Sector():getCoordinates()
    local rarities = generator:getSectorRarityDistribution(x, y)

    local EquipmentDock = _G.EquipmentDock
    if EquipmentDock and type(EquipmentDock.rarityFactors) == "table" then
        for rarityValue, factor in pairs(EquipmentDock.rarityFactors) do
            if rarities[rarityValue] then
                rarities[rarityValue] = rarities[rarityValue] * factor
            end
        end
    end

    return rarities, x, y
end

local function addGuaranteedItem(shop)
    if Config.debugLogging then
        local station = Entity()
        local name = station and (station.translatedTitle or station.name or station.index.string) or "<unknown>"
        local count = (shop and shop.soldItems and #shop.soldItems) or 0
        print(string.format("[HyperBlocker] EquipmentDock refresh erkannt in %s (Items: %d)", tostring(name), count))
    end

    local forceInsert = guaranteedSlotEnabled
    local roll = nil
    local doRngInsert = false

    if not guaranteedSlotEnabled and rngChance > 0 then
        local rng = random()
        roll = rng:getFloat()
        doRngInsert = roll <= rngChance
    end

    if not forceInsert and not doRngInsert then
        if Config.debugLogging and roll then
            local station = Entity()
            local name = station and (station.translatedTitle or station.name or station.index.string) or "<unknown>"
            print(string.format("[HyperBlocker] RNG verpasst in %s (Roll %.3f > Chance %.3f)", tostring(name), roll, rngChance))
        end
        return
    end

    if hasHyperblocker(shop.soldItems) then
        return
    end

    if not ensureGenerator() then
        if Config.debugLogging then
            print("[HyperBlocker] UpgradeGenerator nicht verfügbar, Hyperblocker kann nicht erzeugt werden.")
        end
        return
    end

    local generator = UpgradeGenerator()
    local rarities, x, y = ensureRarityTable(generator)
    local rarity = getValueFromDistribution(rarities, random())
    if type(rarity) == "number" then
        rarity = Rarity(rarity)
    end
    rarity = rarity or Rarity(RarityType.Uncommon)

    local seed = generator:getUpgradeSeed(x, y, hyperblockerScript, rarity)
    local template = SystemUpgradeTemplate(hyperblockerScript, rarity, seed)

    shop:addFront(template, getInt(1, 2))

    if Config.debugLogging then
        local station = Entity()
        local name = station and (station.translatedTitle or station.name or station.index.string) or "<unknown>"
        local mode = forceInsert and "Garantierter" or "RNG"
        print(string.format("[HyperBlocker] %s Hyperblocker in %s (Rarität %s)", mode, tostring(name), rarity.name or rarity.value))
    end
end

function Hook.refreshConfiguration()
    updateConfigFlag()
end

function Hook.wrapShop(shop)
    updateConfigFlag()

    if not shouldActivate() then
        return false, "Feature deaktiviert"
    end

    if not shop then
        return false, "Shop nicht verfügbar"
    end

    if shop._hyperblockerWrapped then
        return true, "Bereits aktiv"
    end

    if not ensureGenerator() then
        return false, "UpgradeGenerator fehlt"
    end

    local originalAddItems = shop.addItems
    if type(originalAddItems) ~= "function" then
        return false, "addItems fehlt"
    end

    shop.addItems = function(self, ...)
        originalAddItems(self, ...)
        addGuaranteedItem(self)
    end

    shop._hyperblockerWrapped = true

    if Config.debugLogging then
        local station = Entity()
        local name = station and (station.translatedTitle or station.name or station.index.string) or "<unknown>"
        print(string.format("[HyperBlocker] EquipmentDock-Hook aktiv in %s", tostring(name)))
    end

    -- apply the RNG immediately so the station doesn't have to wait for the next restock
    addGuaranteedItem(shop)

    return true
end

return Hook
