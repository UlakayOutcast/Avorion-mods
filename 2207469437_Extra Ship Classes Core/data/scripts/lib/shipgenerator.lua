ShipGenerator._Debug = 0

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

function ShipGenerator.createDefenderByName(faction, position, _Name)
    _Name = _Name or "M"

    local _Ship = nil
    if _Name == "L" then
        _Ship = ShipGenerator.createLightDefender(faction, position)
    elseif _Name == "M" then
        _Ship = ShipGenerator.createDefender(faction, position)
    elseif _Name == "MS" then
        _Ship = ShipGenerator.createMilitaryShip(faction, position)
    else
        _Ship = ShipGenerator.createHeavyDefender(faction, position)
    end

    return _Ship
end

function ShipGenerator.createLightDefender(faction, position)
    local _MethodName = "Create Light Defender"
    ShipGenerator.Log(_MethodName, "Beginning...")

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 3.75 * _Amp

    local ship = ShipGenerator.createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.idealCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)
    ship.shieldDurability = ship.shieldMaxDurability
    ship.damageMultiplier = ship.damageMultiplier * 3 * _HighAmp

    ship:addScript("ai/patrol.lua")
    ship:addScript("antismuggle.lua")
    ship:setValue("is_armed", true)
    ship:setValue("is_defender", true)
    ship:setValue("npc_chatter", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/military-ship.png")

    return ship
end

function ShipGenerator.createHeavyDefender(faction, position)
    local _MethodName = "Create Heavy Defender"
    ShipGenerator.Log(_MethodName, "Beginning...")

    --You thought the defender was big? These guys are bigger.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 15.0 * _Amp

    local ship = ShipGenerator.createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    --Add two sets of turrets and give them x3 damage. This should result in roughly 50% more damage than a standard defender.
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.idealCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)
    ship.shieldDurability = ship.shieldMaxDurability
    ship.damageMultiplier = ship.damageMultiplier * 3 * _HighAmp * _HighAmp

    ship:addScript("ai/patrol.lua")
    ship:addScript("antismuggle.lua")
    ship:setValue("is_armed", true)
    ship:setValue("is_defender", true)
    ship:setValue("npc_chatter", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/defender.png")

    return ship
end

function ShipGenerator.createHeavyCarrier(faction, position)
    local _MethodName = "Create Heavy Carrier"
    ShipGenerator.Log(_MethodName, "Beginning...")

    position = position or Matrix()
    fighters = fighters or 12 + random():getInt(6, 12) --at least 18, up to 24 fighters.

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 25.0 * _Amp

    local plan = PlanGenerator.makeCarrierPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    ship.shieldDurability = ship.shieldMaxDurability
    --Add fighters.
    local hangar = Hangar(ship.index)
    hangar:addSquad("Alpha")
    hangar:addSquad("Beta")
    hangar:addSquad("Gamma")

    local numFighters = 0
    local generator = SectorFighterGenerator()
    generator.factionIndex = faction.index

    for squad = 0, 2 do
        local fighter = generator:generateArmed(faction:getHomeSectorCoordinates())
        for i = 1, 7 do
            hangar:addFighter(squad, fighter)

            numFighters = numFighters + 1
            if numFighters >= fighters then break end
        end

        if numFighters >= fighters then break end
    end

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.idealCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)
    ship.shieldDurability = ship.shieldMaxDurability

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/carrier.png")

    return ship
end

function ShipGenerator.createAWACS(faction, position)
    local _MethodName = "Create AWACS"
    ShipGenerator.Log(_MethodName, "Beginning...")

    position = position or Matrix()
    --About twice as big as a standard blocker ship.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 2 * _Amp

    local ship = Sector():createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    --Add a standard armament and blocker equipment
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addBlockerEquipment(ship)
    ship.crew = ship.idealCrew
    ship.title = "AWACS Ship"%_t
    ship.shieldDurability = ship.shieldMaxDurability

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", true)
    ship:setValue("is_awacs", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/block.png")

    return ship
end

function ShipGenerator.createScout(faction, position)
    local _MethodName = "Create Scout"
    ShipGenerator.Log(_MethodName, "Beginning...")
    
    position = position or Matrix()
    --Scouts are tiny. Low mass = jump drives recharge quickly.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 0.5 * _Amp

    local ship = Sector():createShip(faction, position, volume)

    --Don't give scouts many turrets, or a damage multiplier.
    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.idealCrew
    ship.title = "Scout Ship"%_t
    ship.shieldDurability = ship.shieldMaxDurability

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", true)
    ship:setValue("is_scout", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/fighter.png")

    return ship
end

function ShipGenerator.createRevenant(faction, wreckage)
    local _MethodName = "Create Revenant"
    ShipGenerator.Log(_MethodName, "Beginning...")

    local _Sector = Sector()
    local plan = wreckage:getMovePlan()
    local position = wreckage.position

    local ship = _Sector:createShip(faction, "", plan, position, EntityArrivalType.Default)

    ShipUtility.addRevenantArtillery(ship)

    local name, type = ShipUtility.getMilitaryNameByVolume(ship.volume)
    name = "Revenant"
    ship:setTitle("${toughness}${ship}", { toughness = "", ship = name})
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability

    ship:setValue("is_armed", true)
    ship:setValue("is_defender", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/defender.png")

    return ship
end

function ShipGenerator.createCivilTransport(faction, position, volume)
    local _MethodName = "Create Civil Transport"
    ShipGenerator.Log(_MethodName, "Beginning...")

    position = position or Matrix()
    volume = volume or Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation()

    local plan = PlanGenerator.makeCivilTransportPlan(faction, volume)

    local ship = Sector():createShip(faction, "", plan, position)

    ship.shieldDurability = ship.shieldMaxDurability
    ship.crew = ship.idealCrew

    AddDefaultShipScripts(ship)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())
    ShipUtility.addArmedTurretsToCraft(ship, turrets)

    ship.crew = ship.idealCrew
    ship.title = ShipUtility.getFreighterNameByVolume(ship.volume)

    ship:addScript("civilship.lua")
    ship:addScript("dialogs/storyhints.lua")
    ship:setValue("is_civil", true)
    ship:setValue("is_civiliantransport", true)
    ship:setValue("npc_chatter", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/civil-ship.png")

    ship:setTitle("Civilian Transport", {})

    return ship
end

function ShipGenerator.createFlagShip(faction, position)
    local _MethodName = "Create FlagShip"
    ShipGenerator.Log(_MethodName, "Beginning...")

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 40.0 * _Amp

    local ship = ShipGenerator.createShip(faction, position, volume)

    ShipUtility.addFlagShipEquipment(ship) --sets title already.
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_flagship", true)

    return ship
end

function ShipGenerator.Log(_MethodName, _Msg, _OverrideDebug)
    local _LocalDebug = ShipGenerator._Debug or 0
    if _OverrideDebug == 1 then
        _LocalDebug = 1
    end

    if _LocalDebug == 1 then
        print("[ESCC Ship Generator] - [" .. _MethodName .. "] - " .. _Msg)
    end
end