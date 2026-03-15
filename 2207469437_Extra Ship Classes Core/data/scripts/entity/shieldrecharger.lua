package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")
HorizonUtil = include("horizonutil")

--namespace ShieldRecharger
ShieldRecharger = {}
local self = ShieldRecharger

self._Debug = 0

self._Data = {}

--[[
Args:
    _MaxRecharges => # of times the shield can recharge itself. Defaults to math.huge (effectively infinite)
    _ChargeAmount => how fast the shield recharges. Defaults to an amount that recharges the shields in 5 seconds.
    _AddChargeIfActivatedUnder => If the shield is forced into recharge mode and the amount of time passed is less than or equal to this value, adds extra charges to _MaxRecharges. Defaults to nil.
    _FastDamageCharges => # of charges to add if the player damages the shield and forces it into recharge mode too quickly. See _AddChargeIfActivatedUnder. Default is 1.
]]
function ShieldRecharger.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Adding v2 of Shield Recharger to enemy.")

    self._Data = _Values or {}

    self._Data._MaxRecharges = self._Data._MaxRecharges or math.huge
    self._Data._ChargeAmount = self._Data._ChargeAmount or (Entity().shieldMaxDurability / 5) --Recharge in 5 seconds.
    self._Data._FastDamageCharges = self._Data._FastDamageCharges or 1

    self._Data._AddedCharges = false
    self._Data._Charging = false
    self._Data._Recharges = 0
    self._Data._TimePassed = 0
end

--region #SERVER functions

function ShieldRecharger.getUpdateInterval()
    return 0.25
end

function ShieldRecharger.updateServer(timeFrame)
    self._Data._TimePassed = self._Data._TimePassed + timeFrame

    local _Entity = Entity()
    local _EntityShieldThreshold = _Entity.shieldDurability / _Entity.shieldMaxDurability

    if _EntityShieldThreshold <= 0.05 then
        self._Data._Charging = true
        if self._Data._AddChargeIfActivatedUnder and self._Data._TimePassed < self._Data._AddChargeIfActivatedUnder then
            if not self._Data._AddedCharges then
                self._Data._MaxRecharges = self._Data._MaxRecharges + self._Data._FastDamageCharges
                self._Data._AddedCharges = true --Only do this once.
            end
        end
    end

    if _EntityShieldThreshold >= 0.99 then
        if self._Data._Charging == true then
            self._Data._Recharges = self._Data._Recharges + 1
        end
        self._Data._Charging = false
    end

    if self._Data._Charging then
        _Entity:healShield(self._Data._ChargeAmount * timeFrame)
    end

    if  self._Data._Recharges >= self._Data._MaxRecharges then
        terminate()
        return
    end
end

--endregion

--region #LOG / SECURE / RESTORE

function ShieldRecharger.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[Shield Recharger] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function ShieldRecharger.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function ShieldRecharger.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion