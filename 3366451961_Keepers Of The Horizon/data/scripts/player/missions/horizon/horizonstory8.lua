--[[
    MISSION 8: The Swordfish's Bill
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local SectorGenerator = include ("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local ShipGenerator = include("shipgenerator")
local Balancing = include ("galaxy")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Счет Рыбы-Меч"

--region #INIT / DATA

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "Вы совершили налет на верфь Хранителей Горизонта и украли огромный массив данных, но похоже, что большая часть из них сильно зашифрована. Возможно, вы знаете кого-то, кто может их взломать..." },
    { text = "Прочитать почту Варланса", bulletPoint = true, fulfilled = false },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Поговорите с Мейсом в Укрытии Контрабандистов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Установите контакт с Укрытием Контрабандистов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Дождитесь абордажной команды", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Добудьте следующие товары для Софи:", bulletPoint = true, fulfilled = false, visible = false },
    { text = "...", bulletPoint = true, fulfilled = false, visible = false }, --placeholder
    { text = "...", bulletPoint = true, fulfilled = false, visible = false }, --placeholder
    { text = "...", bulletPoint = true, fulfilled = false, visible = false }, --placeholder
    { text = "...", bulletPoint = true, fulfilled = false, visible = false }, --placeholder
    { text = "...", bulletPoint = true, fulfilled = false, visible = false }, --placeholder
    { text = "Дождитесь Софи", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Дождитесь Варланса", bulletPoint = true, fulfilled = false, visible = false }
}

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.phase3DialogStarted = false
mission.data.custom.phase5Timer = 0
mission.data.custom.phase5Chatter = {
    { time = 10, chatter = "Абордажная команда здесь. Готовим шаттл для входа.", sent = false, fromVarlance = true },
    { time = 20, chatter = "Первый шлюз уничтожен. Так мы не попадем.", sent = false, fromVarlance = false },
    { time = 30, chatter = "Второй шлюз тоже уничтожен. Устанавливаем заряды.", sent = false, fromVarlance = false },
    { time = 45, chatter = "Мы внутри. Зачищаем палубы. Выживших немного. Опрашиваем их о местонахождении Мейса.", sent = false, fromVarlance = false }
}
mission.data.custom.phase5DialogStarted = false
mission.data.custom.ingredients = {
    { name = "Энергетическая ячейка", amount = 5 },
    { name = "Вычислительный мейнфрейм", amount = 1 },
    { name = "Охлаждающая жидкость", amount = 1 },
    { name = "Спутник", amount = 1 },
    { name = "Пищевой батончик", amount = 3 }
}
mission.data.custom.phase7DialogStarted = false
mission.data.custom.phase8DialogStarted = false

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
        runFullSectorCleanup(true)
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].noPlayerEventsTargetSector = true
mission.phases[1].noLocalPlayerEventsTargetSector = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Get a sector that's very close to the outer edge of the barrier.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.hackerSector = kothStory8_getNextLocation(true)

    local _X = mission.data.custom.hackerSector.x
    local _Y = mission.data.custom.hackerSector.y

    mission.data.description[3].arguments = { _X = mission.data.custom.hackerSector.x, _Y = mission.data.custom.hackerSector.y }

    --Send mail to player.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Привет, приятель,\n\nБольшая часть данных, которые мы вытащили с этой верфи, сильно зашифрована. Как и ожидалось, но, по крайней мере, у них не было возможности удалить их. Помнишь моего контакта в аванпосте контрабандистов? Мы собираемся вернуться, чтобы поговорить с Мейсом. Они должны быть в состоянии взломать шифрование. Наконец, мы сможем точно выяснить, чем занимается Horizon Keepers, и получить ответы на этот таинственный \"Project XSOLOGIZE\".\n\nКонтрабандисты переехали в (%1%:%2%) - приходите встретиться с нами там.\n\nВарланс", _X, _Y)
	_Mail.header = "Снова зашифровано"
	_Mail.sender = "Varlance @FrostbiteCompany"
	_Mail.id = "_horizon_story8_mail"
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
				if _Mail.id == "_horizon_story8_mail" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].noPlayerEventsTargetSector = true
