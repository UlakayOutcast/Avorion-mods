package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--namespace TankemSpecial
TankemSpecial = {}
local self = TankemSpecial

--Based on IronCurtain.
self._Data = {}
--self._Data._Duration = nil            The duration that the ship will be invulnerable for.
--self._Data._TimeActive = nil          The amount of time the effect has been active for.
--self._Data._MinDura = nil             The minimum durability - after the ship hits this % health the effect activates.
--self._Data._Active = nil              Whether or not the effect is active.
--self._Data._SentMessage = false       Set to true once the message is sent.
--self._Data._SGActive = false          Set to true once the siege gun is set to active.

self._Debug = 0

function TankemSpecial.initialize(_MaxDuration, _MinDurability, _DamageFactor)
    _MaxDuration = _MaxDuration or 120
    _MinDurability = _MinDurability or 0.25

    self._Data._Duration = _MaxDuration
    self._Data._MinDura = _MinDurability
    self._Data._TimeActive = 0
    self._Data._Active = false
    self._Data._DamageFactor = _DamageFactor or 1
    self._Data._SentMessage = false
    self._Data._SGActive = false

    if onServer() then
        Entity():registerCallback("onDamaged", "onDamaged")
    end
end

function TankemSpecial.getUpdateInterval()
    return 5
end

function TankemSpecial.updateServer(_TimeStep)
    if self._Data._Active then
        self._Data._TimeActive = self._Data._TimeActive + _TimeStep
        if self._Data._TimeActive > self._Data._Duration then
            Entity().invincible = false
            terminate()
            return
        end
    end
end

function TankemSpecial.onDamaged(_OwnID, _Amount, _InflictorID)
    local _Sector = Sector()
    
    local _Entity = Entity()
    local _Ratio = _Entity.durability / _Entity.maxDurability
    local _MinRatio = self._Data._MinDura

    if _Ratio < _MinRatio then
        if not self._Data._SentMessage then
            self.sendMessage()
            self._Data._SentMessage = true
        end
        _Entity.invincible = true
        self._Data._Active = true

        if not self._Data._SGActive then
            self.addSG()
            self._Data._SGActive = true
        end
    end
end

function TankemSpecial.addSG()
    local _MethodName = "Add Siege Gun"
    self.Log(_MethodName, "Adding Siege Gun to Tankem.")

    local _SGD = {}
    _SGD._CodesCracked = false
    _SGD._Velocity = 400
    _SGD._ShotCycle = 30
    _SGD._ShotCycleSupply = 0
    _SGD._ShotCycleTimer = 30
    _SGD._UseSupply = false
    _SGD._FragileShots = false
    _SGD._TargetPriority = 1 --Target a random enemy.
    _SGD._UseEntityDamageMult = true --Use the entity damage multiplier. Fun with the overdrive / avenger scripts :)

    local _Damage = 65000 * self._Data._DamageFactor
    _SGD._BaseDamagePerShot = _Damage

    Entity():addScript("entity/stationsiegegun.lua", _SGD)
end

function TankemSpecial.sendMessage()
    Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, "Curtain is up! Activate the siege gun now!")
end

--region #CLIENT / SERVER functions

function TankemSpecial.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[TankemSpecial] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function TankemSpecial.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function TankemSpecial.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion