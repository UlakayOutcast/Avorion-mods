package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("randomext")

-- namespace LaserSniper
LaserSniper = {}
local self = LaserSniper

--All of the various messages come with a _RequireDebugLevel parameter baked in. If you wish to see some specific messages, you can find those and set
--_RequireDebugLevel to 0 for those messages. You can also set self._Debug to match it. Most messages are going to require level 1 but some require more.
self._Debug = 0
self._DebugLevel = 1
self._Target_Invincible_Debug = 0

self._Data = {}

local laser = nil
local targetlaser = nil

local _LookConstant = 210

self._LaserData = {}
self._LaserData._From = nil
self._LaserData._To = nil
self._LaserData._TargetPoint = nil

function LaserSniper.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing Laser Sniper v72 script on entity.", 1)

    self._Data = _Values or {}

    if onServer() then
        local _entity = Entity()
        local self_is_xsotan = _entity:getValue("is_xsotan")
        local defaultTargetPriority = 1
        if self_is_xsotan then
            defaultTargetPriority = 2
        end
    
        Boarding(_entity).boardable = false
    
        if not _restoring then
            self.Log(_MethodName, "_restore is not set - setting initial data.")

            --Values the player isn't meant to adjust.
            self._Data._TimeToActive = self._Data._TimeToActive or 0
            self._Data._TargetLaserActive = false
            self._Data._TargetBeamActiveTime = 0
            self._Data._MaxBeamActiveTime = 2 --How long the beam is active for.
            self._Data._BeamActiveTime = 0
            self._Data._ShotLaserActive = false
            self._Data._BeamMisses = 0
            self._Data._CurrentTarget = nil
            self._Data._FireCycle = nil
            self._Data._DOTCycle = 0
            self._Data._TargetPoint = nil
            self._Data._StaticDamageMultSet = false
            self._Data._StaticDamageMultValue = 1
        
            --Values the player can adjust.
            self._Data._MaxRange = self._Data._MaxRange or 20000
            self._Data._DamagePerFrame = self._Data._DamagePerFrame or 100000 --100k
            self._Data._ShieldPen = self._Data._ShieldPen or false
            self._Data._TargetCycle = self._Data._TargetCycle or 10 --Starts targeting when the firing cycle is greater than this value - set to adjust amount of time between shots.
            self._Data._TargetingTime = self._Data._TargetingTime or 1.75 --Amount of time it takes to target the laser.
            self._Data._CreepingBeam = self._Data._CreepingBeam or true
            self._Data._CreepingBeamSpeed = self._Data._CreepingBeamSpeed  or 0.75
            self._Data._UseEntityDamageMult = self._Data._UseEntityDamageMult or false
            self._Data._UseStaticDamageMult = self._Data._UseStaticDamageMult or false
            self._Data._IncreaseDamageOT = self._Data._IncreaseDamageOT or false
            self._Data._IncreaseDOTCycle = self._Data._IncreaseDOTCycle or 0
            self._Data._IncreaseDOTAmount = self._Data._IncreaseDOTAmount or 0
            self._Data._DamageFactor = self._Data._DamageFactor or 1
            --TARGET PRIORITIES:
            -- 1 - Random enemy - must be ship or station.
            -- 2 - Any non-Xsotan ship or station.
            -- 3 - Any entity with a specified scriptvalue - chosen by self._Data._TargetTag - for example, is_pirate would target any enemies with is_pirate set.
            -- 4 - The target player's current ship. Set with _pindex. Works similarly to TorpedoSlammer's priority 5.
            -- 5 - a random player or alliance owned ship / station.
            self._Data._TargetPriority = self._Data._TargetPriority or defaultTargetPriority
            --Target priority 3 goes off of self._Data._TargetTag which can be nil - it is deliberately not set here, I did not miss it.
        
            --Fix the target priority - if the ship isn't Xsotan make it use 1 instead of 2.
            if self._Data._TargetPriority == 2 and not self_is_xsotan then
                self._Data._TargetPriority = 1 --Just use 1.
            end
            if self._Data._TargetPriority == 4 and self._Data._pindex == nil then
                self._Data._TargetPriority = 1
            end
        else
            self.Log(_MethodName, "Restoring data from self.Restore()")
        end
    else
        --onClient()
        self._Data._TimeToActive = self._Data._TimeToActive or 0 --Need this or it spams the hell out of client logs.
    end

    Entity():registerCallback("onDestroyed", "onDestroyed")
end

function LaserSniper.onDestroyed()
    LaserSniper.deleteCurrentLasers()
end

function LaserSniper.update(_TimeStep)
    local _MethodName = "Update"

    local _entity = Entity()

    if self._Data._TimeToActive >= 0 then
        self._Data._TimeToActive = self._Data._TimeToActive - _TimeStep
        return
    end

    --If Xsotan, don't start blasting unless enemies are present.
    if _entity:getValue("is_xsotan") then
        local myAI = ShipAI()
        if not myAI:isEnemyPresent(true) then
            return
        end
    end

    if self._Data._LookConstantOverride then
        _LookConstant = self._Data._LookConstantOverride
    end
    LaserSniper.updateLaser()

    if onServer() then
        --If we're using a static damage multiplier, set it here. We only do this once.
        if self._Data._UseStaticDamageMult and not self._Data._StaticDamageMultSet then
            local _Mult = (_entity.damageMultiplier or 1)
            self.Log(_MethodName, "Setting static multiplier to: " .. tostring(_Mult), 1)
            self._Data._StaticDamageMultValue = _Mult
            self._Data._StaticDamageMultSet = true
        end

        --Retarget if missing too frequently
        if self._Data._BeamMisses >= 5 then
            self.Log(_MethodName, "Beam has missed too frequently. Picking a new target.", 1)
            self._Data._CurrentTarget = nil
            self._Data._BeamMisses = 0
        end

        --Manage increasing damage over time
        if self._Data._IncreaseDamageOT then
            self._Data._DOTCycle = (self._Data._DOTCycle or 0) + _TimeStep
            if self._Data._DOTCycle >= self._Data._IncreaseDOTCycle then
                self._Data._DamagePerFrame = self._Data._DamagePerFrame + self._Data._IncreaseDOTAmount
                self.Log(_MethodName, "Increasing damage per frame - new value is " .. tostring(self._Data._DamagePerFrame), 1)
                self._Data._DOTCycle = 0
            end
        end

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
                self.Log(_MethodName, "Firing big laser and resetting fire cycle.", 1)
                self.createShotLaser()
                self._Data._BeamMisses = self._Data._BeamMisses + 1
                self._Data._TargetLaserActive = false
                self._Data._ShotLaserActive = true
                self._Data._FireCycle = 0
                self._Data._BeamActiveTime = 0
            end

            if self._Data._ShotLaserActive then
                LaserSniper.updateIntersection(_TimeStep)
                self._Data._BeamActiveTime = (self._Data._BeamActiveTime or 0) + _TimeStep
                if self._Data._BeamActiveTime >= self._Data._MaxBeamActiveTime then
                    self._Data._ShotLaserActive = false
                    self._Data._CreepTime = 0
                    self.deleteCurrentLasers()
                end
            end
        end
        --Send data to client.
        self.sync(self._Data)
    end
end

function LaserSniper.updateIntersection(_TimeStep)
    local _MethodName = "Update Intersection"
    if onClient() then return end

    local ray = Ray()
    ray.origin = vec3(self._LaserData._From) or vec3()
    ray.direction = (vec3(self._LaserData._To) or vec3()) - ray.origin
    ray.planeIntersectionThickness = 6
    if not ray then 
        return 
    end

    local boss = Entity()
    _Entity = Sector():intersectBeamRay(ray, boss, nil)
    if _Entity then
        if _Entity.type == EntityType.Asteroid or _Entity.type == EntityType.Wreckage then
            self.showExplosion(_Entity)
            _Entity:destroy(boss.id, 1, DamageType.Energy)
            if _Entity then Sector():deleteEntity(_Entity) end
        else
            self._Data._BeamMisses = 0
            local _Shield = Shield(_Entity.id)

            --Require log level 3 for these to avoid spam. It's not quite as bad as log level 5 but it's still rough.
            local _EntityDamageMultiplier = 1
            if self._Data._UseEntityDamageMult then
                if self._Data._UseStaticDamageMult then
                    _EntityDamageMultiplier = (self._Data._StaticDamageMultValue or 1)
                    self.Log(_MethodName, "Static damage multiplier is " .. tostring(_EntityDamageMultiplier), 3)
                else
                    _EntityDamageMultiplier = (boss.damageMultiplier or 1)
                    self.Log(_MethodName, "Damage multiplier is " .. tostring(_EntityDamageMultiplier), 3)
                end
            end

            local _DamageToShield = self._Data._DamagePerFrame * _EntityDamageMultiplier * self._Data._DamageFactor
            local _DamageToHull = 0

            self.Log(_MethodName, "Inflicting " .. tostring(_DamageToShield) .. " damage", 3)

            --We'll be nice and not bypass shields this time, unlike IHDTX-style lasers.
            if _Shield and not self._Data._ShieldPen then
                if _Shield.durability < _DamageToShield then
                    _DamageToHull = _DamageToShield - _Shield.durability
                    _DamageToShield = _Shield.durability
                end
                if _DamageToShield > 0 then
                    _Shield:inflictDamage(_DamageToShield, 1, DamageType.Energy, boss.translationf, boss.id)
                end
            else
                _DamageToHull = _DamageToShield
            end

            if _DamageToHull > 0 then
                local durability = Durability(_Entity.id)
                if not durability then return end
                durability:inflictDamage(_DamageToHull, 1, DamageType.Energy, boss.id)
            end
        end
    end
