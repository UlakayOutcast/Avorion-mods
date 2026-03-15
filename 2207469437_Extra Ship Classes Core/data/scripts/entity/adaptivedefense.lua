package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--Don't remove the namespace comment!!! The script could break.
--namespace AdaptiveDefense
AdaptiveDefense = {}
local self = AdaptiveDefense

self._Data = {}
--Placeholder / demo values to show what the script can have altered in one easy spot.
--self._Data._Resistance = nil --defaults to 0.55
--self._Data._PhysDamageTaken = nil
--self._Data._AntiDamageTaken = nil
--self._Data._PlasDamageTaken = nil
--self._Data._EnRGDamageTaken = nil
--self._Data._ElecDamageTaken = nil
--self._Data._OverallDamageTaken = nil
--self._Data._FirstUpdateRun = false

local _DamageTaken = 0
local _DamageTakenTable = {}

self._Debug = 0

function AdaptiveDefense.initialize(_Values)
    local _MethodName = "Initialize"
    local _Entity = Entity()
    self.Log(_MethodName, "Attaching AdaptiveDefense v3 script to enemy.")

    self._Data = _Values or {}
    self._Data._Resistance = self._Data._Resistance or 0.55
    self._Data._HullResistance = self._Data._HullResistance or 0.65

    --Values that the player shouldn't mess with via args.
    self._Data._PhysDamageTaken = 0
    self._Data._AntiDamageTaken = 0
    self._Data._PlasDamageTaken = 0
    self._Data._EnRGDamageTaken = 0
    self._Data._ElecDamageTaken = 0
    self._Data._OverallDamageTaken = 0
    self._Data._FirstUpdateRun = false --Updates once per second until this is run, then once per 20s afterwards.

    if onServer() then
        --Pulse cannon gang sit down.
        _Entity:addAbsoluteBias(StatsBonuses.ShieldImpenetrable, 1)

        if _Entity:registerCallback("onShieldDamaged", "onShieldDamaged") == 1 then
            self.Log(_MethodName, "Could not attach onShieldDamaged callback.")
        end
        if _Entity:registerCallback("onDamaged", "onDamaged") == 1 then
            self.Log(_MethodName, "Could not attach onDamaged callback.")
        end
    end
end

function AdaptiveDefense.getUpdateInterval()
    if self._Data._FirstUpdateRun then 
        return 20
    else
        return 1
    end
end

function AdaptiveDefense.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    self.Log(_MethodName, "Amount of damage taken: " .. tostring(_DamageTaken))
    if _DamageTaken > 0 then
        self.Log(_MethodName, "Adapting defenses to offensive pressure...")

        self.adaptShield()

        self.adaptHull()

        self._Data._FirstUpdateRun = true
    else
        self.Log(_MethodName, "Have not taken damage yet - nothing to adapt to.")
    end
end

function AdaptiveDefense.adaptShield()
    local _MethodName = "Adapt Shield"
    local _AdaptToDamage = 0
    local _AdaptToType = DamageType.Physical
    for _DmgType, _DmgTaken in pairs(_DamageTakenTable) do
        if _DmgTaken > _AdaptToDamage then
            _AdaptToDamage = _DmgTaken
            _AdaptToType = _DmgType
        end
    end

    self.Log(_MethodName, "Setting shield resistance to " .. tostring(_AdaptToType))

    local _Shield = Shield()
    if _Shield then
        self.Log(_MethodName, "Shield exists - setting resistance amount.")
        _Shield:setResistance(_AdaptToType, self._Data._Resistance)
    end
end

function AdaptiveDefense.adaptHull()
    local _MethodName = "Adapt Hull"
    local _AdaptToDamage = 0
    local _AdaptToType = DamageType.Physical
    for _DmgType, _DmgTaken in pairs(_DamageTakenTable) do
        if _DmgTaken > _AdaptToDamage then
            _AdaptToDamage = _DmgTaken
            _AdaptToType = _DmgType
        end
    end

    self.Log(_MethodName, "Setting hull resistance to " .. tostring(_AdaptToType))

    local _Durability = Durability()
    if _Durability then
        self.Log(_MethodName, "Durability exists - setting resistance amount.")
        _Durability:setWeakness(_AdaptToType, self._Data._HullResistance * -1)
    end
end

function AdaptiveDefense.onShieldDamaged(_ObjectIndex, _Amount, _DamageType, _InflictorID)
    local _MethodName = "On Shield Damaged"
    self.Log(_MethodName, "Running On Shield Damage callback - damage amount is " .. tostring(_Amount) .. " and damage type is " .. tostring(_DamageType))
    if not _DamageType or not _Amount then
        return
    else
        self.adaptDefense(_DamageType, _Amount)
    end
end

function AdaptiveDefense.onDamaged(_ObjectIndex, _Amount, _Inflictor, _DamageSource, _DamageType)
    local _MethodName = "On Damaged"
    self.Log(_MethodName, "Running on Damaged callback - damage amount is " .. tostring(_Amount) .. " and damage type is " .. tostring(_DamageType))
    if not _DamageType or not _Amount then
        return
    else
        self.adaptDefense(_DamageType, _Amount)
    end
end

function AdaptiveDefense.adaptDefense(_DamageType, _Amount)
    _DamageTaken = (_DamageTaken or 0) + _Amount
    _DamageTakenTable[_DamageType] = (_DamageTakenTable[_DamageType] or 0) + _Amount
end

--region #CLIENT / SERVER functions

function AdaptiveDefense.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[AdaptiveDefense] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function AdaptiveDefense.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing AdaptiveDefense._Data")

    self._Data._OverallDamageTaken = _DamageTaken
    self._Data._PhysDamageTaken = _DamageTakenTable[DamageType.Physical]
    self._Data._AntiDamageTaken = _DamageTakenTable[DamageType.AntiMatter]
    self._Data._PlasDamageTaken = _DamageTakenTable[DamageType.Plasma]
    self._Data._EnRGDamageTaken = _DamageTakenTable[DamageType.Energy]
    self._Data._ElecDamageTaken = _DamageTakenTable[DamageType.Electric]

    return self._Data
end

function AdaptiveDefense.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring AdaptiveDefense._Data")
    self._Data = _Values

    _DamageTaken = AdaptiveDefense._Data._OverallDamageTaken
    _DamageTakenTable[DamageType.Physical] =    self._Data._PhysDamageTaken
    _DamageTakenTable[DamageType.AntiMatter] =  self._Data._AntiDamageTaken
    _DamageTakenTable[DamageType.Plasma] =      self._Data._PlasDamageTaken
    _DamageTakenTable[DamageType.Energy] =      self._Data._EnRGDamageTaken
    _DamageTakenTable[DamageType.Electric] =    self._Data._ElecDamageTaken
end

--endregion