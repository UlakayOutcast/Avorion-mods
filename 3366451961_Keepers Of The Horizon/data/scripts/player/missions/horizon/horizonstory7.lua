--[[
    MISSION 7: Kermit Tyler's Folly
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local SectorGenerator = include ("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Безумие Кермита Тайлера"

--region #INIT / DATA

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "Флот Хранителей Горизонта ослаблен потерей линкоров и нескольких крейсеров. Путь вперед теперь ясен - атакуйте верфь Хранителей Горизонта и проникните в их сеть." },
    { text = "Прочитать почту Варланса", bulletPoint = true, fulfilled = false },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Присоединитесь к Софи в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Оставайтесь незамеченными", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Рекомендуется) Держитесь на расстоянии не менее 30 км от военного аванпоста", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Сопроводите грузовой корабль", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Защитите грузовой корабль", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Защитите верфь", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Рекомендуется) Убедитесь, что грузовой корабль в безопасности, прежде чем атаковать артиллерийские крейсеры", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уйдите до прибытия подкрепления", bulletPoint = true, fulfilled = false, visible = false }
}

--Пользовательские данные, которые нам понадобятся.
mission.data.custom.dangerLevel = 10 --Все основано на уровне опасности 10.
mission.data.custom.phase4Timer = 0
mission.data.custom.phase4DialogSent = false
mission.data.custom.phase5MiloutpostMinDist = 3000 --30 км
--Корабли подсвечиваются, если они находятся на расстоянии меньше диапазона подсветки - они подсвечиваются красным цветом, если они находятся в @ срочном диапазоне.
mission.data.custom.phase5ShipHighlightRange = 2000 --20 км
mission.data.custom.phase5ShipUrgentHighlightRange = 1500 --15 км
mission.data.custom.phase5Timer = 0
mission.data.custom.phase5Chatter1Sent = false
mission.data.custom.phase5Chatter2Sent = false
mission.data.custom.phase5Chatter3Sent = false
mission.data.custom.phase5Chatter4Sent = false
mission.data.custom.phase5Chatter5Sent = false
mission.data.custom.phase5Chatter6Sent = false
mission.data.custom.phase5Chatter7Sent = false
mission.data.custom.phase5Chatter8Sent = false
mission.data.custom.phase5Chatter9Sent = false
mission.data.custom.phase5Chatter10Sent = false
mission.data.custom.waveState = 1
mission.data.custom.waveNumber = 1
mission.data.custom.phase6Chatter1Sent = false
mission.data.custom.phase7Timer = 0
mission.data.custom.phase7FinishEventDone = false

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onAbandon = function()
    kothStory7_clearShipyardCargo()
    
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    kothStory7_sendFailureMail()
    kothStory7_clearShipyardCargo()

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
    local phIndex = mission.internals.phaseIndex
    --Немедленно провалитесь в фазах скрытности.
    if phIndex == 4 or phIndex == 5 then
        fail()
    elseif phIndex == 7 and mission.data.custom.phase7FinishEventDone then
        kothStory7_finishAndReward()
    else
        mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --У игрока есть 5 минут, чтобы вернуться в сектор.
        mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Получите сектор, который очень близок к внешнему краю барьера.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory7_getNextLocation(true)

    local _X = mission.data.custom.firstLocation.x
    local _Y = mission.data.custom.firstLocation.y

    mission.data.description[3].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Отправить почту игроку.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Привет, приятель,\n\nМои команды просматривали всю информацию, которую мы получили с прототипов оружия. Похоже, большая часть была взорвана вместе с их кораблями, но мы нашли несколько интересных кусочков. В основном это связано с чем-то под названием \"Project XSOLOGIZE\". Единственная полная информация, которую мы получили, - это расписание. Похоже, оно близится к завершению. Если это хоть немного похоже на те прототипы, с которыми мы сражались раньше, мы не можем позволить Хранителям Горизонта развязать это - галактика будет вынуждена преклонить колено или столкнуться с уровнем страданий и смерти, которого мы не видели со времен Великой войны.\n\nК счастью, это не меняет наших планов. Мы захватили грузовой корабль и будем использовать его для проникновения на их верфь. Нам нужно быть осторожными в том, как мы к этому подходим - если мы чему-то и научились за последние несколько вылазок, так это тому, что эти ублюдки быстро удаляют любую информацию из своих банков данных.\n\nПриходи в (%1%:%2%). Я обсужу с тобой план.\n\nВарланс", _X, _Y)
	_Mail.header = "Пришло время"
	_Mail.sender = "Варланс @FrostbiteCompany"
	_Mail.id = "_horizon_story7_mail"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story7_mail" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBegin = function()
    local _MethodName = "Phase 2 On Begin"
    mission.Log(_MethodName, "Начинается...")

    mission.data.location = mission.data.custom.firstLocation

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_x, _y)
    if onServer() then
        kothStory7_spawnVarlance()
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_x, _y)
    --Запустить диалог Варланса, затем перейти к фазе 3.
    invokeClientFunction(Player(), "kothStory7_onPhase2Dialog", mission.data.custom.varlanceID)
end

local kothStory7_onPhase2DialogEnd = makeDialogServerCallback("kothStory7_onPhase2DialogEnd", 2, function()
    mission.data.custom.secondLocation = kothStory7_getNextLocation(false)

    mission.data.description[4].arguments = { _X = mission.data.custom.secondLocation.x, _Y = mission.data.custom.secondLocation.y }

    local varlance = Entity(mission.data.custom.varlanceID)
    varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    Player():setValue("_horizonkeepers_story7_heardplan", true)

    nextPhase()
end)

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Начинается...")

    mission.data.location = mission.data.custom.secondLocation

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

mission.phases[3].onTargetLocationEntered = function(x, y)
    if onServer() then
        local _player = Player()
        if _player:hasScript("events/alienattack.lua") then
            _player:removeScript("events/alienattack.lua")
            _player:sendChatMessage("", 3, "Подпространственные сигналы внезапно исчезают с ваших датчиков.")
        end

        kothStory7_buildObjectiveSector(x, y)
    end
end

mission.phases[3].onTargetLocationArrivalConfirmed = function(_x, _y)
    --Запустить диалог Варланса, затем перейти к фазе 3.
    HorizonUtil.varlanceChatter("<Secure Channel> Софи на связи. Эта военная установка меня нервирует. Не приближайтесь к ней ближе, чем на 30 кликов, иначе она может нас раскрыть. Если нас окликнут, просто следуйте моему примеру.")
    nextPhase()
end

mission.phases[4] = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    local _MethodName = "Phase 4 On Begin"
    mission.Log(_MethodName, "Начинается...")

    mission.data.location = mission.data.custom.secondLocation

    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true
    mission.data.description[7].visible = true
end

mission.phases[4].onBeginServer = function()
    --Прикажите Софи и грузовому кораблю находиться в пределах 20 км от станции.
    local sophie = Entity(mission.data.custom.varlanceID)
    local freighter = Entity(mission.data.custom.freighterID)
    local shipyard = Entity(mission.data.custom.shipyardID)

    local orderTable = { sophie, freighter }

    for _, ship in pairs(orderTable) do
        local ai = ShipAI(ship)
        ai:setFlyLinear(shipyard.translationf, 2000, false)
    end
end

mission.phases[4].updateTargetLocationServer = function(timeStep)
    --через 30 секунд вызвать игрока.
    mission.data.custom.phase4Timer = mission.data.custom.phase4Timer + timeStep

    if mission.data.custom.phase4Timer >= 30 and not mission.data.custom.phase4DialogSent then
        mission.data.custom.phase4DialogSent = true

        invokeClientFunction(Player(), "kothStory7_onPhase4Dialog", mission.data.custom.militaryOutpostID)
    end
end

mission.phases[4].onEntityDestroyed = function(id, lastDamageInflictor)
    --Не знаю, как его уничтожают в p4, но на всякий случай.
    if id == mission.data.custom.freighterID then
        kothStory7_onFreighterDestroyed()
    end
end

local kothStory7_onPhase4DialogEndGood = makeDialogServerCallback("kothStory7_onPhase4DialogEndGood", 4, function()
    nextPhase()
end)

local kothStory7_onPhase4DialogEndBad = makeDialogServerCallback("kothStory7_oonPhase4DialogEndBad", 4, function()
    --далее, каждый корабль Horizon становится враждебным
    --добавить мощный контроллер защиты в сектор.
    kothStory7_onStealthBroken(true)

    --далее, провалить миссию.
    fail()
end)

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].sectorCallbacks = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].onBeginServer = function()
    local _MethodName = "Phase 5 On Begin Server"
    mission.Log(_MethodName, "Начинается...")

    --Добро пожаловать в раздел скрытности!
    local freighter = Entity(mission.data.custom.freighterID)
    local shipyard = Entity(mission.data.custom.shipyardID)

    local radius = shipyard:getBoundingSphere().radius

    local ai = ShipAI(freighter)
    ai:setFlyLinear(shipyard.translationf, radius * 3, false)
end

mission.phases[5].onPreRenderHud = function()
    if atTargetLocation() then
        kothStory7_onMarkCloseShips()
    end
end

mission.phases[5].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Phase 5 Update Target Location Server"

    local freighter = Entity(mission.data.custom.freighterID)
    local shipyard = Entity(mission.data.custom.shipyardID)

    local _sector = Sector()

    local dist = 0
    if freighter then 
        dist = shipyard:getNearestDistance(freighter)
    else
        kothStory7_onFreighterDestroyed()
    end

    if dist <= 500 then
        mission.data.custom.phase5Timer = mission.data.custom.phase5Timer + timeStep

        if mission.data.custom.phase5Timer >= 30 and not mission.data.custom.phase5Chatter1Sent then
            mission.data.custom.phase5Chatter1Sent = true

            mission.Log(_MethodName, "Отправка сообщения 1")

            _sector:broadcastChatMessage(freighter, ChatMessageType.Chatter, "<Secure Channel> Установлен входной уплотнитель. Установлены режущие заряды. Скоро будем внутри.")
        end

        if mission.data.custom.phase5Timer >= 60 and not mission.data.custom.phase5Chatter2Sent then
            mission.data.custom.phase5Chatter2Sent = true
            
            mission.Log(_MethodName, "Отправка сообщения 2")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Мы внутри. Мы установили узел ретрансляции - любой трафик связи должен выглядеть как информация о наведении или диагностике.")
        end

        if mission.data.custom.phase5Timer >= 90 and not mission.data.custom.phase5Chatter3Sent then
            mission.data.custom.phase5Chatter3Sent = true
            
            mission.Log(_MethodName, "Отправка сообщения 3")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Нашли терминал. Пытаемся получить права администратора...")
        end

        if mission.data.custom.phase5Timer >= 105 and not mission.data.custom.phase5Chatter10Sent then
            mission.data.custom.phase5Chatter10Sent = true

            mission.Log(_MethodName, "Отправка сообщения 10")

            HorizonUtil.varlanceChatter("<Secure Channel> Корабли здесь выглядят довольно ветхими. У них даже нет класса Raider - Horizon, должно быть, действительно нуждается в силах.")
        end

        if mission.data.custom.phase5Timer >= 120 and not mission.data.custom.phase5Chatter4Sent then
            mission.data.custom.phase5Chatter4Sent = true
            
            mission.Log(_MethodName, "Отправка сообщения 4")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Есть! Загружаем данные сейчас!")
        end

        if mission.data.custom.phase5Timer >= 150 and not mission.data.custom.phase5Chatter5Sent then
            mission.data.custom.phase5Chatter5Sent = true
            
            mission.Log(_MethodName, "Отправка сообщения 5")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Мы получили данные, но... э-э.")
        end

        if mission.data.custom.phase5Timer >= 160 and not mission.data.custom.phase5Chatter6Sent then
            mission.data.custom.phase5Chatter6Sent = true
            
            mission.Log(_MethodName, "Отправка сообщения 6")

            HorizonUtil.varlanceChatter("<Secure Channel> \"Э-э\"? Мне не нравится \"э-э\". Дайте мне отчет о ситуации.")
        end

        if mission.data.custom.phase5Timer >= 180 and not mission.data.custom.phase5Chatter7Sent then
            mission.data.custom.phase5Chatter7Sent = true

            mission.Log(_MethodName, "Отправка сообщения 7")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Повсюду срабатывает сигнализация! Что значит, мы \"вызвали сетевое оповещение\"?")
        end

        if mission.data.custom.phase5Timer >= 210 and not mission.data.custom.phase5Chatter8Sent then
            mission.data.custom.phase5Chatter8Sent = true

            mission.Log(_MethodName, "Отправка сообщения 8")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Черт. Охрана?! Нам придется пробиваться с боем!")
        end

        if mission.data.custom.phase5Timer >= 225 and not mission.data.custom.phase5Chatter9Sent then
            --как только вы это увидите, вам больше не нужно беспокоиться об обнаружении, но вы все равно не можете начать взрывать вещи!
            mission.data.custom.phase5Chatter9Sent = true

            mission.Log(_MethodName, "Отправка сообщения 9")

            HorizonUtil.varlanceChatter("Они знают, что мы здесь, капитан! Больше нет смысла в скрытности - разогрейте эти пушки!")
        end

        if mission.data.custom.phase5Timer >= 230 then
            nextPhase()
        end
    end
end

mission.phases[5].onEntityDestroyed = function(id, lastDamageInflictor)
    local destroyer = Entity(lastDamageInflictor)

    if id == mission.data.custom.freighterID then
        kothStory7_onFreighterDestroyed()
    end

    if destroyer and valid(destroyer) then
        local _player = Player()
        
        if destroyer.factionIndex == _player.index then
            kothStory7_onStealthBroken(true)
            fail()
        end

        if _player.allianceIndex and destroyer.factionIndex == _player.allianceIndex then
            kothStory7_onStealthBroken(true)
            fail()
        end
    end
end

--region #PHASE 5 CALLBACK CALLS
mission.phases[5].sectorCallbacks[1] = {
    name = "startHorizon7StealthTimer",
    func = function(defenderidx, playershipidx)
        local _MethodName = "Phase 5 Custom Callback 1"
        mission.Log(_MethodName, "Вызов.", _MethodName)

        local pShip = Entity(playershipidx)
        local eShip = Entity(defenderidx)
        
        Player():sendChatMessage("", 3, "Ваш корабль ${_PLAYERSHIP} слишком близко к кораблю Horizon ${_ENEMYSHIP}. Отдалитесь на 10 км, прежде чем он сможет вас отсканировать." % { _PLAYERSHIP = pShip.name, _ENEMYSHIP = eShip.name})
        --Проверьте слоты таймеров с 6 по 30. Используйте первый доступный (таймер 3 выполняет очистку)
        local _MINTIMERSLOT = 6
        local _MAXTIMERSLOT = 30

        for tidx = _MINTIMERSLOT, _MAXTIMERSLOT do
            if not mission.phases[5].timers[tidx] then
                mission.phases[5].timers[tidx] = {
                    time = 15,
                    callback = function()
                        local _MethodName = "Phase 5 Timer [6 to 30]"
                        mission.Log(_MethodName, "Вызов.", _MethodName)

                        local _sector = Sector()

                        if atTargetLocation() then
                            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
                            local playerShips = {}
                            for _, _e in pairs(playerEntities) do
                                if _e.type == EntityType.Ship then
                                    table.insert(playerShips, _e)
                                end
                            end
                            local defenderShips = { _sector:getEntitiesByScriptValue("is_horizon_defender") }
    
                            for _, pShip in pairs(playerShips) do
                                for _, dShip in pairs(defenderShips) do
                                    --то же, что и в скрипте sus. Необходимое расстояние уменьшается хамелеоном.
                                    local baseDist = 1000

                                    local dist = pShip:getNearestDistance(dShip)
                                    if dist <= baseDist then --Не стоит этим заниматься, если мы даже в пределах 10 км. Иначе это пустая трата вычислительной мощности.
                                        local adjDist = baseDist
                                        local ret, detectionRangeFactor = pShip:invokeFunction("internal/dlc/blackmarket/systems/badcargowarningsystem.lua", "getDetectionRangeFactor")
                                        if ret == 0 then
                                            adjDist = baseDist * detectionRangeFactor
                                        end

                                        if dist <= adjDist then
                                            kothStory7_onStealthBroken(true)
                                            fail()
                                        end
                                    end
                                end
                            end
                        end
                    end,
                    repeating = false
                }
                break
            end
        end
    end
}

--endregion

--region #ВЫЗОВЫ ТАЙМЕРОВ ФАЗЫ 5

--СЛОТЫ ТАЙМЕРОВ
--1 = находится ли игрок в пределах 30 км от военного аванпоста? в качестве альтернативы, проверьте, повреждены ли щиты аванпоста.
--2 = каждые 30 секунд очищать все остановленные таймеры с idx 3 по 30
--3 = находится ли игрок в пределах 20 км от грузового корабля? если нет, запустите таймер для провала.
--4 = 20 секунд до того, как военный аванпост нарушит маскировку - установлено в таймере 1.
--5 = 20 секунд, чтобы игрок вернулся в радиус 20 км от грузового корабля - установлено в таймере 3.
--с 6 по 30 = 10 секунд до того, как защитник нарушит маскировку - устанавливается через отправленный обратный вызов.

if onServer() then

mission.phases[5].timers[1] = {
    time = 10,
    callback = function()
        local _sector = Sector()
        if atTargetLocation() then
            local militaryOutpost = Entity(mission.data.custom.militaryOutpostID)
            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
            local playerShips = {}
            for _, _e in pairs(playerEntities) do
                if _e.type == EntityType.Ship then
                    table.insert(playerShips, _e)
                end
            end

            --Запустите таймер, если игрок находится в пределах 30 км от аванпоста.
            --На самом деле, это один из самых мучительных кусков логики, которые я когда-либо писал, но, черт возьми, если это не работает.
            local _TIMERSLOT = 4

            for _, pShip in pairs(playerShips) do
                local dist = militaryOutpost:getNearestDistance(pShip)
                if dist <= mission.data.custom.phase5MiloutpostMinDist and not mission.phases[5].timers[_TIMERSLOT] then
                    Player():sendChatMessage("", 3, "Ваш корабль слишком близко к военной установке. Отдалитесь на 30 км, прежде чем он сможет вас отсканировать.")
                    --добавить слот таймера 3 - если игрок все еще находится в пределах 30 км от аванпоста через 30 секунд, провалить задание.
                    mission.phases[5].timers[_TIMERSLOT] = {
                        time = 20,
                        callback = function()
                            local _MethodName = "Phase 5 Timer 3 Callback"
                            mission.Log(_MethodName, "Вызов.", _MethodName)

                            local _sector = Sector()

                            if atTargetLocation() then
                                local militaryOutpost = Entity(mission.data.custom.militaryOutpostID)
                                local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
                                local playerShips = {}
                                for _, _e in pairs(playerEntities) do
                                    if _e.type == EntityType.Ship then
                                        table.insert(playerShips, _e)
                                    end
                                end

                                for _, pShip in pairs(playerShips) do
                                    local dist = militaryOutpost:getNearestDistance(pShip)
                                    if dist <= mission.data.custom.phase5MiloutpostMinDist then
                                        kothStory7_onStealthBroken(true)
                                        fail()
                                    end
                                end
                            end
                        end,
                        repeating = false
                    }
                end
            end

            --Кроме того, проверьте, повреждены ли щиты аванпоста.
            local shieldPct = militaryOutpost.shieldDurability / militaryOutpost.shieldMaxDurability
            if shieldPct <= 0.95 then
                kothStory7_onStealthBroken(true)
                fail()
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[2] = {
    time = 30,
    callback = function()
        local _MethodName = "Phase 5 Timer 2 Callback"

        local _MINTIMERSLOT = 4
        local _MAXTIMERSLOT = 30

        for tidx = _MINTIMERSLOT, _MAXTIMERSLOT do
            --Очистка остановленных таймеров.
            if mission.phases[5].timers[tidx] and mission.phases[5].timers[tidx].stopped then
                mission.Log(_MethodName, "Очистка таймера " .. tostring(tidx), _MethodName)
                mission.phases[5].timers[tidx] = nil
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[3] = {
    time = 10,
    callback = function()
        local _sector = Sector()
        if atTargetLocation() then
            local freighter = Entity(mission.data.custom.freighterID)
            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
            local playerShips = {}
            for _, _e in pairs(playerEntities) do
                if _e.type == EntityType.Ship then
                    table.insert(playerShips, _e)
                end
            end
    
            --необходимо, чтобы хотя бы 1 корабль игрока находился в пределах 20 км от грузового корабля.
            local escortOK = false
            for _, pShip in pairs(playerShips) do
                local dist  = 0
                if freighter then
                    dist = freighter:getNearestDistance(pShip)
                else
                    kothStory7_onFreighterDestroyed()
                end
                if dist <= 2000 then
                    escortOK = true
                    break
                end
            end
            
            local _TIMERSLOT = 5

            if not escortOK and not mission.phases[5].timers[_TIMERSLOT] then
                Player():sendChatMessage("", 3, "Вы слишком далеко от грузового корабля. Держитесь в пределах 20 км от него, иначе Horizon заподозрит неладное.")

                mission.phases[5].timers[_TIMERSLOT] = {
                    time = 20,
                    callback = function()
                        local _sector = Sector()

                        if atTargetLocation() then
                            local freighter = Entity(mission.data.custom.freighterID)
                            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
                            local playerShips = {}
                            for _, _e in pairs(playerEntities) do
                                if _e.type == EntityType.Ship then
                                    table.insert(playerShips, _e)
                                end
                            end

                            local escortOK = false
                            for _, pShip in pairs(playerShips) do
                                local dist = freighter:getNearestDistance(pShip)
                                if dist <= 2000 then
                                    escortOK = true
                                    break
                                end
                            end

                            if not escortOK then
                                kothStory7_onStealthBroken(true)
                                fail()
                            end
                        end
                        
                    end,
                    repeating = false
                }
            end
        end

    end,
    repeating = true
}

end

--endregion

mission.phases[6] = {}
mission.phases[6].timers = {}
mission.phases[6].showUpdateOnEnd = true
mission.phases[6].onBegin = function()
    local _MethodName = "Phase 6 On Begin"
    mission.Log(_MethodName, "Начало...", _MethodName)
    
    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true
    mission.data.description[7].fulfilled = true
    mission.data.description[8].visible  = true
    mission.data.description[9].visible  = true
end

mission.phases[6].onBeginServer = function()
    local _MethodName = "Phase 6 On Begin Server"
    mission.Log(_MethodName, "Начало...", _MethodName)

    kothStory7_onStealthBroken(false)

    local frostbiteFaction = HorizonUtil.getFriendlyFaction()
    local shipyard = Entity(mission.data.custom.shipyardID)
    shipyard.factionIndex = frostbiteFaction.index

    local sophie = Entity(mission.data.custom.varlanceID)
    local sophieAI = ShipAI(sophie)
    sophieAI:registerFriendEntity(mission.data.custom.militaryOutpostID)
    sophieAI:setAggressive()

    HorizonUtil.varlanceChatter("Нам нужно выиграть время для абордажной команды! Убедитесь, что Horizon не уничтожит верфь.")

    invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)
end

mission.phases[6].updateTargetLocationServer = function()
    local _MethodName = "Phase 6 Update Target Location Server"

    local horizonCt = ESCCUtil.countEntitiesByValue("is_horizon_ship")
    if horizonCt == 0 then
        if mission.data.custom.waveState == 2 then
            mission.Log(_MethodName, "Отправка чата грузового корабля для " .. tostring(mission.data.custom.waveNumber) .. " и сброс состояния волны.", _MethodName)

            local lineidx = mission.data.custom.waveNumber - 1
            local msgFuncs = {
                function()
                    local shipyard = Entity(mission.data.custom.shipyardID)
                    Sector():broadcastChatMessage(shipyard, ChatMessageType.Chatter, "Мы прижаты к земле! Пытаемся вырваться!")
                end,
                function()
                    local shipyard = Entity(mission.data.custom.shipyardID)
                    Sector():broadcastChatMessage(shipyard, ChatMessageType.Chatter, "Встречаем ожесточенное сопротивление. Нам нужно еще немного времени, капитан!")
                end,
                function()
                    local freighter = Entity(mission.data.custom.freighterID)
                    Sector():broadcastChatMessage(freighter, ChatMessageType.Chatter, "Команда вернулась на корабль! Устанавливаем координаты гиперпространства!")
                end
            }

            msgFuncs[lineidx]()

            mission.data.custom.waveState = 3
        elseif mission.data.custom.waveState == 3 then
            mission.Log(_MethodName, "Сброс состояния волны. Теперь могут появиться корабли.", _MethodName)
            mission.data.custom.waveState = 1
        end

        if mission.data.custom.waveNumber == 4 then
            nextPhase()
        end
    end
end

mission.phases[6].onEntityDestroyed = function(id, lastDamageInflictor)
    if id == mission.data.custom.freighterID then
        kothStory7_onFreighterDestroyed()
    end

    if id == mission.data.custom.shipyardID then
        kothStory7_onShipyardDestroyed()
    end
end

--region #ВЫЗОВЫ ТАЙМЕРОВ ФАЗЫ 6

if onServer() then

mission.phases[6].timers[1] = {
    time = 60,
    callback = function()
        local _MethodName = "Phase 6 Timer 1 Callback"
        mission.Log(_MethodName, "Выполнение...", _MethodName)

        --Ничего не делайте, если мы не на месте. Технически это не нужно, так как выпрыгивание игрока приводит к провалу миссии в этот момент.
        if atTargetLocation() then
            if mission.data.custom.waveState == 1 and mission.data.custom.waveNumber < 4 then
                mission.Log(_MethodName, "Появление пиратской волны " .. tostring(mission.data.custom.waveNumber), _MethodName)
                kothStory7_spawnPirateWave(mission.data.custom.waveNumber == 3)
                if mission.data.custom.waveNumber == 3 then
                    kothStory7_spawnHorizonWave()
                end

                mission.data.custom.waveNumber = mission.data.custom.waveNumber + 1
            end
        end
    end,
    repeating = true
}

mission.phases[6].timers[2] = {
    time = 15,
    callback = function()
        if atTargetLocation() and not mission.data.custom.phase6Chatter1Sent then
            mission.data.custom.phase6Chatter1Sent = true

            local militaryOutpost = Entity(mission.data.custom.militaryOutpostID)

            Sector():broadcastChatMessage(militaryOutpost, ChatMessageType.Chatter, "<Перехвачено> ВНИМАНИЕ! Данные проекта XSOLOGIZE скомпрометированы! Критическая ситуация! Отправьте группу реагирования СЕЙЧАС ЖЕ! ВНИМАНИЕ!")
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[7] = {}
mission.phases[7].onBegin = function()
    mission.data.description[9].fulfilled = true
    mission.data.description[10].fulfilled = true
end

mission.phases[7].onBeginServer = function()
    local _MethodName = "Phase 7 On Begin Server"
    mission.Log(_MethodName, "Выполнение...", _MethodName)
    
    local shipyard = Entity(mission.data.custom.shipyardID)
    local horizonFaction = HorizonUtil.getEnemyFaction()

    shipyard.factionIndex = horizonFaction.index

    local freighter = Entity(mission.data.custom.freighterID)

    local frPos = freighter.translationf

    local dir = freighter.look * -1 --должно быть прямо за ним.
    local frMoveToPos = frPos + (dir * 20000)

    local freighterAI = ShipAI(freighter)
    freighterAI:setFlyLinear(frMoveToPos, 0, false)
end

mission.phases[7].updateTargetLocationServer = function(timeStep)
    mission.data.custom.phase7Timer = mission.data.custom.phase7Timer + timeStep

    if mission.data.custom.phase7Timer >= 15 and not mission.data.custom.phase7FinishEventDone then
        mission.data.custom.phase7FinishEventDone = true --Предотвратить повторную трансляцию.

        local freighter = Entity(mission.data.custom.freighterID)
        local sophie = Entity(mission.data.custom.varlanceID)

        HorizonUtil.varlanceChatter("Выпрыгиваю, капитан - советую вам сделать то же самое! Мы будем на связи!")

        freighter:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
        sophie:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))

        kothStory7_addDefenseController(Sector())

        mission.data.description[8].fulfilled = true
        mission.data.description[11].visible = true

        sync()
    end
end

--endregion

--region #СЕРВЕРНЫЕ ВЫЗОВЫ

function kothStory7_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Получение местоположения.", _MethodName)
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Получите сектор, который очень близок к внешнему краю барьера.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax), _MethodName)
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 2, 4, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 2, 4, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 4, 8, false)
    end

    mission.Log(_MethodName, "X координата следующего местоположения: " .. tostring(target.x) .. " Y координата следующего местоположения: " .. tostring(target.y), _MethodName)
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящее место для миссии. Завершение скрипта.", _MethodName)
        terminate()
        return
    end

    return target
end

function kothStory7_spawnVarlance()
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Varlance - вызываю его.", _MethodName)

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(false)

        --Маловероятно, что корабль Varlance получит достаточно повреждений, чтобы отступить, поэтому мы можем это формализовать.
        local _VarlanceDurability = Durability(_Varlance)
        _VarlanceDurability.invincibility = 0.5

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory7_spawnSophie()
    local _MethodName = "Spawn Sophie"
    
    kothStory7_spawnVarlance()

    local varlance = Entity(mission.data.custom.varlanceID)
    varlance.title = "Корабль Софи"
    varlance.name = "День в аду"
end
function kothStory7_buildObjectiveSector(x, y)
    local _MethodName = "Build Objective Sector"
    mission.Log(_MethodName, "Начало.")

    local _random = random()

    local _Generator = SectorGenerator(x, y)

    --Make asteroid fields.
    _Generator:createAsteroidField()

    local _fields = _random:getInt(3, 5)
    --Add: 3-5 small asteroid fields.
    for _ = 1, _fields do
        _Generator:createSmallAsteroidField()
    end

    --Make shipyard.
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local sypos = ESCCUtil.getVectorAtDistance(pos, 3500, true)
    local symatrix = MatrixLookUpPosition(look, up, sypos)

    --Make military outpost approx. 30 km from shipyard and hopefully more than 30 km from player.
    local dir = normalize(sypos - pos)
    local bmopos = sypos + (dir * 3000)

    local mopos = ESCCUtil.getVectorAtDistance(bmopos, 1000, false)
    local momatrix = MatrixLookUpPosition(look, up, mopos)

    local sy = HorizonUtil.spawnHorizonShipyard1(false, symatrix)
    mission.data.custom.shipyardID = sy.index

    local mo = HorizonUtil.spawnMilitaryOutpost(false, momatrix)
    mission.data.custom.militaryOutpostID = mo.index
    local moDura = Durability(mo)
    moDura.invincibility = 0.94
    mo:setValue("_DefenseController_Manage_Own_Invincibility", true)
    mo:addScriptOnce("player/missions/horizon/story7/horizonstory7miloutpost.lua")

    local frostbiteFaction = HorizonUtil.getFriendlyFaction()
    local _HorizonFaction = HorizonUtil.getEnemyFaction()

    kothStory7_spawnSophie()
    --spawn horizon freighter, then turn it over to frostbite control.
    local sophie = Entity(mission.data.custom.varlanceID)

    local fPos = ESCCUtil.getVectorAtDistance(sophie.translationf, 1000, false)

    local freighter = HorizonUtil.spawnHorizonFreighter(false, MatrixLookUpPosition(sophie.look, sophie.up, fPos), frostbiteFaction)
    mission.data.custom.freighterID = freighter.index
    freighter:setValue("is_horizon", nil)
    freighter:setValue("is_horizon_ship", nil)
    freighter:setValue("is_horizon_freighter", nil)
    freighter:setValue("is_frostbite", true)
    freighter:setValue("is_frostbite_ship", true)
    freighter:setValue("is_frostbite_freighter", true)

    --spawn pirate defenders, then register everything as ally EXCEPT for the military outpost.
    --these guys aren't particularly intimidating - spawn @ danger 5.
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel / 2, 12, "Low")
    local _CreatedPirateTable = {}
    local _AIManipulationTable = {}

    table.insert(_AIManipulationTable, sy)

    for _, _Pirate in pairs(_PirateTable) do
        local pLook = _random:getVector(-100, 100)
        local pUp = _random:getVector(-100, 100)
        local pPos = ESCCUtil.getVectorAtDistance(sy.translationf, 1000, false)

        local _ship = PirateGenerator.createScaledPirateByName(_Pirate, MatrixLookUpPosition(pLook, pUp, pPos))
        _ship.factionIndex = _HorizonFaction.index
        _ship:setValue("is_horizon", true)
        _ship:setValue("is_horizon_defender", true)
        _ship:addScriptOnce("player/missions/horizon/story7/horizonstory7patrol.lua")        

        table.insert(_CreatedPirateTable, _ship)
        table.insert(_AIManipulationTable, _ship)
    end

    SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

    Placer.resolveIntersections()

    --register all ships as friendly - use the swoks trick. Need this in case players bring in multiple ships.
    for _, _ship in pairs(_AIManipulationTable) do
        local allianceIndex = _Player.allianceIndex
        local ai = ShipAI(_ship)
        ai:registerFriendFaction(_Player.index)
        ai:registerFriendFaction(frostbiteFaction.index)
        if allianceIndex then
            ai:registerFriendFaction(allianceIndex)
        end
    end

    --Register frostbite as a friend faction for the military installation so they won't attack it.
    local mai = ShipAI(mo)
    mai:registerFriendFaction(frostbiteFaction.index)

    mission.data.custom.cleanUpSector = true
end

function kothStory7_onStealthBroken(runMissionFailed)
    local _sector = Sector()

    local horizonUnits = {_sector:getEntitiesByScriptValue("is_horizon")}
    for _, horizonShip in pairs(horizonUnits) do
        local horizonAI = ShipAI(horizonShip)
        horizonAI:clearFriendFactions()
        horizonAI:clearFriendEntities()
    end

    if runMissionFailed then
        --mission ends. first, frostbite ships immediately jump out
        HorizonUtil.varlanceChatter("Они нас обнаружили! Отходим! Отходим!")
        local sophie = Entity(mission.data.custom.varlanceID)
        local freighter = Entity(mission.data.custom.freighterID)

        local orderTable = { sophie, freighter }

        for _, ship in pairs(orderTable) do
            ship:addScript("utility/delayeddelete.lua", random():getFloat(2, 3))
        end

        invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)

        kothStory7_addDefenseController(_sector)
    end
end

function kothStory7_spawnPirateWave(lastWave)
    --common vals
    local _WaveDanger = 5 + mission.data.custom.waveNumber
    local _Distance = 250 --_#DistAdj

    local _spawnFunc = function(onSpawnFunc, isAlpha, lastWave)
        local wingGenerator = AsyncPirateGenerator(nil, onSpawnFunc)
        wingGenerator.pirateLevel = mission.data.custom.pirateLevel

        local threatTable = "Low"
        if lastWave then
            threatTable = "Standard"
        end

        local _ct = 4
        if isAlpha then
            _ct = 3 --Alpha wing always has a jammer.
        end

        local wingTable = ESCCUtil.getStandardWave(_WaveDanger, _ct, threatTable, false)
        local wingPositions = wingGenerator:getStandardPositions(_Distance, _ct)
        if isAlpha then
            table.insert(wingTable, "Jammer")
        end

        wingGenerator:startBatch()

        for posIdx, _pirate in pairs(wingTable) do
            wingGenerator:createScaledPirateByName(_pirate, wingPositions[posIdx])
        end

        wingGenerator:endBatch()
    end

    --spawn alpha wing
    _spawnFunc(kothStory7_onSpawnAlphaWingFinished, true, lastWave)

    --spawn beta wing
    _spawnFunc(kothStory7_onSpawnBetaWingFinished, false, lastWave)
end

function kothStory7_spawnHorizonWave()
    local _MethodName = "Spawn Horizon Wave"
    mission.Log(_MethodName, "Начало.")

    local _random = random()
    local horizonShipyard = Entity(mission.data.custom.shipyardID)
    local syPos = horizonShipyard.translationf
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos1 = ESCCUtil.getVectorAtDistance(syPos, 3000, true)
    local pos2 = ESCCUtil.getVectorAtDistance(pos1, 1000, false) --Get one reasonably close
    local pos3 = ESCCUtil.getVectorAtDistance(pos1, 1000, false)

    --Spawn 3 arty cruisers
    local _arty1 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos1), nil)
    local _arty2 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos2), nil)
    local _arty3 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos3), nil)

    Placer.resolveIntersections()

    local _artyTable = { _arty1, _arty2, _arty3 }
    for _, _arty in pairs(_artyTable) do
        local _artyAI = ShipAI(_arty)
        
        _artyAI:setIdle()
        _artyAI:setPassiveShooting(true)
        _artyAI:setFlyLinear(syPos, 2500, false)

        local tTag = "is_horizon_shipyard"

        local torpSlammerValues = {
            _TimeToActive = 5,
            _ROF = 4,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 7, --Osprey
            _DurabilityFactor = 4,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag
        }

        local torpSlammerValues2 = {
            _TimeToActive = 20,
            _ROF = 2,
            _DamageFactor = 1.2,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 7, --Osprey
            _DurabilityFactor = 8,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag,
            _AccelFactor = 1.5,
            _VelocityFactor = 1.5
        }

        local torpSlammerValues3 = {
            _TimeToActive = 40,
            _ROF = 2,
            _DamageFactor = 1.4,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 8, --Eagle
            _DurabilityFactor = 16,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag,
            _AccelFactor = 2,
            _VelocityFactor = 2,
            _ShockwaveFactor = 2
        }

        --The death torps - the shipyard should fall to these pretty quickly.
        local torpSlammerValues4 = {
            _TimeToActive = 60,
            _ROF = 2,
            _DamageFactor = 1.6,
            _PreferWarheadType = 2, --Neutron
            _PreferBodyType = 9, --Hawk
            _DurabilityFactor = 72,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag,
            _AccelFactor = 3,
            _VelocityFactor = 3,
            _ShockwaveFactor = 6
        }

        _arty:addScript("torpedoslammer.lua", torpSlammerValues)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues2)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues3)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues4)
    end

    HorizonUtil.varlanceChatter("Уф. Опять этот трюк. Станция выдержит несколько ударов. Убедитесь, что с фрейтером все в порядке, прежде чем нападать на крейсеры.")
 
    mission.data.description[10].visible = true
    sync()
end

function kothStory7_onSpawnAlphaWingFinished(generated)
    mission.data.custom.waveState = 2

    --Attacks Varlance
    local _TargetPriorityData = {
        _TargetPriority = 1,
        _TargetTag = "is_frostbite_freighter"
    }

    local horizonFaction = HorizonUtil.getEnemyFaction()

    for _, _ship in pairs(generated) do
        _ship.factionIndex = horizonFaction.index
        _ship:setValue("is_horizon_ship", true)

        _ship:addScript("ai/priorityattacker.lua", _TargetPriorityData)
    end

    SpawnUtility.addEnemyBuffs(generated)

    Placer.resolveIntersections()
end

function kothStory7_onSpawnBetaWingFinished(generated)
    mission.data.custom.waveState = 2

    --Attacks the player
    local _TargetPriorityData = {
        _TargetPriority = 1,
        _TargetTag = "is_horizon_shipyard"
    }

    local horizonFaction = HorizonUtil.getEnemyFaction()

    for _, _ship in pairs(generated) do
        _ship.factionIndex = horizonFaction.index
        _ship:setValue("is_horizon_ship", true)

        _ship:addScript("ai/priorityattacker.lua", _TargetPriorityData)
    end

    SpawnUtility.addEnemyBuffs(generated)

    Placer.resolveIntersections()
end

function kothStory7_onFreighterDestroyed()
    local sophie = Entity(mission.data.custom.varlanceID)

    if sophie then
        HorizonUtil.varlanceChatter("Мы потеряли фрейтер! Отходим! Отходим!")

        sophie:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
    end

    invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)

    fail()
end

function kothStory7_onShipyardDestroyed()
    local sophie = Entity(mission.data.custom.varlanceID)

    if sophie then
        HorizonUtil.varlanceChatter("Мы потеряли верфь! Отходим! Отходим!")

        sophie:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
    end

    local freighter = Entity(mission.data.custom.freighterID)

    if freighter and valid(freighter) then
        freighter:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
    end

    invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)

    fail()
end

function kothStory7_addDefenseController(_sector)
    local horizonFaction = HorizonUtil.getEnemyFaction()
    local defControlValues = {
        _DefenseLeader = mission.data.custom.militaryOutpostID,
        _DefenderCycleTime = 60,
        _DangerLevel = mission.data.custom.dangerLevel,
        _MaxDefenders = 12,
        _AllDefenderDamageScale = 2,
        _MaxDefendersSpawn = 6,
        _DefenderDistance = 5000,
        _LowTable = "High",
        _IsPirate = false,
        _Factionid = horizonFaction.index,
        _DefenderHPThreshold = 0.5,
        _DefenderOmicronThreshold = 0.5,
        _PreventLootDrop = true
    }

    _sector:addScriptOnce("sector/background/defensecontroller.lua", defControlValues)
end

function kothStory7_sendFailureMail()
    if not mission.data.custom.sentFailMail then
        local _player = Player()
        local _Mail = Mail()
        _Mail.text = Format("Привет, приятель,\n\nОперация прошла не так, как планировалось, но мы все еще можем ударить по нескольким их наемникам. С достаточными потерями им придется сменить сторожевых псов. Когда это произойдет, новые ребята ничего о нас не узнают. Между этим и еще одной лазейкой, которую я нашел в их графике поставок, мы можем попытаться перезапустить операцию позже.\n\nЯ свяжусь с тобой.\n\nВарланс")
        _Mail.header = "Миссия провалена"
        _Mail.sender = "Варланс @FrostbiteCompany"
        _Mail.id = "_horizon_story7_mail3"
        _player:addMail(_Mail)

        mission.data.custom.sentFailMail = true
    end
end

function kothStory7_clearShipyardCargo()
    if atTargetLocation() then
        local horizonShipyard = Entity(mission.data.custom.shipyardID)
        if horizonShipyard and valid(horizonShipyard) then
            local syBay = CargoBay(horizonShipyard)
            syBay:clear()
        end
    end
end

function kothStory7_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _player = Player()

    local _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."
    local _BaseReward = 53790000

    _player:setValue("_horizonkeepers_story_stage", 8)
    _player:setValue("encyclopedia_koth_sophie", true)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward, paymentMessage = "Заработали %1% кредитов за кражу данных." }

    --Send the player a mail from Sophie.
    local _Mail = Mail()
	_Mail.text = Format("Привет, капитан!\n\nЭто Софи Нетреба из Frostbite. Просто хотела сказать, что мне понравилось добывать эти данные вместе с вами - ничто так не бодрит, как хорошая миссия скрытности, да? Извините за внезапный уход, но это был лишь вопрос времени, когда появится подкрепление! Варланс сказал, что свяжется с вами, когда мы разберемся, что с этими данными. Там много чего нужно разобрать, и похоже, что большая часть все еще зашифрована, несмотря на наши меры предосторожности.\n\nС нетерпением жду следующей встречи!\n\nСофи")
	_Mail.header = "Хорошие времена!"
	_Mail.sender = "Софи @FrostbiteCompany"
	_Mail.id = "_horizon_story7_mail2"
	_player:addMail(_Mail)

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function kothStory7_onMarkCloseShips()
    local _MethodName = "On Mark Ships"

    local player = Player()
    if not player then return end

    local _Ship = Entity(player.craftIndex)

    if not _Ship then
        return
    end

    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    local horizonShips = { Sector():getEntitiesByScriptValue("is_horizon_defender") }

    for _, ship in pairs(horizonShips) do
        local dist = ship:getNearestDistance(_Ship)
        if dist <= mission.data.custom.phase5ShipHighlightRange then
            local rColor = 255
            local bColor = 0
            local gColor = 127
            if dist <= mission.data.custom.phase5ShipUrgentHighlightRange then
                gColor = 0
            end

            local warningColor = ESCCUtil.getSaneColor(rColor, gColor, bColor)

            local _, size = renderer:calculateEntityTargeter(ship)

            renderer:renderEntityTargeter(ship, warningColor, size * 1.25)
            renderer:renderEntityArrow(ship, 30, 10, 250, warningColor)
        end
    end

    renderer:display()
end

--endregion

--region #CLIENT DIALOG CALLS

function kothStory7_changeOutpostTrack(outpostID)
    Entity(outpostID):invokeFunction("horizonstory7miloutpost.lua", "switchTracks")
end

function kothStory7_onPhase2Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}

    local playerHeardPlan = Player():getValue("_horizonkeepers_story7_heardplan")

    d0.text = "Рад, что ты смог прийти, приятель."
    d0.followUp = d1

    d1.text = "Вот план. Твой корабль и Ice Nova будут сопровождать наш захваченный фрейтер в сектор. К сожалению, у них полно кадров, как мы уничтожаем их корабли. Я ожидаю, что они мгновенно узнают профили наших кораблей."
    if playerHeardPlan then
        d8.text = "Понял. Я отправляю вам координаты верфи сейчас. Софи встретит вас там с захваченным фрейтером."
        d8.onEnd = kothStory7_onPhase2DialogEnd

        d1.answers = {
            { answer = "Продолжай.", followUp = d2 },
            { answer = "Мы уже это обсуждали.", followUp = d8 }
        }
    else
        d1.followUp = d2
    end

    d2.text = "Так что меня \"казнят\" за эту миссию. Мой заместитель - Софи Нетреба - будет притворяться капитаном пиратов, который недавно захватил этот корабль."
    d2.followUp = d3

    d3.text = "Очень приятно, капитан. Я видел вашу работу своими глазами и являюсь поклонником. Будет интересно сражаться вместе с вами!"
    d3.followUp = d4

    d4.text = "Вы двое останетесь позади и позволите фрейтеру пролететь. На нем будет абордажная команда, и они попытаются незаметно снять данные с сети - на этот раз, не вызывая никаких тревог."
    d4.followUp = d5

    d5.text = "Между данными, которые мы восстановили с прототипов, и некоторыми данными, которые собрал наш AWACS, мы восстановили ряд их IFF-кодов. Пока вы не подпустите к себе ни одного из защитников, патрулирующих сектор, у вас не должно возникнуть проблем. Будьте наготове с Ice Nova на случай возникновения каких-либо проблем."
    d5.answers = {
        { answer = "Я понимаю.", followUp = d7 },
        { answer = "Мне нужно установить подсистему?", followUp = d6 }
    }

    d6.text = "Что ты думаешь, мы - Семья? Неа. Наша техника лучше - мы тебя прикроем. Но если ты нервничаешь, можешь установить хамелеон."
    d6.followUp = d7

    d7.text = "Я отправляю вам координаты верфи сейчас. Софи встретит вас там с захваченным фрейтером."
    d7.onEnd = kothStory7_onPhase2DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d4, d5, d6, d7, d8 }, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({d3}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothStory7_onPhase4Dialog(outpostID)
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
    local d16 = {}
    local d17 = {}
    local d18 = {}
    local _PlayerName = Player().name

    d0.text = "Неопознанные корабли, это военная база MRI-7873-SRD6F6C - управление воздушным движением сектора. Ваши профили целей совпадают с наемниками, которые совершали набеги на наши конвои в течение последних нескольких недель."
    d0.followUp = d1

    d1.text = "Остановитесь и приготовьтесь к абордажу."
    d1.followUp = d2

    d2.text = "Говорит Day In Hell, капитан Софи Нетреба - что у вас там происходит, управление?"
    d2.followUp = d3

    d3.text = "Согласно нашим записям, этот линкор является собственностью Horizon Keepers и был украден во время рейда капитаном Варлансом Калдером из Frostbite Company. Вы должны немедленно его вернуть."
    d3.followUp = d4

    d4.text = "Варланс? Должно быть, тот парень, которого мы зафражили на прошлой неделе. Надо было слышать, как он кричал прямо перед тем, как мы отправили его в космос. Что упало, то пропало, управление. Я не собираюсь возвращать этот корабль."
    d4.followUp = d5

    d5.text = "Так вы хотите проявить немного больше благодарности за то, что мы эскортировали ваш грузовой корабль сюда, или вы просто собираетесь жаловаться?"
    d5.followUp = d6

    d6.text = "Ваше отношение неуместно, капитан."
    d6.followUp = d7

    d7.text = "Принято, управление. Мы положим это в ящик для жалоб."
    d7.followUp = d8

    d8.text = "... Ладно. А вы?"
    d8.answers = {
        { answer = "Я?", followUp = d9 }
    }
    
    d9.text = "Да, вы. Остановитесь и приготовьтесь к абордажу."
    d9.answers = {
        { answer = "Отрицательно. Мы не остановимся.", followUp = d10 },
        { answer = "О чем вы говорите?", followUp = d11 } 
    }
    
    d10.text = "Мы не давали вам выбора."
    d10.onEnd = kothStory7_onPhase4DialogEndBad
    
    d11.text = "Ваши корабли уничтожили наш флот - уничтожили технологии на миллиарды кредитов. Тысячи наших товарищей мертвы."
    d11.answers = {
        { answer = "Этот корабль захвачен. ${_PLAYER} мертв." % { _PLAYER = _PlayerName } , followUp = d13 },
        { answer = "Вашим пиратским наемникам все равно.", followUp = d12 }
    }
    
    d12.text = "Понятно. Мы передумали. Всем кораблям, атаковать и уничтожить неопознанные корабли."
    d12.onEnd = kothStory7_onPhase4DialogEndBad
    
    d13.text = "Понятно. Мне в это трудно поверить. Мы отправим команду для осмотра вашего корабля. Держите оружие выключенным."
    d13.answers = {
        { answer = "С меня хватит.", followUp = d14 },    
        { answer = "Пожалуйста за эскорт грузового корабля, придурки.", followUp = d15 }
    }
    
    d14.text = "Это наше пространство. Вы с нами еще не \"закончили\". Всем кораблям, усмирить два неопознанных судна."
    d14.onEnd = kothStory7_onPhase4DialogEndBad
    
    d15.text = "<Подслушано> Нам нужно прекратить нанимать таких агрессивных пиратских капитанов для охраны наших грузов."
    d15.followUp = d16

    d16.text = "<Подслушано> Просто пропустите их. Корпорация разберется с ними позже."
    d16.followUp = d17

    d17.text = "Но... Уф. Ладно. ... Вам разрешено продолжить. Вы двое - та еще парочка."
    d17.followUp = d18

    d18.text = "<Защищенный канал> Фух! Я боялся, что они будут настаивать. Сейчас мы отправим грузовой корабль. Постарайтесь держаться подальше от защитников и следите за этой установкой!"
    d18.onEnd = kothStory7_onPhase4DialogEndGood
    
    ESCCUtil.setTalkerTextColors({d2, d4, d5, d7, d18}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(outpostID):interactShowDialog(d0, false)
end

--endregion