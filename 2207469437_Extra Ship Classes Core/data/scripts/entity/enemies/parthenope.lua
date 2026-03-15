package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

local ESCCUtil = include("esccutil")
local Xsotan = include ("story/xsotan")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Parthenope
Parthenope = {}
local self = Parthenope

self.timeStep = 5
self.data = {}
self.lasers = {}

local lasers = self.lasers

function Parthenope.initialize()
    local entity = Entity()
    entity:setValue("xsotan_parthenope", true)
end

if onServer() then

function Parthenope.getUpdateInterval()
    return self.timeStep
end

else --onClient()

function Parthenope.getUpdateInterval()
    return 0
end

end 

function Parthenope.updateServer(timeStep)
    self.timeStep = random():getFloat(5, 7)

    local entity = Entity()

    if ShipAI(entity).isAttackingSomething then
        if self.getSpawnableMinions() > 0 then
            self.spawnMinion()
            self.timeStep = random():getFloat(2, 3)
        end
    end
end

function Parthenope.updateClient(timeStep)
    local entity = Entity()
    for k, l in pairs(lasers) do

        if valid(l.laser) then
            l.laser.from = entity.translationf
            l.laser.to = l.to
        else
            lasers[k] = nil
        end
    end
end

function Parthenope.spawnMinion()
    local direction = random():getDirection()

    local master = Entity()
    local pos = master.translationf
    local radius = master.radius
    local minionPosition = pos + direction * radius * random():getFloat(5, 10)

    broadcastInvokeClientFunction("animation", direction, minionPosition)

    local matrix = MatrixLookUpPosition(master.look, master.up, minionPosition)
    local minion = nil
    local xSpawned = (self.data.spawned or 0)

    local specialSpawnChance = math.min(0.5,  xSpawned * 0.005) --maxes out at 50% after 100 spawns
    if random():test(specialSpawnChance) then
        local _XsotanFunction = randomEntry(Xsotan.getSpecialXsotanFunctions())

        minion = _XsotanFunction(matrix, 1)
    else
        minion = Xsotan.createShip(matrix, 1)
    end

    self.createWormhole(minion, minionPosition)

    if minion then --Only do this if a minion is successfully spawned.
        minion:setValue("xsotan_parthenope_minion", true)

        local spawnBonus = 1 + (xSpawned * 0.02)
    
        ESCCUtil.multiplyOverallDurability(minion, spawnBonus)
    
        minion.damageMultiplier = (minion.damageMultiplier or 1) * spawnBonus
    
        local attackedId = ShipAI(master).attackedEntity
        minion:invokeFunction("xsotanbehaviour.lua", "onSetToAggressive", attackedId)
    
        self.data.spawned = (self.data.spawned or 0) + 1
    else
        print("ERROR - minion not spawned.")
    end
end

function Parthenope.createWormhole(minion, position)
    -- spawn a wormhole
    local desc = WormholeDescriptor()
    desc:removeComponent(ComponentType.EntityTransferrer)
    desc:addComponents(ComponentType.DeletionTimer)
    desc.position = MatrixLookUpPosition(vec3(0, 1, 0), vec3(1, 0, 0), position)

    local size = minion.radius + random():getFloat(10, 15)
    local wormhole = desc:getComponent(ComponentType.WormHole)
    wormhole:setTargetCoordinates(random():getInt(-50, 50), random():getInt(-50, 50))
    wormhole.visible = true
    wormhole.visualSize = size
    wormhole.passageSize = math.huge
    wormhole.oneWay = true
    wormhole.simplifiedVisuals = true

    desc:addScriptOnce("data/scripts/entity/wormhole.lua")

    local wormhole = Sector():createEntity(desc)

    local timer = DeletionTimer(wormhole.index)
    timer.timeLeft = 3
end

function Parthenope.animation(direction, minionPosition)
    local sector = Sector()

    local entity = Entity()
    local pos = entity.translationf

    local laser = sector:createLaser(entity.translationf, minionPosition, ColorRGB(0.8, 0.6, 0.1), 1.5)
    laser.maxAliveTime = 1.5
    laser.collision = false
    laser.animationSpeed = -500

    table.insert(lasers, {laser = laser, to = minionPosition})
end

function Parthenope.getSpawnableMinions()
    local summoners = Sector():getNumEntitiesByScriptValue("xsotan_parthenope")
    local minions = Sector():getNumEntitiesByScriptValue("xsotan_parthenope_minion")

    local minionsPerSummoner = 6 + GameSettings().difficulty
    local open = (summoners * minionsPerSummoner) - minions

    --unlike normal summoners, parthenopes do spawn infinitely.

    return open
end

function Parthenope.secure()
    return self.data
end

function Parthenope.restore(data)
    self.data = data or {}
end
