--[[
    MISSION 6: Gods of War
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include("shiputility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Gods of War"

--region #INIT / DATA

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "You've driven off the bulk of Horizon Keeper's fleet, now it's time to hunt down their wounded battleships. Put an end to them to clear your path." },
    { text = "Read Varlance's mail", bulletPoint = true, fulfilled = false },
    { text = "Head to sector (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Destroy the Horizon battleships", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Recommended) Defeat the Horizon battle line", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Destroy remaining Horizon ships", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Destroy the prototype Horizon weapons", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Recommended) Destroy the Alpha weapon to eliminate point defenses", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Recommended) Use shield-piercing munitions to destroy the Beta weapon", bulletPoint = true, fulfilled = false, visible = false }
}

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.stage2OrdersSet = false
mission.data.custom.playerRushedBattleships = false
mission.data.custom.phase3Timer = 0
mission.data.custom.phase4Timer = 0
mission.data.custom.phase4DialogStarted = false
mission.data.custom.phase4CallSupports = false
mission.data.custom.varlanceP4ChatterSent = false

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        if atTargetLocation() then
            kothStory6_frostbiteDeparts()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        if atTargetLocation() then
            kothStory6_frostbiteDeparts()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    --Reset gretel 'death laser' if needed.
    if onServer() and mission.data.custom.gretelID and Sector():exists(mission.data.custom.gretelID) then
        local gretel = Entity(mission.data.custom.gretelID)
        gretel:invokeFunction("lasersniper.lua", "resetTimeToActive", 15)
    end

    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --Player has 5 minutes to head back to the sector.
    mission.data.timeLimitInDescription = true --Show the player how much time is left.
end

--region #GLOBALPHASE TIMERS

if onServer() then

mission.globalPhase.timers[1] = {
    time = 180, --He doesn't have the resources of Adriana, can't respawn as quickly.
    callback = function()
        local _MethodName = "Global Phase Timer 1 Callback"

        if atTargetLocation() then
            mission.Log(_MethodName, "On Location - respawning Varlance if needed.")

            kothStory6_spawnVarlance()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Get a sector that's very close to the outer edge of the barrier.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory6_getNextLocation(true)

    local _X = mission.data.custom.firstLocation.x
    local _Y = mission.data.custom.firstLocation.y

    mission.data.description[3].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Send mail to player.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Hey, buddy.\n\nI've tracked the battleships to (%1%:%2%). Meet up with me there. It's time to put the Horizon battle fleet down for good.\n\nVarlance", _X, _Y)
	_Mail.header = "Found the Battleships"
	_Mail.sender = "Varlance @FrostbiteCompany"
	_Mail.id = "_horizon_story6_mail"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story6_mail" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBegin = function()
    local _MethodName = "Phase 2 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.firstLocation

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_x, _y)
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    if onServer() then
        kothStory6_buildObjectiveSector(_x, _y)
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_x, _y)
    --Start varlance dialog, then go to phase 3.
    invokeClientFunction(Player(), "kothStory6_onPhase2Dialog", mission.data.custom.battleshipID)
end

local kothStory6_onPhase2DialogEnd = makeDialogServerCallback("kothStory6_onPhase2DialogEnd", 2, function()
    nextPhase()
end)

--region #PHASE 2 TIMER CALLS

if onServer() then

mission.phases[2].timers[1] = {
    time = 1,
    callback = function()
        if atTargetLocation() then
            local ships = {Sector():getEntitiesByType(EntityType.Ship)}
            for _, ship in pairs(ships) do
                if ship.playerOrAllianceOwned then
                    local ai = ShipAI(ship)
                    ai:stop()
                end
            end
        end
    end,
    repeating = true --We want this to fire repeatedly as long as we're in phase 2.
}

end

--endregion

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    mission.data.description[5].visible = true
end

mission.phases[3].onBeginServer = function()
    local _MethodName = "Phase 3 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    --Start fight.
    kothStory6_runPhase3Orders()
    kothStory6_setbShipStage1Orders()
end

mission.phases[3].updateTargetLocationServer = function(timeStep)
    local horizonCt = ESCCUtil.countEntitiesByValue("is_horizon")
    if horizonCt == 0 then
        mission.data.custom.phase3Timer = mission.data.custom.phase3Timer + timeStep

        if mission.data.custom.phase3Timer >= 5 then
            nextPhase()
        end
    end
end

--region #PHASE 3 TIMER CALLS

if onServer() then

mission.phases[3].timers[1] = {
    time = 5,
    callback = function()
        --Don't do anything if we're not in the location.
        if atTargetLocation() then
            local cruiserCt = ESCCUtil.countEntitiesByValue("is_horizon_combatcruiser")
            if cruiserCt == 0 and not mission.data.custom.stage2OrdersSet and not mission.data.custom.playerRushedBattleships then
                mission.data.custom.stage2OrdersSet = true

                mission.data.description[5].fulfilled = true

                HorizonUtil.varlanceChatter("Their defensive screen is gone. The battleships will have to engage us directly now.")

                kothStory6_setbShipStage2Orders()

                sync()
                mission.phases[3].timers[1].repeating = false --We don't need this one again.
            end
        end
    end,
    repeating = true
}

mission.phases[3].timers[2] = {
    time = 5,
    callback = function()
        if atTargetLocation() then
            local cruiserCt = ESCCUtil.countEntitiesByValue("is_horizon_combatcruiser")
            local bshipCt = ESCCUtil.countEntitiesByValue("is_horizon_battleship")

            if cruiserCt > 0 and bshipCt == 0 then
                mission.data.custom.playerRushedBattleships = true

                mission.data.description[4].fulfilled = true
                mission.data.description[5].fulfilled = true
                mission.data.description[6].visible = true

                sync()
                mission.phases[3].timers[2].repeating = false --We don't need this one again.
            end
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    mission.data.description[4].fulfilled = true
    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true
end

mission.phases[4].onBeginServer = function()
    local _MethodName = "Phase 4 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    kothStory6_spawnVarlance()

    --Set varlance to idle.
    local varlanceAI = ShipAI(mission.data.custom.varlanceID)
    varlanceAI:stop()

    --Hansel / Gretel jump in and confront you.
    kothStory6_spawnBosses()

    invokeClientFunction(Player(), "kothStory6_onPhase4CutScene", mission.data.custom.hanselID)
end

mission.phases[4].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Phase 4 On Update Server"
    mission.data.custom.phase4Timer = mission.data.custom.phase4Timer + timeStep

    --mission.Log(_MethodName, "Phase 4 timer is " .. tostring(mission.data.custom.phase4Timer))
    --Give the cinematic enough time to play out.
    if mission.data.custom.phase4Timer >= 8 and not mission.data.custom.phase4DialogStarted then
        mission.data.custom.phase4DialogStarted = true
        invokeClientFunction(Player(), "kothStory6_onPhase4Dialog", mission.data.custom.hanselID)
    end
end

local kothStory6_onPhase4DialogEnd = makeDialogServerCallback("kothStory6_onPhase4DialogEnd", 4, function()
    --set varlance to aggressive.
    local varlanceAI = ShipAI(mission.data.custom.varlanceID)
    varlanceAI:setAggressive()

    --clear friend faction from hansel / gretel, add boss scripts, and set laser sniper to activate in 30 seconds.
    local _Sector = Sector()
    local horizonShips = { _Sector:getEntitiesByScriptValue("is_horizon_prototype") }
    for _, horizonShip in pairs(horizonShips) do
        local horizonAI = ShipAI(horizonShip)
        horizonAI:clearFriendFactions()
        horizonAI:clearFriendEntities()
        horizonAI:setAggressive()
        horizonShip:addScriptOnce("player/missions/horizon/story6/horizonstory6boss.lua")
    end

    local gretelShip = { _Sector:getEntitiesByScriptValue("is_beta_gretel") }
    gretelShip[1]:invokeFunction("lasersniper.lua", "resetTimeToActive", 30)

    --Allow support ships to spawn.
    mission.data.custom.phase4CallSupports = true

    --Set objective 7-9 to visible.
    mission.data.description[7].visible = true
    mission.data.description[8].visible = true
    mission.data.description[9].visible = true

    sync()
end)

--region #PHASE 4 TIMER CALLS

if onServer() then

mission.phases[4].timers[1] = {
    time = 180,
    callback = function()
        local _MethodName = "Phase 4 Timer 1 Callback"
        mission.Log(_MethodName, "Beginning...")

        local _sector = Sector()

        if atTargetLocation() and mission.data.custom.phase4CallSupports then
            mission.Log(_MethodName, "Spawning torpedo loader.")

            if not mission.data.custom.varlanceP4ChatterSent and _sector:exists(mission.data.custom.varlanceID) then
                mission.data.custom.varlanceP4ChatterSent = true
                HorizonUtil.varlanceChatter("Torpedo loader on scene. Close with them and they can provide you with sabot torpedoes.")
            end

            --spawn a torp loader and order it to follow the player ship.
            local torpLoader = HorizonUtil.spawnFrostbiteTorpedoLoader(true, true)
            local torpLoaderAI = ShipAI(torpLoader)

            --Get player ship
            local ship = Player().craft
            if ship then 
                torpLoaderAI:setFollow(ship, false)
            else
                torpLoaderAI:setFlyLinear(torpLoader.look * 20000, 0, false)
            end

            --Let's be real - these will almost always get destroyed by the Gretel before they hit the 2 minute mark.
            torpLoader:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(120, 130))
        end
    end,
    repeating = true
}

mission.phases[4].timers[2] = {
    time = 5,
    callback = function()
        if atTargetLocation() then
            local hanselCt = ESCCUtil.countEntitiesByValue("is_alpha_hansel")
            local gretelCt = ESCCUtil.countEntitiesByValue("is_beta_gretel")

            local player = Player()

            if hanselCt == 0 then
                mission.data.description[8].fulfilled = true
                player:setValue("_horizonkeepers_killed_hansel", true)

                if gretelCt > 0 and not mission.data.custom.gretelOverdriveActive then
                    mission.data.custom.gretelOverdriveActive = true

                    local _sector = Sector()
                    local gretel = { _sector:getEntitiesByScriptValue("is_beta_gretel") }
                    _sector:broadcastChatMessage(gretel[1], ChatMessageType.Chatter, "NO!!! Overload the reactor NOW! We'll drag them to the depths of hell with us!")
                    gretel[1]:addScriptOnce("frenzy.lua", { _UpdateCycle = 30, _IncreasePerUpdate = 0.15, _DamageThreshold = 1.01 })
                end
            end

            if gretelCt == 0 then
                mission.data.description[9].fulfilled = true
                player:setValue("_horizonkeepers_killed_gretel", true)

                --I don't anticipate players seeing this under most cirumstances, buuuuut...
                if hanselCt > 0 and not mission.data.custom.hanselOverdriveActive then
                    mission.data.custom.hanselOverdriveActive = true

                    local _sector = Sector()
                    local hansel = { _sector:getEntitiesByScriptValue("is_alpha_hansel") }
                    _sector:broadcastChatMessage(hansel[1], ChatMessageType.Chatter, "How... how is this possible?! Kill them! KILL THEM NOW!!!")
                    hansel[1]:addScriptOnce("frenzy.lua", { _UpdateCycle = 30, _IncreasePerUpdate = 0.25, _DamageThreshold = 1.01 })
                end
            end
            
            if hanselCt == 0 or gretelCt == 0 then
                sync()
            end
    
            if mission.data.custom.phase4CallSupports and hanselCt == 0 and gretelCt == 0 then
                nextPhase()
            end
        end
    end,
    repeating = true
}

mission.phases[4].timers[3] = {
    time = 1,
    callback = function()
        --Stops our ships from shooting the bosses down during the dialog.
        if atTargetLocation() and not mission.data.custom.phase4CallSupports then
            local ships = {Sector():getEntitiesByType(EntityType.Ship)}
            for _, ship in pairs(ships) do
                if ship.playerOrAllianceOwned then
                    local ai = ShipAI(ship)
                    ai:stop()
                end
            end
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[5] = {}
mission.phases[5].onBegin = function()
    mission.data.description[7].fulfilled = true
    mission.data.description[8].fulfilled = true
    mission.data.description[9].fulfilled = true
end

mission.phases[5].onBeginServer = function()
    local _MethodName = "Phase 5 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    kothStory6_spawnVarlance()

    --Set varlance to idle.
    local varlanceAI = ShipAI(mission.data.custom.varlanceID)
    varlanceAI:stop()

    --Send varlance dialog.
    invokeClientFunction(Player(), "kothStory6_onPhase5Dialog", mission.data.custom.varlanceID)
end

local kothStory6_onPhase5DialogEnd = makeDialogServerCallback("kothStory6_onPhase5DialogEnd", 5, function()
    local varlance = Entity(mission.data.custom.varlanceID)
    MissionUT.deleteOnPlayersLeft(varlance)

    kothStory6_finishAndReward()
end)

--endregion

--region #SERVER CALLS

function kothStory6_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Getting a location.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Get a sector that's very close to the outer edge of the barrier.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 6, 12, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 6, 12, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 8, 18, false)
    end

    mission.Log(_MethodName, "X coordinate of next location is : " .. tostring(target.x) .. " Y coordinate of next location is : " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Could not find a suitable mission location. Terminating script.")
        terminate()
        return
    end

    return target
end

function kothStory6_buildObjectiveSector(x, y)
    local methodName = "Build Objective Sector"

    local _random = random()

    --Get player position first.
    local look = _random:getVector(-100, 100)
    local look2 = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local up2 = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local bshipPos1 = ESCCUtil.getVectorAtDistance(pos, 6500, true)
    local bsMatrix1 = MatrixLookUpPosition(look, up, bshipPos1)

    local bshipPos2 = ESCCUtil.getVectorAtDistance(bshipPos1, 1000, false)
    local bsMatrix2 = MatrixLookUpPosition(look2, up2, bshipPos2)

    local createdShipTable = {}

    --spawn 2 battleships
    local bShip1 = HorizonUtil.spawnHorizonBattleship(false, bsMatrix1, nil)
    local bShip2 = HorizonUtil.spawnHorizonBattleship(false, bsMatrix2, nil)

    mission.data.custom.battleshipID = bShip1.index

    --damage both of them.
    bShip1.durability = bShip1.maxDurability * 0.25
    bShip2.durability = bShip2.maxDurability * 0.25

    table.insert(createdShipTable, bShip1)
    table.insert(createdShipTable, bShip2)

    --spawn 4 cruisers
    for idx = 1, 4 do
        local cLook = _random:getVector(-100, 100)
        local cUp = _random:getVector(-100, 100)
        local cPos = ESCCUtil.getVectorAtDistance(bshipPos1, 1500, false)
        local cMatrix = MatrixLookUpPosition(cLook, cUp, cPos)

        local cruiser = HorizonUtil.spawnHorizonCombatCruiser(false, cMatrix, nil)
        table.insert(createdShipTable, cruiser)
    end

    --spawn varlance
    kothStory6_spawnVarlance()

    --add buffs
    SpawnUtility.addEnemyBuffs(createdShipTable)

    --resolve intersections
    Placer.resolveIntersections()

    --register all ships as friendly - use the swoks trick. Need this in case players bring in multiple ships.
    for _, _ship in pairs(createdShipTable) do
        local allianceIndex = _Player.allianceIndex
        local ai = ShipAI(_ship)
        ai:registerFriendFaction(_Player.index)
        if allianceIndex then
            ai:registerFriendFaction(allianceIndex)
        end
    end

    mission.data.custom.cleanUpSector = true
end

function kothStory6_spawnVarlance()
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "No Varlance in sector - spawning him in.")

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(false)

        --He can stay idle in other phases, but he needs to aggro in p3/pr
        if mission.internals.phaseIndex == 3 or mission.internals.phaseIndex == 4 then
            local varlanceAI = ShipAI(_Varlance)
            varlanceAI:setAggressive()
        end

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory6_frostbiteDeparts()
    local _frostbiteShips = { Sector():getEntitiesByScriptValue("is_frostbite") }
    for _, _ship in pairs(_frostbiteShips) do
        _ship:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
    end
end

function kothStory6_setbShipStage1Orders()
    --Get all turrets on the ship and set them to range 8000

    --Add torpedo slammer script.
    local _Sector = Sector()

    local slammerValues = {
        _TimeToActive = 5,
        _ROF = 6,
        _DamageFactor = 2,
        _PreferWarheadType = 3, --Fusion
        _PreferBodyType = 7, --Osprey
        _DurabilityFactor = 4,
        _TargetPriority = 4, --random enemy
        _AccelFactor = 2,
        _VelocityFactor = 2,
        _TurningSpeedFactor = 2,
        _ReachFactor = 2
    }

    local battleshipTable = { _Sector:getEntitiesByScriptValue("is_horizon_battleship") }
    for _, battleShip in pairs(battleshipTable) do
        local battleshipAI = ShipAI(battleShip)

        --Delete all the turrets on the battleship, then re-add them.
        local _ClearTurrets = {battleShip:getTurrets()}
        for _, _Turret in pairs(_ClearTurrets) do
            _Sector:deleteEntity(_Turret)
        end

        --adding point defenses will cause it to not shoot until the PD is in range too. Wacky but it is what it is.
        ShipUtility.addSpecificScalableWeapon(battleShip, { WeaponType.Cannon }, 4, 1, 8000)

        battleShip:addScriptOnce("torpedoslammer.lua", slammerValues)

        battleshipAI:stop()
        battleshipAI:setPassiveShooting(true)

        local dmgMult = battleShip.damageMultiplier
        battleShip:setValue("_original_dmgMultiplier", dmgMult)
        battleShip.damageMultiplier = battleShip.damageMultiplier * 2
    end
end

function kothStory6_setbShipStage2Orders()
    --remove torpedo slammer script.
    local _Sector = Sector()
    
    local battleshipTable = { _Sector:getEntitiesByScriptValue("is_horizon_battleship") }
    for _, battleShip in pairs(battleshipTable) do
        local battleshipAI = ShipAI(battleShip)

        --Delete all the turrets on the battleship, then re-add them.
        local _ClearTurrets = {battleShip:getTurrets()}
        for _, _Turret in pairs(_ClearTurrets) do
            _Sector:deleteEntity(_Turret)
        end

        ShipUtility.addSpecificScalableWeapon(battleShip, { WeaponType.Cannon }, 4, 1)
        ShipUtility.addBossAntiTorpedoEquipment(battleShip)

        battleShip:removeScript("torpedoslammer.lua")

        battleshipAI:stop()
        battleshipAI:setPassiveShooting(false)
        battleshipAI:setAggressive()

        local dmgMult = battleShip:getValue("_original_dmgMultiplier") * 0.66 --reduce damage.
        battleShip.damageMultiplier = dmgMult
    end
end

function kothStory6_runPhase3Orders()
    local _MethodName = "Run Phase 3 Orders"

    local _Sector = Sector()
    local horizonShips = { _Sector:getEntitiesByScriptValue("is_horizon") }
    for _, horizonShip in pairs(horizonShips) do
        local horizonAI = ShipAI(horizonShip)
        horizonAI:clearFriendFactions()
        horizonAI:clearFriendEntities()
    end

    local horizonCruisers = { _Sector:getEntitiesByScriptValue("is_horizon_combatcruiser") }
    --should go 1 to 4
    for idx, horizonCruiser in pairs(horizonCruisers) do
        local horizonAI = ShipAI(horizonCruiser)

        local tgtPriority = 2 - math.fmod(idx, 2)

        mission.Log(_MethodName, "Target priority for cruiser is " .. tostring(tgtPriority))

        horizonCruiser:addScriptOnce("ai/priorityattacker.lua", { _TargetPriority = tgtPriority, _TargetTag = "is_frostbite" })

        horizonAI:setAggressive() --stopgap while waiting for priority attacker to run first update.
    end

    local frostbiteShips = { _Sector:getEntitiesByScriptValue("is_frostbite") }
    for _, frostbiteShip in pairs(frostbiteShips) do
        local frostAI = ShipAI(frostbiteShip)
        frostAI:setAggressive()
    end
end

function kothStory6_spawnBosses()
    local _random = random()

    --Get player position first.
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local hanselPos = ESCCUtil.getVectorAtDistance(pos, 3500, true)
    local hanselMatrix = MatrixLookUpPosition(look, up, hanselPos)

    local gretelPos = ESCCUtil.getVectorAtDistance(hanselPos, 900, false)
    local gretelMatrix = MatrixLookUpPosition(look, up, gretelPos)

    local _addGoodLootHansel = false
    if not _Player:getValue("_horizonkeepers_killed_hansel") then
        _addGoodLootHansel = true
    end
    local _addGoodLootGretel = false
    if not _Player:getValue("_horizonkeepers_killed_gretel") then
        _addGoodLootGretel = true
    end
    local hansel = HorizonUtil.spawnAlphaHansel(false, hanselMatrix, _addGoodLootHansel, false)
    local gretel = HorizonUtil.spawnBetaGretel(false, gretelMatrix, _addGoodLootGretel, false)

    local createdShipTable = { hansel, gretel }

    --register all ships as friendly - use the swoks trick. Need this in case players bring in multiple ships.
    for _, _ship in pairs(createdShipTable) do
        local allianceIndex = _Player.allianceIndex
        local ai = ShipAI(_ship)
        ai:registerFriendFaction(_Player.index)
        if allianceIndex then
            ai:registerFriendFaction(allianceIndex)
        end
    end

    mission.data.custom.hanselID = hansel.index
    mission.data.custom.gretelID = gretel.index
end

function kothStory6_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    local _player = Player()

    local _AccomplishMessage = "Frostbite Company thanks you. Here's your compensation."
    local _BaseReward = 38420000

    _player:setValue("_horizonkeepers_story_stage", 7)
    _player:setValue("encyclopedia_koth_hanselgretel", true)
    _player:setValue("encyclopedia_koth_torploader", true)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward, paymentMessage = "Earned %1% credits for destroying the Horizon Keeper fleet." }

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function kothStory6_onPhase2Dialog(battleshipID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "There they are, buddy. Our cornered rats."
    d0.answers = {
        { answer = "Those are damn big rats.", followUp = d1 }
    }

    d1.text = "Don't let their size intimidate you - we've already torn them to pieces once. Our claws are sharper."
    d1.followUp = d2

    d2.text = "Take out the battle line of cruisers first. As long as the battleships have a defensive screen they can stand off and hammer us with torpedoes and cannon fire."
    d2.followUp = d3

    d3.text = "Let's get moving. We'll show them how high we can soar."
    d3.onEnd = kothStory6_onPhase2DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(battleshipID):interactShowDialog(d0, false)
end

function kothStory6_onPhase4CutScene(weaponID)
    startBossCameraAnimation(weaponID)
end

function kothStory6_onPhase4Dialog(weaponID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}
    local d9 = {}

    d0.text = "We're too late... they're all dead."
    d0.followUp = d1

    d1.text = "You'll pay for what you've done, butchers."
    d1.followUp = d2

    d2.text = "Butchers? You're the ones providing high-tech weapons to pirates."
    d2.followUp = d3

    d3.text = "You don't understand. To stay as we are... it is only a matter of time until the galaxy is rent asunder again."
    d3.followUp = d4

    d4.text = "They are endless. They are unstoppable. We must evolve, and the Xsotan are the next step... beyond the horizon!"
    d4.followUp = d5

    d5.text = "I see. You've clearly lost your grasp on reality."
    d5.followUp = d6

    d6.text = "Stay on your toes, buddy. The readings we're getting from these ships are concerning."
    d6.followUp = d7

    d7.text = "Preliminary scans show the alpha unit has some sort of advanced point defense system. The beta unit has a powerful shielding system."
    d7.followUp = d8

    d8.text = "It doesn't look like it's hardened. Sabot torpedoes or pulse cannons will tear right through it."
    d8.followUp = d9

    d9.text = "There's a trick I learned from The Cavaliers that'll work here. Let's finish this."
    d9.onEnd = kothStory6_onPhase4DialogEnd

    ESCCUtil.setTalkerTextColors({d2, d5, d6, d7, d8, d9}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(weaponID):interactShowDialog(d0, false)
end

function kothStory6_onPhase5Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    d0.text = "That was a nightmare."
    d0.followUp = d1

    d1.text = "I think we just spared the galaxy from facing something truly terrifying."
    d1.followUp = d2
    
    d2.text = "These ships - these captains - were a cut above the idiot in charge of this stolen battleship. I'll see what information we can dredge out of the computer systems in these wrecks."
    d2.followUp = d3

    d3.text = "In the meantime, our path is clear. We assault their shipyard next."
    d3.followUp = d4

    d4.text = "I'll contact you when it's time, buddy."
    d4.onEnd = kothStory6_onPhase5DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

--endregion