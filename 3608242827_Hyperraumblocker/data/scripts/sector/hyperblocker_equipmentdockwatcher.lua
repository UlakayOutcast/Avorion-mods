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

-- namespace HyperblockerEquipmentDockWatcher
HyperblockerEquipmentDockWatcher = {}
local self = HyperblockerEquipmentDockWatcher
local equipmentDockScript = "data/scripts/entity/merchants/equipmentdock.lua"
local augmentScript = "entity/hyperblocker_equipmentdockaugment.lua"

local function log(message)
    if config.debugLogging then
        print(string.format("[HyperBlocker] DockWatcher: %s", message))
    end
end

local function attachToEntity(entity)
    if not valid(entity) then return end
    if not entity:hasScript(equipmentDockScript) then return end
    if entity:hasScript(augmentScript) then return end

    entity:addScriptOnce(augmentScript)

    if config.debugLogging then
        local name = entity.name or entity.title or entity.index
        log(string.format("Augment angefügt an %s (%s)", tostring(name), tostring(entity.index)))
    end
end

local function refreshExisting()
    local sector = Sector()
    if not sector then return end

    for _, entity in pairs({sector:getEntitiesByScript(equipmentDockScript)}) do
        attachToEntity(entity)
    end
end

function HyperblockerEquipmentDockWatcher.initialize()
    if not onServer() then return end

    local sector = Sector()
    if not sector then return end

    sector:registerCallback("onEntityCreated", "onEntityCreated")
    local x, y = sector:getCoordinates()
    log(string.format("Watcher aktiv in (%d:%d)", x or -1, y or -1))
    refreshExisting()
end

function HyperblockerEquipmentDockWatcher.onEntityCreated(entityId)
    if not onServer() then return end
    local entity = Entity(entityId)
    attachToEntity(entity)
end

function HyperblockerEquipmentDockWatcher.refresh()
    if not onServer() then return end
    refreshExisting()
end


return HyperblockerEquipmentDockWatcher