mission.phases[2].noLocalPlayerEventsTargetSector = true
mission.phases[2].onBegin= function()
    local _MethodName = "Phase 2 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.hackerSector

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Phase 2 on Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    if onServer() then
        kothStory8_buildSmugglerSector(_X, _Y)
        kothStory8_spawnVarlance()
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    --after varlance is spawned, delete loot.
    local _sector = Sector()
    for _, entity in pairs({_sector:getEntities()}) do
        if entity.type == EntityType.Loot then
            _sector:deleteEntity(entity)
        end
    end

    nextPhase()
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].noBossEncountersTargetSector = true
mission.phases[3].noPlayerEventsTargetSector = true
mission.phases[3].noLocalPlayerEventsTargetSector = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

local kothStory8_onPhase3DialogEnd = makeDialogServerCallback("kothStory8_onPhase3DialogEnd", 3, function()
    nextPhase()
end)

mission.phases[3].timers[1] = {
    time = 15,
    callback = function()
        if onServer() and atTargetLocation() and not mission.data.custom.phase3DialogStarted then
            mission.data.custom.phase3DialogStarted = true

            invokeClientFunction(Player(), "kothStory8_onPhase3Dialog", mission.data.custom.varlanceID)
        end
    end,
    repeating = true --have to repeat since the player might leave the sector.
}

mission.phases[4] = {}
mission.phases[4].triggers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].noBossEncountersTargetSector = true
mission.phases[4].noPlayerEventsTargetSector = true
mission.phases[4].noLocalPlayerEventsTargetSector = true
mission.phases[4].onBegin = function()
    local _MethodName = "Phase 4 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
end

mission.phases[4].onBeginServer = function()
    local _VarlanceAI = ShipAI(mission.data.custom.varlanceID)
    _VarlanceAI:setIdle()
    _VarlanceAI:setPassiveShooting(true)

    local _SmugglerHideout = Entity(mission.data.custom.smugglerOutpostID)
    local _Radius = _SmugglerHideout:getBoundingSphere().radius * 2

    _VarlanceAI:setFlyLinear(_SmugglerHideout.translationf, _Radius, false)
end

local kothStory8_onPhase4DialogEnd = makeDialogServerCallback("kothStory8_onPhase4DialogEnd", 4, function()
    nextPhase()
end)

--region #PHASE 4 TRIGGER CALLS

if onServer() then

mission.phases[4].triggers[1] = {
    condition = function()
        if atTargetLocation() then
            local outpost = Entity(mission.data.custom.smugglerOutpostID)
            local varlance = Entity(mission.data.custom.varlanceID)
    
            local dist = outpost:getNearestDistance(varlance)
            if dist <= 1000 then
                return true
            end
        end

        return false
    end,
    callback = function()
        invokeClientFunction(Player(), "kothStory8_onPhase4Dialog", mission.data.custom.smugglerOutpostID)
    end,
    repeating = false
}

end

--endregion

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].triggers = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].noBossEncountersTargetSector = true
mission.phases[5].noPlayerEventsTargetSector = true
mission.phases[5].noLocalPlayerEventsTargetSector = true
mission.phases[5].onBegin = function()
    local _MethodName = "Phase 5 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[5].fulfilled = true
    mission.data.description[6].visible = true
end

mission.phases[5].onBeginServer = function()
    --Spawn a relief ship.
    local frostbiteRelief = HorizonUtil.spawnFrostbiteReliefShip(false)
    mission.data.custom.frostbiteReliefID = frostbiteRelief.index
    local fbReliefAI = ShipAI(frostbiteRelief)

    local smugglerHideout = Entity(mission.data.custom.smugglerOutpostID)
    local _Radius = smugglerHideout:getBoundingSphere().radius * 2

    fbReliefAI:setFlyLinear(smugglerHideout.translationf, _Radius, false)
end

mission.phases[5].updateTargetLocationServer = function()
    mission.data.custom.phase5Timer = mission.data.custom.phase5Timer + 1

    for _, msg in pairs(mission.data.custom.phase5Chatter) do
        if mission.data.custom.phase5Timer >= msg.time and not msg.sent then
            msg.sent = true

            local senderEntity
            if msg.fromVarlance then
                senderEntity = Entity(mission.data.custom.varlanceID)
            else
                senderEntity = Entity(mission.data.custom.smugglerOutpostID)
            end
            if senderEntity then
                Sector():broadcastChatMessage(senderEntity, ChatMessageType.Chatter, msg.chatter)
            else
                print("ERROR! Could not find sender entity for p5 chatter.")
            end 
        end
    end
end

local kothStory8_onPhase5DialogEnd = makeDialogServerCallback("kothStory8_onPhase5DialogEnd", 5, function()
    nextPhase()
end)

--region #TIMER CALLS

mission.phases[5].timers[1] = {
    time = 60,
    callback = function()
        if onServer() and atTargetLocation() and not mission.data.custom.phase5DialogStarted then
            mission.data.custom.phase5DialogStarted = true

            invokeClientFunction(Player(), "kothStory8_onPhase5Dialog", mission.data.custom.smugglerOutpostID)
        end
    end,
    repeating = true --have to repeat since the player might leave the sector.
}

--endregion

--region #TRIGGER CALLS

if onServer() then

mission.phases[5].triggers[1] = {
    condition = function()
        if atTargetLocation() then
            local frostbiteRelief = Entity(mission.data.custom.frostbiteReliefID)
            local smugglerHideout = Entity(mission.data.custom.smugglerOutpostID)

            local dist = smugglerHideout:getNearestDistance(frostbiteRelief)
            if dist <= 500 then
                return true
            end
        end
        
        return false
    end,
    callback = function()
        local frostbiteRelief = Entity(mission.data.custom.frostbiteReliefID)

        Sector():broadcastChatMessage(frostbiteRelief, ChatMessageType.Chatter, "Корабль помощи ${_SHIPNAME} на станции. Переходим к оказанию медицинской помощи выжившим." % {_SHIPNAME = frostbiteRelief.name})
    end,
    repeating = false
}

end

--endregion

mission.phases[6] = {}
mission.phases[6].playerCallbacks = {}
mission.phases[6].showUpdateOnEnd = true
mission.phases[6].noBossEncountersTargetSector = true
mission.phases[6].noPlayerEventsTargetSector = true
mission.phases[6].noLocalPlayerEventsTargetSector = true
mission.phases[6].onBegin = function()
    local _MethodName = "Phase 6 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[6].fulfilled = true
    mission.data.description[7].visible = true

    kothStory8_updateDescription()

    local ship = Player().craft
    if not ship then return end
    ship:registerCallback("onCargoChanged", "kothStory8_updateDescription")
end

mission.phases[6].onBeginServer = function()
    local smugglerHideout = Entity(mission.data.custom.smugglerOutpostID)
    smugglerHideout:setValue("horizon_story_player", Player().index)
    smugglerHideout:addScriptOnce("player/missions/horizon/story8/horizonstory8dialog1.lua")
end

mission.phases[6].onRestore = function()
    local ship = Player().craft
    if not ship then return end
    ship:registerCallback("onCargoChanged", "kothStory8_updateDescription")
end

mission.phases[6].playerCallbacks[1] = {
    name = "onShipChanged",
    func = function()
        local ship = Player().craft
        if not ship then return end
        ship:registerCallback("onCargoChanged", "kothStory8_updateDescription")
        kothStory8_updateDescription() -- update immediately as well
    end
}

mission.phases[7] = {}
mission.phases[7].timers = {}
mission.phases[7].playerCallbacks = {}
mission.phases[7].showUpdateOnEnd = true
mission.phases[7].noBossEncountersTargetSector = true
mission.phases[7].noPlayerEventsTargetSector = true
mission.phases[7].noLocalPlayerEventsTargetSector = true
mission.phases[7].onBegin = function()
    local _MethodName = "Phase 7 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[7].fulfilled = true
    local bulletPoint = 8
    for _, item in pairs(mission.data.custom.ingredients) do
        --Careful about uncommenting this log message!
        --mission.Log(_MethodName, "Setting bullet " .. tostring(idx) .. " to done.")
        mission.data.description[bulletPoint].visible = false
        bulletPoint = bulletPoint + 1
    end
    mission.data.description[13].visible = true
end
mission.phases[7].onBeginServer = function()
    local smugglerHideout = Entity(mission.data.custom.smugglerOutpostID)
    smugglerHideout:removeScript("player/missions/horizon/story8/horizonstory8dialog1.lua")

    local _sector = Sector()
    --Have the relief ship fly out at this point if it's still around.
    if _sector:exists(mission.data.custom.frostbiteReliefID) then
        local frostbiteRelief = Entity(mission.data.custom.frostbiteReliefID)
        frostbiteRelief:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(30, 45))

        local fbReliefAI = ShipAI(frostbiteRelief)
        fbReliefAI:setFlyLinear(frostbiteRelief.look * -1 * 20000, 0, false)

        _sector:broadcastChatMessage(frostbiteRelief, ChatMessageType.Chatter, "Мы сделали все, что могли, для выживших. Покидаем этот район.")
    end
end

