package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HorizonStory4Battleship
HorizonStory4Battleship = {}
local self = HorizonStory4Battleship

self._Debug = 0

function HorizonStory4Battleship.initialize()
    local _MethodName = "Initialize"

    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/horizon/fs2razorback.ogg")
    end

    if onServer() then
        local _ShipAI = ShipAI()
        _ShipAI:setIdle()
        _ShipAI:setPassiveShooting(false)

        local _Durability = Durability()
        _Durability.invincibility = 0.25
    end
end

function HorizonStory4Battleship.getUpdateInterval()
    return 0
end

function HorizonStory4Battleship.updateServer(_timeStep)
    --Follow after the tow ship.
    local _towShips = {Sector():getEntitiesByScriptValue("_horizon4_towship")}
    local _ShipAI = ShipAI()

    if #_towShips > 0 then
        local _towShip = _towShips[1]
        local _radius = _towShip:getBoundingSphere().radius * 2

        _ShipAI:setFlyLinear(_towShip.translationf, _radius, false)
        self.createLaserFX(_towShip.translationf)
    else
        _ShipAI:stop()
    end
end

function HorizonStory4Battleship.createLaserFX(_toPosition)
    local _MethodName = "Start Laser"
    if onServer() then
        self.Log(_MethodName, "Calling on Server => broadcast invoking on Client")
        broadcastInvokeClientFunction("createLaserFX", _toPosition)
        return
    end
    self.Log(_MethodName, "Calling on Client")

    local _ownPosition = Entity().translationf
    local _Laser = Sector():createLaser(_ownPosition, _toPosition, ColorRGB(0, 0.1, 1), 6)
    _Laser.collision = false
    _Laser.maxAliveTime = 0.25
end
callable(HorizonStory4Battleship, "createLaserFX")

function HorizonStory4Battleship.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 4 Battleship] - [" .. _MethodName .. "] - " .. _Msg)
    end
end