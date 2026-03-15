package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")

ESCCUtil = include("esccutil")

--Don't remove this or else the script might break.
--namespace SiegeGunShot
SiegeGunShot = {}
local self = SiegeGunShot

self._Debug = 0

self._Position = nil
self._Velocity = nil
self._TimeToExpire = nil
self._TimeAlive = 0
self._ShotDamage = 0
self._OriginID = -1
self._Fragile = nil

--region #INIT

function SiegeGunShot.initialize(_Position, _Velocity, _TimeToExpire, _ShotDamage, _OriginID, _Fragile)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Adding shot script v 32. Initial values are - _Position: " .. tostring(_Position) .. " _Velocity: " .. tostring(_Velocity) .. " _TimeToExpire: " .. tostring(_TimeToExpire) .. " _ShotDamage: " .. tostring(_ShotDamage) .. " _OriginID: " .. tostring(_OriginID) .. " _Fragile: " .. tostring(_Fragile))

    self._Position = _Position
    self._Velocity = _Velocity
    self._TimeToExpire = _TimeToExpire
    self._ShotDamage = _ShotDamage
    self._OriginID = _OriginID
    self._Fragile = _Fragile

    if onServer() then
        self.Log(_MethodName, "Broadcasting Sync.")
        broadcastInvokeClientFunction("syncData", self._Position, self._Velocity)
    end
end

--endregion

--region #SERVER CALLS

function SiegeGunShot.getUpdateInterval()
    return onClient() and 0 or 0.25
end

function SiegeGunShot.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    if not self._Position then
        self.Log(_MethodName, "WARNING - self._Position is nil - terminating script immediately.", 1)
        terminate()
        return
    end
    if not self._Velocity then
        self.Log(_MethodName, "WARNING - self._Velocity is nil - terminating script immediately.", 1)
        terminate()
        return
    end
    --Update position. Check hitbox. Damage entities if needed. Send drawing coordinates to the client.
    --self.Log(_MethodName, "Beginning...")
    self._Position = self._Position + (self._Velocity * _TimeStep)

    self._TimeAlive = self._TimeAlive + _TimeStep
    if self._TimeAlive > self._TimeToExpire then
        self.Log(_MethodName, "Time alive is: " .. tostring(self._TimeAlive) .. " which exceeds " .. tostring(self._TimeToExpire))
        terminate()
        return
    end

    --Make a small bounding sphere simulating the shot.
    local _ShotSphere = Sphere(self._Position, 10)
    local _SectorEntities = {Sector():getEntitiesByLocation(_ShotSphere)}
    if #_SectorEntities > 0 then
        local _HitSomething = false
        for _, e in pairs(_SectorEntities) do
            if e.id ~= self._OriginID then
                if e.type == EntityType.Asteroid or e.type == EntityType.Wreckage then
                    --Just delete the entity.
                    Sector():deleteEntity(e)
                    if self._Fragile then
                        --Delete the shot if we have fragile shots enabled.
                        _HitSomething = true 
                    end
                elseif e.type == EntityType.Torpedo then
                    Sector():deleteEntity(e)
                    goto nextIteration
                end

                local _Shield = Shield(e.id)
                local _Dura = Durability(e.id)
                local _Entity = Entity(e.id)
                if _Shield then
                    --Do as much damage as possible to the shield, then hit the hull for the remaining damage.
                    self.Log(_MethodName, "Found target. Inflicting " .. tostring(self._ShotDamage) .. " damage to " .. tostring(_Entity.name))
                    local _ShieldDamage = self._ShotDamage
                    local _HullDamage = 0
                    if _Shield.durability < self._ShotDamage then
                        _ShieldDamage = _Shield.durability
                        _HullDamage = self._ShotDamage - _ShieldDamage
                    end
                    self.Log(_MethodName, tostring(_ShieldDamage) .. " damage to " .. tostring(_Entity.name) .. " shield")
                    _Shield:inflictDamage(_ShieldDamage, 1, DamageType.Energy, self._Position, self._OriginID)
                    if _HullDamage > 0 then
                        self.Log(_MethodName, tostring(_HullDamage) .. " damage to " .. tostring(_Entity.name) .. " hull")
                        _Dura:inflictDamage(_HullDamage, 1, DamageType.Energy, self._OriginID)
                    end
                    if e.type ~= EntityType.Fighter or self._Fragile then
                        _HitSomething = true
                    end
                else
                    if _Dura then
                        --Do everything to the hull.
                        self.Log(_MethodName, "Found target. Inflicting " .. tostring(self._ShotDamage) .. " damage to " .. tostring(_Entity.name))
                        _Dura:inflictDamage(self._ShotDamage, 1, DamageType.Energy, self._OriginID)
                        if e.type ~= EntityType.Fighter or self._Fragile then
                            _HitSomething = true
                        end
                    end
                end
            end
            ::nextIteration::
        end
        if _HitSomething then
            broadcastInvokeClientFunction("explosionEffect", self._Position)
            terminate()
            return
        end
    end

    broadcastInvokeClientFunction("syncData", self._Position, self._Velocity)
end

--endregion

--region #CLIENT CALLS

function SiegeGunShot.updateClient(_TimeStep)
    if self._Position and self._Velocity then
        self._Position = self._Position + (self._Velocity * _TimeStep)
    end
    self.drawShot()
end

function SiegeGunShot.syncData(_Position, _Velocity)
    local _MethodName = "Sync Data"
    --self.Log(_MethodName, "Running sync... _Position is: " .. tostring(_Position) .. " and _Velocity is " .. tostring(_Velocity))
    self._Position = _Position
    self._Velocity = _Velocity
end

function SiegeGunShot.drawShot()
    local _MethodName = "Draw Shot"

    if self._Position then
        local _Sector = Sector()
        local _DrawColor = ESCCUtil.getSaneColor(255, 255, 0)

        for _ = 1, 4 do
            _Sector:createGlow(self._Position, 20, _DrawColor)
        end
        for _ = 1, 2 do
            _Sector:createGlow(self._Position, 40, _DrawColor)
        end
    end
end

function SiegeGunShot.explosionEffect(_Position)
    local _MethodName = "Explosion Effect"
    self.Log(_MethodName, "Showing explosion!!!")

    local rand = random()
    local offMin = -12
    local offMax = 12

    for idx = 1, 4 do
        local f1 = rand:getFloat(offMin, offMax)
        local f2 = rand:getFloat(offMin, offMax)
        local f3 = rand:getFloat(offMin, offMax)
        local boomSize = rand:getFloat(20, 28)

        local _Offset = vec3(f1, f2, f3)
        local _ExplosionPos = _Position + _Offset

        Sector():createExplosion(_ExplosionPos, boomSize, false)
    end
end

--endregion

--region #CLIENT / SERVER CALLS

function SiegeGunShot.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[ESCC Siege Gun Shot] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion