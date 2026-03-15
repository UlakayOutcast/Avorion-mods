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

local config = include("lib/hyperblockerconfig") or {}

-- namespace HyperblockerInstaller
HyperblockerInstaller = {}
local self = HyperblockerInstaller

local watcherScript = "sector/hyperblocker_equipmentdockwatcher.lua"

local function log(message)
    if config.debugLogging then
        print(string.format("[HyperBlocker] PlayerInstaller: %s", message))
    end
end

local function ensureWatcher()
    if not onServer() then return end

    local sector = Sector()
    if not sector then return end

    local x, y = sector:getCoordinates()

    if not sector:hasScript(watcherScript) then
        sector:addScriptOnce(watcherScript)
        log(string.format("Watcher nachgeladen in (%d:%d)", x or -1, y or -1))
    else
        sector:invokeFunction(watcherScript, "refresh")
        log(string.format("Watcher aktualisiert in (%d:%d)", x or -1, y or -1))
    end
end

function HyperblockerInstaller.initialize()
    if not onServer() then return end

    local player = Player()
    if not player then return end

    player:registerCallback("onSectorChanged", "onSectorChanged")
    player:registerCallback("onSectorEntered", "onSectorChanged")
    log(string.format("Callbacks registriert für Spieler %s", player.name or player.index))

    ensureWatcher()
end

function HyperblockerInstaller.onSectorChanged()
    ensureWatcher()
end
