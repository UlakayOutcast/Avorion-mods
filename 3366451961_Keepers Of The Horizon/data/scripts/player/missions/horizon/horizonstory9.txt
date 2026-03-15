--[[
    MISSION 9: Keepers of the Horizon
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local Balancing = include ("galaxy")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Keepers of the Horizon"

--region #INIT / DATA

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "There are no more obstacles in your path. It's time to strike at the heart of project XSOLOGIZE and defeat the horror that Horizon Keepers, LTD. plans to unleash on the galaxy." },
    { text = "Read Varlance's mail", bulletPoint = true, fulfilled = false },
    { text = "Join the assault at (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Recommended) Equip a weapon that deals electric damage", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Destroy Project XSOLOGIZE before it's activated", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Pursue Project XSOLOGIZE to (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Destroy Project XSOLOGIZE", bulletPoint = true, fulfilled = false, visible = false }
}

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.setPhase3DeathLaser = false
mission.data.custom.allowPhase3Advance = false

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}
mission.globalPhase.onAbandon = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --Player has 5 minutes to head back to the sector.
    mission.data.timeLimitInDescription = true --Show the player how much time is left.
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Get a sector that's very close to the outer edge of the barrier.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory9_getNextLocation(true)
    local firstX = mission.data.custom.firstLocation.x
    local firstY = mission.data.custom.firstLocation.y

    mission.data.description[3].arguments = { _X = firstX, _Y = firstY }

    --Send mail to player.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Hey buddy,\n\nThis is it. We're going to put a stop to the Horizon Keepers. Permanently. I'm gathering up some ships from Frostbite Company and we're going to launch an all-out assault against the main Project XSOLOGIZE shipyard. Hopefully we manage to hit them before they can complete it.\n\nIf not... get ready for a fight. I've been reading through the data again, and it seems like it has some sort of weakness to electrical weapons. I'd suggest equipping a couple if you have any.\n\nThe shipyard is in (%1%:%2%). See you there.\n\nVarlance", firstX, firstY)
	_Mail.header = "Stopping XSOLOGIZE"
	_Mail.sender = "Varlance @FrostbiteCompany"
	_Mail.id = "_horizon_story9_mail"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = 
{
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story9_mail" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].onBegin = function()
    local _MethodName = "Phase 2 On Begin"
    mission.Log(_MethodName, "Beginning...")
    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
    mission.data.description[4].visible = true
end

mission.phases[2].onBeginServer = function()
    local _MethodName = "Phase 2 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.firstLocation

    mission.data.custom.secondLocation = kothStory9_getNextLocation(false)
    local secondX = mission.data.custom.secondLocation.x
    local secondY = mission.data.custom.secondLocation.y

    mission.data.description[6].arguments = { _X = secondX, _Y = secondY }
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Phase 2 on Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    if onServer() then
        kothStory9_buildObjectiveSector(_X, _Y)
        kothStory9_spawnVarlance()
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    nextPhase()
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].triggers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].noBossEncountersTargetSector = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[3].fulfilled = true
    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
    
    if onClient() then
        startBossCameraAnimation(mission.data.custom.xsologizeID)
    end
end

mission.phases[3].onBeginServer = function()
    --Set phase 3 orders
    local aggroFunc = function(ships)
        for _, ship in pairs(ships) do
            local ai = ShipAI(ship)
            ai:setAggressive()
        end
    end

    local _sector = Sector()
    aggroFunc({ _sector:getEntitiesByScriptValue("is_frostbite") })
    aggroFunc({ _sector:getEntitiesByScriptValue("is_horizon_combatcruiser") })
    aggroFunc({ _sector:getEntitiesByScriptValue("is_horizon_shipyard") })

    local xsologizeEntities = { _sector:getEntitiesByScriptValue("is_project_xsologize") }
    for _, xsolo in pairs(xsologizeEntities) do
        local ai = ShipAI(xsolo)
        ai:setIdle()
        ai:setPassiveShooting(true)

        local shipDurability = Durability(xsolo)
        shipDurability.invincibility = 0.95 --We destroy it in phase 4.
    end
end

local kothStory9_onPhase3DialogEnd = makeDialogServerCallback("kothStory9_onPhase3DialogEnd", 3, function()
    nextPhase()
end)

--region #PHASE 3 TIMER CALLS

if onServer() then

mission.phases[3].timers[1] = {
    time = 10,
    callback = function()
        local methodName = "Phase 3 Timer 1 Callback"
        mission.Log(methodName, "Beginning.")

        HorizonUtil.varlanceChatter("Glad you could make it, buddy. Destroy XSOLOGIZE before they activate it!")
    end,
    repeating = false
}

mission.phases[3].timers[2] = {
    time = 30,
    callback = function()
        local methodName = "Phase 3 Timer 2 Callback"

        if atTargetLocation() and not mission.data.custom.setPhase3DeathLaser then
            mission.Log(methodName, "Setting death laser")

            mission.data.custom.setPhase3DeathLaser = true

            --laser script
            local _sector = Sector()
            local x, y = _sector:getCoordinates()
            local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 250

            local _LaserSniperValues = {
                _DamagePerFrame = _dpf,
                _TimeToActive = 0,
                _TargetCycle = 5, --shoot roughly twice as fast
                _TargetPriority = 3,
                _CreepingBeamSpeed = 5, --basically locks on.
                _TargetTag = "is_frostbite_warship"
            }

            Entity(mission.data.custom.xsologizeID):addScriptOnce("lasersniper.lua", _LaserSniperValues)

            HorizonUtil.varlanceChatter("Massive power surge detected?! No...! We're too late!")
        end
    end,
    repeating = true
}

end

--endregion

--region #PHASE 3 TRIGGER CALLS

if onServer() then

mission.phases[3].triggers[1] = {
    condition = function()
        if atTargetLocation() then
            if ESCCUtil.countEntitiesByValue("is_frostbite_warship") == 0 then
                return true
            end
        end

        return false
    end,
    callback = function()
        local _sector = Sector()
        local x, y = _sector:getCoordinates()
        local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 750 --x3 the damage. we want it to get varlance to critical in one shot.

        local xsologize = Entity(mission.data.custom.xsologizeID)

        if not xsologize then
            print("ERROR: XSOLOGIZE should exist at this point")
            terminate()
            return
        end

        xsologize:invokeFunction("lasersniper.lua", "adjustDamage", _dpf)
        xsologize:invokeFunction("lasersniper.lua", "adjustTargetPrio", 3, "is_varlance")
    end,
    repeating = false
}

mission.phases[3].triggers[2] = {
    condition = function()
        if atTargetLocation() then
            local varlance = Entity(mission.data.custom.varlanceID)
            local varlanceHPThreshold = varlance.durability / varlance.maxDurability

            if ESCCUtil.countEntitiesByValue("is_frostbite") == 1 and varlanceHPThreshold < 0.2 then
                return true
            end
        end

        return false
    end,
    callback = function()
        local xsologize = Entity(mission.data.custom.xsologizeID)
        --remove the laser script from xsologize
        xsologize:invokeFunction("lasersniper.lua", "deleteCurrentLasers")
        xsologize:removeScript("lasersniper.lua")
        --xsologize leaves
        xsologize:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))
        --allow phase advance
        mission.data.custom.allowPhase3Advance = true
    end,
    repeating = false
}

mission.phases[3].triggers[3] = {
    condition = function()
        if atTargetLocation() then
            local _sector = Sector()
            if mission.data.custom.allowPhase3Advance and not _sector:exists(mission.data.custom.xsologizeID) then
                return true
            end
        end
    end,
    callback = function()
        local _MethodName = "Phase 3 Trigger 3 Callback"
        mission.Log(_MethodName, "Beginning...")
        invokeClientFunction(Player(), "kothStory9_onPhase3Dialog", mission.data.custom.varlanceID)
    end,
    repeating = false
}

end

--endregion

mission.phases[4] = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].noBossEncountersTargetSector = true
mission.phases[4].noPlayerEventsTargetSector = true
mission.phases[4].noLocalPlayerEventsTargetSector = true
mission.phases[4].onBegin = function()
    local _MethodName = "Phase 4 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.secondLocation

    mission.data.description[5].fulfilled = true
    mission.data.description[6].visible = true

    mission.data.timeLimit = mission.internals.timePassed + (10 * 60) --Player has 10 minutes to pursue.
    mission.data.timeLimitInDescription = true --Show the player how much time is left.
end

mission.phases[4].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Phase 4 on Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    if onServer() then
        kothStory9_buildBossSector()
        nextPhase()
    end
end

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].triggers = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].noBossEncountersTargetSector = true
mission.phases[5].noPlayerEventsTargetSector = true
mission.phases[5].noLocalPlayerEventsTargetSector = true
mission.phases[5].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[6].fulfilled = true
    mission.data.description[7].visible = true
end

local kothStory9_onPhase5Dialog1End = makeDialogServerCallback("kothStory9_onPhase5Dialog1End", 5, function()
    local xsologize = Entity(mission.data.custom.xsologizeID)

    xsologize:addScriptOnce("player/missions/horizon/story9/xsologizebosslaser.lua", { _pindex = Player().index })
end)

local kothStory9_onPhase5Dialog2End = makeDialogServerCallback("kothStory9_onPhase5Dialog2End", 5, function()
    local xsologize = Entity(mission.data.custom.xsologizeID)

    local xsoloShield = Shield(mission.data.custom.xsologizeID)
    xsoloShield.invincible = false

    local ai = ShipAI(mission.data.custom.xsologizeID)
    ai:clearFriendFactions()
    ai:clearFriendEntities()
    ai:setAggressive()

    xsologize:addScriptOnce("player/missions/horizon/story9/horizonstory9boss.lua")
    xsologize:addScriptOnce("entity/xsologizeboss.lua")
    xsologize:invokeFunction("entity/xsologizeboss.lua", "setInternalClock", 30)
    nextPhase()
end)

--region #PHASE 5 TIMER CALLS

if onServer() then

mission.phases[5].timers[1] = {
    time = 5,
    callback = function()
        local xsoloShield = Shield(mission.data.custom.xsologizeID)
        xsoloShield.invincible = true

        invokeClientFunction(Player(), "kothStory9_onPhase5Dialog", mission.data.custom.xsologizeID)
    end,
    repeating = false
}

mission.phases[5].timers[2] = {
    time = 1,
    callback = function()
        --We still set the shield to invincible, but this works as well.
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
    repeating = true --We want this to fire repeatedly as long as we're in phase 5.
}

end

--endregion

--region #PHASE 5 TRIGGER CALLS

if onServer() then

mission.phases[5].triggers[1] = {
    condition = function()
        if atTargetLocation() then
            local xsologize = Entity(mission.data.custom.xsologizeID)
            if xsologize and xsologize:getValue("_horizon_story9_laserexplosion") then
                return true
            end
        end

        return false
    end,
    callback = function()
        invokeClientFunction(Player(), "kothStory9_onPhase5Dialog2", mission.data.custom.xsologizeID)
    end,
    repeating = false
}

end

--endregion

mission.phases[6] = {}
mission.phases[6].timers = {}
mission.phases[6].noBossEncountersTargetSector = true
mission.phases[6].noPlayerEventsTargetSector = true
mission.phases[6].noLocalPlayerEventsTargetSector = true

--region #PHASE 6 TIMER CALLS

if onServer() then

mission.phases[6].timers[1] = {
    time = 10,
    callback = function()
        if atTargetLocation() then
            if ESCCUtil.countEntitiesByValue("is_project_xsologize") == 0 then
                kothStory9_finishAndReward()
            end
        end
    end,
    repeating = true
}

end

--endregion

--endregion

--region #SERVER CALLS

function kothStory9_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Getting a location.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Get a sector that's very close to the outer edge of the barrier.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 2, 4, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 2, 4, false)
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

function kothStory9_spawnVarlance()
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

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(true) --for once, we'll set him up to despawn when we leave.

        local varlanceAI = ShipAI(_Varlance)
        varlanceAI:setAggressive()

        local varlanceDurability = Durability(_Varlance)
        varlanceDurability.invincibility = 0.16 --Juuuuuust above the point where he withdraws.

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory9_buildObjectiveSector(x, y)
    local _MethodName = "Build Objective Sector"
    mission.Log(_MethodName, "Beginning.")

    local _random = random()

    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    --make XSOLOGIZE 60km out.
    local xsolopos = ESCCUtil.getVectorAtDistance(pos, 6000, true)
    local xsoloMatrix = MatrixLookUpPosition(look, up, xsolopos)
    local xsologize = HorizonUtil.spawnProjectXsologize(true, xsoloMatrix)
    mission.Log(_MethodName, "Setting mission.data.custom.xsologizeID to" .. tostring(xsologize.index))    
    mission.data.custom.xsologizeID = xsologize.index    

    --next, start @ xsologize, and move away from player, then make shipyard.
    local dir = normalize(xsolopos - pos)
    local sybasepos = xsolopos + (dir * 1500)
    local sypos = ESCCUtil.getVectorAtDistance(sybasepos, 1000, false) --jiggle it a little to hopefully get a better shot of xsologize on the cutscene.
    local symatrix = MatrixLookUpPosition(look, up, sypos)

    local sy = HorizonUtil.spawnHorizonShipyard2(true, symatrix)
    mission.data.custom.shipyardID = sy.index
  
    --Make 3 horizon combat cruisers
    for _ = 1, 3 do
        local cruiser = HorizonUtil.spawnHorizonCombatCruiser(true, nil, nil)
        cruiser:setValue("_ESCC_bypass_hazard", true)
    end

    --Make 4 frostbite warships
    for _ = 1, 4 do
        local frostbite = HorizonUtil.spawnFrostbiteWarship(true)
        frostbite:setValue("_ESCC_bypass_hazard", true)
    end

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function kothStory9_buildBossSector()
    local _MethodName = "Build Boss Sector"
    mission.Log(_MethodName, "Beginning.")

    local _random = random()
    --spawn xsologize - set faction to friendly for a short dialog
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end
    local xsolopos = ESCCUtil.getVectorAtDistance(pos, 3000, true)
    local xsoloMatrix = MatrixLookUpPosition(look, up, xsolopos)

    local xsologize = HorizonUtil.spawnProjectXsologize(false, xsoloMatrix)

    local ai = ShipAI(xsologize)
    ai:registerFriendFaction(Player().index)

    mission.Log(_MethodName, "xsologize is " .. tostring(xsologize) .. " setting xsologize id to " .. tostring(xsologize.index) .. "and syncing")

    mission.data.custom.xsologizeID = xsologize.index
    sync()
