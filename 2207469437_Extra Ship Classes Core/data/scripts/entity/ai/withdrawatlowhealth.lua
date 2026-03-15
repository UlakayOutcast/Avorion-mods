package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LowHealthWithdraw
LowHealthWithdraw = {}
local self = LowHealthWithdraw

self._Debug = 0

self._Data = {}

function LowHealthWithdraw.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Starting v6 of ESCC Low HP Withdraw script.")

    self._Data = _Values or {}

    --Withdraw at 10% unless otherwise specified.
    self._Data._Threshold = self._Data._Threshold or 0.1
    self._Data._MinTime = self._Data._MinTime or 3
    self._Data._MaxTime = self._Data._MaxTime or 6
    self._Data._ScriptAdded = false

    if self._Data._Invincibility then
        --This should only get executed onServer() anyways.
        local _Dura = Durability()
        if _Dura then
            _Dura.invincibility = self._Data._Invincibility
            Entity():setValue("SDKEDSDisabled", true) --Need to disable SDK extended docking shields.
        end
    end
end

function LowHealthWithdraw.getUpdateInterval()
    --Update every second.
    return 1
end

function LowHealthWithdraw.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    local _Entity = Entity()
    local _HPThreshold = _Entity.durability / _Entity.maxDurability

    self.Log(_MethodName, "HP threshold of entity " .. _Entity.name .. " is " .. tostring(_HPThreshold))
    if _Entity.playerOrAllianceOwned then
        print("[ERROR] Don't attach withdrawatlowhealth.lua to player or alliance entities!!!")
        terminate()
        return
    end

    if _HPThreshold <= self._Data._Threshold then
        self.Log(_MethodName, "Entity withdrawing in " .. tostring(self._Data._MinTime) .. " to " .. tostring(self._Data._MaxTime))
        --Add the script again(?), but likely with a shorter withdraw time.
        if not self._Data._ScriptAdded then
            if self._Data._WithdrawMessage then
                Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, self._Data._WithdrawMessage)
            end
            if self._Data._SetValueOnWithdraw then
                _Entity:setValue(self._Data._SetValueOnWithdraw, true)
            end
            _Entity:addScript("entity/utility/delayeddelete.lua", random():getFloat(self._Data._MinTime, self._Data._MaxTime))
            self._Data._ScriptAdded = true
        end
    end
end

--region #CLIENT / SERVER functions

function LowHealthWithdraw.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[ESCC Withdraw on Low HP AI] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion

--region #SECURE / RESTORE

function LowHealthWithdraw.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function LowHealthWithdraw.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion