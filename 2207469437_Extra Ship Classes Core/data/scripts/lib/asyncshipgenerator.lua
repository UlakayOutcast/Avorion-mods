ESCCUtil = include("esccutil")

--GET _AMP
local _ActiveMods = Mods()
local _Amp = 1.0
local _HighAmp = 1.0

for _, _Xmod in pairs(_ActiveMods) do
	if _Xmod.id == "1821043731" then --HET
		_Amp = _Amp + 2
        _HighAmp = _HighAmp * 2
	end
end

function AsyncShipGenerator:createDefenderByName(faction, position, _Name)
    local _MethodName = "Create defender by Name"

    _Name = _Name or "M"

    local _Ship = nil
    if _Name == "L" then
        _Ship = self:createLightDefender(faction, position)
    elseif _Name == "M" then
        _Ship = self:createDefender(faction, position)
    elseif _Name == "H" then
        _Ship = self:createHeavyDefender(faction, position)
    elseif _Name == "C" then
        _Ship = self:createCarrier(faction, position)
    elseif _Name == "BLOCKER" then
        _Ship = self:createBlockerShip(faction, position)
    elseif _Name == "MS" then
        _Ship = self:createMilitaryShip(faction, position)
    else
        print("ERROR: " .. tostring(_Name) .. " is not a valid name - spawning a standard defender instead.")
        _Ship = self:createDefender(faction, position)
    end

    return _Ship
end

function AsyncShipGenerator:getStandardPositions(_Distance, _Count, _DirMultiplier)
    local _MethodName = "[ESCC] Get Standard Positions"
    _Count = math.floor(_Count)
    _Distance = _Distance or 100
    _DirMultiplier = _DirMultiplier or 1000

	local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
	local up = vec3(0, 1, 0)
	local right = normalize(cross(dir, up))
	local pos = dir * _DirMultiplier

	local _PositionTable = {}

	for idx = 1, _Count do
		local posMult
		if idx % 2 == 1 then
			posMult = (idx - 1) / 2 * -1
		else
			posMult = idx / 2
		end

		local posValue = pos
		if posMult ~= 0 then
			posValue = pos + right * _Distance * posMult
		end

		table.insert(_PositionTable, MatrixLookUpPosition(-dir, up, posValue))
	end

	return _PositionTable
end

function AsyncShipGenerator:getGenericPosition()
    local _MethodName = "Get Generic Position"

	local _Rgen = ESCCUtil.getRand()
	local _Pos = _Rgen:getVector(-1000, 1000)
    return MatrixLookUpPosition(-_Pos, vec3(0, 1, 0), _Pos)
end

--region #LIGHT DEFENDER

function AsyncShipGenerator:createLightDefender(faction, position)
    local _MethodName = "[ESCC] Create Light Defender"

    position = position or Matrix()

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 3.75 * _Amp

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_light_defender_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onLightDefenderPlanFinished(plan, generatorId, position, factionIndex)
    local _MethodName = "[ESCC] Light Defender Plan Finished"

    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    --One set of armed turrets and x3 damage.
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)
    ship.damageMultiplier = ship.damageMultiplier * 3 * _HighAmp

    ship:addScript("ai/patrol.lua")
    ship:addScript("antismuggle.lua")
    ship:setValue("is_armed", true)
    ship:setValue("is_defender", true)
    ship:setValue("npc_chatter", true)

    --No 2nd bar for these guys.
    ship:addScript("icon.lua", "data/textures/icons/pixel/military-ship.png")

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end

--endregion

--region #HEAVY DEFENDER

