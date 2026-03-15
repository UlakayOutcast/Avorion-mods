package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

ESCCUtil = include("esccutil")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Meathook
Meathook = {}
local self = Meathook

self._Debug = 0

self._Data = {}

local laser = nil

self._LaserData = {}
self._LaserData._From = nil
self._LaserData._To = nil

function Meathook.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Adding v23 of meathook.lua to entity.")

    self._Data = _Values or {}

    --Values the player isn't meant to adjust
    self._Data._CurrentTarget = nil
    self._Data._FireCycle = 0
    self._Data._OffsetCycle = 0
    self._Data._PullActiveTime = 0

    --Values the player is meant to adjust.
    self._Data._Power = self._Data._Power or 10
    self._Data._PullDuration = self._Data._PullDuration or 5
    self._Data._Cycle = self._Data._Cycle or 25
    self._Data._Offset = self._Data._Offset or 0
    self._Data._TargetPriority = self._Data._TargetPriority or 1 --1 is random, 2 is farthest enemy.

    Entity():registerCallback("onDestroyed", "onDestroyed")
end

function Meathook.onDestroyed()
    Meathook.deleteCurrentLasers()
end

function Meathook.getUpdateInterval()
    return 0 --call on every frame.
end

function Meathook.update(_TimeStep)
    local _MethodName = "Update"
    Meathook.updateLaser()

    if onServer() then
        self._Data._OffsetCycle = (self._Data._OffsetCycle or 0) + _TimeStep
        if self._Data._OffsetCycle < self._Data._Offset then
            return
        end

        if self._Data._CurrentTarget == nil or not valid(self._Data._CurrentTarget) then
            self._Data._CurrentTarget = self.pickNewTarget()
            self._Data._FireCycle = 0
        else
            self._Data._FireCycle = (self._Data._FireCycle or 0) + _TimeStep
            if self._Data._FireCycle >= self._Data._Cycle then
                self.Log(_MethodName, "Firing pull laser.")
                self.createLaser(15.0, Entity().translationf, self._Data._CurrentTarget.translationf)
                self._Data._PullLaserActive = true
                self._Data._PullActiveTime = 0
                self._Data._FireCycle = 0
                self.Log(_MethodName, "Target position is: " .. tostring(self._Data._CurrentTarget.translationf))
            end

            if self._Data._PullLaserActive then
                self._Data._PullActiveTime = (self._Data._PullActiveTime or 0) + _TimeStep
                self.repositionTarget()
                if self._Data._PullActiveTime >= self._Data._PullDuration then
                    self._Data._PullLaserActive = false
                    self.deleteCurrentLasers()
                    self.Log(_MethodName, "Target position is: " .. tostring(self._Data._CurrentTarget.translationf))
                end
            end
        end
    end
end

--region #CLIENT functions

function Meathook.repositionPlayerTarget(_idx, _Shift)
    if onClient() then
        local _Target = Entity(_idx)
        local _TargetPosition = _Target.position
        _TargetPosition.translation = _TargetPosition.translation - _Shift
        _Target.position = _TargetPosition
        --Apply a slight penalty to velocity.
        local _TargetVelocity = Velocity(_idx)
        local _NormalizedVelocity = normalize(_TargetVelocity.velocity)
        _TargetVelocity.velocity = _TargetVelocity.velocity - _NormalizedVelocity
    end
end

--endregion

--region #SERVER functions

