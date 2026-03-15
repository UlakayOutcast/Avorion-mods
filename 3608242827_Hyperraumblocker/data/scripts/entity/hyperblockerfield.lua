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

include("galaxy")
include("utility")
include("stringutility")
include("faction")
include("player")
include("callable")

local Config = include("lib/hyperblockerconfig") or {
    rarityOrder = {},
    rangeByRarity = {},
    energyBase = 0,
    energyPerKm = 0,
    priceBase = 0,
    pricePerRarity = 0,
}

local stackValueKey = "hyperblockerStacks"
local debugLogging = Config.debugLogging == true

local active = true
local activeStacks = {}
local currentRange = 0
local rangeSquared = 0
local ui = {}

local function playerCanInteract(playerIndex)
    if not playerIndex then return false end

    local entity = Entity()
    if not entity then return false end

    if playerIndex == entity.factionIndex then
        return true
    end

    if onServer() then
        local player = Player(playerIndex)
        if player then
            if player.allianceIndex == entity.factionIndex then
                return true
            end
        else
            local faction = Faction(playerIndex)
            if faction and faction.index == entity.factionIndex then
                return true
            end
        end
    else
        local ownerFaction = Faction(entity.factionIndex)
        if ownerFaction and ownerFaction.isAlliance then
            local player = Player()
            return player and player.allianceIndex == ownerFaction.index
        end
    end

    return false
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

local function recalcRange()
    local best = 0
    for rarityValue, amount in pairs(activeStacks) do
        if amount and amount > 0 then
            local range = Config.rangeByRarity[rarityValue] or 0
            if range > best then
                best = range
            end
        end
    end

    currentRange = best
    rangeSquared = best * best

    if debugLogging then
        print(string.format("[HyperBlocker] Range updated to %.0f km", (currentRange or 0) / 1000))
    end
end

local function syncStacksFromEntity()
    local entity = Entity()
    if not entity then return end

    activeStacks = deserializeStacks(entity:getValue(stackValueKey))
    recalcRange()

    if not next(activeStacks) then
        if debugLogging then
            print(string.format("[HyperBlocker] No stacks left on %s, terminating field script", tostring(entity.index)))
        end
        terminate()
        return false
    end

    return true
end

function secure()
    return {
        stacks = activeStacks,
        range = currentRange,
        active = active,
    }
end

function restore(data)
    activeStacks = data and data.stacks or {}
    currentRange = data and data.range or 0
    active = not (data and data.active == false)
    rangeSquared = currentRange * currentRange
end

function initialize(active_in)
    if active_in == nil then
        active = false
    else
        active = active_in ~= 0 and active_in ~= false
    end

    syncStacksFromEntity()
end

function getUpdateInterval()
    return 2.0
end

function interactionPossible(playerIndex, option)
    return playerCanInteract(playerIndex)
end

function initUI()
    local menu = ScriptUI()
    local res = getResolution()
    local size = vec2(340, 150)
    local rect = Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5)

    local window = menu:createWindow(rect)
    window.caption = "Hyperraumblocker"%_t
    window.showCloseButton = true
    window.moveable = true

    menu:registerWindow(window, "Hyperraumblocker"%_t)

    window:createLabel(vec2(15, 30), "Schaltet den Blocker ein oder aus."%_t, 14)
    ui.toggleButton = window:createButton(Rect(15, 70, size.x - 15, 110), "Aktivieren/Deaktivieren"%_t, "onToggleButtonPressed")
end

function onToggleButtonPressed()
    if onClient() then
        invokeServerFunction("toggleActive")
    else
        toggleActive()
    end
end

local function blockShips()
    if not active or currentRange <= 0 then return end

    local entity = Entity()
    local sector = Sector()
    if not entity or not sector then return end

    local position = entity.translationf
    local ships = {sector:getEntitiesByComponent(ComponentType.HyperspaceEngine)}

    for _, ship in pairs(ships) do
        local d2 = distance2(position, ship.translationf)
        if d2 <= rangeSquared then
            ship:blockHyperspace(2.5)
            if debugLogging then
                print(string.format("[HyperBlocker] Blocking %s within %.0f km", ship.name or ship.index.string, currentRange / 1000))
            end
        end
    end
end

function updateServer(timeStep)
    if not onServer() then return end
    if not syncStacksFromEntity() then return end
    blockShips()
end

function onShowWindow()
end

function toggleActive()
    if callingPlayer and not playerCanInteract(callingPlayer) then
        return
    end

    active = not active

    if debugLogging then
        local state = active and "on" or "off"
        print(string.format("[HyperBlocker] Toggled %s", state))
    end
end
callable(nil, "toggleActive")

function activate()
    active = true
end

function deactivate()
    active = false
end
