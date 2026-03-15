--[[
    ESCC guide to pirate sizes:
    0.75    - Outlaw		- Military x0.25
    1       - Bandit		- Military x0.5
	1       - Jammer*		- Blocker
	1.25	- Stinger*		- Disruptor
    1.5     - Pirate		- Military x0.75
    2       - Marauder		- (Disruptor / Artillery / CIWS)
    2       - Disruptor		- (Disruptor / CIWS)
    4       - Raider		- (Disruptor / Persecutor / Torpedo)
    6       - Scorcher*		- (CIWS / Disruptor) + Disruptor + Disruptor + Disruptor
	6		- Bomber*		- Artillery + Siege Gun Script
    8       - Ravager		- (Artillery / Persecutor)
    10      - Sinner*		- Disruptor + Military x1 + Torpedo
    12      - Prowler*		- (Disruptor / Artillery) + Military x1.5
    18      - Pillager*		- (Disruptor / Persecutor / Torpedo) + Military x2
    28      - Devastator*	- (Artillery / Persecutor) + Military x3 + Military x3
    25      - Mothership	- (Carrier / Flagship) + Boss Anti-Torpedo
	25		- Flagship***	- Flagship + Boss Anti-Torpedo
	20-50  - Executioner*	- ExeStandard x3 + Artillery A/2 + Artillery A/2 + [2A] + [APD] + [ExeStandard x3 + 2A] + [4A] + [4A]**

	* - Custom ships added by ESCC
	** - Yes, it has ALL of these, depending on a special scale value. This special scale determines the 20-50 size as well.
	** - The executioner has a bonus to DPS / HP that increases after it reaches maximum size. This does not have a cap.
	*** - Technically a copy of the Mothership. I needed one without the "carrier" equipment.
]]
include ("utility")

ESCCUtil = include("esccutil")

--Add debug information last.

PirateGenerator._Debug = 0

--region #SCALING

--GET _AMP
local _ActiveMods = Mods()
local _Amp = 1.0
local _HighAmp = 1.0

for _, _Xmod in pairs(_ActiveMods) do
	if _Xmod.id == "2191291553" then --HarderEnemys
		_Amp = _Amp + 2
		_HighAmp = _HighAmp * 2
	end
	if _Xmod.id == "1821043731" then --HET
		_Amp = _Amp + 0.5
		_HighAmp = _HighAmp * 2
	end
end

--endregion

--region #POSITION FUNCTIONS

function PirateGenerator.getStandardPositions(positionCT, distance, _DirMultiplier)
	local _MethodName = "[ESCC] Get Standard Positions"
	--Just in case some joker passes us 5.25 positions.
	positionCT = math.floor(positionCT)
	distance = distance or 100
	_DirMultiplier = _DirMultiplier or 1000
	PirateGenerator.Log(_MethodName, "Getting " .. tostring(positionCT) .. " at " .. tostring(distance))

	local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
	local up = vec3(0, 1, 0)
	local right = normalize(cross(dir, up))
	local pos = dir * _DirMultiplier

	local positionTable = {}

	for idx = 1, positionCT do
		local posMult
		if idx % 2 == 1 then
			posMult = (idx - 1) / 2 * -1
		else
			posMult = idx / 2
		end

		local posValue = pos
		if posMult ~= 0 then
			posValue = pos + right * distance * posMult
		end

		table.insert(positionTable, MatrixLookUpPosition(-dir, up, posValue))
	end

	return positionTable
end

function PirateGenerator.getGenericPosition()
    local _MethodName = "Get Generic Position"
    PirateGenerator.Log(_MethodName, "Beginning...")

	local _Rgen = ESCCUtil.getRand()
	local _Pos = _Rgen:getVector(-1000, 1000)
    return MatrixLookUpPosition(-_Pos, vec3(0, 1, 0), _Pos)
end

--endregion

--Get a number of positions for spawning pirates in the standard positions they spawn in for attacks, so we don't need to do it in our missions / events.
--region #CREATE SCALED

function PirateGenerator.createScaledJammer(position)
	local _MethodName = "[ESCC] Create Scaled Jammer"
	PirateGenerator.Log(_MethodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 1.0 * _Amp * scaling, "Jammer"%_T)
end

function PirateGenerator.createScaledStinger(position)
	local _MethodName = "[ESCC] Create Scaled Stinger"
	PirateGenerator.Log(_MethodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 1.25 * _Amp * scaling, "Stinger"%_T)
end

function PirateGenerator.createScaledScorcher(position)
	local _MethodName = "[ESCC] Create Scaled Scorcher"
	PirateGenerator.Log(_MethodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 6.0 * _Amp * scaling, "Scorcher"%_T)
end

function PirateGenerator.createScaledBomber(position)
	local _MethodName = "[ESCC] Create Scaled Bomber"
	PirateGenerator.Log(_MethodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 6.0 * _Amp * scaling, "Bomber"%_T)
end

function PirateGenerator.createScaledSinner(position)
	local _MethodName = "[ESCC] Create Scaled Sinner"
	PirateGenerator.Log(_MethodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 10.0 * _Amp * scaling, "Sinner"%_T)
end

function PirateGenerator.createScaledProwler(position)
	local _MethodName = "[ESCC] Create Scaled Prowler"
	PirateGenerator.Log(_MethodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 12.0 * _Amp * scaling, "Prowler"%_T)
end

function PirateGenerator.createScaledPillager(position)
	local _MethodName = "[ESCC] Create Scaled Pillager"
	PirateGenerator.Log(_MethodName, "Beginning...")

    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 18.0 * _Amp * scaling, "Pillager"%_T)
end

function PirateGenerator.createScaledDevastator(position)
	local _MethodName = "[ESCC] Create Scaled Devastator"
	PirateGenerator.Log(_MethodName, "Beginning...")

    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 28.0 * _Amp * scaling, "Devastator"%_T)
end

function PirateGenerator.createScaledFlagship(position)
	local methodName = "[ESCC] Create Scaled Flagship"
	PirateGenerator.Log(methodName, "Beginning...")

	local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 25.0 * _Amp * scaling, "Pirate Flagship"%_T)
end

function PirateGenerator.createScaledDemolisher(position)
	local _MethodName = "[ESCC] Create Scaled Demolisher (Devastator)"
	PirateGenerator.Log(_MethodName, "DEMOLISHER COMPATIBILITY CALL - Beginning...")

	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 28.0 * _Amp * scaling, "Devastator"%_T)
end

function PirateGenerator.createScaledExecutioner(position, specialScale)
	local _MethodName = "[ESCC] Create Scaled Executioner"

	specialScale = specialScale or 100

	PirateGenerator.Log(_MethodName, "Beginning... Special scale value is " .. tostring(specialScale))

	local specialShipScale = 20 + math.min(30, (math.max(0, specialScale - 200) / 10)) * _Amp
	local scaling = PirateGenerator.getScaling()
	PirateGenerator["_ESCC_executioner_specialscale"] = specialScale
	return PirateGenerator.create(position, specialShipScale * scaling, "Executioner"%_T)
end

--Adds a very easy way to spawn any scaled pirate
function PirateGenerator.createScaledPirateByName(name, position)
	local _MethodName = "[ESCC] Create Scaled Pirate By Name"
	PirateGenerator.Log(_MethodName, "Creating Pirate - name: " .. tostring(name))

	return PirateGenerator["createScaled" .. name](position)
end

--endregion

--region #CREATE

function PirateGenerator.createJammer(position)
	local _MethodName = "[ESCC] Create Jammer"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 1.0 * _Amp, "Jammer"%_T)
end

function PirateGenerator.createStinger(position)
	local _MethodName = "[ESCC] Create Stinger"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 1.25 * _Amp, "Stinger"%_T)
end

function PirateGenerator.createScorcher(position)
	local _MethodName = "[ESCC] Create Scorcher"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 6.0 * _Amp, "Scorcher"%_T)
end

function PirateGenerator.createBomber(position)
	local _MethodName = "[ESCC] Create Bomber"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 6.0 * _Amp, "Bomber"%_T)
end

function PirateGenerator.createSinner(position)
	local _MethodName = "[ESCC] Create Sinner"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 10.0 * _Amp, "Sinner"%_T)
end

function PirateGenerator.createProwler(position)
	local _MethodName = "[ESCC] Create Prowler"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 12.0 * _Amp, "Prowler"%_T)
end

function PirateGenerator.createPillager(position)
	local _MethodName = "[ESCC] Create Pillager"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return PirateGenerator.create(position, 18.0 * _Amp, "Pillager"%_T)
end

function PirateGenerator.createDevastator(position)
	local _MethodName = "[ESCC] Create Devastator"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return PirateGenerator.create(position, 28.0 * _Amp, "Devastator"%_T)
end

function PirateGenerator.createFlagship(position)
	local methodName = "[ESCC] Create Flagship"
	PirateGenerator.Log(_MethodName, "Beginning...")

	return PirateGenerator.create(position, 25 * _Amp, "Pirate Flagship"%_T)
end

function PirateGenerator.createDemolisher(position)
	local _MethodName = "[ESCC] Create Demolisher (Devastator)"
	PirateGenerator.Log(_MethodName, "DEMOLISHER COMPATIBILITY CALL - Beginning...")

	return PirateGenerator.create(position, 28.0 * _Amp, "Devastator"%_T)
end

function PirateGenerator.createExecutioner(position, specialScale)
	local _MethodName = "[ESCC] Create Executioner"

	specialScale = specialScale or 100

	PirateGenerator.Log(_MethodName, "Beginning... Special scale value is " .. tostring(specialScale))

	local specialShipScale = 20 + math.min(30, (math.max(0, specialScale - 200) / 10)) * _Amp
	PirateGenerator["_ESCC_executioner_specialscale"] = specialScale
	return PirateGenerator.create(position, specialShipScale, "Executioner"%_T)
end

--Adds a very easy way to spawn any pirate
function PirateGenerator.createPirateByName(name, position)
	local _MethodName = "[ESCC] Create Pirate By Name"
	PirateGenerator.Log(_MethodName, "Creating Pirate - name: " .. tostring(name))

	return PirateGenerator["create" .. name](position)
end

--endregion

--[[
Adds custom equipment / loot for our custom NPC ships.
This will still add the standard equipment for other pirates (Outlaw, Bandit, Marauder, etc.)
]]
local extraShipClassesCore_addPirateEquipment = PirateGenerator.addPirateEquipment
function PirateGenerator.addPirateEquipment(craft, title)
	local _MethodName = "Add Pirate Equipment"
	PirateGenerator.Log(_MethodName, "Adding Equipment...")

	if not craft then
		PirateGenerator.Log(_MethodName, "ERROR - craft argument was nil. Expected craft to not be nil. function will error out shortly.")
	end
	if not title then
		PirateGenerator.Log(_MethodName, "ERROR - title argument was nil. Expected title to not be nil. function will error out shortly.")
	end

	PirateGenerator.Log(_MethodName, "Adding Pirate Equipment to a ship - craft: " .. tostring(craft) .. " - title: " .. tostring(title))

	local IsExtraShipClass = false
	local ExtraShipClassTitles = {
		"Pillager",
		"Devastator",
		"Scorcher",
		"Bomber",
		"Prowler",
		"Sinner",
		"Jammer",
		"Stinger",
		"Executioner",
		"Pirate Flagship"
	}
	for _, p in pairs(ExtraShipClassTitles) do
		if title == p then
			IsExtraShipClass = true
		end
	end

	if IsExtraShipClass then
		PirateGenerator.Log(_MethodName, "Extra ship class found. Adding appropriate equipment for an extra ship class.")
		local _Drops = 0

		PirateGenerator.Log(_MethodName, "Initializing sector / turret generator / rarities / upgrade generator / system rarities for loot purposes")
		local x, y = Sector():getCoordinates()

		local turretGenerator = SectorTurretGenerator()
		local turretRarities = turretGenerator:getSectorRarityDistribution(x, y)

		local upgradeGenerator = UpgradeGenerator()
		local upgradeRarities = upgradeGenerator:getSectorRarityDistribution(x, y)

		if title == "Jammer" then
			--A tiny ship that focuses on disrupting the player. Blocks hyperspace
			ShipUtility.addBlockerEquipment(craft)

			ESCCUtil.replaceIcon(craft, "data/textures/icons/pixel/jammer.png")
			craft:setValue("is_jammer", true)
		elseif title == "Stinger" then
			--A fast, tiny ship that focuses on destroying shields. Focus on death by 1000 paper cuts.
			ShipUtility.addDisruptorEquipment(craft)
			Entity(craft.index):addMultiplier(StatsBonuses.Acceleration, 8)
			Entity(craft.index):addMultiplier(StatsBonuses.Velocity, 8)

			Boarding(craft).boardable = false
			craft:setValue("is_stinger", true)
		elseif title == "Scorcher" then
			--A small ship that focuses on shield damage.
			local type = random():getInt(1, 2)
			if type == 1 then
				ShipUtility.addCIWSEquipment(craft)
			elseif type == 2 then
				ShipUtility.addDisruptorEquipment(craft)
			end
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addDisruptorEquipment(craft)

			craft.damageMultiplier = (craft.damageMultiplier or 1) * _HighAmp --Double dip on the bonus for extra scariness

			if type == 2 then
				ESCCUtil.replaceIcon(craft, "data/textures/icons/pixel/scorcher.png")
			end
			craft:setValue("is_scorcher", true)
		elseif title == "Bomber" then
			--A small ship with a single set of artillery turrets and a siege gun script.
			ShipUtility.addArtilleryEquipment(craft)

			local _X, _Y = Sector():getCoordinates()

			local _BSGData = {} --Bomber Siege Gun Data
			_BSGData._Velocity = 150
			_BSGData._ShotCycle = 30
			_BSGData._ShotCycleSupply = 0
			_BSGData._ShotCycleTimer = 0
			_BSGData._UseSupply = false
			_BSGData._FragileShots = false
			_BSGData._TargetPriority = 7
			_BSGData._BaseDamagePerShot = Balancing_GetSectorWeaponDPS(_X, _Y) * 2000

			craft:addScriptOnce("entity/stationsiegegun.lua", _BSGData)

			craft:setValue("is_bomber", true)
		elseif title == "Sinner" then
			--A mid-sized ship with an odd / eclectic group of equipment + quantum jumps.
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addMilitaryEquipment(craft, 1, 0)
			ShipUtility.addTorpedoBoatEquipment(craft)

			craft:addScriptOnce("enemies/blinker.lua")

			Boarding(craft).boardable = false
			craft:setValue("is_sinner", true)
		elseif title == "Prowler" then
			--A mid-sized combat ship armed similarly to a Marauder (no CIWS)
			local type = random():getInt(1, 2)

			if type == 1 then
				ShipUtility.addDisruptorEquipment(craft)
			elseif type == 2 then
				ShipUtility.addArtilleryEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 1.5, 0)

			craft.damageMultiplier = (craft.damageMultiplier or 1) * 1.1

			craft:setValue("is_prowler", true)
		elseif title == "Pillager" then
			--A heavy combat ship armed similarly to a Raider - special loot similar to a raider.
			local type = random():getInt(1, 3)
			if type == 1 then
				ShipUtility.addDisruptorEquipment(craft)
			elseif type == 2 then
				ShipUtility.addPersecutorEquipment(craft)
			elseif type == 3 then
				ShipUtility.addTorpedoBoatEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 2, 0)

			craft.damageMultiplier = (craft.damageMultiplier or 1) * 1.2

			_Drops = 2
			turretRarities[-1] = 0 -- no petty turrets
			turretRarities[0] = 0 -- no common turrets
			turretRarities[1] = 0 -- no uncommon turrets

			upgradeRarities[-1] = 0 --no petty systems
			upgradeRarities[0] = 0 --no common systems

			craft:setValue("is_pillager", true)
		elseif title == "Devastator" then
			--An ultraheavy combat ship armed similarly to a Ravager - special loot similar to a ravager.
			local type = random():getInt(1, 2)
			if type == 1 then
				ShipUtility.addArtilleryEquipment(craft)
			elseif type == 2 then
				ShipUtility.addPersecutorEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 3.0, 0)
			ShipUtility.addMilitaryEquipment(craft, 3.0, 0)

			--Yeah I don't think these guys are threatening enough even with all of that, so they also get a damage bonus.
			craft.damageMultiplier = (craft.damageMultiplier or 1) * 1.5 * _HighAmp --Double dip on the bonus for extra scariness

			_Drops = 3
			turretRarities[-1] = 0 -- no petty turrets
			turretRarities[0] = 0 -- no common turrets
			turretRarities[1] = 0 -- no uncommon turrets
			turretRarities[2] = turretRarities[2] * 0.75 -- reduce rates for rare turrets slightly to have higher chance for the others

			upgradeRarities[-1] = 0 --no petty systems
			upgradeRarities[0] = 0 --no common systems
			upgradeRarities[1] = upgradeRarities[1] * 0.75 --uncommon slightly less likely

			craft:setValue("is_devastator", true)
		elseif title == "Pirate Flagship" then
			--Identical to vanilla's Pirate Mothership, but without the possibility of carrier equipment.
			ShipUtility.addFlagShipEquipment(craft)
        	ShipUtility.addBossAntiTorpedoEquipment(craft)

        	_Drops = 2
        	turretRarities[-1] = 0 -- no petty turrets
        	turretRarities[0] = 0 -- no common turrets
        	turretRarities[1] = 0 -- no uncommon turrets

        	upgradeRarities[-1] = 0 -- no petty upgrades
        	upgradeRarities[0] = 0 -- no common upgrades
        	upgradeRarities[1] = 0 -- no uncommon upgrades
		elseif title == "Executioner" then
			local specialScale = PirateGenerator["_ESCC_executioner_specialscale"] or 100
			PirateGenerator["_ESCC_executioner_specialscale"] = nil
			local finalDamageMultiplier = 1

			--Always add x3 turrets
			local _ArtilleryCt = 2
			ShipUtility.addExecutionerStandardEquipment(craft, 3.0, 0)
			if specialScale >= 300 then
				local _APDBase = Balancing_GetTechLevel(x, y)

				local _APDValues = {}
				_APDValues._ROF = 0.6
				_APDValues._TargetTorps = true
				_APDValues._TargetFighters = true
				_APDValues._FighterDamage = math.max(8, _APDBase * 0.9)
				_APDValues._TorpDamage = math.max(8, (_APDBase / 4) * 0.9)
				_APDValues._MaxTargets = math.floor(math.max(2, _APDBase / 8.5))

				craft:addScriptOnce("absolutepointdefense.lua", _APDValues)
				finalDamageMultiplier = finalDamageMultiplier + 0.2
			end
			if specialScale >= 500 then
				_ArtilleryCt = _ArtilleryCt + 2
				ShipUtility.addExecutionerStandardEquipment(craft, 3.0, 0)
				if specialScale >= 1000 then
					craft:addScript("megablocker.lua", 1)
				else
					craft:addScript("blocker.lua", 1)
				end
			end
			if specialScale >= 700 then
				_ArtilleryCt = _ArtilleryCt + 4
				finalDamageMultiplier = finalDamageMultiplier + 0.2
			end
			if specialScale >= 900 then
				_ArtilleryCt = _ArtilleryCt + 4
				finalDamageMultiplier = finalDamageMultiplier + 0.25
			end
			ShipUtility.addScalableArtilleryEquipment(craft, _ArtilleryCt / 2, 1)
			ShipUtility.addScalableArtilleryEquipment(craft, _ArtilleryCt / 2, 0)

			if specialScale >= 500 then
				--Scale health / shield after hitting max size + extra equipment added.
				local extraScaling = (specialScale - 500) / 40
				--print("extraScaling is " .. extraScaling)
				finalDamageMultiplier = finalDamageMultiplier + (0.015 * extraScaling)
				local finalHealthMultiplier = (0.015 * extraScaling) / 2

				local durability = Durability(craft)
				if durability then durability.maxDurabilityFactor = (durability.maxDurabilityFactor or 0) + finalHealthMultiplier end
				local shield = Shield(craft)
				if shield then shield.maxDurabilityFactor = (shield.maxDurabilityFactor or 0) + finalHealthMultiplier end
			end

			craft.damageMultiplier = (craft.damageMultiplier or 1) * finalDamageMultiplier * _HighAmp  --Double dip on the bonus for extra scariness

			_Drops = 4
			turretRarities[-1] = 0 -- no petty turrets
			turretRarities[0] = 0 -- no common turrets
			turretRarities[1] = 0 -- no uncommon turrets
			turretRarities[2] = turretRarities[2] * 0.5 -- reduce rates for rare turrets slightly to have higher chance for the others

			upgradeRarities[-1] = 0
			upgradeRarities[0] = 0
			upgradeRarities[1] = 0
			upgradeRarities[2] = upgradeRarities[2] * 0.5

			ESCCUtil.replaceIcon(craft, "data/textures/icons/pixel/executioner.png")
			craft:setValue("is_executioner", true)
			craft:setValue("IW_nuclear_m", 0.5)
		end

		if craft.numTurrets == 0 then
			PirateGenerator.Log(_MethodName, "No turrets found on " .. tostring(title) .. " - adding substandard equipment.")
			ShipUtility.addMilitaryEquipment(craft, 1, 0)
		end

		craft.damageMultiplier = (craft.damageMultiplier or 1) * _HighAmp

		PirateGenerator.Log(_MethodName, "Adding " .. _Drops .. " extra drops to loot.")
		turretGenerator.rarities = turretRarities
		for idx = 1, _Drops do
			if random():test(0.5) then
				Loot(craft):insert(upgradeGenerator:generateSectorSystem(x, y, nil, upgradeRarities))
			else
				Loot(craft):insert(InventoryTurret(turretGenerator:generate(x, y)))
			end
		end

		PirateGenerator.Log(_MethodName, "Setting ship title / toughness argument, increasing shields to max.")
		ShipAI(craft.index):setAggressive()
		craft:setTitle("${toughness}${title}", {toughness = "", title = title})
		craft.shieldDurability = craft.shieldMaxDurability

		craft:setValue("is_pirate", true)
	else
		PirateGenerator.Log(_MethodName, "Adding appropriate equipment for a standard Avorion pirate ship class.")

		extraShipClassesCore_addPirateEquipment(craft, title)
	end
end

--region #LOGGING

function PirateGenerator.Log(_MethodName, _Msg)
    if PirateGenerator._Debug == 1 then
        print("[ESCC PirateGenerator] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion