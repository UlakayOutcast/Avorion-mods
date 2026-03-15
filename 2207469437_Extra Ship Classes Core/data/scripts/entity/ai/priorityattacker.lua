package.path = package.path .. ";data/scripts/lib/?.lua"

include("randomext")

--namespace PriorityAttacker
PriorityAttacker = {}
local self = PriorityAttacker

self._Debug = 0
self._Target_Invincible_Debug = 0

self._Data = {}
--[[
    Here's a guide to how this thing works:
        _TargetPriority = Targets enemies according to specific priorities. Defaults to 1.
                            1 - target enemies with the _TargetTag script value.
                            2 - target player or alliance owned ships only.
        _TargetTag      = Targets entities with this script value.
        _CurrentTarget  = The current target of this entity.
        _UseShipAI      = If this is set to true, it gets eneeies by ship AI and not by faction index
        _AllowNoneType  = Allows targeting of EntityType.None
]]

function PriorityAttacker.initialize(_Values)
    local methodName = "Initialize"
    self.Log(methodName, "Initializing AI Priority Attacker v16 script on entity.")

    self._Data = _Values or {}

    self._Data._TargetPriority = self._Data._TargetPriority or 1
end

function PriorityAttacker.getUpdateInterval()
    return 10
end

function PriorityAttacker.updateServer(_TimeStep)
    local methodName = "Update Server"

    local _entity = Entity()

    local logMsgTbl = {
        "Running on Entity " .. _entity.name .. ". Looking for tag " .. tostring(self._Data._TargetTag),
        "Running on Entity " .. _entity.name .. ". Looking for player or alliance owned ships."
    }
    self.Log(methodName, logMsgTbl[self._Data._TargetPriority])

    local _ShipAI = ShipAI()
    local aiState = _ShipAI.state

    --Pick a new target and attack that target.
    if self._Data._CurrentTarget == nil or not valid(self._Data._CurrentTarget) then
        self.Log(methodName, "Target is nil or not valid. Picking a new target.")
        self._Data._CurrentTarget = self.pickNewTarget()
    end

    --If we couldn't find a new, valid target, just set the AI to aggressive.
    if self._Data._CurrentTarget == nil or not valid(self._Data._CurrentTarget) then
        if aiState ~= AIState.Attack and aiState ~= AIState.Aggressive then
            self.Log(methodName, "Picked target is dead and ship AI is not aggressive state - setting to general attacking state.")
            _ShipAI:setAggressive()
        end
    else
        if _ShipAI.attackedEntity ~= self._Data._CurrentTarget.index then
            self.Log(methodName, "Ship not attacking picked target - attacking picked target.")
            _ShipAI:setAttack(self._Data._CurrentTarget)
        end
    end
end

function PriorityAttacker.pickNewTarget()
    local methodName = "Pick New Target"
    local _Factionidx = Entity().factionIndex
    local _Sector = Sector()
    local _TargetPriority = self._Data._TargetPriority

    --Get the list of enemies. This is a bit of work since it includes wacky crap like turrets.
    local rawEnemies = {}

    if self._Data._UseShipAI then
        local shipAI = ShipAI()
        rawEnemies = { shipAI:getEnemies() }
    else
        rawEnemies = { _Sector:getEnemies(_Factionidx) }
    end

    local _Enemies = {}
    for _, rawEnemy in pairs(rawEnemies) do
        if self.entityTypeOK(rawEnemy.type) then
           table.insert(_Enemies, rawEnemy) 
        end
    end

    --Log # of enemies, etc.
    local logMsg = "Raw number of enemies found : " .. tostring(#_Enemies)
    if self._Data._UseShipAI then
        logMsg = logMsg .. ". Using Ship AI to find enemies."
    end
    if self._Data._AllowNoneType then
        logMsg = logMsg .. " Type 'None' OK."
    end
    self.Log(methodName, logMsg)
    
    --Build target candidate list.
    local _TargetCandidates = {}

    local _TargetPriorityFunctions = {
        function() --1 = Targets enemies with the target script value / tag as set by _TargetTag
            for _, _Candidate in pairs(_Enemies) do
                if _Candidate:getValue(self._Data._TargetTag) then
                    table.insert(_TargetCandidates, _Candidate)
                end
            end
        end,
        function() --2 = Targets player / alliance enemies only
            for _, _Candidate in pairs(_Enemies) do
                if _Candidate.playerOrAllianceOwned then
                    table.insert(_TargetCandidates, _Candidate)
                end
            end
        end
    }

    _TargetPriorityFunctions[_TargetPriority]()

    if #_TargetCandidates > 0 then
        local chosenCandidate = nil
        local attempts = 0

        self.Log(methodName, "Found at least one suitable target. Picking a random one.")

        while not chosenCandidate and attempts < 10 do
            local randomPick = randomEntry(_TargetCandidates)
            if self.invincibleTargetCheck(randomPick) then
                chosenCandidate = randomPick
            end
            attempts = attempts + 1
        end

        if not chosenCandidate then
            self.Log(methodName, "Could not find a non-invincible target in 10 tries - picking one at random")
            chosenCandidate = randomEntry(_TargetCandidates)
        end

        self.Log(methodName, "Chosen candidate is entity " .. tostring(chosenCandidate.name))
        
        return chosenCandidate
    else
        self.Log(methodName, "WARNING - Could not find any target candidates.")
        return nil
    end
end

function PriorityAttacker.invincibleTargetCheck(entity)
    if not entity.invincible or self._Target_Invincible_Debug == 1 then
        return true
    else
        return false
    end
end

function PriorityAttacker.entityTypeOK(entityType)
    local entityTypeOK = false

    if entityType == EntityType.Ship or entityType == EntityType.Station then
        entityTypeOK = true --always accept ships or stations.
    end

    if self._Data._AllowNoneType and entityType == EntityType.None then
        entityTypeOK = true --Allow EntityType.None under limited circumstances.
    end

    return entityTypeOK
end

--region #CLIENT / SERVER CALLS

function PriorityAttacker.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[AI Escort Attacker] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function PriorityAttacker.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self._Data")
    return self._Data
end

function PriorityAttacker.restore(_Values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion