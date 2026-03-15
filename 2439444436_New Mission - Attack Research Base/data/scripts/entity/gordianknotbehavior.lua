package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

ESCCUtil = include("esccutil")

--namespace GordianKnotBehavior
GordianKnotBehavior = {}
local self = GordianKnotBehavior

self._Debug = 0

self._Data = {}
self._Data._KitePenaltyTime = 0
self._Data._KitePenaltyActive = 300 --5 minutes by default. Let the player think they're winning.
self._Data._KiteKillerTimer = 0
self._Data._KiteKillerROF = 2
self._Data._KiteKillerDamage = 25000000 --25 million every 2 seconds seems reasonable
self._Data._ThirtyCycle = 0

function GordianKnotBehavior.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Beginning...")
    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/special/mezame.ogg")
    end
    if onServer() then
        Sector():registerCallback("onShotHit", "onShotHit")
    end
end

function GordianKnotBehavior.getUpdateInterval()
    return 1
end

function GordianKnotBehavior.updateServer(_TimeStep)
    local methodName = "Update Server"

    if not Entity():hasScript("gordianknot.lua") then
        Entity():addScriptOnce("gordianknot.lua")
    end

    local _Sector = Sector()
    local _Players = {_Sector:getPlayers()}
    if #_Players > 0 then
        local _PlayersWithScript = false
        for _, _Player in pairs(_Players) do
            if _Player:hasScript("destroysuperweapon.lua") then
                _PlayersWithScript = true
                break
            end
        end

        local _Rgen = ESCCUtil.getRand()

        if not _PlayersWithScript then
            local _ShipAI = ShipAI()
            _ShipAI:setPassive()
            Entity():addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(2, 4))
        end
    end
    
    --Kite management function.
    self._Data._KitePenaltyTime = self._Data._KitePenaltyTime + _TimeStep
    if self._Data._KitePenaltyTime >= self._Data._KitePenaltyActive then
        self._Data._KiteKillerTimer = self._Data._KiteKillerTimer + _TimeStep

        if self._Data._KiteKillerTimer >= self._Data._KiteKillerROF then
            self.fireAntiKite()
            self._Data._KiteKillerTimer = 0
        end
    end

    --Every 30 updates, force the torpedo slammer to reconsider its target.
    if not self._Data._ThirtyCycle then
        self._Data._ThirtyCycle = 0
    end

    if self._Data._ThirtyCycle < 30 then
        self._Data._ThirtyCycle = self._Data._ThirtyCycle + 1
    else
        self.Log(methodName, "Run 30 update cycles - reconsidering torpslammer target.")

        self._Data._ThirtyCycle = 0
        Entity():invokeFunction("torpedoslammer.lua", "resetTarget")
    end
end

function GordianKnotBehavior.onShotHit(_ObjectIndex, _ShooterIndex, _Location)
    local _MethodName = "On Shot Hit"
    if _ShooterIndex == Entity().index then
        --Be careful about enabling this, it is quite spammy.
        --self.Log(_MethodName, "One of own shots hit - resetting antikite timer.")
        self._Data._KitePenaltyTime = 0
        self._Data._KiteKillerTimer = 0
    end
end

function GordianKnotBehavior.fireAntiKite()
    local _MethodName = "Fire Anti-Kite Laser"
    self.Log(_MethodName, "Beginning...")

    local _Rgen = ESCCUtil.getRand()
    local _Entity = Entity()
    local _EnemyEntities = {Sector():getEnemies(_Entity.factionIndex)}
    local _EnemyShips = {}
    for _, _En in pairs(_EnemyEntities) do
        if _En.type == EntityType.Ship then
            table.insert(_EnemyShips, _En)
        end
    end

    if #_EnemyShips > 0 then
        local _Enemy = _EnemyShips[_Rgen:getInt(1, #_EnemyShips)]
    
        local _MyPosition = _Entity.translationf
        local _EnemyPosition = _Enemy.translationf
    
        local _EnemyShield = Shield(_Enemy)
        local _EnemyDurability = Durability(_Enemy)
        local _DamageToDura = 0
    
        if _EnemyShield then
            self.Log(_MethodName, "Found enemy shield.")
            local _DamageToShield = 0
            if _EnemyShield.durability < self._Data._KiteKillerDamage then
                _DamageToShield = _EnemyShield.durability
                _DamageToDura = self._Data._KiteKillerDamage - _DamageToShield
            else
                _DamageToShield = self._Data._KiteKillerDamage
            end
            if _DamageToShield > 0 then
                self.Log(_MethodName, "Inflicting " .. tostring(_DamageToShield) .. " to shield of ".. tostring(_Enemy.name))
                _EnemyShield:inflictDamage(_DamageToShield, 1, DamageType.Energy, _MyPosition, _Entity.id)
            end
        else
            _DamageToDura = self._Data._KiteKillerDamage
        end
    
        if _DamageToDura > 0 then
            self.Log(_MethodName, "Inflicting " .. tostring(_DamageToDura) .. " to durability of " .. tostring(_Enemy.name))
            _EnemyDurability:inflictDamage(_DamageToDura, 1, DamageType.Energy, _Entity.id)
        end
        self.createAntiKiteLaser(_MyPosition, _EnemyPosition)
    end
end

--region #CLIENT / SERVER CALLS

function GordianKnotBehavior.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[GordianKnotBehavior] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function GordianKnotBehavior.createAntiKiteLaser(_From, _To)
    if onServer() then
        broadcastInvokeClientFunction("createAntiKiteLaser", _From, _To)
        return
    end

    local _Color = color or ColorRGB(1, 0, 0)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(_From, _To, _Color, 40)

    _Laser.maxAliveTime = 0.25
    _Laser.collision = false
end

--endregion