local kothStory8_onPhase7DialogEnd = makeDialogServerCallback("kothStory8_onPhase7DialogEnd", 7, function()
    nextPhase()
end)

--region #PHASE 7 TIMER CALLS

mission.phases[7].timers[1] = {
    time = 15,
    callback = function()
        if onServer() and atTargetLocation() and not mission.data.custom.phase7DialogStarted then
            mission.data.custom.phase7DialogStarted = true

            invokeClientFunction(Player(), "kothStory8_onPhase7Dialog", mission.data.custom.smugglerOutpostID)
        end
    end,
    repeating = true --have to repeat since the player might leave the sector.
}

--endregion

mission.phases[8] = {}
mission.phases[8].timers = {}
mission.phases[8].noBossEncountersTargetSector = true
mission.phases[8].noPlayerEventsTargetSector = true
mission.phases[8].noLocalPlayerEventsTargetSector = true
mission.phases[8].onBegin = function()
    local _MethodName = "Phase 8 On Begin"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.description[13].fulfilled = true
    mission.data.description[14].visible = true
end

local kothStory8_onPhase8DialogEnd = makeDialogServerCallback("kothStory8_onPhase8DialogEnd", 8, function()
    kothStory8_finishAndReward()
end)

--region #PHASE 8 TIMER CALLS

mission.phases[8].timers[1] = {
    time = 15,
    callback = function()
        if onServer() and atTargetLocation() and not mission.data.custom.phase8DialogStarted then
            mission.data.custom.phase8DialogStarted = true

            invokeClientFunction(Player(), "kothStory8_onPhase8Dialog", mission.data.custom.varlanceID)
        end
    end,
    repeating = true --have to repeat since the player might leave the sector.
}

--endregion

--endregion

--region #SERVER CALLS

function kothStory8_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Получаем местоположение.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Get a sector that's very close to the outer edge of the barrier.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 6, 12, false)
    end

    mission.Log(_MethodName, "X координата следующего местоположения: " .. tostring(target.x) .. " Y координата следующего местоположения: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящее место для миссии. Завершаем скрипт.")
        terminate()
        return
    end

    return target
end

function kothStory8_buildSmugglerSector(_X, _Y)
    local _MethodName = "Build Main Sector"
    
    mission.Log(_MethodName, "Сектор еще не построен. Начинаем...")

    local _Generator = SectorGenerator(_X, _Y)
    local _random = random()

    --Get a smuggler faction.
    mission.Log(_MethodName, "Строим базу контрабандистов.")
    local _SmugglerFaction = ESCCUtil.getNeutralSmugglerFaction()

    local smugglerHideout = _Generator:createStation(_SmugglerFaction, "merchants/smugglersmarket.lua")
    smugglerHideout.title = "Укрытие контрабандистов"%_t
    smugglerHideout:setValue("no_chatter", true)
    smugglerHideout:addScript("merchants/tradingpost.lua")
    smugglerHideout.shieldDurability = 0
    smugglerHideout.durability = smugglerHideout.maxDurability * 0.08
    
    local smugglerHideoutDurability = Durability(smugglerHideout)
    smugglerHideoutDurability.invincibility = 0.01
    
    mission.data.custom.smugglerOutpostID = smugglerHideout.id

    --Make a group of 6 pirates.
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 8, "Standard")
    local createdPirateTable = {}

    for _, _Pirate in pairs(_PirateTable) do
        local _ship = PirateGenerator.createScaledPirateByName(_Pirate, _Generator:getPositionInSector())

        table.insert(createdPirateTable, _ship)
    end
    
    local _Shipyard = _Generator:createShipyard(_SmugglerFaction)
    _Shipyard:removeScript("backup.lua")
    _Shipyard:setValue("_ESCC_bypass_hazard", true)
    _Shipyard:destroy(createdPirateTable[1].index)

    for _ = 1, 3 do
        local ship = ShipGenerator.createDefender(_SmugglerFaction, _Generator:getPositionInSector())
        ship:setValue("_ESCC_bypass_hazard", true)
        ship:destroy(createdPirateTable[1].index)
    end

    for _ = 1, _random:getInt(2, 4) do
        _Generator:createSmallAsteroidField()
    end

    _Generator:createAsteroidField()

    _Generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()

    for _, obj in pairs(createdPirateTable) do
        obj:destroy(mission.data.custom.smugglerOutpostID)
    end

    mission.data.custom.cleanUpSector = true

    sync()
end

