package.path = package.path .. ";data/scripts/lib/?.lua"

include ("galaxy")
include ("randomext")
include("weapontype")

local SectorTurretGenerator = include ("sectorturretgenerator")
local ShipUtility = include("shiputility")

--namespace SecondaryWeapons
SecondaryWeapons = {}
local self = SecondaryWeapons

self._Data = {}
self._Data._InitialFirepower = nil
self._Data._Threshold = nil
self._Data._OnlyBolters = nil
self._Data._TurretMultiplier = nil
self._Data._CustomizeWeapons = nil
self._Data._WeaponRange = nil
self._Data._WeaponDamageMultiplier = nil
self._Data._MinimumWeaponDamage = nil

self._Debug = 0

function SecondaryWeapons.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Adding v4 of secondaryweapons.lua to entity.")

    self._Data = _Values or {}

    self._Data._InitialFirepower = nil

    self._Data._OnlyBolters = self._Data._OnlyBolters or false
    self._Data._Threshold = self._Data._Threshold or 0.25
    self._Data._TurretMultiplier = self._Data._TurretMultiplier or 10
    self._Data._CustomizeWeapons = self._Data._CustomizeWeapons or false
    self._Data._Charges = self._Data._Charges or 1
end

function SecondaryWeapons.getUpdateInterval()
    return 5
end

function SecondaryWeapons.updateServer(_TimeStep)
    local _MethodName = "On Update Server"

    --Get current firepower.
    local _Firepower = Entity().firePower
    --If initial firepower is nil, set it to that.
    if not self._Data._InitialFirepower then
        self._Data._InitialFirepower = _Firepower
    end

    --Compare current firepower to initial firepower - if it is less than or equal to initial * threshold then spawn secondary weapons and maybe terminate script.
    local _ThresholdFirepower = self._Data._InitialFirepower * self._Data._Threshold
    if _Firepower <= _ThresholdFirepower then
        self.Log(_MethodName, "Threshold reached - deploying secondary weapons.")
        self.spawnSecondaryWeapons()
        
        self._Data._Charges = self._Data._Charges - 1
        if self._Data._Charges <= 0 then
            self.Log(_MethodName, "No charges left - terminating and returning.")
            terminate()
            return
        end
    end
end

function SecondaryWeapons.spawnSecondaryWeapons()
    local _MethodName = "Spawn Secondary Weapons"
    self.Log(_MethodName, "Running spaw n secondary weapons")
    self.Log(_MethodName, "self._Data._WeaponRange : " .. tostring(self._Data._WeaponRange))
    self.Log(_MethodName, "self._Data._WeaponDamageMultiplier : " .. tostring(self._Data._WeaponDamageMultiplier))
    self.Log(_MethodName, "self._Data._MinimumWeaponDamage : " .. tostring(self._Data._MinimumWeaponDamage))
    local _Rand = math.random(1, 2)
    local _WType = WeaponType.ChainGun
    if _Rand == 2 or self._Data._OnlyBolters then
        _WType = WeaponType.Bolter
    end

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _Seed = SectorSeed(_X, _Y)

    local _TurretCount = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * self._Data._TurretMultiplier + 2
    local _Generator = SectorTurretGenerator(_Seed)

    local _SecondaryTurret = _Generator:generate(_X, _Y, 0, nil, _WType, nil)
    _SecondaryTurret.coaxial = false
    if self._Data._CustomizeWeapons then
        self.Log(_MethodName, "Customizing weapons.")
        local _SecondaryTurretWeapons = {_SecondaryTurret:getWeapons()}
        _SecondaryTurret:clearWeapons()
        for _, _W in pairs(_SecondaryTurretWeapons) do
            _W.damage = math.max(_W.damage * self._Data._WeaponDamageMultiplier, self._Data._MinimumWeaponDamage)
            _W.reach = self._Data._WeaponRange

            _SecondaryTurret:addWeapon(_W)
        end
    end

    ShipUtility.addTurretsToCraft(Entity(), _SecondaryTurret, _TurretCount)
end

--region #CLIENT / SERVER functions

function SecondaryWeapons.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[SecondaryWeapons] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function SecondaryWeapons.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function SecondaryWeapons.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion