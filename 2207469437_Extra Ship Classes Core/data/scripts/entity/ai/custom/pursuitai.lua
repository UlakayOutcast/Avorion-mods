--Custom AI script.
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")
include ("randomext")

local targetEntity
local minDist = -1

--namespace PursuitAIScript
PursuitAIScript = {}

if onServer() then

    --TODO: SEE IF WE CAN GET THIS TO SWAP BACK TO THE DEFAULT BOXELWARE AI ONCE IT IS WITHIN RANGE OF ALL WEAPONS
    --Not an ideal solution but better than waiting around hoping for that API request to be resolved.
    function PursuitAIScript.initialize(...)
        --Immediately set the AI idle. PursuitAIScript will tell it how to behave instead of the default ship AI.
        local ship = Entity()
        local ai = ShipAI()
        local ctlUnit = ControlUnit()
        --print("PursuitAIScript AI successfully attached to " .. ship.name)

        ai:stop()
        ai:setIdle()
        ai:setPassiveShooting(true)
        for _, t in pairs({ship:getTurrets()}) do
            local xt = Turret(t)
            xt.group = 8
            local xw = Weapons(t)
            if xw.damageType ~= DamageType.Fragments and (xw.reach < minDist or minDist == -1) then
                minDist = xw.reach
            end
        end
        if minDist <= ship:getBoundingSphere().radius then
            --Make sure it is at least the bounding radius
            minDist = ship:getBoundingSphere().radius
        else
            --Make it a bit smaller than the minimum range to make sure we're always inside of it.
            minDist = math.max(ship:getBoundingSphere().radius, minDist - 200)
        end
        --print("minimum range is " .. minDist)
    end

    function PursuitAIScript.getUpdateInterval()
        --Per Koonschi, this needs to be run every single frame.
        return 0
    end

    function PursuitAIScript.updateServer(timeStep)
        local ship = Entity()
        local ai = ShipAI()
        local ctlUnit = ControlUnit()
        local eng = Engine()

        for _, t in pairs({ship:getTurrets()}) do
            local xt = Turret(t)
            print("xt group is " .. tostring(xt.group))
        end

        if not targetEntity then
            local ships = {Sector():getEntitiesByType(EntityType.Ship)}
            local possibleTargets = {}
            for _,p in pairs(ships) do
                if ai:isEnemy(p) then
                    table.insert(possibleTargets, p)
                end
            end
            --print("PursuitAIScript AI picked " .. targetEntity.name .. " as a pursuit target.")
            targetEntity = possibleTargets[math.random(1, #possibleTargets)]
        end

        if targetEntity and valid(targetEntity) then
            --Set the aimed position of all the weapons in group 1.
            ctlUnit:setAimedPosition(targetEntity.translationf, 0)
            ctlUnit:setControlActions(ControlActionBit.Fire1, 0)
            ctlUnit:setKeyDownMask(ControlActionBit.Fire1, 0)
            --Use the AI to fly.
            local distanceToTarget = distance(targetEntity.translationf, ship.translationf)
            if distanceToTarget > minDist then
                --print("Distance to target is ... " .. distanceToTarget .. " desired is " .. minDist)
                ctlUnit:flyToLocation(targetEntity.translationf, eng.maxVelocity)
                --ai:setFlyLinear(targetEntity.translationf, minDist * 2, false)
            end
        else
            --print("PursuitAIScript AI lost track of its current target, and will pick a new one on its next update.")
            targetEntity = nil
        end
    end

end