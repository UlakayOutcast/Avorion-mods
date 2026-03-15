--[[
    Побочная миссия ранга 4.
    Доставка передовых материалов
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Игрок должен успешно завершить 3-ю сюжетную миссию (уничтожить пиратов + хорошая концовка, позволяющая выполнить 4-ю миссию — также мягкое требование ранга 3).
        - Игрок должен найти Аворион.
        - Игрок должен владеть собственным складом ресурсов.
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок направляется к ближайшему складу ресурсов (должен принадлежать игроку или альянсу).
        - Игрок создаёт груз Авориона за 5000 единиц.
        - Игроку приходит сообщение от Кавалеров с указанием встретиться в определённом месте.
        - Игрок встречается с контактным лицом Кавалеров и передаёт Аворион.
        - Базовое вознаграждение: 35.8 * 3 * 5000 (цена продажи Авориона на своём складе * 3 * 5000, так как игрок доставляет 5000 единиц Авориона).
        - Умножается на богатство сектора. Это может привести к абсурдно высоким выплатам, но это нормально.
    УРОВЕНЬ ОПАСНОСТИ:
        1+
        6 - [Эти условия действуют при уровне опасности 6 и выше]
            - 10% шанс на каждый уровень опасности (максимум 50% на уровне 10), что пиратам удастся провести атаку "человек посередине" против игрока и отправить ему ложные координаты.
            - Создание и использование таблицы высокой угрозы для спавна атаки, похожей на ложный сигнал бедствия.
        10 - [Эти условия действуют при уровне опасности 10]
            - Пиратская засада включает дополнительный флагман, а также два глушильщика.
            - Вторая волна из 5 пиратов появляется, когда флагман теряет 50% или меньше HP.
            - Да, возможно, что при уровне опасности 10 не выпадет атака, и игрок получит дополнительную репутацию просто так. Это нормально. Иногда можно дать игроку бонус.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-- Запуск остальных подключений.
include("callable")
include("randomext")
include("structuredmission")
include("stringutility")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")

local AsyncPirateGenerator = include("asyncpirategenerator")
local PirateGenerator = include("pirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Доставка передовых материалов"

mission.data.custom.locations = {}
mission.data.custom.wreckagePieceIds = {}

-- Настройка данных миссии
local llte_sidemission_init = initialize
function initialize()
    local _MethodName = "Инициализация"

    if onServer() then
        if not _restoring then
            local _Name = "Кавалеры"
            local _Faction = Galaxy():findFaction(_Name)

            -- У нас нет доступа к данным объявления миссии, поэтому определяем здесь.
            mission.data.brief = "Доставка передовых материалов"
            mission.data.title = "Доставка передовых материалов"
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.description = {
                "Кавалеры связались с вами и попросили доставить им передовые материалы.",
                { text = "Направляйтесь на склад ресурсов, принадлежащий вам, вашему альянсу или фракции, с которой вы в союзе", bulletPoint = true, fulfilled = false },
                { text = "Создайте и заберите груз передовых материалов", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Прочитайте письмо от Кавалеров", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Доставьте груз в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Вас застали в ловушку. Сбегите от атакующих пиратов или уничтожьте их", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Прочитайте второе письмо от Кавалеров", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Доставьте груз в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Передайте груз кораблю ${_SHIP}", bulletPoint = true, fulfilled = false, visible = false }
            }

            local _Rgen = ESCCUtil.getRand()

            -- 35.8 — это количество кредитов, которые вы получаете за продажу Авориона на своём складе ресурсов.
            -- 2 — стандартный множитель для миссий "нам срочно нужны ресурсы!". Нам нужно больше.
            -- 5000 — количество Авориона, которое игрок должен заплатить для выполнения миссии.
            local _RewardBase = 35.8 * 3 * 5000
            local _InitialMessage = "Спасибо! Мы свяжемся с вами, когда будем готовы забрать материалы."
            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .cavaliersindex
            -- .playerIsAttacked
            -- .deliveryLocation
            -- .commanderName
            -- .createdPirates
            -- .runAddShipment
            -- .freightername
            mission.data.custom.dangerLevel = _Rgen:getInt(1, 10)
            mission.data.custom.cavaliersindex = _Faction.index
            mission.data.custom.playerIsAttacked = false

            if mission.data.custom.dangerLevel >= 6 then
                local _PctChance = mission.data.custom.dangerLevel - 5
                local _Dice = _Rgen:getInt(1, 10)
                if _Dice <= _PctChance then
                    mission.Log(_MethodName, tostring(_Dice) .. " <= " .. tostring(_PctChance) .. " Игрока атакуют пираты.")
                    mission.data.custom.playerIsAttacked = true
                else
                    mission.Log(_MethodName, "Игрока не атакуют.")
                end
            end

            local _SectorFactor = Balancing.GetSectorRewardFactor(Sector():getCoordinates())
            local _SectorFactor = math.max(_SectorFactor / 2, 1)
            mission.Log(_MethodName, "Коэффициент сектора: " .. tostring(_SectorFactor))
            local missionReward = ESCCUtil.clampToNearest(_RewardBase * _SectorFactor, 5000, "Up")

            mission.Log(_MethodName, "Вознаграждение за миссию: " .. tostring(missionReward))

            missionData_in = {location = nil, reward = {credits = missionReward}}

            llte_sidemission_init(missionData_in)
            Player():sendChatMessage("Кавалеры", 0, _InitialMessage)
        else
            -- Восстановление
            llte_sidemission_init()
        end
    end

    if onClient() then
        if not _restoring then
            initialSync()
        else
            sync()
        end
    end
end

-- Вызов фаз миссии
mission.globalPhase.timers = {}
mission.globalPhase.onSectorEntered = function(_X, _Y)
    local _MethodName = "Глобальная фаза: вход в сектор"
    if mission.data.custom.runAddShipment then
        -- Запуск добавления груза каждый раз при входе в сектор после входа в фазу 2. Это сделано на случай, если игрок потеряет груз.
        addShipmentScript()
    end
end

mission.phases[1] = {}
mission.phases[1].triggers = {}
mission.phases[1].triggers[1] = {
    condition = function()
        local _MethodName = "Условие триггера фазы 1"
        -- Должно быть условие, которое проверяется постоянно, так как игрок может принять миссию внутри сектора, в котором есть склад ресурсов, соответствующий условиям.
        local _Stations = {Sector():getEntitiesByType(EntityType.Station)}
        local _Return = false
        for _, _Station in pairs(_Stations) do
            local _Player = Player()
            local _HasRefinery = _Station:hasScript("refinery.lua")
            local _OwnedByPlayer = _Station.factionIndex == _Player.index or _Station.factionIndex == _Player.allianceIndex
            local _AlliedDepot = _OwnedByPlayer

            if not _OwnedByPlayer then
                -- Проверяем, есть ли у игрока (НЕ у альянса игрока) союз с этой фракцией. Если да, то этот склад подходит.
                local _Faction = Faction(_Station.factionIndex)
                local _Relation = _Player:getRelation(_Faction.index)
                _AlliedDepot = _Relation.status == RelationStatus.Allies
            end

            if _HasRefinery and _AlliedDepot then
                _Return = true
            end
        end

        return _Return
    end,
    callback = function()
        nextPhase()
    end,
    repeating = false
}
mission.phases[1].showUpdateOnEnd = true

mission.phases[2] = {}
mission.phases[2].playerEntityCallbacks = {}
mission.phases[2].playerEntityCallbacks[1] = {
    name = "onCargoChanged",
    func = function(_ObjectIndex, _Delta, _Good)
        -- Это, с другой стороны, можно сделать с помощью обратного вызова.
        if _Good.name == "Avorion Shipment" and _Delta > 0 then
            nextPhase()
        end
    end
}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBeginServer = function()
    local _MethodName = "Фаза 2: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
    addShipmentScript()
    mission.data.custom.runAddShipment = true
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
    mission.data.custom.deliveryLocation = getNextLocation(true)
    mission.data.custom.commanderName = LLTEUtil.getHumanFullName()

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _CommanderName = mission.data.custom.commanderName
    local _X, _Y = mission.data.custom.deliveryLocation.x, mission.data.custom.deliveryLocation.y

    mission.Log(_MethodName, "Аргументы - ранг: " .. tostring(_Rank) .. ", имя: " .. tostring(_Player.name) .. ", _X: " .. tostring(_X) .. ", _Y: " .. tostring(_Y) .. ", Командир: " .. tostring(_CommanderName))

    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nМы готовы забрать груз, когда вы будете готовы его доставить. Привезите его в сектор (%3%:%4%), и мы встретим вас там.\nДа здравствует Императрица!\n\nКомандир %5%", _Rank, _Player.name, _X, _Y, _CommanderName)
    _Mail.header = "Место получения"
    _Mail.sender = Format("Командир %1% @Кавалеры", _CommanderName)
    _Mail.id = "_llte_side6_mail1"
    _Player:addMail(_Mail)
end

mission.phases[3].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_side6_mail1" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[4] = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].noBossEncountersTargetSector = true
mission.phases[4].onBeginServer = function()
    local _MethodName = "Фаза 4: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.deliveryLocation
    mission.data.description[4].fulfilled = true
    mission.data.description[5].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[5].visible = true
end

mission.phases[4].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 4: вход в целевой сектор"
    if mission.data.custom.playerIsAttacked then
        mission.Log(_MethodName, "Игрока атакуют — переход к следующей фазе и спавн пиратов.")
        -- Спавн пиратов.
        nextPhase()
    else
        mission.Log(_MethodName, "Игрока не атакуют — спавн Кавалеров.")
        -- Спавн Кавалеров
        spawnCavaliers()
    end
end

mission.phases[5] = {}
mission.phases[5].triggers = {}
mission.phases[5].triggers[1] = {
    condition = function()
        return mission.data.custom.createdPirates and ESCCUtil.countEntitiesByValue("is_pirate") == 0
    end,
    callback = function()
        nextPhase()
    end,
    repeating = false
}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].onBeginServer = function()
    local _MethodName = "Фаза 5: начало на сервере"
    mission.data.description[5].fulfilled = true
    mission.data.description[6].visible = true
    spawnPirates()
    if mission.data.custom.dangerLevel == 10 then
        mission.phases[5].triggers[2] = {
            condition = function()
                local _MotherShipTable = {Sector():getEntitiesByScriptValue("is_mothership")}

                if #_MotherShipTable == 0 then
                    return true
                else
                    local _MotherShip = _MotherShipTable[1]
                    if _MotherShip then
                        local _Ratio = _MotherShip.durability / _MotherShip.maxDurability

                        return _Ratio <= 0.5
                    end
                end

                return false
            end,
            callback = function()
                spawnSecondPirateWave()
            end,
            repeating = false
        }
    end
end

mission.phases[6] = {}
mission.phases[6].showUpdateOnEnd = true
mission.phases[6].onBeginServer = function()
    local _MethodName = "Фаза 6: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[6].fulfilled = true
    mission.data.description[7].visible = true
    mission.data.custom.secondDeliveryLocation = getNextLocation(false)

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _CommanderName = mission.data.custom.commanderName
    local _RealCommanderName = LLTEUtil.getHumanFullName()
    local _X, _Y = mission.data.custom.deliveryLocation.x, mission.data.custom.deliveryLocation.y
    local _MX, _MY = mission.data.custom.secondDeliveryLocation.x, mission.data.custom.secondDeliveryLocation.y

    local _Mail = Mail()
    _Mail.text = Format("%1% %2%!\n\nНедавно мне стало известно, что вы получили сообщение от '%5%' относительно груза Авориона. Это тревожно — я проверил наши записи, и %5% никогда не был связан с Кавалерами. НЕ НАПРАВЛЯЙТЕСЬ В (%3%:%4%) — повторяю — НЕ НАПРАВЛЯЙТЕСЬ В (%3%:%4%)!!!\n\nДоставьте груз в (%6%:%7%) вместо этого.\nДа здравствует Императрица!\n\nКомандир %8%", _Rank, _Player.name, _X, _Y, _CommanderName, _MX, _MY, _RealCommanderName)
    _Mail.header = Format("Внимание: %1% — ИГНОРИРУЙТЕ предыдущее письмо", _Player.name)
    _Mail.sender = Format("Командир %1% @Кавалеры", _RealCommanderName)
    _Mail.id = "_llte_side6_mail2"
    _Player:addMail(_Mail)
end

mission.phases[6].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_side6_mail2" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[7] = {}
mission.phases[7].showUpdateOnEnd = true
mission.phases[7].onBeginServer = function()
    local _MethodName = "Фаза 7: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.secondDeliveryLocation
    mission.data.description[7].fulfilled = true
    mission.data.description[8].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[8].visible = true
end

mission.phases[7].onTargetLocationEntered = function(_X, _Y)
    spawnCavaliers()
end

-- Вызов серверных функций
function spawnPirates()
    local _MethodName = "Спавн пиратов"
    if not mission.data.custom.createdPirates then
        -- Спавн 7 пиратов.
        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 7, "High")
        local _CreatedPirateTable = {}
        -- Если уровень опасности 10, спавн 2 глушильщиков и флагмана.
        if mission.data.custom.dangerLevel == 10 then
            table.insert(_PirateTable, "Jammer")
            table.insert(_PirateTable, "Jammer")
            table.insert(_PirateTable, "Boss")
        end

        shuffle(random(), _PirateTable)

        for _, _P in pairs(_PirateTable) do
            local _NextPirate = PirateGenerator.createPirateByName(_P, PirateGenerator.getGenericPosition())
            _NextPirate:addScript("player/missions/empress/side/side6/llteside6pirate.lua")
            if _P == "Boss" then
                _NextPirate:setValue("is_mothership", true)
            end
            table.insert(_CreatedPirateTable, _NextPirate)
        end
        _CreatedPirateTable[1]:addScript("player/missions/empress/side/side6/llteside6ambushleader.lua")

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)
        mission.data.custom.createdPirates = true
    end
end

function spawnSecondPirateWave()
    local _MethodName = "Спавн второй волны пиратов"
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 5, "High")

    shuffle(random(), _PirateTable)

    local _Generator = AsyncPirateGenerator(nil, onSecondWaveFinished)
    _Generator.pirateLevel = PirateGenerator.pirateLevel

    _Generator:startBatch()

    local posCounter = 1
    local distance = 250

    local pirate_positions = _Generator:getStandardPositions(#_PirateTable, distance)
    for _, _P in pairs(_PirateTable) do
        _Generator:createScaledPirateByName(_P, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    _Generator:endBatch()
end

function onSecondWaveFinished(_Generated)
    local _MethodName = "Вторая волна пиратов создана (Сервер)"
    mission.Log(_MethodName, "Начало...")

    SpawnUtility.addEnemyBuffs(_Generated)

    mission.Log(_MethodName, "Трансляция угроз пиратов в сектор")
    mission.Log(_MethodName, "Объект: " .. tostring(_Generated[1].name))

    local _Lines = {
        "Ты далеко от дома, не так ли?",
        "Мы разорвём тебя на части!",
        "Все корабли, оружие на полную мощность! Атакуйте! Атакуйте! Атакуйте!",
        "Убейте их всех! Ха-ха-ха!"
    }

    Sector():broadcastChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(_Lines))
end

function addShipmentScript()
    local _MethodName = "Добавление скрипта груза"
    mission.Log(_MethodName, "Начало...")
    local _Stations = {Sector():getEntitiesByType(EntityType.Station)}
    for _, _Station in pairs(_Stations) do
        mission.Log(_MethodName, "Проверка " .. tostring(_Station.name))
        local _Player = Player()
        local _HasRefinery = _Station:hasScript("refinery.lua")
        local _OwnedByPlayer = _Station.factionIndex == _Player.index or _Station.factionIndex == _Player.allianceIndex
        local _HasGetShipment = _Station:hasScript("llteside6getshipment.lua")
        local _AlliedDepot = _OwnedByPlayer

        if not _OwnedByPlayer then
            -- Проверяем, есть ли у игрока (НЕ у альянса игрока) союз с этой фракцией. Если да, то этот склад подходит.
            local _Faction = Faction(_Station.factionIndex)
            local _Relation = _Player:getRelation(_Faction.index)
            _AlliedDepot = _Relation.status == RelationStatus.Allies
        end

        mission.Log(_MethodName, "Есть переработчик: " .. tostring(_HasRefinery) .. " | Союзник игрока: " .. tostring(_AlliedDepot) .. " | Есть скрипт получения груза: " .. tostring(_HasGetShipment))

        if _HasRefinery and _AlliedDepot and not _HasGetShipment then
            _Station:addScriptOnce("player/missions/empress/side/side6/llteside6buildshipment.lua")
        end
    end
end

function spawnCavaliers()
    -- Создание защитников
    local shipGenerator = AsyncShipGenerator(nil, onDefendersFinished)
    local _Faction = Faction(mission.data.custom.cavaliersindex)
    local _X, _Y = Sector():getCoordinates()

    shipGenerator:startBatch()

    shipGenerator:createDefender(_Faction, shipGenerator:getGenericPosition())
    shipGenerator:createDefender(_Faction, shipGenerator:getGenericPosition())

    shipGenerator:endBatch()

    -- Создание грузового корабля.
    local cavFreighterVolume = Balancing_GetSectorShipVolume(_X, _Y) * 8
    local shipGenerator2 = AsyncShipGenerator(nil, onFreighterFinished)

    shipGenerator2:startBatch()

    shipGenerator2:createFreighterShip(_Faction, shipGenerator2:getGenericPosition(), cavFreighterVolume)

    shipGenerator2:endBatch()
end

function onFreighterFinished(_Generated)
    local _MethodName = "Грузовой корабль создан"
    mission.Log(_MethodName, "Начало...")

    for _, ship in pairs(_Generated) do
        ship.name = LLTEUtil.getFreighterName()
        ship.title = "Кавалеры: " .. ship.title
        ship:removeScript("civilship.lua")
        ship:removeScript("dialogs/storyhints.lua")
        ship:setValue("_llte_escort_mission_freighter", true)
        ship:setValue("is_civil", nil)
        ship:setValue("npc_chatter", nil)
        ship:setValue("is_freighter", nil)
        ship:setValue("is_cavaliers", true)

        local _WithdrawData = {
            _Threshold = 0.8,
            _MinTime = 1,
            _MaxTime = 1,
            _Invincibility = 0.02
        }

        ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        ship:addScript("player/missions/empress/side/side6/llteside6giveshipment.lua")
        MissionUT.deleteOnPlayersLeft(ship)

        mission.data.custom.freightername = ship.name
    end

    mission.data.description[5].fulfilled = true
    mission.data.description[8].fulfilled = true
    mission.data.description[9].arguments = { _SHIP = mission.data.custom.freightername }
    mission.data.description[9].visible = true

    sync()
end

function onDefendersFinished(_Generated)
    local _MethodName = "Защитники созданы"
    mission.Log(_MethodName, "Начало...")

    for _, ship in pairs(_Generated) do
        ship.title = "Кавалеры: " .. ship.title
        ship:removeScript("antismuggle.lua")
        ship:setValue("npc_chatter", nil)
        ship:setValue("is_cavaliers", true)

        local _WithdrawData = {
            _Threshold = 0.8,
            _MinTime = 1,
            _MaxTime = 1,
            _Invincibility = 0.02
        }

        ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        MissionUT.deleteOnPlayersLeft(ship)
    end
end

function getNextLocation(_FirstLocation)
    local _MethodName = "Получение следующего местоположения"

    mission.Log(_MethodName, "Получение местоположения.")
    local x, y = Sector():getCoordinates()
    local target = {}
    local _inBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    local _stayInBarrier = false -- По умолчанию выходим за барьер, но если уже внутри, то не важно.
    if _inBarrier then
        _stayInBarrier = nil
    end

    if _FirstLocation then
        -- Получаем сектор, который находится далеко от текущего.
        target.x, target.y = MissionUT.getSector(x, y, 12, 20, false, false, false, false, _stayInBarrier)
    else
        target.x, target.y = MissionUT.getSector(x, y, 3, 5, false, false, false, false, _stayInBarrier)
    end

    return target
end

function finishMission()
    local _MethodName = "Завершение миссии"
    if onClient() then
        mission.Log(_MethodName, "Вызов на [Клиенте]")
        mission.Log(_MethodName, "Вызов на сервере")

        invokeServerFunction("finishMission")
    else
        mission.Log(_MethodName, "Вызов на [Сервере]")

        local _Ships = {Sector():getEntitiesByScriptValue("is_cavaliers")}
        local _Rgen = ESCCUtil.getRand()
        for _, _S in pairs(_Ships) do
            _S:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
        end
        llteSide6_finishAndReward()
    end
end
callable(nil, "finishMission")

function llteSide6_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()

    local _WinMsgTable = {
        "Императрица будет рада услышать об этом.",
        "Спасибо за то, что сделали галактику безопаснее.",
        "Ваша поддержка, как всегда, ценна.",
        "Потрясающая работа, " .. _Player.name .. "!",
        "Отличная работа, " .. _Rank .. "!"
    }

    _Player:setValue("_llte_cavaliers_have_avorion", true)
    local _Strength = _Player:getValue("_llte_cavaliers_strength") or 0
    _Strength = math.min(_Strength + 1, 5)
    _Player:setValue("_llte_cavaliers_strength", _Strength)

    local _RepReward = 4
    if mission.data.custom.dangerLevel == 10 then
        _RepReward = _RepReward + 1
    end

    -- Увеличение репутации на 4 (5 при уровне опасности 10)
    mission.data.reward.paymentMessage = "Получено %1% кредитов за доставку материалов."
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + _RepReward)
    _Player:sendChatMessage("Кавалеры", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Мы перевели вознаграждение на ваш счёт.")
    reward()
    accomplish()
end

--endregion