package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--namespace AbsolutePointDefense
AbsolutePointDefense = {}
local self = AbsolutePointDefense

--This works for non-turret based point defense. Use this in case you want a ship to have point defenses without the AI going nuts from having point defense and 
--regular turrets stuck on the same ship.
self._Data = {}
self._Data._ROF = nil
self._Data._TargetTorps = nil
self._Data._TorpDamage = nil
self._Data._TargetFighters = nil
self._Data._FighterDamage = nil
self._Data._RangeFactor = nil
self._Data._MaximumTargets = nil
self._Data._TimeCycle = nil

self._Debug = 0

--!!!WARNING!!! 
--The default values on this script will WRECK fighters and torpedoes. If you want to make this go a bit easier on the player, tone it down some. 
--!!!WARNING!!!
function AbsolutePointDefense.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Initializing v2 of APD script.")
    self._Data = _Values or {}

    self._Data._ROF = self._Data._ROF or 0.25
    self._Data._TargetTorps = self._Data._TargetTorps or true
    self._Data._TorpDamage = self._Data._TorpDamage or 100
    self._Data._TargetFighters = self._Data._TargetFighters or true
    self._Data._FighterDamage = self._Data._FighterDamage or 10
    self._Data._RangeFactor = self._Data._RangeFactor or 20
    self._Data._MaximumTargets = self._Data._MaximumTargets or 4

    if self._Debug == 1 and onServer() then
        for k, v in pairs(self._Data) do
            self.Log(_MethodName, "APD value of " .. tostring(k) .. " is : " .. tostring(v))
        end
    end
end

function AbsolutePointDefense.getUpdateInterval()
    return 0.25
end

function AbsolutePointDefense.updateServer(_TimeStep)
    self._Data._TimeCycle = (self._Data._TimeCycle or 0) + _TimeStep

    if self._Data._TimeCycle >= self._Data._ROF then
        --We basically don't care about any of this unless it is ready to shoot.
        --Find all torpedoes
        local _Sector = Sector()
        
        local _Entity = Entity()
        local _Bounds = _Entity:getBoundingSphere()
        local _MaxRange = _Bounds.radius * self._Data._RangeFactor

        local _MyFactionIndex = _Entity.factionIndex
        local _MyPosition = _Entity.translationf

        local _TargetedEntities = 0
        local _MaxTargets = self._Data._MaximumTargets

        if self._Data._TargetTorps then
            local _Torpedoes = {_Sector:getEntitiesByType(EntityType.Torpedo)}
    
            for _, _Torp in pairs(_Torpedoes) do
                if _Torp.factionIndex ~= _MyFactionIndex and _TargetedEntities < _MaxTargets then
                    if self.targetInRange(_MyPosition, _Torp.translationf, _MaxRange) then
                        self.createLaser(Entity().translationf, _Torp.translationf)
                        local _Dura = Durability(_Torp)
                        _Dura:inflictDamage(self._Data._TorpDamage, 1, DamageType.Energy, Entity().id)
                        _TargetedEntities = _TargetedEntities + 1
                    end
                end
            end
        end
    
        if self._Data._TargetFighters then
            local _Fighters = {_Sector:getEntitiesByType(EntityType.Fighter)}
    
            for _, _Fighter in pairs(_Fighters) do
                if _Fighter.factionIndex ~= _MyFactionIndex and _TargetedEntities < _MaxTargets then
                    if self.targetInRange(_MyPosition, _Fighter.translationf, _MaxRange) then
                        self.createLaser(Entity().translationf, _Fighter.translationf)
                        local _Dura = Durability(_Fighter)
                        _Dura:inflictDamage(self._Data._FighterDamage, 1, DamageType.Energy, Entity().id)
                        _TargetedEntities = _TargetedEntities + 1
                    end
                end
            end
        end

        self._Data._TimeCycle = 0
    end
end

function AbsolutePointDefense.targetInRange(_Vec1, _Vec2, _MaxRange)
    return distance(_Vec1, _Vec2) < _MaxRange
end

--region #CLIENT / SERVER functions

function AbsolutePointDefense.createLaser(_From, _To)
    if onServer() then
        broadcastInvokeClientFunction("createLaser", _From, _To)
        return
    end

    local _Color = color or ColorRGB(0, 1, 0)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(_From, _To, _Color, 1)

    _Laser.maxAliveTime = 0.25
    _Laser.collision = false
end

function AbsolutePointDefense.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[AbsolutePointDefense] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function AbsolutePointDefense.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function AbsolutePointDefense.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion