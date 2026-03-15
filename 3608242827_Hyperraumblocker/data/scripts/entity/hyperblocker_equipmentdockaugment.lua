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

local Hook = include("lib/equipmentdockhook") or {}

-- namespace HyperblockerEquipmentDockAugment
HyperblockerEquipmentDockAugment = {}
local self = HyperblockerEquipmentDockAugment
local equipmentDockScript = "data/scripts/entity/merchants/equipmentdock.lua"

self._retryTimer = 0
self._retryInterval = 5
self._hooked = false

local function tryApply()
    if not onServer() then
        return true
    end

    local station = Entity()
    if not station or not station:hasScript(equipmentDockScript) then
        return false
    end

    local equipmentDock = _G.EquipmentDock
    if not equipmentDock or not equipmentDock.shop then
        return false
    end

    if Hook and Hook.wrapShop then
        local ok = Hook.wrapShop(equipmentDock.shop)
        if ok then
            self._hooked = true
            return true
        end
    end

    return false
end

function HyperblockerEquipmentDockAugment.initialize()
    if not onServer() then
        return
    end

    tryApply()
end

function HyperblockerEquipmentDockAugment.update(timeStep)
    if not onServer() then
        return
    end

    if self._hooked then
        return
    end

    self._retryTimer = self._retryTimer + (timeStep or 0)
    if self._retryTimer >= self._retryInterval then
        self._retryTimer = 0
        tryApply()
    end
end

return HyperblockerEquipmentDockAugment