end

function kothStory9_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    local _player = Player()

    local accomplishMessage = "Frostbite Company thanks you. Here's your compensation."
    local baseReward = 75000000

    local runTime = Server().unpausedRuntime

    _player:setValue("_horizonkeepers_story_stage", 10)
    _player:setValue("_horizonkeepers_story_complete", true)
    _player:setValue("_horizonkeepers_last_side1", runTime)
    _player:setValue("_horizonkeepers_last_side2", runTime)
    _player:setValue("encyclopedia_koth_xsologize", true)
    _player:setValue("encyclopedia_koth_01macedon", true)

    _player:sendChatMessage("Frostbite Company", 0, accomplishMessage)
    mission.data.reward = {credits = baseReward, paymentMessage = "Earned %1% credits for destroying XSOLOGIZE." }

    --Send the player TWO mails! One from Varlance and one forwarded from Mace.
    local _Mail = Mail()

    local _LMTCS = SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), random():createSeed())
    _Mail:addItem(_LMTCS)

    local frostbiteTorpedoBeacon = UsableInventoryItem("frostbitetorpedoloadercaller.lua", Rarity(RarityType.Legendary), HorizonUtil.getFriendlyFaction().index)
    _Mail:addItem(frostbiteTorpedoBeacon)

	_Mail.text = Format("Hey ${_PLAYERNAME},\n\nThe battle doesn't always go to the strong and the race doesn't always go to the swift, but today victory goes to you. With the defeat of XSOLOGIZE, you've spared the galaxy from the path of death and destruction that Horizon Keeper would have ripped through it.\n\nPerhaps someday, we'll meet again. In the meantime, keep those claws of yours sharp. You never know when you might need them.\n\nAlso, in case you were wondering, I got some mail from a mutual acquaintance of ours. I forwarded it to you.\n\nVarlance" % {_PLAYERNAME = _player.name})
	_Mail.header = "You did it"
	_Mail.sender = "Varlance @FrostbiteCompany"
	_Mail.id = "_horizon_story9_mail2"
	_player:addMail(_Mail)

    local _Mail2 = Mail()
	_Mail2.text = Format("Found this in my inbox. Thought you would be interested.\nVarlance\n\n------ Forwarded Message ------\nOriginal sender: 01Macedon\n\nI'm alive. That's all I can tell you. It's better for both of us that our paths not cross again.\n\nAlex")
	_Mail2.header = "Fwd: Don't look for me"
	_Mail2.sender = "Varlance @FrostbiteCompany"
	_Mail2.id = "_horizon_story9_mail3"
	_player:addMail(_Mail2)

    reward()
    accomplish()
end

--endregion

--region #CLIENT DIALOG CALLS

function kothStory9_onPhase3Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}

    d0.text = "Damn! This is exactly what I feared. We were too late to stop them."
    d0.followUp = d1

    d1.text = "My ship is critically damaged. Our nav is toast. We won't be able to pursue it..."
    d1.followUp = d2

    d2.text = "Please, stop it ${_PLAYERNAME}! Only you can fly high enough!" % {_PLAYERNAME = Player().name}
    d2.onEnd = kothStory9_onPhase3DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothStory9_onPhase5Dialog(xsologizeID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    d0.text = "Billions of credits wasted. Thousands dead."
    d0.followUp = d1

    d1.text = "But it was all worth it."
    d1.followUp = d2

    d2.text = "Your ship... Your lives..."
    d2.followUp = d3

    d3.text = "Just another flagstone on our path to conquest."
    d3.followUp = d4

    d4.text = "This is the end, Captain."
    d4.onEnd = kothStory9_onPhase5Dialog1End

    ScriptUI(xsologizeID):interactShowDialog(d0, false)
end

function kothStory9_onPhase5Dialog2(xsologizeID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "What?! The LONGINUS system is down?"
    d0.followUp = d1

    d1.text = "Damn that Varlance! If you two hadn't forced us to rush this..."
    d1.followUp = d2

    d2.text = "It's no matter. Activate HIEROPHANT!"
    d2.followUp = d3

    d3.text = "Helm, turn us to engage that warship!"
    d3.onEnd = kothStory9_onPhase5Dialog2End

    ScriptUI(xsologizeID):interactShowDialog(d0, false)
end

--endregion