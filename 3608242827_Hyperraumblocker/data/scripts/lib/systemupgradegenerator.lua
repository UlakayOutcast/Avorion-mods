local function appendPackagePath(rule)
    if not package.path:find(rule, 1, true) then
        package.path = package.path .. ";" .. rule
    end
end

appendPackagePath("data/scripts/?.lua")
appendPackagePath("data/scripts/lib/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/?.lua")
appendPackagePath("mods/HyperBlocker/data/scripts/lib/?.lua")

local Injector = {}
local hyperblockerScript = "data/scripts/systems/hyperblocker.lua"
local Config = include("lib/hyperblockerconfig") or {}
local DEFAULT_WEIGHT = 0.5

local function getDesiredWeight()
    local weight = Config.generatorWeight
    if type(weight) ~= "number" or weight <= 0 then
        return DEFAULT_WEIGHT
    end
    return weight
end

local function findUpgradeGeneratorClass(constructor)
    if type(constructor) ~= "function" then return nil end

    local index = 1
    while true do
        local name, value = debug.getupvalue(constructor, index)
        if not name then break end
        if name == "UpgradeGenerator" and type(value) == "table" then
            return value
        end
        index = index + 1
    end
end

local function findScriptsTable(initializeFunc)
    if type(initializeFunc) ~= "function" then return nil end

    local index = 1
    while true do
        local name, value = debug.getupvalue(initializeFunc, index)
        if not name then break end
        if name == "scripts" and type(value) == "table" then
            return value
        end
        index = index + 1
    end
end

local function ensureEntry(target)
    if type(target) ~= "table" then return false end
    local desiredWeight = getDesiredWeight()
    local existing = target[hyperblockerScript]
    if existing then
        if type(existing) == "table" then
            existing.weight = desiredWeight
        else
            target[hyperblockerScript] = {
                weight = desiredWeight,
                dist2ToCenter = nil,
            }
        end
        return false
    end

    target[hyperblockerScript] = {
        weight = desiredWeight,
        dist2ToCenter = nil,
    }
    return true
end

local function wrapInitialize(upgradeClass)
    if Injector._initializeWrapped then
        return
    end

    local originalInitialize = upgradeClass.initialize
    if type(originalInitialize) ~= "function" then
        return
    end

    upgradeClass.initialize = function(self, ...)
        originalInitialize(self, ...)
        if self and self.scripts then
            ensureEntry(self.scripts)
        end
    end

    Injector._initializeWrapped = true
end

function Injector.apply()
    if Injector._applied then
        return true
    end

    local ok, moduleOrError = pcall(include, "upgradegenerator")
    if not ok then
        print("[HyperBlocker] upgradegenerator include fehlgeschlagen: " .. tostring(moduleOrError))
        return false
    end

    local generatorModule = moduleOrError
    local constructor = generatorModule and (generatorModule.new or (getmetatable(generatorModule) and getmetatable(generatorModule).__call))
    if not constructor then
        print("[HyperBlocker] UpgradeGenerator-Konstruktor nicht gefunden.")
        return false
    end

    local upgradeClass = findUpgradeGeneratorClass(constructor)
    if not upgradeClass then
        print("[HyperBlocker] UpgradeGenerator-Klasse nicht gefunden.")
        return false
    end

    local scriptsTable = findScriptsTable(upgradeClass.initialize)
    if not scriptsTable then
        print("[HyperBlocker] UpgradeGenerator scripts-Upvalue nicht gefunden.")
        return false
    end

    local inserted = ensureEntry(scriptsTable)
    wrapInitialize(upgradeClass)
    Injector._applied = true

    if inserted then
        print("[HyperBlocker] Hyperraumblocker im UpgradeGenerator registriert.")
    end

    return true
end

return Injector