end

function LaserSniper.pickNewTarget()
    local _MethodName = "Pick New Target"
    local _Factionidx = Entity().factionIndex
    local _TargetPriority = self._Data._TargetPriority

    --Pick a random target for now. I had this done by highest firepower, but I think it made the sniper too predictable.
    --Now remodeled to make it harder for my dumb ass to put an infinite loop in and explode my computer :3
    local _Sector = Sector()
    local _RawEnemies = {_Sector:getEnemies(_Factionidx)} 
    local _Enemies = {}
    for _, _RawEnemy in pairs(_RawEnemies) do
        if _RawEnemy.type == EntityType.Ship or _RawEnemy.type == EntityType.Station then
           table.insert(_Enemies, _RawEnemy) 
        end
    end

    local _TargetCandidates = {}

    local _TargetPriorityFunctions = {
        function() --1 - pick an enemy at random.
            for _, _Candidate in pairs(_Enemies) do
                table.insert(_TargetCandidates, _Candidate)
            end
        end,
        function() --2 - pick a random non-Xostan
            local _Ships = {_Sector:getEntitiesByType(EntityType.Ship)}
            local _Stations = {_Sector:getEntitiesByType(EntityType.Station)}

            for _, _Candidate in pairs(_Ships) do
                if not self.isXsotanCheck(_Candidate) then
                    table.insert(_TargetCandidates, _Candidate)
                end
            end

            for _, _Candidate in pairs(_Stations) do
                if not self.isXsotanCheck(_Candidate) then
                    table.insert(_TargetCandidates, _Candidate)
                end
            end
        end,
        function() --3 - pick enemies with a specific script value.
            local _Entities = {_Sector:getEntitiesByScriptValue(self._Data._TargetTag)}
            for _, _Candidate in pairs(_Entities) do
                table.insert(_TargetCandidates, _Candidate)
            end
        end,
        function() --4 - pick the player's current ship. Similar to TorpedoSlammer's priority 5
            if self._Data._pindex then
                local _PlayerTarget = Player(self._Data._pindex)
                local _PlayerTargetShip = Entity(_PlayerTarget.craft.id)

                if _PlayerTargetShip and valid(_PlayerTargetShip) then
                    table.insert(_TargetCandidates, _PlayerTargetShip)
                end
            end
        end,
        function() --5 - random player or alliance ship or station
            local _Entities = { _Sector:getEntities() }
            for _, _Candidate in pairs(_Entities) do
                if (_Candidate.type == EntityType.Ship or _Candidate.type == EntityType.Station) and _Candidate.playerOrAllianceOwned then
                    table.insert(_TargetCandidates, _Candidate)
                end
            end
        end
    }

     _TargetPriorityFunctions[_TargetPriority]()

    if #_TargetCandidates > 0 then
        local chosenCandidate = nil
        local attempts = 0

        self.Log(_MethodName, "Found at least one suitable target. Picking a random one.", 1)

        while not chosenCandidate and attempts < 10 do
            local randomPick = randomEntry(_TargetCandidates)
            if self.invincibleTargetCheck(randomPick) then
                chosenCandidate = randomPick
            end
            attempts = attempts + 1
        end

        if not chosenCandidate then
            self.Log(_MethodName, "Could not find a non-invincible target in 10 tries - picking one at random", 1)
            chosenCandidate = randomEntry(_TargetCandidates)
        end
        
        return chosenCandidate
    else
        self.Log(_MethodName, "WARNING - Could not find any target candidates.", 1)
        return nil
    end
