local function appendPackagePath(rule)
    if not package.path:find(rule, 1, true) then
        package.path = package.path .. ";" .. rule
    end
end

appendPackagePath("data/scripts/?.lua")
appendPackagePath("data/scripts/lib/?.lua")
appendPackagePath("data/scripts/systems/?.lua")
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

include("basesystem")
include("utility")
include("stringutility")
include("randomext")

local Config = include("lib/hyperblockerconfig") or {
    rarityOrder = {},
    rangeByRarity = {},
    energyBase = 0,
    energyPerKm = 0,
    priceBase = 0,
    pricePerRarity = 0,
    debugLogging = false,
}
local fieldScript = "data/scripts/entity/hyperblockerfield.lua"
local iconScript = "data/scripts/entity/icon.lua"
local blockerIcon = "data/textures/icons/pixel/block.png"
local stackValueKey = "hyperblockerStacks"
local debugLogging = Config.debugLogging == true
local ensureCheckTimer = 0

local function dbg(fmt, ...)
    if not debugLogging then return end
    local prefix = "[HyperBlocker] Hyperblocker.lua"
    if select('#', ...) > 0 then
        print(string.format(prefix .. ": " .. fmt, ...))
    else
        print(prefix .. ": " .. fmt)
    end
end

local function ownerTag()
    local entity = Entity()
    if not entity then return "<no-entity>" end
    local factionIndex = entity.factionIndex
    if not factionIndex then return string.format("entity=%s", tostring(entity.id and entity.id.string or entity.index)) end
    local faction = Faction(factionIndex)
    if faction then
        if faction.isAlliance then
            return string.format("alliance:%d %s", factionIndex, faction.name or "?")
        end
        if faction.isPlayer then
            return string.format("player:%d %s", factionIndex, faction.name or "?")
        end
        return string.format("faction:%d %s", factionIndex, faction.name or "?")
    end
    return string.format("faction:%s", tostring(factionIndex))
end

PermanentInstallationOnly = true
FixedEnergyRequirement = true
UniquePositive = false

local displayName = "Блокатор гиперпространства"
local description = "Создает блокаду гиперпрыжка для кораблей игрока и альянса в пределах диапазона, зависящего от редкости. Должен быть установлен стационарно."
local icon = "data/textures/icons/warhead.png"

local function ensureFieldScript()
    if not onServer() then return end
    local entity = Entity()
    if not entity then
        if debugLogging then
            print("[HyperBlocker] ensureFieldScript: Entity() returned nil")
        end
        return
    end

    local entityId = tostring(entity.index)
    if not entity:hasScript(fieldScript) then
        entity:addScriptOnce(fieldScript, false)
        dbg("Added field script to entity %s", entityId)
    elseif debugLogging then
        dbg("Entity %s already has field script", entityId)
    end
end

local function ensureIcon(entity)
    if entity:hasScript(iconScript) then
        entity:invokeFunction(iconScript, "set", blockerIcon)
    else
        entity:addScriptOnce(iconScript, blockerIcon)
    end
end

local function clearIcon(entity)
    if entity:hasScript(iconScript) then
        entity:invokeFunction(iconScript, "set", "")
    end
end

local function maintainFieldScriptPresence(entity, serializedStacks)
    if not onServer() then return end
    if not entity then return end

    local hasStacks = serializedStacks ~= nil and serializedStacks ~= ""
    local hasScript = entity:hasScript(fieldScript)

    if hasStacks and not hasScript then
        entity:addScriptOnce(fieldScript, false)
        dbg("Reattached field script to entity %s", tostring(entity.index))
    elseif not hasStacks and hasScript then
        entity:removeScript(fieldScript)
        dbg("Removed field script from entity %s", tostring(entity.index))
    end

    if hasStacks then
        ensureIcon(entity)
    else
        clearIcon(entity)
    end
end

local function deserializeStacks(serialized)
    local result = {}
    if type(serialized) ~= "string" or serialized == "" then
        return result
    end

    for chunk in string.gmatch(serialized, "([^,]+)") do
        local rarityStr, amountStr = chunk:match("(-?%d+):(-?%d+)")
        if rarityStr and amountStr then
            local rarityValue = tonumber(rarityStr)
            local amount = math.max(0, tonumber(amountStr) or 0)
            if rarityValue and amount > 0 then
                result[rarityValue] = amount
            end
        end
    end

    return result
end

local function serializeStacks(stacks)
    local keys = {}
    for rarityValue, amount in pairs(stacks) do
        if amount and amount > 0 then
            table.insert(keys, rarityValue)
        end
    end

    if #keys == 0 then
        return nil
    end

    table.sort(keys)

    local parts = {}
    for _, rarityValue in ipairs(keys) do
        table.insert(parts, string.format("%d:%d", rarityValue, stacks[rarityValue]))
    end

    return table.concat(parts, ",")
end


local function updateStoredStacks(change, rarityValue)
    local entity = Entity()
    if not entity then return end

    local stacks = deserializeStacks(entity:getValue(stackValueKey))
    local current = stacks[rarityValue] or 0
    local delta = change == "addStack" and 1 or -1
    local nextAmount = math.max(0, current + delta)

    if nextAmount > 0 then
        stacks[rarityValue] = nextAmount
    else
        stacks[rarityValue] = nil
    end

    local serialized = serializeStacks(stacks)
    if not serialized then
        entity:setValue(stackValueKey, "")
    else
        entity:setValue(stackValueKey, serialized)
    end
    maintainFieldScriptPresence(entity, serialized)

    local serializedState = entity:getValue(stackValueKey) or "<nil>"
    dbg("updateStoredStacks entity=%s change=%s rarity=%s -> %s (owner=%s)", tostring(entity.index), change, tostring(rarityValue), serializedState, ownerTag())
end

local function pushStackChange(change, rarityValue)
    if not onServer() then return end
    dbg("pushStackChange %s rarity=%s owner=%s", change, tostring(rarityValue), ownerTag())
    ensureFieldScript()
    updateStoredStacks(change, rarityValue)
end

function updateServer(timeStep)
    if not onServer() then return end

    ensureCheckTimer = (ensureCheckTimer or 0) - timeStep
    if ensureCheckTimer > 0 then return end
    ensureCheckTimer = 10

    local entity = Entity()
    if not entity then return end

    local serialized = entity:getValue(stackValueKey)
    maintainFieldScriptPresence(entity, serialized)
end

local function hasExistingBlocker()
    local entity = Entity()
    if not entity then return false end

    local stacks = deserializeStacks(entity:getValue(stackValueKey))
    for _, amount in pairs(stacks) do
        if amount and amount > 0 then
            return true
        end
    end

    return false
end

function getName(seed, rarity)
    return displayName
end

function getIcon(seed, rarity)
    return icon
end

function getEnergy(seed, rarity, permanent)
    local energy = Config.energyByRarity and Config.energyByRarity[rarity.value]

    if not energy then
        local rangeUnits = Config.rangeByRarity[rarity.value] or 0
        local unitsPerKm = Config.unitsPerKilometer or 100
        local rangeKm = rangeUnits / unitsPerKm
        energy = (Config.energyBase or 0) + (Config.energyPerKm or 0) * rangeKm
    end

    energy = energy or 0

    if permanent then
        return energy
    else
        return energy * 1 -- hohe Strafe für temporären Einbau
    end
end

function getPrice(seed, rarity)
    return Config.priceBase + Config.pricePerRarity * (rarity.value + 1)
end

function getTooltipLines(seed, rarity, permanent)
    local rangeUnits = Config.rangeByRarity[rarity.value] or 0
    local unitsPerKm = Config.unitsPerKilometer or 100
    local rangeKm = rangeUnits / unitsPerKm
    return {
        {ltext = "Диапозон", rtext = string.format("%.0f km", rangeKm), icon = icon, boosted = permanent},
        {ltext = "Фиксированная установка", rtext = "Erforderlich", icon = "data/textures/icons/anchor.png", boosted = permanent},
    }
end

function getDescriptionLines(seed, rarity, permanent)
    return {description}
end

function onInstalled(seed, rarity, permanent)
    dbg("onInstalled rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    if not permanent then
        Entity():addScriptOnce("data/scripts/entity/hyperblockerwarning.lua")
    end

    if hasExistingBlocker() then
        dbg("Installation blocked: ship already has a Hyperblocker")
        return
    end

    ensureFieldScript()
    pushStackChange("addStack", rarity.value)
end

function onUninstalled(seed, rarity, permanent)
    dbg("onUninstalled rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    pushStackChange("removeStack", rarity.value)
end

function onAddedToShip(seed, rarity, permanent)
    dbg("onAddedToShip rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    if hasExistingBlocker() then
        dbg("Inventory add ignored: ship already has Hyperblocker")
        return
    end
    ensureFieldScript()
    pushStackChange("addStack", rarity.value)
end

function onRemovedFromShip(seed, rarity, permanent)
    dbg("onRemovedFromShip rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    pushStackChange("removeStack", rarity.value)
end

function canInstall(seed, rarity)
    return true
end


local function appendPackagePath(rule)
    if not package.path:find(rule, 1, true) then
        package.path = package.path .. ";" .. rule
    end
end

appendPackagePath("data/scripts/?.lua")
appendPackagePath("data/scripts/lib/?.lua")
appendPackagePath("data/scripts/systems/?.lua")
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

include("basesystem")
include("utility")
include("stringutility")
include("randomext")

local Config = include("lib/hyperblockerconfig") or {
    rarityOrder = {},
    rangeByRarity = {},
    energyBase = 0,
    energyPerKm = 0,
    priceBase = 0,
    pricePerRarity = 0,
    debugLogging = false,
}
local fieldScript = "data/scripts/entity/hyperblockerfield.lua"
local iconScript = "data/scripts/entity/icon.lua"
local blockerIcon = "data/textures/icons/pixel/block.png"
local stackValueKey = "hyperblockerStacks"
local debugLogging = Config.debugLogging == true
local ensureCheckTimer = 0

local function dbg(fmt, ...)
    if not debugLogging then return end
    local prefix = "[HyperBlocker] Hyperblocker.lua"
    if select('#', ...) > 0 then
        print(string.format(prefix .. ": " .. fmt, ...))
    else
        print(prefix .. ": " .. fmt)
    end
end

local function ownerTag()
    local entity = Entity()
    if not entity then return "<no-entity>" end
    local factionIndex = entity.factionIndex
    if not factionIndex then return string.format("entity=%s", tostring(entity.id and entity.id.string or entity.index)) end
    local faction = Faction(factionIndex)
    if faction then
        if faction.isAlliance then
            return string.format("alliance:%d %s", factionIndex, faction.name or "?")
        end
        if faction.isPlayer then
            return string.format("player:%d %s", factionIndex, faction.name or "?")
        end
        return string.format("faction:%d %s", factionIndex, faction.name or "?")
    end
    return string.format("faction:%s", tostring(factionIndex))
end

PermanentInstallationOnly = true
FixedEnergyRequirement = true
UniquePositive = false

local displayName = "Гиперпространственный блокатор"
local description = "Создает гиперпрыжковую блокаду для кораблей игроков и альянсов в пределах дальности, зависящей от редкости. Должен быть установлен стационарно."
local icon = "data/textures/icons/warhead.png"

local function ensureFieldScript()
    if not onServer() then return end
    local entity = Entity()
    if not entity then
        if debugLogging then
            print("[HyperBlocker] ensureFieldScript: Entity() returned nil")
        end
        return
    end

    local entityId = tostring(entity.index)
    if not entity:hasScript(fieldScript) then
        entity:addScriptOnce(fieldScript, false)
        dbg("Added field script to entity %s", entityId)
    elseif debugLogging then
        dbg("Entity %s already has field script", entityId)
    end
end

local function ensureIcon(entity)
    if entity:hasScript(iconScript) then
        entity:invokeFunction(iconScript, "set", blockerIcon)
    else
        entity:addScriptOnce(iconScript, blockerIcon)
    end
end

local function clearIcon(entity)
    if entity:hasScript(iconScript) then
        entity:invokeFunction(iconScript, "set", "")
    end
end

local function maintainFieldScriptPresence(entity, serializedStacks)
    if not onServer() then return end
    if not entity then return end

    local hasStacks = serializedStacks ~= nil and serializedStacks ~= ""
    local hasScript = entity:hasScript(fieldScript)

    if hasStacks and not hasScript then
        entity:addScriptOnce(fieldScript, false)
        dbg("Reattached field script to entity %s", tostring(entity.index))
    elseif not hasStacks and hasScript then
        entity:removeScript(fieldScript)
        dbg("Removed field script from entity %s", tostring(entity.index))
    end

    if hasStacks then
        ensureIcon(entity)
    else
        clearIcon(entity)
    end
end

local function deserializeStacks(serialized)
    local result = {}
    if type(serialized) ~= "string" or serialized == "" then
        return result
    end

    for chunk in string.gmatch(serialized, "([^,]+)") do
        local rarityStr, amountStr = chunk:match("(-?%d+):(-?%d+)")
        if rarityStr and amountStr then
            local rarityValue = tonumber(rarityStr)
            local amount = math.max(0, tonumber(amountStr) or 0)
            if rarityValue and amount > 0 then
                result[rarityValue] = amount
            end
        end
    end

    return result
end

local function serializeStacks(stacks)
    local keys = {}
    for rarityValue, amount in pairs(stacks) do
        if amount and amount > 0 then
            table.insert(keys, rarityValue)
        end
    end

    if #keys == 0 then
        return nil
    end

    table.sort(keys)

    local parts = {}
    for _, rarityValue in ipairs(keys) do
        table.insert(parts, string.format("%d:%d", rarityValue, stacks[rarityValue]))
    end

    return table.concat(parts, ",")
end


local function updateStoredStacks(change, rarityValue)
    local entity = Entity()
    if not entity then return end

    local stacks = deserializeStacks(entity:getValue(stackValueKey))
    local current = stacks[rarityValue] or 0
    local delta = change == "addStack" and 1 or -1
    local nextAmount = math.max(0, current + delta)

    if nextAmount > 0 then
        stacks[rarityValue] = nextAmount
    else
        stacks[rarityValue] = nil
    end

    local serialized = serializeStacks(stacks)
    if not serialized then
        entity:setValue(stackValueKey, "")
    else
        entity:setValue(stackValueKey, serialized)
    end
    maintainFieldScriptPresence(entity, serialized)

    local serializedState = entity:getValue(stackValueKey) or "<nil>"
    dbg("updateStoredStacks entity=%s change=%s rarity=%s -> %s (owner=%s)", tostring(entity.index), change, tostring(rarityValue), serializedState, ownerTag())
end

local function pushStackChange(change, rarityValue)
    if not onServer() then return end
    dbg("pushStackChange %s rarity=%s owner=%s", change, tostring(rarityValue), ownerTag())
    ensureFieldScript()
    updateStoredStacks(change, rarityValue)
end

function updateServer(timeStep)
    if not onServer() then return end

    ensureCheckTimer = (ensureCheckTimer or 0) - timeStep
    if ensureCheckTimer > 0 then return end
    ensureCheckTimer = 10

    local entity = Entity()
    if not entity then return end

    local serialized = entity:getValue(stackValueKey)
    maintainFieldScriptPresence(entity, serialized)
end

local function hasExistingBlocker()
    local entity = Entity()
    if not entity then return false end

    local stacks = deserializeStacks(entity:getValue(stackValueKey))
    for _, amount in pairs(stacks) do
        if amount and amount > 0 then
            return true
        end
    end

    return false
end

function getName(seed, rarity)
    return displayName
end

function getIcon(seed, rarity)
    return icon
end

function getEnergy(seed, rarity, permanent)
    local energy = Config.energyByRarity and Config.energyByRarity[rarity.value]

    if not energy then
        local rangeUnits = Config.rangeByRarity[rarity.value] or 0
        local unitsPerKm = Config.unitsPerKilometer or 100
        local rangeKm = rangeUnits / unitsPerKm
        energy = (Config.energyBase or 0) + (Config.energyPerKm or 0) * rangeKm
    end

    energy = energy or 0

    if permanent then
        return energy
    else
        return energy * 1 -- hohe Strafe für temporären Einbau
    end
end

function getPrice(seed, rarity)
    return Config.priceBase + Config.pricePerRarity * (rarity.value + 1)
end

function getTooltipLines(seed, rarity, permanent)
    local rangeUnits = Config.rangeByRarity[rarity.value] or 0
    local unitsPerKm = Config.unitsPerKilometer or 100
    local rangeKm = rangeUnits / unitsPerKm
    return {
        {ltext = "Гиперпространственный блокатор", rtext = string.format("%.0f km", rangeKm), icon = icon, boosted = permanent},
        {ltext = "Стационарная установка", rtext = "Требуется", icon = "data/textures/icons/anchor.png", boosted = permanent},
    }
end

function getDescriptionLines(seed, rarity, permanent)
    return {description}
end

function onInstalled(seed, rarity, permanent)
    dbg("onInstalled rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    if not permanent then
        Entity():addScriptOnce("data/scripts/entity/hyperblockerwarning.lua")
    end

    if hasExistingBlocker() then
        dbg("Installation blocked: ship already has a Hyperblocker")
        return
    end

    ensureFieldScript()
    pushStackChange("addStack", rarity.value)
end

function onUninstalled(seed, rarity, permanent)
    dbg("onUninstalled rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    pushStackChange("removeStack", rarity.value)
end

function onAddedToShip(seed, rarity, permanent)
    dbg("onAddedToShip rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    if hasExistingBlocker() then
        dbg("Inventory add ignored: ship already has Hyperblocker")
        return
    end
    ensureFieldScript()
    pushStackChange("addStack", rarity.value)
end

function onRemovedFromShip(seed, rarity, permanent)
    dbg("onRemovedFromShip rarity=%s permanent=%s owner=%s", rarity and rarity.value or "<nil>", tostring(permanent), ownerTag())
    pushStackChange("removeStack", rarity.value)
end

function canInstall(seed, rarity)
    return true
end
