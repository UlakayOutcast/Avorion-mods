package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

local Xsotan = include("story/xsotan")

--namespace Reanimator
Reanimator = {}
local self = Reanimator

self._Debug = 0

self.data = {}

function Reanimator.initialize(_Values)
    local methodName = "Initialize"
    self.Log(methodName, "Adding v3 of reanimator.lua to entity.")

    self.data = _Values or {}

    --[ADJUSTABLE VALUES]
    self.data.maxGlobalRevenants = self.data.maxGlobalRevenants or 10
    self.data.maxRevenantCharges = self.data.maxRevenantCharges or 1
    self.data.maxReanimationVolumeFactor = self.data.maxReanimationVolumeFactor or 100

    --[UNADJUSTABLE VALUES]
    self.data.nextReanimationAt = 10
    self.data.revenantCharges = 0
    self.data.revenantTimer = 0
end

function Reanimator.getUpdateInterval()
    return 1
end

function Reanimator.updateServer(timeStep)
    local methodName = "Update Server"
    self.Log(methodName, "Running.")

    self.data.revenantTimer = (self.data.revenantTimer or 0) + timeStep
    if self.data.revenantTimer >= self.data.nextReanimationAt and self.data.revenantCharges < self.data.maxRevenantCharges then
        self.Log(methodName, "Accumulating charge")
        self.data.revenantCharges = self.data.revenantCharges + 1
        self.data.nextReanimationAt = random():getInt(4, 7)
        self.data.revenantTimer = 0
    end

    if ShipAI():isEnemyPresent(true) and self.data.revenantCharges > 0 then
        local _Revenants = {Sector():getEntitiesByScriptValue("is_revenant")}
        local _RevenantCt = #_Revenants
        if _RevenantCt < self.data.maxGlobalRevenants then
            --Find a suitable wreckage.
            local _Wreck = Reanimator.findSuitableWreck()
            if _Wreck then
                self.Log(methodName, "Found wreck - creating Revenant")
                local _WreckPosition = _Wreck.translationf
                --Make a revenant out of it.
                Xsotan.createRevenant(_Wreck)
                self.data.revenantCharges = self.data.revenantCharges - 1
                --Make the laser.
                self.createLaser(Entity().translationf, _WreckPosition)
            end
        end
    end
end

function Reanimator.findSuitableWreck()
    local methodName = "Find Suitable Wreck"
    self.Log(methodName, "Running.")

    --Get table of candidate wreckages
    local _sector = Sector()
    local x, y = _sector:getCoordinates()
    local _Wreckages = { _sector:getEntitiesByType(EntityType.Wreckage)}
    local maximumVolumeToRevive = Balancing_GetSectorShipVolume(x, y) * self.data.maxReanimationVolumeFactor

    --Pick all candidate wrecks that are above 200 blocks and less than or equal to the maximum volume to revive.
    shuffle(random(), _Wreckages)
    local _CandidateWrecks = {}
    for _, _Wreck in pairs(_Wreckages) do
        local _Pl = Plan(_Wreck.id)
        if _Pl.numBlocks >= 200 and _Pl.volume <= maximumVolumeToRevive then
            table.insert(_CandidateWrecks, _Wreck)
        end
    end

    if #_CandidateWrecks > 0 then
        return randomEntry(_CandidateWrecks)
    else
        return
    end
end

--region #CLIENT functions

function Reanimator.createLaser(_From, _To)
    if onServer() then
        broadcastInvokeClientFunction("createLaser", _From, _To)
        return
    end

    local _Color = ColorRGB(0.8, 0.0, 0.8)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(_From, _To, _Color, 16)

    _Laser.maxAliveTime = 1.5
    _Laser.collision = false
end

--endregion

--region #CLIENT / SERVER functions

function Reanimator.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[Reanimator] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function Reanimator.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self.data")
    return self.data
end

function Reanimator.restore(_Values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self.data")
    self.data = _Values
end

--endregion