end

function LaserSniper.invincibleTargetCheck(entity)
    if not entity.invincible or self._Target_Invincible_Debug == 1 then
        return true
    else
        return false
    end
end

function LaserSniper.isXsotanCheck(entity)
    --Minions don't have the is_xsotan tag set, so we need to set up a list.
    local xsotanTags = {
        "is_xsotan",
        "xsotan_summoner_minion",
        "xsotan_master_summoner_minion", --We're unlikely to see these, but hey! you never know.
        "xsotan_revenant"
    }

    for idx, tag in pairs(xsotanTags) do
        if entity:getValue(tag) then
            return true
        end
    end

    return false
end

--region #SERVER => EXTERNAL ADJ METHODS

function LaserSniper.resetTimeToActive(_Time)
    self._Data._TimeToActive = _Time
end

function LaserSniper.adjustDamage(_dmg)
    local _MethodName = "Adjusting Damage"
    self.Log(_MethodName, "Adjusting damage from external call. Setting to " .. tostring(_dmg) .. " per update", 1)

    self._Data._DamagePerFrame = _dmg
end

function LaserSniper.adjustTargetPrio(_prio, _tag)
    local _MethodName = "Adjusting Priority"
    self.Log(_MethodName, "Adjusting target priority / tag from external call. Setting priority to " .. tostring(_prio) .. " and tag to " .. tostring(_tag), 1)

    self._Data._TargetPriority = _prio
    self._Data._TargetTag = _tag
    --Forcibly reset the target so another is picked in line w/ the new priority.
    self._Data._CurrentTarget = nil
end

--endregion

--region #CLIENT CALLS

function LaserSniper.updateLaser()
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
            if self._Data._ShotLaserActive then
                _CreepSpeed = _CreepSpeed * 0.8
            end

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
        LaserSniper.syncLaserData(self._LaserData)
    end
end

--endregion

--region #CLIENT / SERVER CALLS

function LaserSniper.createTargetingLaser()
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

    LaserSniper.deleteCurrentLasers()
    LaserSniper.createLaser(1, ColorRGB(0, 1, 0), true, _Entity.translationf, self._Data._TargetPoint)
end

--Creating the shot laser
function LaserSniper.createShotLaser()
    local _MethodName = "Create Shot Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on Server - invoking on Client", 1)
        broadcastInvokeClientFunction("createShotLaser")
        return
    else
        self.Log(_MethodName, "Calling on client", 1)
    end

    --Continue to shoot from the last point calculated by the targeting laser.
    local _Entity = Entity()
    local _TargetPoint = self._LaserData._TargetPoint

    self.Log(_MethodName, "Target point is " .. tostring(self._LaserData._TargetPoint), 1)

    LaserSniper.deleteCurrentLasers()
    LaserSniper.createLaser(20, ColorRGB(1, 0, 0), false, _Entity.translationf, _TargetPoint)
end

--Creating the laser
function LaserSniper.createLaser(_Width, _Color, _Collision, _From, _TargetPoint)
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
function LaserSniper.showChargeEffect()
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
function LaserSniper.showExplosion(entity)
    if onServer() then
        broadcastInvokeClientFunction("showExplosion", entity)
        return
    end

    if not entity then return end
    local position = entity.translationf
    local _Bounds = entity:getBoundingSphere()
    Sector():createExplosion(position, math.max(_Bounds.radius, 200), false)
end

--Removes laser and targetlaser. Broadcast invokes the client function if it is called on the server.
function LaserSniper.deleteCurrentLasers()
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
function LaserSniper.sync(_Data_In)
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
callable(LaserSniper, "sync")

--Sends _LaserData from the client to the server.
function LaserSniper.syncLaserData(_Data_In)
    if onClient() then
        invokeServerFunction("syncLaserData", self._LaserData)
    else
        self._LaserData = _Data_In
    end
end
callable(LaserSniper, "syncLaserData")

--endregion

--region #LOG / SECURE / RESTORE

function LaserSniper.Log(_MethodName, _Msg, _RequireDebugLevel)
    _RequireDebugLevel = _RequireDebugLevel or 1

    if self._Debug == 1 and self._DebugLevel >= _RequireDebugLevel then
        print("[LaserSniper] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function LaserSniper.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data", 1)
    return self._Data
end

function LaserSniper.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data", 1)
    self._Data = _Values
end

--endregion