function Meathook.pickNewTarget()
    local _MethodName = "Pick New Target"
    local _Factionidx = Entity().factionIndex
    local _Rgen = ESCCUtil.getRand()

    local _Enemies = {Sector():getEnemies(_Factionidx)}
    local _TargetCandidates = {}

    if self._Data._TargetPriority == 1 then --Pick random target.
        for _, _Enemy in pairs(_Enemies) do
            table.insert(_TargetCandidates, _Enemy)
        end
    elseif self._Data._TargetPriority == 2 then --Pick target that is the farthest away from me.
        local _TargetValue = 0
        local _DistanceCandidatePairs = {}
        for _, _Enemy in pairs(_Enemies) do
            local _MyPosition = Entity().translationf
            local _EnemyPosition = _Enemy.translationf
            local _Dist = distance(_MyPosition, _EnemyPosition)
            if _Dist > _TargetValue then
                _TargetValue = _Dist
            end
            table.insert(_DistanceCandidatePairs, {Enemy = _Enemy, Dist = _Dist})
        end

        for _, _DCPairs in pairs(_DistanceCandidatePairs) do
            if _DCPairs.Dist == _TargetValue then
                table.insert(_TargetCandidates, _DCPairs.Enemy)
            end
        end
    end

    if #_TargetCandidates > 0 then
        self.Log(_MethodName, "Found at least one suitable target. Picking a random one.")
        return _TargetCandidates[_Rgen:getInt(1, #_TargetCandidates)]
    else
        self.Log(_MethodName, "WARNING - Could not find any target candidates.")
        return nil
    end
end

function Meathook.repositionTarget()
    local _MethodName = "Reposition"
    local _MyPosition = Entity().translationf
    local _EnemyPosition = self._Data._CurrentTarget.translationf

    local _Radius = Entity():getBoundingSphere().radius
    local _DistanceToTarget = distance(_MyPosition, _EnemyPosition)
    local _MinPullDistance = _Radius * 3
    if _DistanceToTarget > _MinPullDistance then
        local _Difference = _EnemyPosition - _MyPosition
        local _NormalizedPosition = normalize(_Difference)
        local _Shift = _NormalizedPosition * self._Data._Power

        --Get the player's current ship - if it is the current ship, we have to set it on the client.
        local _EnemyFaction = Faction(self._Data._CurrentTarget.factionIndex)
        if _EnemyFaction.isPlayer then
            local _EnemyPlayer = Player(_EnemyFaction.index)
            local _PlayerShip = _EnemyPlayer.craft
            if _PlayerShip.index == self._Data._CurrentTarget.index then
                invokeClientFunction(_EnemyPlayer, "repositionPlayerTarget", _PlayerShip.index, _Shift)
            else
                local _NMEMatrix = self._Data._CurrentTarget.position
		        _NMEMatrix.translation = _NMEMatrix.translation - _Shift
                self._Data._CurrentTarget.position = _NMEMatrix
                --Apply a slight penalty to velocity.
                local _NMEVelocity = Velocity(self._Data._CurrentTarget.index)
                local _NormalizedVelocity = normalize(_NMEVelocity.velocity)
                _NMEVelocity.velocity = _NMEVelocity.velocity - _NormalizedVelocity
            end
        else
            local _NMEMatrix = self._Data._CurrentTarget.position
            _NMEMatrix.translation = _NMEMatrix.translation - _Shift
            self._Data._CurrentTarget.position = _NMEMatrix
            --Apply a slight penalty to velocity.
            local _NMEVelocity = Velocity(self._Data._CurrentTarget.index)
            local _NormalizedVelocity = normalize(_NMEVelocity.velocity)
            _NMEVelocity.velocity = _NMEVelocity.velocity - _NormalizedVelocity
        end
    else
        --self.Log(_MethodName, "Distance is " .. tostring(_DistanceToTarget) .. " this is less than the radius^2 * 3 (" .. tostring(_MinPullDistance) .. ") - not pulling in.")
    end
end

--endregion

--region #CLIENT / SERVER functions

function Meathook.createLaser(_Width, _From, _To)
    local _MethodName = "Create Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on Server - invoking on Client")
        broadcastInvokeClientFunction("createLaser", _Width, _From, _To)
        return
    else
        self.Log(_MethodName, "Calling on client - values are : _Width : " .. tostring(_Width) .. " - _From : " .. tostring(_From) .. " - _To : " .. tostring(_To))
    end

    local _Color = ColorRGB(0.0, 0.6, 1.0)

    local _lFrom = _From
    local _lTo = _To
    laser = Sector():createLaser(vec3(), vec3(), _Color, _Width or 1)
    laser.from = _lFrom
    laser.to = _lTo
    laser.collision = false

    self.Log(_MethodName, "Making laser from : " .. tostring(_lFrom) .. " to : " .. tostring(_lTo))
    if not laser then
        self.Log(_MethodName, "WARNING! laser is nil")
    end

    laser.maxAliveTime = 2
end

function Meathook.updateLaser()
    local _MethodName = "Update Laser"

    if onServer() then
        if not self._Data._PullLaserActive or not self._Data._CurrentTarget then 
            return
        end

        local _Entity = Entity()
        local _Target = self._Data._CurrentTarget

        local _From = _Entity.translationf
        local _To = _Target.translationf

        self._LaserData._From = _From
        self._LaserData._To = _To

        Meathook.syncLaserData({_From = _From, _To = _To})
    else --onClient()
        if not laser or not self._LaserData._From or not self._LaserData._To then
            return
        end

        laser.from = self._LaserData._From
        laser.to = self._LaserData._To
        laser.aliveTime = 0
    end
end

function Meathook.deleteCurrentLasers()
    local _MethodName = "Delete Current Lasers"
    if onServer() then
        self.Log(_MethodName, "Calling on Server - invoking on Client")
        broadcastInvokeClientFunction("deleteCurrentLasers")
        return
    else
        self.Log(_MethodName, "Calling on client")
    end

    if valid(laser) then Sector():removeLaser(laser) end
end

function Meathook.syncLaserData(_Data_In)
    if onServer() then
        broadcastInvokeClientFunction("syncLaserData", self._LaserData)
    else
        if _Data_In then
            self._LaserData = _Data_In
        else
            invokeServerFunction("syncLaserData")
        end
    end
end
callable(Meathook, "syncLaserData")

function Meathook.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[Meathook] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function Meathook.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function Meathook.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion