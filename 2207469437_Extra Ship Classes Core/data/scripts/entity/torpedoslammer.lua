package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("randomext")

local TorpedoGenerator = include ("torpedogenerator")

--namespace TorpedoSlammer
TorpedoSlammer = {}
local self = TorpedoSlammer

self._Debug = 0
self._Target_Invincible_Debug = 0

self._DebugLevel = 1 --Determines what debug messages show.

self._Data = {}
--[[
    Some of these values are self-explanatory, but here's a guide to how this thing works:
        _ROF                    = A torpedo is fired once per _ROF seconds.
        _FireCycle              = Keeps track of how much time has passed. Sets to 0 every time a torp fires.
        _TimeToActive           = Time in seconds until this script becomes active.
        _CurrentTarget          = The current target of the script
        _PreferWarheadType      = This script will always use this warhead type if this value is supplied. Otherwise a random type is used.
        _PreferSecondaryWarheadType     = If _PreferWarheadType is also set, this allows a second type of warhead to be picked at random. Does nothing if _PreferWarheadType is not set.
        _PreferBodyType         = This script will always use this body type if this value is supplied. Otherwise a random type is used.
        _UpAdjust               = Adjusts the spawned torpedo upwards or not. Used for not spawning a torpedo in the ship's bounding box which does weird shit to the AI.
        _UpAdjustFactor         = Determines how much upwards to adjust the spawned torpedo. Defaults to 1.
        _DamageFactor           = Multiplies the amount of damage the torpedo does.
        _ForwardAdjustFactor    = Adjusts how far forward a torpedo spawns relative to the attached entity. Used for not spawning a torpedo in the ship's bounding box which does weird shit to the AI.
        _DurabilityFactor       = Multiplies the durability of torpedoes by this amount. Useful for making torpedoes that are hard to shoot down.
        _UseEntityDamageMult    = Multiplies the damage of the torpedoes by the attached entity's damage multiplier. Useful for overdrive or avenger enemies.
        _UseStaticDamageMult    = Sets a multiplier on the first update and does not dynamically use the entity's damage multiplier.
        _TargetPriority         = Target priority set per below:
            1 = most firepower
            2 = by script value
            3 = random non-xsotan
            4 = random enemy
            5 = player's current ship - specified by _pindex
            6 = random pirate or xsotan
            7 = random player or alliance ship or station
        _TargetTag              = The script value to target by - "xtest1" for example would target by Sector():getByScriptValue("xtest1")
        _TorpOffset             = Applies an offset to torpedo generation. Defaults to 0. Set to a negative value for higher tech level torpedoes.
        _pindex                 = The index of the player to target w/ _TargetPriority 5. _TargetPriority cannot be set to 5 if this value is nil.
        _ReachFactor            = Multiplies the reach of each torpedo by this value. Defaults to 1.
        _AccelFactor            = Multiplies the acceleration of each torpedo by this value. Defaults to 1.
        _VelocityFactor         = Multiplies the velocity of each torpedo by this value. Defaults to 1.
        _TurningSpeedFactor     = Multiplies the turning speed of each torpedo by this value. Defaults to 1.
        _ShockwaveFactor        = Multiplies the size of the shockwave. Defaults to 1.
        _LimitAmmo              = Set to true / false - if true, this script will terminate when _Ammo is 0 or less.
        _Ammo                   = Amount of ammo.
        _FireBarrage            = Set to true / false - if true, this script will fire barrages of torpedoes.
        _BarrageCount           = # of additional torpedos to fire in the barrage
        _BarrageDelay           = length of time between subsequent torpedoes in each barrage. _BarrageCount 4 / _BarrageDelay 0.5 would fire four extra torpedoes with a delay of 0.5s between each.

        Example:

        local _TorpSlammerValues = {}
        _TorpSlammerValues._TimeToActive = 12
        _TorpSlammerValues._ROF = 2
        _TorpSlammerValues._UpAdjust = false
        _TorpSlammerValues._DamageFactor = _TorpedoFactor
        _TorpSlammerValues._DurabilityFactor = _TorpDuraFactor
        _TorpSlammerValues._ForwardAdjustFactor = 1

        _Boss:addScriptOnce("torpedoslammer.lua", _TorpSlammerValues)

        Alternate example:

        local TorpedoUtility = include ("torpedoutility")
        _Boss:addScriptOnce("torpedoslammer.lua", { _ROF = 1, _TimeToActivate = 5, _PreferWarheadType = TorpedoUtility.WarheadType.EMP, _PreferBodyType = TorpedoUtility.BodyType.Hawk})
]]

function TorpedoSlammer.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing Torpedo Slammer v23 script on entity.", 1)

    self._Data = _Values or {}

    if onServer() then
        local _entity = Entity()

        local self_is_xsotan = _entity:getValue("is_xsotan")
        local defaultTargetPriority = 1
        if self_is_xsotan then
            defaultTargetPriority = 3
        end

        Boarding(_entity).boardable = false

        if not _restoring then
            --Stuff the player can't mess with.
            self._Data._FireCycle = 0
            self._Data._CurrentTarget = nil
            self._Data._StaticDamageMultSet = false
            self._Data._StaticDamageMultValue = 1
        
            --Preferred warhead / body type aren't set - if they are nil, that is fine.
            self._Data._TimeToActive = self._Data._TimeToActive or 10
            self._Data._ROF = self._Data._ROF or 1
            self._Data._UpAdjust = self._Data._UpAdjust or false
            self._Data._UpAdjustFactor = self._Data._UpAdjustFactor or 1
            self._Data._DamageFactor = self._Data._DamageFactor or 1
            self._Data._ForwardAdjustFactor = self._Data._ForwardAdjustFactor or 1
            self._Data._DurabilityFactor = self._Data._DurabilityFactor or 1
            self._Data._UseEntityDamageMult = self._Data._UseEntityDamageMult or false
            self._Data._UseStaticDamageMult = self._Data._UseStaticDamageMult or false
            self._Data._TargetPriority = self._Data._TargetPriority or defaultTargetPriority
            self._Data._TorpOffset = self._Data._TorpOffset or 0
            self._Data._ReachFactor = self._Data._ReachFactor or 1
            self._Data._AccelFactor = self._Data._AccelFactor or 1
            self._Data._VelocityFactor = self._Data._VelocityFactor or 1
            self._Data._ShockwaveFactor = self._Data._ShockwaveFactor or 1
            self._Data._TurningSpeedFactor = self._Data._TurningSpeedFactor or 1
            self._Data._LimitAmmo = self._Data._LimitAmmo or false
            self._Data._Ammo = self._Data._Ammo or -1
            --_pindex, _PreferWarheadType, _PreferBodyType, _TargetTag, and _FireBarrage can all be nil.
            self._Data._BarrageCount = self._Data._BarrageCount or 0
            self._Data._BarrageDelay = self._Data._BarrageDelay or math.huge
    
            --Fix the target priority - if the ship isn't Xsotan make it use 4 instead of 3.
            if self._Data._TargetPriority == 3 and not self_is_xsotan then
                self.Log(_MethodName, "Enttiy is not xsotan - adjusting target priority", 1)
                self._Data._TargetPriority = 4 --Just use 4. It's functionally the same as 3 but you won't target yourself due to the list of non-xsotan including you.
            end
            if self._Data._TargetPriority == 5 and self._Data._pindex == nil then
                self.Log(_MethodName, "Player index not set - adjusting target priority", 1)
                self._Data._TargetPriority = 4
            end
    
            self.Log(_MethodName, "Setting UpAdjust to : " .. tostring(self._Data._UpAdjust), 1)
            self.Log(_MethodName, "Preferred warhead type is : " .. tostring(self._Data._PreferWarheadType), 1)
            self.Log(_MethodName, "Preferred bodty type is : " .. tostring(self._Data._PreferBodyType), 1)
        else
            self.Log(_MethodName, "Restoring data from self.Restore()")
        end
    end
end

function TorpedoSlammer.getUpdateInterval()
    return 1
end

