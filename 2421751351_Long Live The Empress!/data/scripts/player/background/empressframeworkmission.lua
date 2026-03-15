package.path = package.path .. ";data/scripts/lib/?.lua"

local MissionUT = include("missionutility")
local AsyncShipGen = include("asyncshipgenerator")
local SectorTurretGenerator = include("sectorturretgenerator")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")

include ("faction")

--Don't remove this or else the script might break.
--namespace EmpressFrameworkMission
EmpressFrameworkMission = {}
local self = EmpressFrameworkMission

self.Cavaliers = nil
self._ContactTime = 30 --Default is 30 minutes - set to 0 for debug

self._Debug = 0

--reigon #INIT

function EmpressFrameworkMission.initialize() 
    local _MethodName = "initialize"
    self.Log(_MethodName, "Beginning...")

    if Player():registerCallback("onSectorArrivalConfirmed", "onSectorArrivalConfirmed") == 1 then
        self.Log(_MethodName, "Failed To Register Callback: onSectorArrivalConfirmed")
    end
end

--endregion

function EmpressFrameworkMission.getUpdateInterval()
    return 30 --Once every 30 seconds should be fine tbh.
end

function EmpressFrameworkMission.Faction()
    -- Try to get the faction if we don't have it loaded
    if not self.Cavaliers then self.Cavaliers = Galaxy():findFaction("The Cavaliers") end
    if not self.Cavaliers then return false end
    return true
end

--region #SERVER CALLS

function EmpressFrameworkMission.updateServer(_TimeStep) 
    local _MethodName = "On Update Server"
    self.Log(_MethodName, "Beginning...")

    -- True/False Faction Check. Also trys to load the faction.
    -- Don't Do anything till we find The Cavaliers
    if not self.Faction() then
        self.Log(_MethodName, "Unable to find The Cavaliers. They remain undiscovered.")
        return
    end
    local player = Player()

    local currentTime = Server().unpausedRuntime
    --First, we need to make sure the player didn't do equlibrium. We do this by loading the new value of cavaliers 5
    local cav5accomplished = player:getValue("cavaliers_5_accomplished")
    local cav5accomplished_old = player:getValue("cavaliers_5_accomplished_old")
    local _Empress = player:getValue("adriana_empress")

    if cav5accomplished then
        player:setValue("encyclopedia_llte_cav5_done", true)
        --We need to set some values here, since the player just newly allied with the Cavaliers + finished their 5th mission.
        if not player:getValue("_llte_cavaliers_rank") then
            if _Empress then
                player:setValue("_llte_cavaliers_rank", "Squire")
            else
                player:setValue("_llte_cavaliers_rank", "General")
            end
        end
        if not player:getValue("_llte_cavaliers_ranklevel") then
            player:setValue("_llte_cavaliers_ranklevel", 1)
        end
        if not player:getValue("_llte_cavaliers_rep") then
            player:setValue("_llte_cavaliers_rep", 0)
        end
        if not player:getValue("_llte_cavaliers_strength") then
            player:setValue("_llte_cavaliers_strength", 1)
        end

        if not cav5accomplished_old or not player:getValue("_llte_cavaliers_startstory") then
            --Wait about 10 minutes before the cavaliers contact the player again - give them time to encounter Izzy and resolve that.
            player:setValue("_llte_cavaliers_startstory", currentTime + (10 * 60))
        end

        --Next, we check the player's rank and give the player the appropriate story mission.
        if _Empress and currentTime > player:getValue("_llte_cavaliers_startstory") then
            local _RankLevel = player:getValue("_llte_cavaliers_ranklevel") or 0
            local _RepLevel = player:getValue("_llte_cavaliers_rep") or 0
            local _VanillaStoryAdvancement = player:getValue("story_advance") or 0
            local _HaveAvo = player:getValue("_llte_cavaliers_have_avorion")
            local _Server = Server()
            local _GuardianRespawn = _Server:getValue("guardian_respawn_time")
            local _SwarmRespawn = _Server:getValue("xsotan_swarm_time")
            local _SwarmDuration = _Server:getValue("xsotan_swarm_duration")
            self.checkPlayerRank(_RankLevel, _RepLevel)

            local _GuardianCanSpawn = true
            if _GuardianRespawn or _SwarmRespawn or _SwarmDuration then
                _GuardianCanSpawn = false
            end

            local _Story1 = player:getValue("_llte_story_1_accomplished")
            self.Log(_MethodName, "Story 1 is " .. tostring(_Story1) .. " checking for script and attaching.")
            if not _Story1 and not player:hasScript("missions/empress/story/lltestorymission1.lua") then
                player:addScript("missions/empress/story/lltestorymission1.lua")
            end
            
            local _Story2 = player:getValue("_llte_story_2_accomplished")
            if _Story1 and not _Story2 and not player:hasScript("missions/empress/story/lltestorymission2.lua") then
                player:addScript("missions/empress/story/lltestorymission2.lua")
            end
            --Mission 3 is obtained through the scout contacting the player. We do, however, need this value to determine if we should start 4.
            local _Story3 = player:getValue("_llte_story_3_accomplished")

            local _Story4 = player:getValue("_llte_story_4_accomplished")
            if _Story3 and not _Story4 and not player:hasScript("missions/empress/story/lltestorymission4.lua") and _RankLevel >= 4 and _HaveAvo then 
                player:addScript("missions/empress/story/lltestorymission4.lua")
            end
            local _Story5 = player:getValue("_llte_story_5_accomplished")
            if _Story4 and not _Story5 and not player:hasScript("missions/empress/story/lltestorymission5.lua") and _RankLevel >= 4 and _VanillaStoryAdvancement >= 6 and _GuardianCanSpawn then
                player:addScript("missions/empress/story/lltestorymission5.lua")
            end
        end
    else
        local _RankLevel = player:getValue("_llte_cavaliers_ranklevel")
        local _Rank = player:getValue("_llte_cavaliers_rank")
        if _RankLevel and _Rank and cav5accomplished_old and _RankLevel > 1 then
            --Send a letter to the player if they've spent any time building up their reputation. Don't send it if they have't done anything.
            local _Mail = Mail()
            _Mail.text = Format("%1% %2%\n\nИли лучше сказать... бывший %1% %2%. Я понимаю, что вы решили работать на другие синдикаты.\nВызывает разочарование, но вполне понятно, что вы решили поставить свое богатство выше безопасности галактики. Я был о тебе лучшего мнения, но так оно и есть.\nЕсли ты захочешь вновь посвятить себя нашему делу, мы будем здесь.\nА пока увидимся на поле битвы.\n\nИмператрица Адриана Шталь", _Rank, player.name)
            _Mail.header = "Severance"
            _Mail.sender = "Empress Adriana Stahl @TheCavaliers"
            _Mail.id = "llte_equilibrium_mail"
            player:addMail(_Mail)
        end
        --Regardless, clear out any rank / rep values / other values for the player, and remove all scripts.
        --Yes, This will COMPLETELY reset your progress with the cavaliers if you side with another faction.
        --Serves you right for siding with the boring space mobsters or the admittedly cool, (but not as cool as the cavaliers) space communists.
        player:setValue("_llte_cavaliers_ranklevel", nil)
        player:setValue("_llte_cavaliers_rank", nil)
        player:setValue("_llte_cavaliers_rep", nil)
        player:setValue("_llte_cavaliers_nextcontact", nil)
        player:setValue("_llte_cavaliers_startstory", nil)
        player:setValue("_llte_story_1_accomplished", nil)
        player:setValue("_llte_story_2_accomplished", nil)
        player:setValue("_llte_story_3_accomplished", nil)
        player:setValue("_llte_story_4_accomplished", nil)
        player:setValue("_llte_story_5_accomplished", nil)
        player:setValue("_llte_failedstory2", nil)
        player:setValue("_llte_pirate_faction_vengeance", nil)
        player:setValue("_llte_got_animosity_loot", nil)
        player:setValue("_llte_cavaliers_have_avorion", nil)
        player:setValue("_llte_cavaliers_strength", nil)
        player:setValue("_llte_cavaliers_inbarrier", nil)
        --Remove all scripts, and I mean ALL scripts.
        local _Scripts = {
            "missions/empress/story/lltestorymission1.lua",
            "missions/empress/story/lltestorymission2.lua",
            "missions/empress/story/lltestorymission3.lua",
            "missions/empress/story/lltestorymission4.lua",
            "missions/empress/story/lltestorymission5.lua",
            "missions/empress/side/lltesidemission1.lua",
            "missions/empress/side/lltesidemission2.lua",
            "missions/empress/side/lltesidemission3.lua",
            "missions/empress/side/lltesidemission4.lua",
            "missions/empress/side/lltesidemission5.lua",
            "missions/empress/side/lltesidemission6.lua"
        }
        for _, _Script in pairs(_Scripts) do
            if player:hasScript(_Script) then
                self.Log(_MethodName, "Invoking fail method of " .. _Script, 1)
                player:invokeFunction(_Script, "fail")
            end
        end
    end
    --After this has set, we regenerate the arsenal, since the value that triggers that can be set during the massive if/elseif above.
    self.regenerateFactionArsenal()

    player:setValue("cavaliers_5_accomplished_old", cav5accomplished)
end

function EmpressFrameworkMission.onSectorArrivalConfirmed(playerIndex, _X, _Y)
    local _MethodName = "On Sector Arrival Confirmed"
    self.Log(_MethodName, "Beginning...")

    -- True/False Faction Check. Also trys to load the faction.
    -- Don't Do anything till we find The Cavaliers
    if not self.Faction() then
        self.Log(_MethodName, "Unable to find The Cavaliers. They remain undiscovered.")
        return
    end
    local _Player = Player()

    local _Cav5accomplished = _Player:getValue("cavaliers_5_accomplished")
    local _CavRank = _Player:getValue("_llte_cavaliers_rank")
    local _CavStartStory = _Player:getValue("_llte_cavaliers_startstory")

    --If the sector is not safe, return.
    local _SectorSafe = self.getSectorSafe(_Player, _X, _Y)
    if not _SectorSafe then return end

    if _Cav5accomplished and _CavRank and _SectorSafe then
        --Start with the scouts after start of story + 10 mins
        local nextcavContact = _Player:getValue("_llte_cavaliers_nextcontact") or (_CavStartStory + (10 * 60))

        local currentTime = Server().unpausedRuntime
        if currentTime >= nextcavContact and currentTime >= _CavStartStory then
            if self.Cavaliers then
                --Contact the player every 30 minutes afterwards. This can be adjusted if needed by modifying self._ContactTime
                self.Log(_MethodName, "Attempting to spawn Cavaliers Scout")
                local futurecavContact = currentTime + (self._ContactTime * 60)
                _Player:setValue("_llte_cavaliers_nextcontact", futurecavContact)
                
                local esccShipGen = AsyncShipGen(EmpressFrameworkMission, EmpressFrameworkMission.onCreateCavScout)
                esccShipGen:startBatch()

                esccShipGen:createScout(self.Cavaliers, EmpressFrameworkMission.getPosition())

                esccShipGen:endBatch()
            end
        else
            self.Log(_MethodName, "The server has run for : " .. tostring(currentTime) .. " seconds - the scout will next spawn at : " .. tostring(nextcavContact) .. " seconds.")
        end
    else
        self.Log(_MethodName, "Cav 5 accomplished is : " .. tostring(_Cav5accomplished) .. " - CavRank is : " .. tostring(_CavRank) .. " - SectorSafe is : " .. tostring(_SectorSafe) .. " - one of these values is not set correctly and the scout will not spawn.")
    end
end

function EmpressFrameworkMission.getPosition()
    local _MethodName = "Get Position"
    self.Log(_MethodName, "Beginning...")

    local _Rgen = ESCCUtil.getRand()
    local _Pos = _Rgen:getVector(-100,100)

    return MatrixLookUpPosition(-_Pos, vec3(0, 1, 0), _Pos)
end

function EmpressFrameworkMission.getSectorSafe(_Player, _X, _Y)
    local _MethodName = "Is Sector Safe"
    self.Log(_MethodName, "Calculating if sector is safe.")
    local _SectorSafe = true

    local _galaxy = Galaxy()

    --If this is the location of another mission, don't have the cavaliers contact the player.
    local otherMissionLocations = MissionUT.getMissionLocations()
    if otherMissionLocations:contains(_X, _Y) then
        self.Log(_MethodName, "Sector not safe - another mission is located here.")
        _SectorSafe = false
    end

    --If this is the location of pirates, don't have the cavaliers contact the player.
    if ESCCUtil.countEntitiesByValue("is_pirate") > 0 then
        self.Log(_MethodName, "Sector not safe - pirates are present.")
        _SectorSafe = false
    end

    if ESCCUtil.countEntitiesByValue("is_xsotan") > 0 then
        self.Log(_MethodName, "Sector not safe - xsotan are present.")
        _SectorSafe = false
    end

    if _galaxy:sectorInRift(_X, _Y) then
        self.Log(_MethodName, "Sector not safe - is in rift.")
        _SectorSafe = false
    end

    --If this is the location of a faction that hates the player, don't have the cavaliers contact the player.
    local controllingFaction = _galaxy:getControllingFaction(_X, _Y)
    if controllingFaction then
        local relation = _Player:getRelations(controllingFaction.index)
        if relation < -80000 then
            self.Log(_MethodName, "Sector not safe - controlling faction hates player.")
            _SectorSafe = false
        end
    end

    --Finally, if the player is inside the barrier and the cavaliers have not yet reached the inside of the barrier, don't have the cavaliers contact the player.
    if MissionUT.checkSectorInsideBarrier(_X, _Y) then
        if not _Player:getValue("_llte_cavaliers_inbarrier") then
            self.Log(_MethodName, "Sector not safe - Cavaliers are not inside barrier yet.")
            _SectorSafe = false
        end
    end

    self.Log(_MethodName, "Final sector safe value : " .. tostring(_SectorSafe))

    return _SectorSafe
end

function EmpressFrameworkMission.onCreateCavScout(generated)
    local _MethodName = "On Create Cavaliers Scout"
    self.Log(_MethodName, "Beginning...")

    for _, ship in pairs(generated) do
        --patrol and then hail the player.
        ship.title = "Cavaliers " .. ship.title
        ship:setValue("_llte_playercontact_idx", Player().index)

        ship:addScript("ai/patrolpeacefully.lua")    
        ship:addScript("entity/cavalierscontact.lua")
        MissionUT.deleteOnPlayersLeft(ship)
    end
end

