package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("randomext")

-- namespace XsologizeBossLaser
XsologizeBossLaser = {}
local self = XsologizeBossLaser

--All of the various messages come with a _RequireDebugLevel parameter baked in. If you wish to see some specific messages, you can find those and set
--_RequireDebugLevel to 0 for those messages. You can also set self._Debug to match it. Most messages are going to require level 1 but some require more.
self._Debug = 0

self._Data = {}

local laser = nil
local targetlaser = nil

local _LookConstant = 210

self._LaserData = {}
self._LaserData._From = nil
self._LaserData._To = nil
self._LaserData._TargetPoint = nil

function XsologizeBossLaser.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing Laser Sniper v66 script on entity.", 1)

    self._Data = _Values or {}

    --Values the player isn't meant to adjust.
    self._Data._TargetLaserActive = false
    self._Data._TargetBeamActiveTime = 0
    self._Data._CurrentTarget = nil
    self._Data._FireCycle = nil
    self._Data._TargetPoint = nil

    --Values the player can adjust.
    self._Data._MaxRange = 20000
    self._Data._TargetCycle = 2 --Starts targeting when the firing cycle is greater than this value - set to increase amount of time between shots.
    self._Data._TargetingTime = 1.75 --Amount of time it takes to target the laser.
    self._Data._CreepingBeam = self._Data._CreepingBeam or true
    self._Data._CreepingBeamSpeed = self._Data._CreepingBeamSpeed  or 0.75
    --TARGET PRIORITIES:
    -- 1 - Random enemy - must be ship or station.
    -- 2 - Any non-Xsotan ship or station.
    -- 3 - Any entity with a specified scriptvalue - chosen by self._Data._TargetTag - for example, is_pirate would target any enemies with is_pirate set.
    -- 4 - The target player's current ship. Set with _pindex. Works similarly to TorpedoSlammer's priority 5.
    self._Data._TargetPriority = 4
    --Target priority 3 goes off of self._Data._TargetTag which can be nil - it is deliberately not set here, I did not miss it.

    --Fix the target priority - if the ship isn't Xsotan make it use 1 instead of 2.
    if self._Data._TargetPriority == 4 and self._Data._pindex == nil then
        self._Data._TargetPriority = 1
    end

    Entity():registerCallback("onDestroyed", "onDestroyed")
end

function XsologizeBossLaser.onDestroyed()
    XsologizeBossLaser.deleteCurrentLasers()
end

function XsologizeBossLaser.update(_TimeStep)
    local _MethodName = "Update"

    XsologizeBossLaser.updateLaser()

    if onServer() then
        if self._Data._CurrentTarget == nil or not valid(self._Data._CurrentTarget) then
            self._Data._CurrentTarget = self.pickNewTarget()
            self._Data._FireCycle = 0
        else
            self._Data._FireCycle = (self._Data._FireCycle or 0) + _TimeStep
            if self._Data._FireCycle >= self._Data._TargetCycle then
                if not self._Data._TargetLaserActive then
                    self.Log(_MethodName, "No target laser active - creating one.", 1)
                    self.createTargetingLaser()
                    self._Data._TargetLaserActive = true
                    self._Data._TargetBeamActiveTime = 0
                else
                    self._Data._TargetBeamActiveTime = (self._Data._TargetBeamActiveTime or 0) + _TimeStep
                    self.showChargeEffect()
                end
            end
            if self._Data._FireCycle >= self._Data._TargetCycle + self._Data._TargetingTime then --Target for X seconds, then fire.
                --Explode, delete lasers, set value, and terminate. shot laser will never be active.
                Entity():setValue("_horizon_story9_laserexplosion", true)
                self.showExplosion(Entity())
                self.deleteCurrentLasers()
                terminate()
                return
            end
        end
        --Send data to client.
        self.sync(self._Data)
    end
end

function XsologizeBossLaser.pickNewTarget()
    local _MethodName = "Pick New Target"

    local _TargetCandidates = {}

    if self._Data._pindex then
        self.Log(_MethodName, "pindex is " .. tostring(self._Data._pindex), 2)
        local _PlayerTarget = Player(self._Data._pindex)
        local _PlayerTargetShip = Entity(_PlayerTarget.craft.id)

        if _PlayerTargetShip and valid(_PlayerTargetShip) then
            table.insert(_TargetCandidates, _PlayerTargetShip)
        end
    end

    if #_TargetCandidates > 0 then
        shuffle(random(), _TargetCandidates)
        self.Log(_MethodName, "Found at least one suitable target. Picking a random one.", 1)
        return _TargetCandidates[1]
    else
        self.Log(_MethodName, "WARNING - Could not find any target candidates.", 1)
        return nil
    end
end

--region #CLIENT CALLS

function XsologizeBossLaser.updateLaser()
    local _MethodName = "Update Laser"
    if onClient() then
        local _Entity = Entity()
        if not laser or not valid(laser) or not _Entity or not valid(_Entity) then
            --Set this to log level 7 - highly reccommend keeping it there unless you absolutely need this message. The spam is unreal.
            self.Log(_MethodName, "Laser not valid!!! Returning immediately.", 7)
            return
        end

        local _boss = Entity()
        self._LaserData._TargetPoint = self._LaserData._TargetPoint or self._Data._TargetPoint

        if self._Data._CreepingBeam then
            --Creep the laser towards the target to make it harder to evade.
            local _CreepSpeed = self._Data._CreepingBeamSpeed

            local _Target = self._Data._CurrentTarget
            if not valid(_Target) then
                self.Log(_MethodName, "Target is not valid!!! Returning immediately.", 1)
                return
            end
            local _TargetLoc = _Target.translationf
            local _Dir = _TargetLoc - self._LaserData._TargetPoint

            local _Direction = normalize(_Dir) * _CreepSpeed
            self._LaserData._TargetPoint = self._LaserData._TargetPoint + _Direction
        end

        local _From = _boss.translationf
        local _TargetPoint = self._LaserData._TargetPoint
        local _Dir = _TargetPoint - _From 
        local _Direction = normalize(_Dir)

        laser.from = _From
        laser.to = _From + (_Direction * _LookConstant)
        laser.aliveTime = 0

        if not _From or not _Direction then
            self.Log(_MethodName, "WARNING - _From is " .. tostring(_From) .. " or _Direction is " .. tostring(_Direction), 1)
        end

        targetlaser.from = laser.to
        targetlaser.to = laser.to + (_Direction * self._Data._MaxRange)
        targetlaser.aliveTime = 0

        self._LaserData._From = targetlaser.from
        self._LaserData._To = targetlaser.to

        --Send laser data back to the server.
        XsologizeBossLaser.syncLaserData(self._LaserData)
    end
end

--endregion

--region #CLIENT / SERVER CALLS

function XsologizeBossLaser.createTargetingLaser()
    local _MethodName = "Create Targeting Laser"
    laserActive = true

    local _Entity = Entity()
    local _TargetEntity = self._Data._CurrentTarget
    self._Data._TargetPoint = _TargetEntity.translationf

    if onServer() then
        self.Log(_MethodName, "Calling on Server - invoking on Client", 1)
        broadcastInvokeClientFunction("createTargetingLaser")
        return
    else
        self.Log(_MethodName, "Calling on client", 1)
    end

    self.Log(_MethodName, "Entity targeted is " .. tostring(_TargetEntity.name) .. " and its position is " .. tostring(self._Data._TargetPoint), 1)

    XsologizeBossLaser.deleteCurrentLasers()
    XsologizeBossLaser.createLaser(1, ColorRGB(0, 1, 0), true, _Entity.translationf, self._Data._TargetPoint)
end

--Creating the laser
function XsologizeBossLaser.createLaser(_Width, _Color, _Collision, _From, _TargetPoint)
    local _MethodName = "Create Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on Server - invoking on Client", 1)
        broadcastInvokeClientFunction("createLaser")
        return
    else
        self.Log(_MethodName, "Calling on client - values are : _Width : " .. tostring(_Width) .. " - _Color : " .. tostring(_Color) .. " - _Collision : " .. tostring(_Collision) .. " - _From : " .. tostring(_From) .. " - _TargetPoint : " .. tostring(_TargetPoint), 1)
    end

    local _Color = _Color or ColorRGB(0.1, 0.1, 0.1)

    local _Dir = _TargetPoint - _From
    local _Direction = normalize(_Dir)

    self.Log(_MethodName, "Target point is : " .. tostring(_TargetPoint) .. " and from is : " .. tostring(_From), 1)
    self.Log(_MethodName, "_Dir is : " .. tostring(_Dir), 1)

    local _lFrom = _From
    local _lTo = _From + (_Direction * _LookConstant)
    laser = Sector():createLaser(vec3(), vec3(), _Color, _Width or 1)
    laser.from = _lFrom
    laser.to = _lTo
    laser.collision = false

    self.Log(_MethodName, "Making laser from : " .. tostring(_lFrom) .. " to : " .. tostring(_lTo), 1)
    if not laser then
        self.Log(_MethodName, "WARNING! laser is nil", 1)
    end

    local _ltFrom = _lTo
    local _ltTo = _lTo + (_Direction * self._Data._MaxRange)
    targetlaser = Sector():createLaser(vec3(), vec3(), _Color, _Width or 1)
    targetlaser.from = _ltFrom
    targetlaser.to = _ltTo
    targetlaser.collision = _Collision

    self.Log(_MethodName, "Making target laser from : " .. tostring(_ltFrom) .. " to : " .. tostring(_ltTo), 1)
    if not targetlaser then
        self.Log(_MethodName, "WARNING! targetlaser is nil", 1)
    end

    self._LaserData._From = _ltFrom
    self._LaserData._To = _ltTo
    --Have to set this for both for it to sync properly.
    self._LaserData._TargetPoint = _TargetPoint
    self._Data._TargetPoint = _TargetPoint

    self.Log(_MethodName, "self._Data._TargetPoint is " .. tostring(self._Data._TargetPoint), 1)

    laser.maxAliveTime = 5
    targetlaser.maxAliveTime = 5
end

--Shows a glow effect - size corresponds to how long the laser has been charging for.
function XsologizeBossLaser.showChargeEffect()
    if onServer() then
        broadcastInvokeClientFunction("showChargeEffect", entity)
        return
    end

    if not laser or not valid(laser) then return end
    local from = laser.from
    local size = 75 + (75 * self._Data._TargetBeamActiveTime)

    if not from then return end
    Sector():createGlow(from, size, ColorRGB(0.2,0.2,1))
    Sector():createGlow(from, size, ColorRGB(0.2,0.2,1))
    Sector():createGlow(from, size, ColorRGB(0.2,0.2,1))
end

--Shows a large explosion. Broadcast invokes the client function if it is called on the server.
function XsologizeBossLaser.showExplosion(entity)
    if onServer() then
        broadcastInvokeClientFunction("showExplosion", entity)
        return
    end

    if not entity then return end
    local position = entity.translationf
    local _Bounds = entity:getBoundingSphere()
    Sector():createExplosion(position, _Bounds.radius, false)
end

--Removes laser and targetlaser. Broadcast invokes the client function if it is called on the server.
function XsologizeBossLaser.deleteCurrentLasers()
    local _MethodName = "Delete Current Lasers"
    if onServer() then
        self.Log(_MethodName, "Calling on Server - invoking on Client", 1)
        broadcastInvokeClientFunction("deleteCurrentLasers")
        return
    else
        self.Log(_MethodName, "Calling on client", 1)
    end

    if valid(laser) then Sector():removeLaser(laser) end
    if valid(targetlaser) then Sector():removeLaser(targetlaser) end
end

--Sends _Data from the server to the client. If this is called on the client it will either set _Data, OR it will attempt to get _Data again.
function XsologizeBossLaser.sync(_Data_In)
    if onServer() then
        broadcastInvokeClientFunction("sync", self._Data)
    else
        if _Data_In then
            self._Data = _Data_In
        else
            invokeServerFunction("sync")
        end
    end
end
callable(XsologizeBossLaser, "sync")

--Sends _LaserData from the client to the server.
function XsologizeBossLaser.syncLaserData(_Data_In)
    if onClient() then
        invokeServerFunction("syncLaserData", self._LaserData)
    else
        self._LaserData = _Data_In
    end
end
callable(XsologizeBossLaser, "syncLaserData")

--Log function
function XsologizeBossLaser.Log(_MethodName, _Msg, _RequireDebugLevel)
    _RequireDebugLevel = _RequireDebugLevel or 1

    if self._Debug >= _RequireDebugLevel then
        print("[XsologizeBossLaser] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function XsologizeBossLaser.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data", 1)
    return self._Data
end

function XsologizeBossLaser.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data", 1)
    self._Data = _Values
end

--endregion