function TorpedoSlammer.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    self.Log(_MethodName, "Running...", 3)
    if self._Data._UseStaticDamageMult and not self._Data._StaticDamageMultSet then
        local _Mult = (Entity().damageMultiplier or 1)
        self.Log(_MethodName, "Setting static multiplier to: " .. tostring(_Mult), 1)
        self._Data._StaticDamageMultValue = _Mult
        self._Data._StaticDamageMultSet = true
    end

    if self._Data._TimeToActive >= 0 then
        self._Data._TimeToActive = self._Data._TimeToActive - _TimeStep
    else
        --If Xsotan, don't start blasting unless enemies are present.
        if Entity():getValue("is_xsotan") then
            local myAI = ShipAI()
            if not myAI:isEnemyPresent(true) then
                return
            end
        end

        --check to see if we limit ammo. If we do limit ammo and the amount of ammo left is 0 or less! no negative ammo here, terminate and return.
        if self._Data._LimitAmmo then
            if self._Data._Ammo <= 0 then
                self.Log(_MethodName, "Out of ammo - terminating script.", 1)
                terminate()
                return
            end
        end

        self._Data._FireCycle = self._Data._FireCycle + _TimeStep
        if self._Data._CurrentTarget == nil or not valid(self._Data._CurrentTarget) then
            self._Data._CurrentTarget = self.pickNewTarget()
        end

        if self._Data._CurrentTarget and valid(self._Data._CurrentTarget) then
            if self._Data._FireCycle >= self._Data._ROF then
                self.fireAtTarget()
                if self._Data._FireBarrage then
                    for barragePosition = 1, self._Data._BarrageCount do
                        deferredCallback(self._Data._BarrageDelay * barragePosition, "fireAtTarget")
                    end
                end
                self._Data._FireCycle = 0

                if self._Data._LimitAmmo then
                    self._Data._Ammo = self._Data._Ammo - 1
                    if self._Data._FireBarrage then
                        self._Data._Ammo = self._Data._Ammo - self._Data._BarrageCount
                    end
                    self.Log(_MethodName, "Reduced ammo count - new ammo count is " .. tostring(self._Data._Ammo), 1)
                end
            end
        end
    end
end

function TorpedoSlammer.resetTarget()
    self._Data._CurrentTarget = nil
end

