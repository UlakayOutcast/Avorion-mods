package.path = package.path .. ";data/scripts/lib/?.lua"

ESCCUtil = include("esccutil")

--namespace AIIgnoreInvincible
AIIgnoreInvincible = {}
local self = AIIgnoreInvincible

self._Debug = 0

function AIIgnoreInvincible.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing AI Ignore Invincible v1 script on entity.")
end

function AIIgnoreInvincible.getUpdateInterval()
    return 10
end

function AIIgnoreInvincible.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    self.Log(_MethodName, "Running...")

    local _ShipAI = ShipAI()

    local _CurrentTarget = Entity(_ShipAI.attackedEntity)

    if _CurrentTarget.invincible then
        local _NewTarget = AIIgnoreInvincible.pickNewTarget()
        if _NewTarget and valid(_NewTarget) then
            _ShipAI:setAttack(_NewTarget)
        else
            _ShipAI:setAggressive()
        end
    end
end

function AIIgnoreInvincible.pickNewTarget()
    local _MethodName = "Pick New Target"
    local _Factionidx = Entity().factionIndex
    local _Rgen = ESCCUtil.getRand()

    local _Enemies = {Sector():getEnemies(_Factionidx)}
    local _TargetCandidates = {}

    for _, _Candidate in pairs(_Enemies) do
        if not _Candidate.invincible then
            table.insert(_TargetCandidates, _Candidate)
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

--region #CLIENT / SERVER CALLS

function AIIgnoreInvincible.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[AI Ignore Invincible] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function AIIgnoreInvincible.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function AIIgnoreInvincible.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion