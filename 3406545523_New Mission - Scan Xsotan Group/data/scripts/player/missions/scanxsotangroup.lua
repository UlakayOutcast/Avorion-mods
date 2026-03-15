package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

ESCCUtil = include("esccutil")

local Xsotan = include("story/xsotan")
local SpawnUtility = include ("spawnutility")
local SectorGenerator = include ("SectorGenerator")
local Balancing = include ("galaxy")
local Placer = include ("placer")
mission._Debug = 0
mission._Name = "Сканирование группы Ксотан"

--region #INIT

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Заполнитель
    { text = "..." },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Отсканируйте Ксотан - ${_SCANNED}/${_SCANNEDMAX} отсканировано", bulletPoint = true, fulfilled = false, visible = false }
}

mission.data.accomplishMessage = "Мы получили хорошие данные с ваших сканов! Спасибо за помощь в наших исследованиях!"
mission.data.failMessage = "Теперь вы не сможете получить все сканы. Нам могли бы пригодиться эти данные..."

local ScanXsotanGroup_init = initialize
function initialize(_Data_in, bulletin)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начинаем...")

    if onServer() and not _restoring then
        mission.Log(_MethodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel) .. " threattype: " .. tostring(_Data_in.threatType))

        local _X, _Y = _Data_in.location.x, _Data_in.location.y

        local _Sector = Sector()
        local _Giver = Entity(_Data_in.giver)
        
        --[[=====================================================
            НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
        =========================================================]]
        mission.data.custom.dangerLevel = _Data_in.dangerLevel
        mission.data.custom.inBarrier = _Data_in.inBarrier
        mission.data.custom.spawnXsotanQty = 5
        local _random = random()
        for _ = 1, mission.data.custom.dangerLevel do
            if _random:test(0.5) then
                mission.data.custom.spawnXsotanQty = mission.data.custom.spawnXsotanQty + 1
            end
        end
        mission.data.custom.scannedXsotan = 0
        local scanPct = 0.5 + (mission.data.custom.dangerLevel * 0.05)
        mission.data.custom.scannedXsotanTgt = math.max(4, math.ceil(mission.data.custom.spawnXsotanQty * scanPct))
        mission.data.custom.scannableXsotanShips = {}

        if mission.data.custom.inBarrier then
            local _KilledGuardian = Player():getValue("wormhole_guardian_destroyed")
            if _KilledGuardian then
                mission.Log(_MethodName, "Игрок убил стража. Устанавливаем режим джокера.")
                mission.data.custom.killedGuardian = true
                _Data_in.reward.credits = _Data_in.reward.credits * 3
                _Data_in.reward.relations = _Data_in.reward.relations + 1000
            end
        end

        --[[=====================================================
            НАСТРОЙКА ОПИСАНИЯ МИССИИ:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { x = _X, y = _Y }
        mission.data.description[3].arguments = { _X = _X, _Y = _Y }
        mission.data.description[4].arguments = { _SCANNED = mission.data.custom.scannedXsotan , _SCANNEDMAX = mission.data.custom.scannedXsotanTgt }
    end

    --Запускаем ванильную инициализацию. Managers _restoring самостоятельно.
    ScanXsotanGroup_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.getRewardedItems = function()
    --25% шанс получить случайное улучшение радара.
    if random():test(0.25) then
        local _SeedInt = random():getInt(1, 20000)
        local _Rarities = {RarityType.Common, RarityType.Common, RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare}

        if mission.data.custom.inBarrier then
            _Rarities = {RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare, RarityType.Rare, RarityType.Exceptional, RarityType.Exotic}
        end

        shuffle(random(), _Rarities)

        return SystemUpgradeTemplate("data/scripts/systems/scannerbooster.lua", Rarity(_Rarities[1]), Seed(_SeedInt))
    end
end

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

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBegin = function()
    local methodName = "Фаза 1. Начало"
    mission.Log(methodName, "Устанавливаем stationId.")
    
    --Нельзя настроить это до вызова init, и это нужно, потому что иначе вы не сможете выйти из игры в середине миссии и ожидать, что диалог будет работать правильно после возвращения.
    mission.data.custom.stationId = mission.data.giver.id.string
end

mission.phases[1].onStartDialog = function(entityId)
    local methodName = "Фаза 1. Начало диалога"
    mission.Log(methodName, "Начинаем...")

    if entityId == Uuid(mission.data.custom.stationId) then

        local td0 = { text = "Вы когда-нибудь выполняли задание 'Исследовать сектор' раньше? Эта миссия работает точно так же, за исключением того, что вы будете сканировать Ксотан." }

        local td1 = { text = "Ксотан, которых вам нужно отсканировать, будут отмечены зеленым цветом. Подлетите к ним поближе, и вы сможете взаимодействовать с кораблем и запустить сканирование." }

        local td2 = { text = "Отсканируйте всех Ксотан, а мы позаботимся об остальном! Спасибо за вашу помощь!" }

        local td3 = { text = "Мы слышали, что Ксотан покинут сектор, если их оставить в покое. Возможно, вам придется спровоцировать их, чтобы они остались." }

        local td4 = { text = "Не стесняйтесь уничтожать некоторых из них, если вам нужно! Просто убедитесь, что вы сначала сделали сканирование! Опять же, те, кого вам нужно отсканировать, отмечены зеленым цветом." }

        local td5 = { text = "Удачной охоты!" }

        td0.followUp = td1
        td1.followUp = td2
        td2.answers = {
            { answer = "Понял." },
            { answer = "Это все?", followUp = td3 }
        }
        td3.followUp = td4
        td4.followUp = td5

        addDialogInteraction("Как мне сканировать Ксотан?", td0)
    end
end

mission.phases[1].onTargetLocationEntered = function(_X, _Y) 
    local _MethodName = "Фаза 1. Вход в целевую локацию"
    
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    if onServer() then
        scanXsotanGroup_spawnMissionSector()
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 1. Подтверждено прибытие в целевую локацию"
    mission.Log(_MethodName, "Начинаем...")

    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onPreRenderHud = function()
    scanXsotanGroup_onMarkScannableXsotan()
end

--region #PHASE 2 PLAYER CALLBACKS

if onServer() then

mission.phases[2].playerCallbacks = {
    {
		name = "onMissionXsotanScanned",
		func = function(_xid)
            local methodName = "Ксотан отсканирован в миссии"

            mission.Log(methodName, "Начинаем...")

            local xsotanScanned = false
			for _, _XsotanID in pairs(mission.data.custom.scannableXsotanShips) do
                if _XsotanID == _xid then
                    xsotanScanned = true
                    break
                end
            end

            if not xsotanScanned then return end

            mission.data.custom.scannedXsotan = mission.data.custom.scannedXsotan + 1

            --Если мы находимся внутри барьера и убили стража, Ксотан становятся агрессивными после сканирования определенного количества.
            if mission.data.custom.inBarrier and mission.data.custom.killedGuardian then
                mission.Log(methodName, "Определяем точку агрессии.")
                local xsotanAggroAfter = math.floor(mission.data.custom.scannedXsotanTgt / 2)
                if mission.data.custom.scannedXsotan >= xsotanAggroAfter then
                    mission.Log(methodName, "Отсканировано " .. tostring(mission.data.custom.scannedXsotan) .. " это больше или равно " .. tostring(xsotanAggroAfter) .. " - агрессия.")
                    scanXsotanGroup_aggroXsotan()
                end
            end

            mission.data.description[4].arguments = { _SCANNED = mission.data.custom.scannedXsotan , _SCANNEDMAX = mission.data.custom.scannedXsotanTgt }
            
            sync()
		end
	}
}

end

--endregion

--region #PHASE 2 TIMERS

--Мы должны проверять провал через таймеры, потому что Ксотан могут уйти в варп, если игрок не спровоцирует их.
--Технически нет необходимости проверять условие победы через таймеры, но эй. Почему бы и нет.
if onServer() then

mission.phases[2].timers[1] = {
    time = 5, 
    callback = function() 
        local methodName = "Фаза 2. Таймер 1. Обратный вызов"
        mission.Log(methodName, "Запускаем условие победы")

        if mission.data.custom.scannedXsotan >= mission.data.custom.scannedXsotanTgt then
            scanXsotanGroup_finishAndReward()
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 5, 
    callback = function() 
        local methodName = "Фаза 2. Таймер 2. Обратный вызов"
        mission.Log(methodName, "Запускаем условие провала")

        if atTargetLocation() then --Нет необходимости делать что-либо из этого, если мы не находимся в целевой локации.
            local remainingXsotanToScan = 0

            local xsotanShips = {Sector():getEntitiesByScriptValue("is_xsotan")}

            for _, xsotanShip in pairs(xsotanShips) do
                if xsotanShip:hasScript("player/missions/scanxsotan/scannablexsotan.lua") then
                    remainingXsotanToScan = remainingXsotanToScan + 1
                end
            end

            if mission.data.custom.scannedXsotan + remainingXsotanToScan < mission.data.custom.scannedXsotanTgt then
                mission.Log(methodName, "Недостаточно Ксотан осталось для сканирования - провал миссии.")
                scanXsotanGroup_failAndPunish()
            end
        end
    end,
    repeating = true
}

end

--endregion

--endregion

--region #SERVER CALLS

function scanXsotanGroup_spawnMissionSector()
    local methodName = "Spawn Mission Sector"
    mission.Log(methodName, "Начинаем...")

    --init
    mission.Log(methodName, "Инициализация значений")

    local _SpawnCount = mission.data.custom.spawnXsotanQty
    local rgen = ESCCUtil.getRand()
    local _Generator = SectorGenerator(Sector():getCoordinates())
    local _XsotanByNameTable = {}
    local _XsotanTable = {}

    --make some asteroid fields (maybe)
    mission.Log(methodName, "Создание астероидных полей")

    for _ = 1, 3 do
        if rgen:test(0.5) then
            _Generator:createSmallAsteroidField()
        end
    end

    --create xsotan spawn table
    mission.Log(methodName, "Создание таблицы спавна")

    local _QuantumChance = 0.1 * mission.data.custom.dangerLevel --Caps @ 100% @ DL 10
    local _SummonerChance = 0.025 * mission.data.custom.dangerLevel --Caps @ 25% @ DL 10
    local _SpecialXsotanChance = 0.01 * mission.data.custom.dangerLevel --Caps @ 10% @ DL 10
    local _WildcardXsotanChance = 0.015 * mission.data.custom.dangerLevel --Caps @ 15% @ DL 10

    if mission.data.custom.inBarrier then
        _QuantumChance = math.min(1.0, _QuantumChance * 2) --Caps @ 100% @ DL 5
        _SummonerChance = _SummonerChance * 2 --Caps @ 50% @ DL 10
        _SpecialXsotanChance = _SpecialXsotanChance * 2 --Caps @ 20% @ DL 10
        _WildcardXsotanChance = _WildcardXsotanChance * 2 --Caps @ 30% @ DL 10

        if mission.data.custom.killedGuardian then
            _QuantumChance = math.min(1.0, _QuantumChance * 2) --Caps @ 100% @ DL 3
            _SummonerChance = math.min(1.0, _SummonerChance * 2) --Caps @ 100% @ DL 10
            _SpecialXsotanChance = math.min(1.0, _SpecialXsotanChance * 2) --Caps @ 40% @ DL 10
            _WildcardXsotanChance = math.min(1.0, _WildcardXsotanChance * 2) --Caps @ 60% @ DL 10
        end
    end

    local _AddQuantum = rgen:test(_QuantumChance)
    local _AddSmn = rgen:test(_SummonerChance)
    local _AddSpecial = rgen:test(_SpecialXsotanChance)
    local _AddWildcard = rgen:test(_WildcardXsotanChance)

    if _AddQuantum then
        mission.Log(methodName, "Добавление Квантового Ксотана")
        table.insert(_XsotanByNameTable, "Quantum")
    end

    if _AddSmn then
        mission.Log(methodName, "Добавление Призывателя")
        table.insert(_XsotanByNameTable, "Summoner")
    end

    if _AddSpecial then
        mission.Log(methodName, "Добавление Особого Ксотана")
        table.insert(_XsotanByNameTable, "Special")
    end

    if _AddWildcard then
        mission.Log(methodName, "Добавление Ксотана-Джокера")
        table.insert(_XsotanByNameTable, getRandomEntry({ "Quantum", "Summoner", "Special" }))
    end

    for _ = 1, _SpawnCount - #_XsotanByNameTable do
        table.insert(_XsotanByNameTable, "Ship")
    end

    --spawn xsotan
    mission.Log(methodName, "Таблица спавна")

    for _ = 1, #_XsotanByNameTable do
        local _Xsotan = nil
        local _Dist = 1500
        if _XsotanByNameTable[_] == "Summoner" then
            _Xsotan = Xsotan.createSummoner(_Generator:getPositionInSector(_Dist), nil)
        elseif _XsotanByNameTable[_] == "Quantum" then
            _Xsotan = Xsotan.createQuantum(_Generator:getPositionInSector(_Dist), nil)
        elseif _XsotanByNameTable[_] == "Special" then
            local _XsotanFunction = getRandomEntry(Xsotan.getSpecialXsotanFunctions())

            _Xsotan = _XsotanFunction(_Generator:getPositionInSector(_Dist), nil)
        else
            _Xsotan = Xsotan.createShip(_Generator:getPositionInSector(_Dist), nil)
        end

        if _Xsotan then
            table.insert(_XsotanTable, _Xsotan)
        else
            mission.Log(_MethodName, "ОШИБКА - Xsotan был nil")
        end
    end

    SpawnUtility.addEnemyBuffs(_XsotanTable)

    --add scripts to appropirate xsotan and build data table
    mission.Log(methodName, "Добавление Ксотанов в таблицу сканируемых Ксотанов")

    shuffle(_XsotanTable)

    for idx = 1, mission.data.custom.scannedXsotanTgt do
        --mission.Log(methodName, "Marking idx " .. tostring(idx))
        local _Xsotan = _XsotanTable[idx]

        _Xsotan:addScriptOnce("player/missions/scanxsotan/scannablexsotan.lua")
        mission.data.custom.scannableXsotanShips[idx] = _Xsotan.id.string
    end

    Placer.resolveIntersections()
    
    mission.data.custom.cleanUpSector = true

    --sync
    mission.Log(methodName, "Синхронизация")

    sync()
end

function scanXsotanGroup_aggroXsotan()
    local _sector = Sector()
    local xsotan = {_sector:getEntitiesByScriptValue("is_xsotan")}
    local players = {_sector:getPlayers()}

    if not mission.data.custom.sentAggroWarning then
        _sector:broadcastChatMessage("", 3, "Ваши сканеры предупредили Ксотанов о вашем присутствии!")
        mission.data.custom.sentAggroWarning = true
    end

    for _, xso in pairs(xsotan) do
        if valid(xso) then
            local xsoAI = ShipAI(xso.id)
            for _, p in pairs(players) do
                xsoAI:registerEnemyFaction(p.index)
            end
            xsoAI:setAggressive()
        end
    end
end

function scanXsotanGroup_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Выполнение условия победы.")

    reward()
    accomplish()
end

function scanXsotanGroup_failAndPunish()
    local _MethodName = "Fail and Punish"
    mission.Log(_MethodName, "Выполнение условия проигрыша.")

    punish()
    fail()
end

--endregion

--region #CLIENT CALLS

function scanXsotanGroup_onMarkScannableXsotan()
    local _MethodName = "On Mark Scannable Xsotan"

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret or player.state == PlayerStateType.PhotoMode then return end

    local renderer = UIRenderer()

    local _sector = Sector()
    if mission.data.custom.scannableXsotanShips then
        for idx = 1, #mission.data.custom.scannableXsotanShips do
            local color = ColorRGB(0.2, 0.5, 0.2)
            local entity = _sector:getEntity(Uuid(mission.data.custom.scannableXsotanShips[idx]))
            if entity and entity:hasScript("player/missions/scanxsotan/scannablexsotan.lua") then
    
                local _, size = renderer:calculateEntityTargeter(entity)
    
                renderer:renderEntityTargeter(entity, color, size * 1.25)
                renderer:renderEntityArrow(entity, 30, 10, 250, color)
            end
        end
    end

    renderer:display()
end

--endregion

--region #MAKEBULLETIN CALLS

function scanXsotanGroup_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    if _Station.title == "Research Station" then
        descriptionType = descriptionType + 3
    end

    if _Station.title == "Resistance Outpost" then
        if random():test(0.5) then
            descriptionType = descriptionType + 3
        end
    end

    local descriptionTable = {
        "В (${x}:${y}) собирается группа Ксотанов. Мы ищем независимого капитана, чтобы отсканировать нескольких из них и узнать больше об их кораблях. Мы компенсируем вам вашу работу. Вы можете уничтожить их, если вам нужно - просто убедитесь, что сначала получили данные.", --Military Outpost Neutral
        "Древний воин однажды сказал, что если вы знаете себя и знаете себя, вам не нужно бояться исхода сотни битв. Нам нужно больше информации о Ксотанах. Группа их собирается в (${x}:${y}). Отсканируйте их корабли. Узнайте их слабости. Нам все равно, что вы с ними сделаете потом.", --Military Outpost Aggressive
        "Мир вам, капитан. Нам нужна ваша помощь. Ксотаны многое у нас забрали, но мы почти ничего не знаем о них взамен. Наши разведчики обнаружили группу странных кораблей, собирающихся в (${x}:${y}). Пожалуйста, отправляйтесь туда и отсканируйте их суда. Мирное решение идеально, но ваша безопасность превыше всего.", --Military Outpost Peaceful
        "Прошли сотни лет с тех пор, как пал Объединенный Альянс, но кажется, что мы почти ничего не знаем о странных инопланетянах, которые свергли вершину могущества галактики. Сегодня мы хотели бы это изменить. В (${x}:${y}) собираются Ксотаны. Мы заплатим вам за любые данные, которые вы сможете собрать с них.", --Research Lab Neutral
        "Нам давно интересно узнать об эффективности Ксотанов в бою. Их корабли часто меньше стандартных кораблей этого региона, но у них часто бывает чрезмерная огневая мощь по сравнению с их весовой категорией. Мы хотели бы выяснить, почему. В (${x}:${y}) есть Ксотаны. Отсканируйте их корабли, и мы разберемся с остальным.", --Research Lab Aggressive
        "Каждый раз, когда Ксотаны нападали на нас, происходила большая гибель людей. Возможно, мы сможем найти способ предотвратить это, но нам потребуется больше информации о том, какие они. Как они работают. Как они думают и чувствуют. В (${x}:${y}) собираются Ксотаны. Пожалуйста, отсканируйте их корабли и передайте нам данные." --Research Lab Peaceful
    }

    return descriptionTable[descriptionType]
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    mission.Log(_MethodName, "Начинаем...")

    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _Rgen = ESCCUtil.getRand()
    local _sector = Sector()
    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 2, 15, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x или Target.y не установлены - возвращаем nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)
    
    local _Description = scanXsotanGroup_formatDescription(_Station)

    local _Difficulty = "Средний"
    if _DangerLevel > 5 then
        _Difficulty = "Сложный"
    end

    local _BaseReward = 60000
    if _DangerLevel > 5 then
        _BaseReward = _BaseReward + 5000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    reward = _BaseReward * Balancing.GetSectorRewardFactor(_sector:getCoordinates()) --SET REWARD HERE

    missionReward = { credits = reward, relations = 4000, paymentMessage = "За сканирование Ксотанов заработано %1% кредитов." }

    local distToCenter = math.sqrt(x * x + y * y)
    local _MatlMin = 0 --7000
    local _MatlMax = 0 --8000
    if distToCenter > 400 then
        _MatlMin = 5000
        _MatlMax = 6000
    elseif distToCenter < 400 and distToCenter > 300 then
        _MatlMin = 10000
        _MatlMax = 12000
    else
        _MatlMin = 20000
        _MatlMax = 24000
    end
    
    mission.Log(_MethodName, "matlmin is ${MIN} and matlmax is ${MAX}" % { MIN = _MatlMin, MAX = _MatlMax }) 

    local materialAmount = round(random():getInt(_MatlMin, _MatlMax) / 100) * 100
    MissionUT.addSectorRewardMaterial(x, y, missionReward, materialAmount)

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission._Name,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/scanxsotangroup.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Ксотаны находятся в секторе \\s(%1%:%2%). Пожалуйста, отсканируйте их корабли.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],
        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = missionReward,
            punishment = { relations = 4000 },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            inBarrier = insideBarrier
        }},
    }

    return bulletin
end

--endregion