function AsyncShipGenerator:createHeavyDefender(faction, position)
    local _MethodName = "[ESCC] Create Heavy Defender"

    position = position or Matrix()

    --You thought the defender was big? These guys are bigger.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 15.0 * _Amp

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_heavy_defender_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onHeavyDefenderPlanFinished(plan, generatorId, position, factionIndex)
    local _MethodName = "[ESCC] Heavy Defender Plan Finished"

    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    --Add two sets of turrets and give them x3 damage. This should result in roughly 50% more damage than a standard defender.
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)
    ship.damageMultiplier = ship.damageMultiplier * 3 * _HighAmp * _HighAmp

    ship:addScript("ai/patrol.lua")
    ship:addScript("antismuggle.lua")
    ship:setValue("is_armed", true)
    ship:setValue("is_defender", true)
    ship:setValue("is_heavy_defender", true)
    ship:setValue("npc_chatter", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/defender.png")

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end

--endregion

--region #HEAVY CARRIER

function AsyncShipGenerator:createHeavyCarrier(faction, position)
    local _MethodName = "[ESCC] Create Heavy Carrier"

    if not carriersPossible() then
        self:createHeavyDefender(faction, position)
        return
    end

    position = position or Matrix()
    fighters = fighters or 12 + random():getInt(6, 12) --at least 18, up to 24 fighters.

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 25.0 * _Amp

    PlanGenerator.makeAsyncCarrierPlan("_ship_generator_on_heavy_carrier_plan_generated", {self.generatorId, position, faction.index, fighters}, faction, volume)
    self:shipCreationStarted()
end

local function onHeavyCarrierPlanFinished(plan, generatorId, position, factionIndex, fighters)
    local _MethodName = "[ESCC] Heavy Carrier Plan Finished"

    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    ShipUtility.addCarrierEquipment(ship, fighters)

    --Add 1 set of military turrets
    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    ShipUtility.addArmedTurretsToCraft(ship, turrets)

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", true)

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end

--endregion

--region #AWACS

function AsyncShipGenerator:createAWACS(faction, position)
    local _MethodName = "[ESCC] Create AWACS"

    position = position or Matrix()
    --About twice as big as a standard blocker ship.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 2 * _Amp

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_awacs_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onAWACSPlanFinished(plan, generatorId, position, factionIndex)
    local _MethodName = "[ESCC] AWACS Plan Finished"

    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    --Add a standard armament and blocker equipment
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addBlockerEquipment(ship)

    ship.title = "AWACS Ship"%_t

    ship:setValue("is_armed", true)
    ship:setValue("is_awacs", true)

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end

--endregion

--region #SCOUT

function AsyncShipGenerator:createScout(faction, position)
    local _MethodName = "[ESCC] Create Scout"

    position = position or Matrix()
    --Scouts are tiny. Low mass = jump drives recharge quickly.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 0.5 * _Amp

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_scout_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onScoutPlanFinished(plan, generatorId, position, factionIndex)
    local _MethodName = "[ESCC] Scout Plan Finished"

    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    --Don't give scouts many turrets, or a damage multiplier.
    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.title = "Scout Ship"%_t

    ship:setValue("is_armed", true)
    ship:setValue("is_scout", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/fighter.png")

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end

--endregion

--region #CIVIL TRANSPORT

function AsyncShipGenerator:createCivilTransportShip(faction, position, volume)
    position = position or Matrix()
    volume = volume or Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation()

    PlanGenerator.makeAsyncCivilTransportPlan("_ship_generator_on_civiltransport_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onCivilTransportPlanFinished(plan, generatorId, position, factionIndex)
    local self = generators[generatorId] or {}

    local faction = Faction(self.factionIndex or factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

    ShipUtility.addArmedTurretsToCraft(ship, turrets)

    ship.title = ShipUtility.getFreighterNameByVolume(ship.volume)

    ship:addScript("civilship.lua")
    ship:addScript("dialogs/storyhints.lua")
    ship:setValue("is_civil", true)
    ship:setValue("is_freighter", true)
    ship:setValue("npc_chatter", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/civil-ship.png")

    ship:setTitle("Civilian Transport", {})

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end

--endregion

---@diagnostic disable-next-line: need-import
local extraShipClassesCore_new = new
local function new(namespace, onGeneratedCallback)
    local _MethodName = "[ESCC] New Async Ship Generator"

    local instance = extraShipClassesCore_new(namespace, onGeneratedCallback)

    if namespace then
        namespace._ship_generator_on_light_defender_plan_generated = onLightDefenderPlanFinished
        namespace._ship_generator_on_heavy_defender_plan_generated = onHeavyDefenderPlanFinished
        namespace._ship_generator_on_heavy_carrier_plan_generated = onHeavyCarrierPlanFinished
        namespace._ship_generator_on_awacs_plan_generated = onAWACSPlanFinished
        namespace._ship_generator_on_scout_plan_generated = onScoutPlanFinished
        namespace._ship_generator_on_civiltransport_plan_generated = onCivilTransportPlanFinished
    else
        _ship_generator_on_light_defender_plan_generated = onLightDefenderPlanFinished
        _ship_generator_on_heavy_defender_plan_generated = onHeavyDefenderPlanFinished
        _ship_generator_on_heavy_carrier_plan_generated = onHeavyCarrierPlanFinished
        _ship_generator_on_awacs_plan_generated = onAWACSPlanFinished
        _ship_generator_on_scout_plan_generated = onScoutPlanFinished
        _ship_generator_on_civiltransport_plan_generated = onCivilTransportPlanFinished
    end

    return instance
end