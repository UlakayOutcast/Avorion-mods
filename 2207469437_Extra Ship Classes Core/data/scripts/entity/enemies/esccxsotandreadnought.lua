package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")
include ("stringutility")

local Xsotan = include ("story/xsotan")
local SpawnUtility = include ("spawnutility")

-- You know the drill by now. Don't remove the comment on the next line or you'll break it.
-- namespace ESCCXsotanDreadnought
ESCCXsotanDreadnought = {}
local self = ESCCXsotanDreadnought

self._Debug = 0

self.data = {}
self.lasers = {}

local lasers = self.lasers

local State =
{
    Fighting = 0,
    Charging = 1,
}

self.state = State.Fighting

function ESCCXsotanDreadnought.initialize(values)
    local methodName = "Initialize"
    self.Log(methodName, "Initializing v7 of esccxsotandreadnought")

    local dreadnought = Entity()

    self.data = values or {}

    self.data.dangerFactor = self.data.dangerFactor or 1
    self.data.shieldBonusMultiplier = self.data.shieldBonusMultiplier or 3
    self.data.shieldRecharges = self.data.shieldRecharges or 0
    self.data.numShipSpawns = self.data.numShipSpawns or 6
    self.data.allyShipVolume = self.data.allyShipVolume or 2
    if self.data.sickoMode == nil then
        self.data.sickoMode = false
    end

    self.data.charge = 0
    self.data.debugTicks = 0

    --Set initial damage multiplier
    self.data.initialDmgMulti = self.data.initialDmgMulti or dreadnought.damageMultiplier

    --Increase shields
    local shieldMultiplier = self.data.shieldBonusMultiplier
    if self.data.sickoMode then
        shieldMultiplier = shieldMultiplier * 1.25 --Give a 25% bonus
    end
    if (dreadnought.maxDurability * shieldMultiplier) - dreadnought.shieldMaxDurability > 0 then
        local shieldBonus = (dreadnought.maxDurability / dreadnought.shieldMaxDurability) * shieldMultiplier * (math.random() * 0.4 + 0.8)
        self.Log(methodName, "Add " .. tostring(shieldBonus) .. " shield multiplier")
        dreadnought:addKeyedMultiplier(StatsBonuses.ShieldDurability, 99001002, shieldBonus)
    end

    if self.data.strongerAtCore or self.data.strongerAtCore2 then
        if self.data.strongerAtCore2 and self.data.dist < self.data.strongerAtCore2 then
            self.data.shieldRecharges = self.data.shieldRecharges + 2
        elseif self.data.strongerAtCore and self.data.dist < self.data.strongerAtCore then
            self.data.shieldRecharges = self.data.shieldRecharges + 1
        end
    end

    local dreadnoughtShields = Shield(dreadnought.id)
    if dreadnoughtShields then
        dreadnoughtShields.impenetrable = true
    end

    if self.data.sickoMode then
        self.data.shieldRecharges = self.data.shieldRecharges + 1
    end

    dreadnought.shieldDurability = dreadnought.shieldMaxDurability
    self.data.shieldDurability = dreadnought.shieldMaxDurability

    self.Log(methodName, "Final shield recharges is: " .. tostring(self.data.shieldRecharges))
end

function ESCCXsotanDreadnought.getUpdateInterval()
    return 0.25
end

function ESCCXsotanDreadnought.updateServer(timePassed)
	local methodName = "Update Server"

    local dreadnought = Entity()

    --Used so that we don't get a message every single time this updates (every 1/4 of a second)
    if self._Debug == 1 then
        self.data.debugTicks = self.data.debugTicks + 1
        if self.data.debugTicks > 10 then
            self.data.debugTicks = 0
        end
    end

	-- State: Fighting
	if self.state == State.Fighting then
		self.data.shieldDurability = dreadnought.shieldDurability
		
		if dreadnought.shieldDurability < (dreadnought.shieldMaxDurability * 0.2) and self.data.charge < self.data.shieldRecharges then
			self.setCharging()
		end
		
	-- State: Charging
	elseif self.state == State.Charging then
		local maxDurability = dreadnought.shieldMaxDurability
		if self.data.charge > 1 then
			local devider = 1 - ((self.data.charge - 1) / (self.data.shieldRecharges - 1) * 0.4)
			maxDurability = dreadnought.shieldMaxDurability * devider
			if maxDurability > dreadnought.shieldMaxDurability then
				maxDurability = dreadnought.shieldMaxDurability
			end

            if self.data.debugTicks == 1 then
                self.Log(methodName, "Divider is: " .. tostring(devider) .. " charge is: " .. tostring(self.data.charge) .. " shieldRecharges is: " .. tostring(self.data.shieldRecharges))
                self.Log(methodName, "Shield max durability is: " .. tostring(dreadnought.shieldMaxDurability) .. " and final max durability is: " .. tostring(maxDurability))
            end
		end
		
		if self.data.shieldDurability < maxDurability then
			local shields = self.data.shieldDurability + self.getShieldChargeTick(timePassed)
			if shields > maxDurability then
				shields = maxDurability
			end
			dreadnought.shieldDurability = shields
		else
			dreadnought.shieldDurability = maxDurability
		end
		self.data.shieldDurability = dreadnought.shieldDurability
		
        if not self.hasAllies() then
            self.setFighting()
        end
	end
	
	if self.data.shieldDurability > (dreadnought.shieldMaxDurability * 0.1) and self.state == State.Charging then
		dreadnought.invincible = true
	else
		dreadnought.invincible = false
	end

	self.aggroAllies()
end

function ESCCXsotanDreadnought.hasAllies()
    local methodName = "Has Allies"
    if self.data.debugTicks == 1 then
        self.Log(methodName, "Checking for allies.")
    end

    local allies = {Sector():getEntitiesByFaction(Entity().factionIndex)}

    local dreadnought = Entity()
    for _, ally in pairs(allies) do
        if ally.index ~= dreadnought.index and ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then
            return true
        end
    end

    return false
end

function ESCCXsotanDreadnought.aggroAllies()
    local methodName = "Aggro Allies"
    if self.data.debugTicks == 1 then
        self.Log(methodName, "Aggroing allies")
    end

    local ownIndex = Entity().factionIndex

    local _sector = Sector()
    local allies = {_sector:getEntitiesByFaction(Entity().factionIndex)}
    local factions = {_sector:getPresentFactions()}

    for _, ally in pairs(allies) do
        if ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then

            local ai = ShipAI(ally.index)
            for _, factionIndex in pairs(factions) do
                if factionIndex ~= ownIndex then
                    ai:registerEnemyFaction(factionIndex)
                end
            end

            if not ally:getValue("escc_xsotandreadnought_aggroed") then
                ai:setAggressive() --repeatedly setting this does weird stuff to the AI.
                ally:setValue("escc_xsotandreadnought_aggroed", true) --So we use this value so it's only set once.
            end
        end
    end

    return false
end

function ESCCXsotanDreadnought.setFighting()
	local methodName = "Set Fighting"
    self.Log(methodName, "Beginning...")

	self.state = State.Fighting
	Sector():broadcastChatMessage("", 3, "The Dreadnought finished charging and is vulnerable again"%_t)
end

function ESCCXsotanDreadnought.setCharging()
	local methodName = "Set Charging"
    self.Log(methodName, "Beginning...")

	self.state = State.Charging

	Sector():broadcastChatMessage("", 3, "The Dreadnought charges up its weapons and shields"%_t)
	self.data.charge = self.data.charge + 1

    local dreadnought = Entity()
	
	dreadnought.damageMultiplier = self.data.initialDmgMulti * (self.data.charge + 1)
	
	dreadnought.shieldDurability = dreadnought.shieldMaxDurability * 0.2
	self.data.shieldDurability = dreadnought.shieldDurability

    local pctChance = 0.25
    if self.data.sickoMode then
        pctChance = 0.5
    end

	local numShips = self.data.numShipSpawns
    local xrand = random()
    if self.data.dangerFactor > 5 then
        local numExtraShips = self.data.dangerFactor - 5
        for _ = 1, numExtraShips do
            if xrand:test(pctChance) then
                numShips = numShips + 1
            end
        end
    end

    local maxSpecialXsotan = math.floor(self.data.dangerFactor / 3)
    local numSpecialXsotanSpawned = 0
    local specialXsotanChance = self.data.dangerFactor * 0.1
    local shipVolumeFactor = (self.data.charge + 1) * self.data.allyShipVolume

    local spawnTable = {}

    for i = 1, numShips do
        if numSpecialXsotanSpawned < maxSpecialXsotan and xrand:test(specialXsotanChance) then
            local potentialSpawns = { "Quantum", "Summoner", "Special" }
            table.insert(spawnTable, randomEntry(potentialSpawns))
            numSpecialXsotanSpawned = numSpecialXsotanSpawned + 1 --cap at 3 @ danger 10.
        else
            table.insert(spawnTable, "Ship")
        end
    end

    local allAlliedXsotan = {}

    for idx, shipType in pairs(spawnTable) do
        local allyPosition = dreadnought.translationf + xrand:getDirection() * xrand:getFloat(500, 750)
		local position = MatrixLookUpPosition(vec3(0, 1, 0), vec3(1, 0, 0), allyPosition)

        local alliedXsotan = nil
        if shipType == "Ship" then
            alliedXsotan = Xsotan.createShip(position, shipVolumeFactor)
        elseif shipType == "Quantum" then
            alliedXsotan = Xsotan.createQuantum(position, shipVolumeFactor)
        elseif shipType == "Summoner" then
            alliedXsotan = Xsotan.createSummoner(position, shipVolumeFactor)
        else
            local xsotanFunction = randomEntry(Xsotan.getSpecialXsotanFunctions())

            alliedXsotan = xsotanFunction(position, shipVolumeFactor)
        end

        if alliedXsotan then
            table.insert(allAlliedXsotan, alliedXsotan)

            broadcastInvokeClientFunction("createLaser", allyPosition)
            self.createWormhole(alliedXsotan, allyPosition)
        end
    end

    if self.data.sickoMode then
        SpawnUtility.addEnemyBuffs(allAlliedXsotan)
    end
end

function ESCCXsotanDreadnought.createWormhole(alliedXsotan, position)
    -- spawn a wormhole
    local desc = WormholeDescriptor()
    desc:removeComponent(ComponentType.EntityTransferrer)
    desc:addComponents(ComponentType.DeletionTimer)
    desc.position = MatrixLookUpPosition(vec3(0, 1, 0), vec3(1, 0, 0), position)

    local size = alliedXsotan.radius + random():getFloat(10, 15)
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

function ESCCXsotanDreadnought.createLaser(position)
    local sector = Sector()
    local entity = Entity()

    local laser = sector:createLaser(entity.translationf, position, ColorRGB(0.8, 0.6, 0.1), 1.5)
    laser.maxAliveTime = 1.5
    laser.collision = false
    laser.animationSpeed = -500

    table.insert(lasers, {laser = laser, to = position})
end

function ESCCXsotanDreadnought.getShieldChargeTick(timePassed)
	return (Entity().shieldMaxDurability) * (timePassed / 8) -- 8 seconds to restore 100% of max shield durability
end

--region #LOG / SECURE / RESTORE

function ESCCXsotanDreadnought.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[ESCC Xsotan Dreadnought] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function ESCCXsotanDreadnought.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self.data")
    return self.data
end

function ESCCXsotanDreadnought.restore(values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self.data")
    self.data = values
end

--endregion