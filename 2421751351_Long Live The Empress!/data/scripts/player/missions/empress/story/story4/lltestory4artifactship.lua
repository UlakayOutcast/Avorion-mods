--Custom AI script.
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")
include ("randomext")
include ("callable")
ESCCUtil = include("esccutil")

--namespace ArtifactShip
ArtifactShip = {}
local self = ArtifactShip

self._Debug = 0

ArtifactShip._Data = {}

function ArtifactShip.initialize(_ToEntity)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing v32 of Artifact Ship AI")

    --Immediately set the AI idle. ArtifactShip will tell it how to behave instead of the default ship AI.
    local ai = ShipAI()
    local ship = Entity()
    --print("ArtifactShip AI successfully attached to " .. ship.name)

    ai:stop()
    ai:setIdle()

    ship:registerCallback("onDestroyed", "onDestroyed")
    
    self._Data._MinDist = ship:getBoundingSphere().radius * 2.9
    self._Data._LaserMinDist = ship:getBoundingSphere().radius * 3.3
    self._Data._ToEntity = _ToEntity
    self._Data._LaserTimer = 0
end

function ArtifactShip.onDestroyed()
    local _MethodName = "On Destroyed"
    self.Log(_MethodName, "Artifact ship destroyed - removing lasers.")

    if onServer() then
        self.stopLaser()
    end
end

function ArtifactShip.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    local _Ship = Entity()
    if valid(self._Data._ToEntity) then
        local _ToPosition = self._Data._ToEntity.translationf

        local ai = ShipAI()
        ai:setFlyLinear(_ToPosition, self._Data._MinDist, false)
    
        self.Log(_MethodName, "ToPositon is " .. tostring(_ToPosition) .. " -- Translationf is " .. tostring(_Ship.translationf), 0)
    
        local _DistanceToTarget = distance(_ToPosition, _Ship.translationf)
        if _DistanceToTarget <= self._Data._LaserMinDist then
            if not self._Data._StartedLaser then
                self.Log(_MethodName, "Starting laser")
                
                self.startLaser(_Ship.translationf, _ToPosition)
    
                self._Data._StartedLaser = true
            else
                if math.floor(self._Data._LaserTimer) % 1 == 0 then
                    self.updateLaser(_Ship.translationf, _ToPosition)
                end
                if self._Data._LaserTimer < 25 then
                    self._Data._LaserTimer = self._Data._LaserTimer + _TimeStep
                else
                    self.stopLaser()
                    self.callJumpFunction()
                end
            end
        end
    end
end

--region #CLIENTSIDE ONLY LASER FUNCTIONS

function ArtifactShip.startLaser(_v1, _v2)
    local _MethodName = "Start Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on server - invoking on client.")
        broadcastInvokeClientFunction("startLaser", _v1, _v2)
        return
    else
        self.Log(_MethodName, "Calling on client.")
    end
    self._Data._Laser = Sector():createLaser(_v1, _v2, ESCCUtil.getSaneColor(0, 27, 255), 6)
    self._Data._Laser.collision = false
    self._Data._Laser.maxAliveTime = 26
end
callable(ArtifactShip, "startLaser")

function ArtifactShip.updateLaser(_v1, _v2)
    local _MethodName = "Update Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on server - invoking on client.")
        broadcastInvokeClientFunction("updateLaser", _v1, _v2)
        return
    else
        self.Log(_MethodName, "Calling on client.")
    end 
    if self._Data._Laser then
        self._Data._Laser.from = _v1
        self._Data._Laser.to = _v2
    else
        self.Log(_MethodName, "ERROR: Tried to update laser but laser is nil.")
    end
end
callable(ArtifactShip, "updateLaser")

function ArtifactShip.stopLaser()
    local _MethodName = "Stop Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on server - invoking on client.")
        broadcastInvokeClientFunction("stopLaser")
        return
    else
        self.Log(_MethodName, "Calling on client.")
    end
    if valid(self._Data._Laser) then
        Sector():removeLaser(self._Data._Laser)
        self._Data._Laser = nil
    end
end
callable(ArtifactShip, "stopLaser")

--endregion

function ArtifactShip.callJumpFunction()
    local _MethodName = "Call Jump Function"
    if onClient() then
        self.Log(_MethodName, "Calling on Client - invoking on server.", 0)
        invokeServerFunction("callJumpFunction")
        return
    else
        self.Log(_MethodName, "Calling on Server", 0)
        if not self._Data._CalledJumpFunction then
            --Get players in sector. If one of them has the 4th story mission script, invoke a specific function on it.
            local _PlayersInSector = {Sector():getPlayers()}
            for _, _P in pairs(_PlayersInSector) do
				_P:invokeFunction("player/missions/empress/story/lltestorymission4.lua", "returnToLastStop")
            end
            self._Data._CalledJumpFunction = true
        end
    end
end
callable(ArtifactShip, "callJumpFunction")

function ArtifactShip.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Artifact Ship] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--region #SECURE / RESTORE CALLS

function ArtifactShip.secure()
    return self._Data
end

function ArtifactShip.restore(_Data)
    self._Data = _Data
end

--endregion