function TorpedoSlammer.pickNewTarget()
    local _MethodName = "Pick New Target"
    local _Factionidx = Entity().factionIndex
    local _Sector = Sector()
    local _TargetPriority = self._Data._TargetPriority

    --Get the list of enemies. This is a bit of work since it includes wacky crap like turrets.
    local _RawEnemies = {_Sector:getEnemies(_Factionidx)}
    local _Enemies = {}
    for _, _RawEnemy in pairs(_RawEnemies) do
        if _RawEnemy.type == EntityType.Ship or _RawEnemy.type == EntityType.Station then
           table.insert(_Enemies, _RawEnemy) 
        end
    end
    
    if self._Debug == 1 then
        for _, _Enemy in pairs(_Enemies) do
            self.Log(_MethodName, "Enemy is a : " .. tostring(_Enemy.typename), 1)
        end
    end

    local _TargetCandidates = {}
    
    local _TargetPriorityFunctions = {
        function() --1 = Go through and find the highest firepower total of all enemies, then put any enemies that match that into a table.
            local _TargetValue = 0

            for _, _Candidate in pairs(_Enemies) do
                if _Candidate.firePower > _TargetValue then
                    _TargetValue = _Candidate.firePower
                end
            end

            for _, _Candidate in pairs(_Enemies) do
                if _Candidate.firePower == _TargetValue then
                    table.insert(_TargetCandidates, _Candidate)
                end
            end
        end,
        function() --2 = Pick an entity with a specific script value - those go in the table.
            local _Entities = {_Sector:getEntitiesByScriptValue(self._Data._TargetTag)}
            for _, _Candidate in pairs(_Entities) do
                table.insert(_TargetCandidates, _Candidate)
            end
        end,
        function() --3 = Pick a random non-xsotan. Ignore the args.
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
        function() --4 = Pick a random enemy.
            for _, _Candidate in pairs(_Enemies) do
                table.insert(_TargetCandidates, _Candidate)
            end
        end,
        function () --5 = Pick the player's current ship.
            if self._Data._pindex then
                local _PlayerTarget = Player(self._Data._pindex)
                local _PlayerTargetShip = Entity(_PlayerTarget.craft.id)

                if _PlayerTargetShip and valid(_PlayerTargetShip) then
                    table.insert(_TargetCandidates, _PlayerTargetShip)
                end
            end
        end,
        function () --6 = Random pirate or xsotan (NOTE: will not target minions / revenants)
            local _Pirates = { _Sector:getEntitiesByScriptValue("is_pirate") }
            local _Xsotan = { _Sector:getEntitiesByScriptValue("is_xsotan") }

            for _, _Candidate in pairs(_Pirates) do
                table.insert(_TargetCandidates, _Candidate)
            end

            for _, _Candidate in pairs(_Xsotan) do
                table.insert(_TargetCandidates, _Candidate)
            end
        end,
        function() --7 = random player or alliance ship or station
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

        self.Log(_MethodName, "Found at least one suitable target out of " .. tostring(#_TargetCandidates) .. ". Picking a random one.", 1)

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

        self.Log(_MethodName, "Candidate name is " .. tostring(chosenCandidate.name))
        
        return chosenCandidate
    else
        self.Log(_MethodName, "WARNING - Could not find any target candidates.", 1)
        return nil
    end
end

function TorpedoSlammer.invincibleTargetCheck(entity)
    if not entity.invincible or self._Target_Invincible_Debug == 1 then
        return true
    else
        return false
    end
end

function TorpedoSlammer.isXsotanCheck(entity)
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

function TorpedoSlammer.fireAtTarget()
    local _MethodName = "Fire At Target"
    local _Torpedo = self.generateTorpedo()

    local _Entity = Entity()

    local _Desc = TorpedoDescriptor()
    local _TorpAI = _Desc:getComponent(ComponentType.TorpedoAI)
    local _Torp = _Desc:getComponent(ComponentType.Torpedo)
    local _TorpVel = _Desc:getComponent(ComponentType.Velocity)
    local _TorpOwn = _Desc:getComponent(ComponentType.Owner)
    local _Flight = _Desc:getComponent(ComponentType.DirectFlightPhysics)
    local _Dura = _Desc:getComponent(ComponentType.Durability)

    _TorpAI.target = self._Data._CurrentTarget.id
    _Torp.intendedTargetFaction = self._Data._CurrentTarget.factionIndex

    _TorpAI.driftTime = 1

    local _EnemyPosition = self._Data._CurrentTarget.translationf
    local _OwnPosition = _Entity.translationf

    local _DVec = _EnemyPosition - _OwnPosition
    local _NDVec = normalize(_DVec)

    local _Bounds = _Entity:getBoundingSphere()
    local _Mat = _Entity.position
    local _Out = Matrix()
    local _SpawnPos = _Mat.position + (_NDVec * _Bounds.radius * 1.25 * self._Data._ForwardAdjustFactor)
    if self._Data._UpAdjust then
        self.Log(_MethodName, "Adjusting up position.", 2)
        _SpawnPos = _SpawnPos + (_Mat.up * _Bounds.radius * 0.1 * self._Data._UpAdjustFactor)
    end

    local _EntityDamageMultiplier = 1
    if self._Data._UseEntityDamageMult then
        if self._Data._UseStaticDamageMult then
            _EntityDamageMultiplier = (self._Data._StaticDamageMultValue or 1)
        else
            _EntityDamageMultiplier = (_Entity.damageMultiplier or 1)
        end
    end

    local _BaseShieldDamage = _Torpedo.shieldDamage
    local _BaseHullDamage = _Torpedo.hullDamage

    _Torpedo.shieldDamage = _Torpedo.shieldDamage * self._Data._DamageFactor * _EntityDamageMultiplier
    _Torpedo.hullDamage = _Torpedo.hullDamage * self._Data._DamageFactor * _EntityDamageMultiplier
    _Torpedo.reach = _Torpedo.reach * self._Data._ReachFactor
    _Torpedo.acceleration = _Torpedo.acceleration * self._Data._AccelFactor
    _Torpedo.maxVelocity = _Torpedo.maxVelocity * self._Data._VelocityFactor
    _Torpedo.turningSpeed = _Torpedo.turningSpeed * self._Data._TurningSpeedFactor
    _Torpedo.shockwaveSize = _Torpedo.shockwaveSize * self._Data._ShockwaveFactor

    --Very spammy - debug level is 2.
    self.Log(_MethodName, "Torpedo has tech of : " .. tostring(_Torpedo.tech) .. " and base shield damage of : " .. tostring(_BaseShieldDamage) .. " and base hull damage of : " .. tostring(_BaseHullDamage), 2)
    self.Log(_MethodName, "Torpedo has final shield damage of " .. tostring(_Torpedo.shieldDamage) .. " and final hull damage of : " .. tostring(_Torpedo.hullDamage), 2)

    _Out.position = _SpawnPos
    _Out.look = _Mat.look
    _Out.up = _Mat.up
    _Desc.position = _Out

    _Torp.shootingCraft = _Entity.id
    _Torp.firedByAIControlledPlayerShip = false
    _Torp.collisionWithParentEnabled = false
    _Torp:setTemplate(_Torpedo)

    _TorpOwn.factionIndex = _Entity.factionIndex

    _Flight.drifting = true
    _Flight.maxVelocity = _Torpedo.maxVelocity
    _Flight.turningSpeed = _Torpedo.turningSpeed * 2

    _TorpVel.velocityf = vec3(1,1,1) * 10

    _Dura.maximum = _Torpedo.durability * self._Data._DurabilityFactor
    _Dura.durability = _Torpedo.durability * self._Data._DurabilityFactor

    Sector():createEntity(_Desc)
end

function TorpedoSlammer.getWarheadType(rgen)
    local methodName = "Get Warhead Type"
    local _WarheadType = nil

    if self._Data._PreferWarheadType then
        self.Log(methodName, "Has preferred warhead type - checking for secondary type.", 1)
        --Check to see if we have a secondary preferred warhead type
        if self._Data._PreferSecondaryWarheadType then
            self.Log(methodName, "Has secondary preferred type - picking randomly.", 1)
            local warheadTable = { self._Data._PreferWarheadType, self._Data._PreferSecondaryWarheadType }
            _WarheadType = randomEntry(warheadTable)
        else
            self.Log(methodName, "No secondary type - using primary.", 1)
            _WarheadType = self._Data._PreferWarheadType
        end
    else
        _WarheadType = rgen:getInt(1, 10)
    end

    return _WarheadType
end

function TorpedoSlammer.generateTorpedo()
    local _MethodName = "Generate Torepedo"
    local _Rgen = random()
    local _TorpX, _TorpY = Sector():getCoordinates()
    local _Generator = TorpedoGenerator()

    local _WarheadType = self.getWarheadType(_Rgen)

    local _BodyType = self._Data._PreferBodyType
    if not _BodyType then
        _BodyType = _Rgen:getInt(1, 9)
    end

    --Boxelware fixed this. Thanks guys! I'm glad you actually listened to my bug report :D
    --The only reason I am leaving this code in here is just in case someone is still running an older version of the game.
    local _SimSector = math.floor(length(vec2(_TorpX, _TorpY))) + self._Data._TorpOffset
    _SimSector = math.max(_SimSector, 0) --Don't let it go below 0, otherwise we get an unexpected tech value.

    self.Log(_MethodName, "x is : " .. tostring(_TorpX) .. " and y is : " .. tostring(_TorpY) .. " and offset is : " .. tostring(self._Data._TorpOffset) .. " and Warhead type is : " .. tostring(_WarheadType) .. " and body type is : " .. tostring(_BodyType), 2)
    self.Log(_MethodName, "Simulated sector is " .. tostring(_SimSector) .. " : 0", 2)

    return _Generator:generate(_SimSector, 0, 0, Rarity(RarityType.Exotic), _WarheadType, _BodyType)
end

function TorpedoSlammer.resetTimeToActive(_Time)
    self._Data._TimeToActive = _Time
end

--region #LOG / SECURE / RESTORE

function TorpedoSlammer.Log(_MethodName, _Msg, _RequireDebugLevel)
    _RequireDebugLevel = _RequireDebugLevel or 1

    if self._Debug == 1 and self._DebugLevel >= _RequireDebugLevel then
        print("[TorpedoSlammer] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function TorpedoSlammer.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data", 1)
    return self._Data
end

function TorpedoSlammer.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data", 1)
    self._Data = _Values
end

--endregion