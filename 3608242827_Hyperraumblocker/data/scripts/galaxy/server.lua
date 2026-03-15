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

local injector = include("lib/systemupgradegenerator")
local config = include("lib/hyperblockerconfig") or {}

local playerInstallerScript = "player/background/hyperblocker_equipmentdockinstaller.lua"

local generatorPatched = false
local retryTimer = 0
local retryInterval = 15
local serverCallbacksRegistered = false

local function tryPatch()
    if not injector or type(injector.apply) ~= "function" then
        print("[HyperBlocker] Injector nicht verfügbar.")
        return
    end

    local ok = injector.apply()
    if ok then
        generatorPatched = true
    else
        print("[HyperBlocker] UpgradeGenerator-Patch fehlgeschlagen, erneuter Versuch folgt.")
    end
end

local function ensurePlayerInstaller(player)
    if not player or not player.addScriptOnce then return end

    if player:hasScript(playerInstallerScript) then return end

    local ok, err = pcall(function()
        player:addScriptOnce(playerInstallerScript)
    end)

    if not ok then
        print(string.format("[HyperBlocker] Installer konnte nicht angehängt werden (%s): %s", tostring(playerInstallerScript), tostring(err)))
        return
    end

    if config.debugLogging then
        print(string.format("[HyperBlocker] Dock-Installer bei Spieler %s aktiv.", player.name or player.index))
    end
end

local function registerServerCallbacks()
    if serverCallbacksRegistered then return end

    local server = Server()
    if server then
        server:registerCallback("onPlayerLogIn", "onPlayerLogIn")
        serverCallbacksRegistered = true
    end
end

local function ensureInstallersForOnlinePlayers()
    local players = {Server():getPlayers()}
    for _, player in pairs(players) do
        ensurePlayerInstaller(player)
    end
end

function onPlayerLogIn(playerIndex)
    if not onServer() then return end
    local player = Player(playerIndex)
    ensurePlayerInstaller(player)
end

function initialize()
    if not generatorPatched then tryPatch() end
    registerServerCallbacks()
    ensureInstallersForOnlinePlayers()
end

function update(timeStep)
    if generatorPatched then return end

    retryTimer = retryTimer + timeStep
    if retryTimer >= retryInterval then
        retryTimer = 0
        if not generatorPatched then tryPatch() end
    end
end