function EmpressFrameworkMission.checkPlayerRank(_CurrentRank, _CurrentRep)
    local _MethodName = "Checking Player Rank"
    self.Log(_MethodName, "Starting...")
    --[[
        RANK
            1 - Squire / General (You will never progress past general if Adriana is not Empress)
            2 - Knight
            3 - Crusader
            4 - Templar
            5 - Paladin

            controlled by _llte_cavaliers_rep - a little hidden reputation stat.
            STORY 1/2/3 = +3, STORY 4/5 = +8
            SIDE -
                - Side1 = +1 (Raiders)
                - Side2 = +1 (Shipment)
                - Side3 = n/a (Resistance)
                - Side4 = +2 (Xsotan)
                - Side5 = +4 (Outpost)
                - Side6 = +4 (Arsenal)
            --All side missions give +1 rep @ danger 10.
            +5 pts to get to 2
            +10 (15 total) pts to get to 3
            +15 (30 total) pts to get to 4
            +20 (50 total) pts to get to 5
    ]]

    local _Player = Player()
    local _CurrentRankName = _Player:getValue("_llte_cavaliers_rank")
    local _Story5Accomplished = _Player:getValue("_llte_story_5_accomplished")
    local _SendMail = false
    local _MailText = nil
    local _AttachPaladinItems = false

    self.Log(_MethodName, "Current rank is " .. tostring(_CurrentRank) .. " (" .. tostring(_CurrentRankName) .. ") and current rep is " .. tostring(_CurrentRep) .. " story 5 accomplished is " .. tostring(_Story5Accomplished))

    if _CurrentRank == 1 and _CurrentRep >= 5 then
        self.Log(_MethodName, "Promoting from 1 => 2")
        --Send mail and promote.
        _SendMail = true
        _MailText = Format("%1% %2%,\n\nПолитическая ситуация, вызванная смертью Императора, затруднила принятие в наши ряды посторонних - даже с учетом того, что ваша служба победила Коммуну и Семью. Однако я с гордостью сообщаю, что теперь вы действительно один из нас. Поздравляю, %2%. Я рад, что вы решили продолжить сотрудничество с нами, и уверен, что вы прослужите с честью!\n\nИмператрица Адриана Шталь", _CurrentRankName, _Player.name)

        _Player:setValue("_llte_cavaliers_ranklevel", 2)
        _Player:setValue("_llte_cavaliers_rank", "Knight")
    elseif _CurrentRank == 2 and _CurrentRep >= 15 then
        self.Log(_MethodName, "Promoting from 2 => 3")
        --Send mail and promote.
        _SendMail = true
        local _NextRank = "Crusader"
        _MailText = Format("%1% %2%,\n\nВ знак признания вашей доблести в бою мы немедленно повысили вас до %3%. Некоторым увеличение ответственности кажется непосильным, но я уверен, что вы справитесь с этим. Заставьте нас гордиться, %2%!\n\nИмператрица Адриана Шталь", _CurrentRankName, _Player.name, _NextRank)

        _Player:setValue("_llte_cavaliers_ranklevel", 3)
        _Player:setValue("_llte_cavaliers_rank", _NextRank)
    elseif _CurrentRank == 3 and _CurrentRep >= 30 then
        self.Log(_MethodName, "Promoting from 3 => 4")
        --Send mail and promote.
        _SendMail = true
        local _NextRank = "Templar"
        _MailText = Format("%1% %2%,\n\nВ знак признания вашей доблести в бою мы немедленно повысили вас до %3%. Некоторым увеличение ответственности кажется непосильным, но я уверен, что вы справитесь с этим. Заставьте нас гордиться, %2%!\n\nИмператрица Адриана Шталь", _CurrentRankName, _Player.name, _NextRank)

        _Player:setValue("_llte_cavaliers_ranklevel", 4)
        _Player:setValue("_llte_cavaliers_rank", _NextRank)
    elseif _CurrentRank == 4 and _CurrentRep >= 50 and _Story5Accomplished then
        self.Log(_MethodName, "Promoting from 4 => 5")
        --Send mail and promote.
        _SendMail = true
        _MailText = Format("%1% %2%,\n\nЭто повышение предоставляется только тем, кто доказал, что является исключительным воином. Я не могу представить себе никого более заслуживающего этой чести, чем ты. Как человек, который уничтожил несколько пиратских фракций, пересек барьер и уничтожил Стража Червоточины, ваши достижения не имеют себе равных. Поздравляем, %2%!\n\nЯ также посылаю вам пару наших новейших рейлгусов и военный TCS. Используйте их с гордостью, Паладин! Вы этого заслуживаете.\n\nИмператрица Адриана Шталь", _CurrentRankName, _Player.name)

        _Player:setValue("_llte_cavaliers_ranklevel", 5)
        _Player:setValue("_llte_cavaliers_rank", "Paladin")
        _AttachPaladinItems = true
    end

    local _NewRank = _Player:getValue("_llte_cavaliers_rank")

    if _SendMail then
        local _Mail = Mail()
        _Mail.text = _MailText
        _Mail.header = Format("Promotion to %1%", _NewRank)
        _Mail.sender = "Empress Adriana Stahl @TheCavaliers"
        _Mail.id = "_llte_promotion_mail"

        if _AttachPaladinItems then
            _Mail:addItem(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), Seed(1)) )
            _Mail:addItem(LLTEUtil.getSpecialRailguns())
            _Mail:addItem(LLTEUtil.getSpecialRailguns())
        end

        _Player:addMail(_Mail)
    end
end

function EmpressFrameworkMission.regenerateFactionArsenal()
    local _MethodName = "Regenerate Faction Arsenal"
    --Determine if the inventory should be regenerated.
    local _Regenerated = self.Cavaliers:getValue("_llte_cavaliers_regeneratedArsenal")

    if _Regenerated then
        self.Log(_MethodName, "The Cavaliers do not need to have their weaponry regenerated - returning and exiting.")
        return
    end

    --Clear out the inventory of the cavaliers.
    self.Cavaliers:getInventory():clear()

    --Next, get tech level by strength
    local _TechLevel = 24

    local _X, _Y = Balancing_GetSectorByTechLevel(_TechLevel)
    local _Seed = Server().seed + self.Cavaliers.index

    local turretGenerator = SectorTurretGenerator(_Seed)
    --Don't add PDC types to this list. We don't want to have Cavaliers ships having PD Slapfights
    self.Log(_MethodName, "Generating more powerful Turrets")
    local _TurretTypes = {
        WeaponType.ChainGun, 
        WeaponType.MiningLaser, 
        WeaponType.SalvagingLaser, 
        WeaponType.Bolter, 
        WeaponType.Laser,
        WeaponType.TeslaGun,
        WeaponType.PulseCannon,
        WeaponType.Cannon,
        WeaponType.PlasmaGun,
        WeaponType.RocketLauncher,
        WeaponType.RailGun,
        WeaponType.LightningGun
    }

    for _, _WType in pairs(_TurretTypes) do
        local _CavTurret = turretGenerator:generate(_X, _Y, 0, nil, _WType)
        _CavTurret.coaxial = false
        if _WType == WeaponType.RocketLauncher then
            local _TWeapons = {_CavTurret:getWeapons()}
            _CavTurret:clearWeapons()
            for _, _W in pairs(_TWeapons) do
                if _WType == WeaponType.RocketLauncher then
                    _W.seeker = true
                end

                _CavTurret:addWeapon(_W)
            end
        end

        self.Cavaliers:getInventory():add(_CavTurret, false)
    end

    self.Cavaliers:setValue("_llte_cavaliers_regeneratedArsenal", true)
end

--endregion

--region #CLIENT / SERVER CALLS

function EmpressFrameworkMission.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Framework Mission] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion

--All of the following player values are added / changed by this mod:
--[[
_llte_cavaliers_ranklevel
_llte_cavaliers_rank
_llte_cavaliers_rep
_llte_cavaliers_nextcontact
_llte_cavaliers_startstory
_llte_story_1_accomplished
_llte_story_2_accomplished
_llte_story_3_accomplished
_llte_story_4_accomplished
_llte_story_5_accomplished
_llte_failedstory2
_llte_pirate_faction_vengeance
_llte_got_animosity_loot
_llte_cavaliers_have_avorion
_llte_cavaliers_strength
_llte_cavaliers_inbarrier
]]

--All of the following cavaliers faction values are added / changed by this mod:
--[[
_llte_cavaliers_regeneratedArsenal
]]