function kothStory8_spawnVarlance()
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Варланса - создаем его.")

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(false)
        local _VarlanceAI = ShipAI(_Varlance)
    
        _VarlanceAI:setIdle()
        _VarlanceAI:setPassiveShooting(true)

        local _VarlanceDurability = Durability(_Varlance)
        _VarlanceDurability.invincibility = 0.5

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory8_updateDescription()
    local methodName = "Update Description"
    --Shamelessly copied from Boxelware. If it works, why not?
    if mission.internals.phaseIndex ~= 6 then 
        return 
    end

    local bulletPoint = 8
    local craft = Player().craft
    if not craft then return end

    local cargos = craft:getCargos()

    for _, ingredient in pairs(mission.data.custom.ingredients or {}) do

        local have = 0
        local needed = ingredient.amount
        local good = goods[ingredient.name]:good()

        for good, amount in pairs(cargos) do
            if ingredient.name == good.name then
                have = amount
                break
            end
        end

        --Careful about uncommenting this log message!
        --mission.Log(methodName, "Updating bullet point " .. tostring(bulletPoint))
        mission.data.description[bulletPoint] = {
            text = "${good}: ${have}/${needed}",
            arguments = {good = good.name, have = have, needed = needed},
            bulletPoint = true,
            fulfilled = false,
            visible = true
        }

        bulletPoint = bulletPoint + 1
    end
    sync()
end

function kothStory8_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Запускаем условие победы.")

    local _player = Player()

    local _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."
    local _BaseReward = 520000

    _player:setValue("_horizonkeepers_story_stage", 9)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward, paymentMessage = "За расшифровку данных получено %1% кредитов." }

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT DIALOG CALLS

function kothStory8_onPhase3Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "Что-то не так."
    d0.followUp = d1

    d1.text = "В прошлый раз, когда мы были здесь, этот сектор был активен. Здесь были верфь и защитники. Кто-то разгромил это место после нашего визита."
    d1.followUp = d2

    d2.text = "Черт. Я думал, наш план был надежным. Как они его раскусили?"
    d2.followUp = d3

    d3.text = "Давайте свяжемся с укрытием. Может быть, Мейс пережил атаку."
    d3.onEnd = kothStory8_onPhase3DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothStory8_onPhase4Dialog(outpostID)
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
    local d10 = {}
    local d11 = {}

    local outpost = Entity(outpostID)
    local values = { _OUTPOSTNAME = outpost.name }

    d0.text = "Астероидная установка ${_OUTPOSTNAME}, вы меня слышите?" % values
    d0.followUp = d1

    d1.text = "... [Нет ответа]"
    d1.followUp = d2

    d2.text = "Повторяю, ${_OUTPOSTNAME}, вы меня слышите?" % values
    d2.followUp = d3

    d3.text =  "... [Нет ответа]"
    d3.followUp = d4

    d4.text = "Черт возьми. Там кто-нибудь жив?"
    d4.followUp = d5

    d5.text = "... Здравствуйте? Кто вы?"
    d5.followUp = d6

    d6.text = "Это капитан Варланс Калдер. Компания Frostbite. Я пришел сюда кое-кого поискать, но я вызову корабль помощи."
    d6.followUp = d7

    d7.text = "... Спасибо. На нас напали пираты. Большинство людей здесь мертвы или ранены."
    d7.followUp = d8

    d8.text = "Держитесь - помощь в пути. Кто-нибудь из выживших откликается на имя Мейс? Сокращенно от 01Macedon."
    d8.followUp = d9

    d9.text = "Я не знаю. Я только что сюда добрался. Я... о боже. Здесь так много тел. Так много крови."
    d9.followUp = d10

    d10.text = "Кто бы это ни был, он в шоке. Логично. Не каждый создан для того, чтобы справляться с издержками войны."
    d10.followUp = d11

    d11.text = "Я попрошу Софи собрать абордажную команду. Может быть, она что-нибудь найдет."
    d11.onEnd = kothStory8_onPhase4DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d2, d4, d6, d8, d10, d11}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(outpostID):interactShowDialog(d0, false)
end

function kothStory8_onPhase5Dialog(outpostID)
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
    local d10 = {}
    local d11 = {}
    local d12 = {}
    local d13 = {}
    local d14 = {}
    local d15 = {}

    d0.text = "Здесь Софи. Я думаю, мы нашли комнату Мейса."
    d0.followUp = d1

    d1.text = "Какой статус?"
    d1.followUp = d2

    d2.text = "Выглядит не очень хорошо. Везде кровь. Половина снаряжения уничтожена."
    d2.followUp = d3

    d3.text =  "Черт! Мы должны как-то расшифровать эти данные. Нужен план Б..."
    d3.followUp = d4

    d4.text = "Я не знаю насчет этого. Это... хм. Как бы это объяснить. Я осматриваю снаряжение, которое не уничтожено, и..."
    d4.followUp = d5

    d5.text = "Разрушение почти... художественное. Как будто кто-то действительно хотел, чтобы мы подумали, что Мейс убит."
    d5.followUp = d6

    d6.text = "Может быть, я смогу... Хммм... Да! Это будет непростая работа, но я думаю, что это можно исправить."
    d6.followUp = d7

    d7.text = "Если ты это исправишь, ты сможешь расшифровать данные?"
    d7.followUp = d8

    d8.text = "Я не зря потратила несколько лет на изучение компьютеров! Я попробую."
    d8.followUp = d9

    d9.text = "Это лучший план, который у нас есть. Что тебе нужно для ремонта?"
    d9.followUp = d10

    d10.text = "Кое-что. Запасные энергетические ячейки - думаю, пяти должно хватить. Вычислительный мейнфрейм. Немного охлаждающей жидкости. Спутник и три батончика."
    d10.followUp = d11

    d11.text = "Спутник? Батончики?"
    d11.followUp = d12

    d12.text = "Да! У Мейса была установка, которая полагалась на кустарное подключение к спутнику. Я думаю, они использовали бортовой компьютер для вычислений. Спутник, который у них здесь есть, уничтожен, но мы можем разобрать и установить новый."
    d12.followUp = d13

    d13.text = "А батончики?"
    d13.followUp = d14
	
	d14.text = "... Что? Я голодна."
	d14.followUp = d15
	
	d15.text = "... Ладно. Я останусь здесь и обеспечу наблюдение. Ты идешь за покупками, приятель."
	d15.onEnd = kothStory8_onPhase5DialogEnd

    ESCCUtil.setTalkerTextColors({ d1, d3, d7, d9, d11, d13, d15 }, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({ d0, d2, d4, d5, d6, d8, d10, d12, d14 }, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(outpostID):interactShowDialog(d0, false)
end

function kothStory8_onPhase7Dialog(outpostID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}

    d0.text = "Окей! Я все восстановила, я..."
    d0.followUp = d1

    d1.text = "Хм! Здесь есть файл README. Это почти как..."
    d1.followUp = d2

    d2.text = "Файлы сейчас расшифровываются!"
    d2.followUp = d3

    d3.text = "Вот оно! ДА! Это именно то, что мы думали - все, что нам нужно знать об XSOLOGIZE. Я передам данные сейчас! Никаких сюрпризов на этот раз!"
    d3.followUp = d4

    d4.text = "Хорошая работа. Возвращайся на корабль."
    d4.followUp = d5

    d5.text = "Так точно! Уже в пути."
    d5.onEnd = kothStory8_onPhase7DialogEnd

    ESCCUtil.setTalkerTextColors({ d4 }, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({ d0, d1, d2, d3, d5 }, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(outpostID):interactShowDialog(d0, false)
end

function kothStory8_onPhase8Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    d0.text = "Я просматриваю данные сейчас. Это..."
    d0.followUp = d1

    d1.text = "Это безумие. Кошмар. Неудивительно, что мы нашли части ксотан в их поставках раньше."
    d1.followUp = d2

    d2.text = "Сейчас, как никогда, мы должны это остановить. Мы не можем позволить им завершить этот проект - где бы они ни были, мы должны ударить по ним быстро и сильно-"
    d2.followUp = d3

    d3.text = "Ага. Вот она - верфь, на которой они строили эту... мерзость. Я свяжусь с вами, когда мы будем готовы начать нашу атаку."
    d3.followUp = d4

    d4.text = "... Если я больше никогда не увижу зашифрованные данные, это будет слишком скоро."
    d4.onEnd = kothStory8_onPhase8DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothStory8_onDeliveredIngredients()
    local _MethodName = "Provided Ingredients"
    if onClient() then
        mission.Log(_MethodName, "Calling on Client => Invoking on Server.")

        invokeServerFunction("kothStory8_onDeliveredIngredients")
        return
    end

    mission.Log(_MethodName, "Calling on Server")

    if mission.internals.phaseIndex == 6 then
        nextPhase() --Takes us into phase 7.
    end
end
callable(nil, "kothStory8_onDeliveredIngredients")

--endregion