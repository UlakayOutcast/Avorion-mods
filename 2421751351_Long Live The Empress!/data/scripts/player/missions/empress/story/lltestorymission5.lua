--[[
    Сюжетная миссия 5.
    Да здравствует Императрица
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ЭТОЙ МИССИИ:
        - Сюжетная миссия 4 выполнена
        - Ранг у Кавалеров 4
        - Сила Кавалеров 2 (Выполнено 2 миссии по улучшению арсенала)
        - Все остальные предварительные условия для битвы с Хранителем выполнены.
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок читает письмо от Адрианы
        - Идёт в место, указанное в письме
        - Диалог с Адрианой - заканчивается вариантами "да/нет".
        - Если игрок говорит "да", появляется XWG после диалога. Сделать его слабой версией XWG, которая не может использовать силу чёрной дыры.
        - Делаем всё, что делает XWG. Он прыгает после потери 75% здоровья.
        - Если игрок говорит "нет", то ничего не происходит. - Адриана просто говорит: "Хорошо, я доверяю тебе. Сообщи, если передумаешь."
            - Она будет ждать в секторе до конца миссии.
        - Если игрок сражается с XWG после того, как тот прыгнул, начинаем с 75% здоровья.
        - В любом случае, игрок побеждает, когда побеждает Хранителя.
    УРОВЕНЬ ОПАСНОСТИ:
        - 5+ Миссия начинается с уровня опасности 5. Это фиксированное значение, так как это неповторяемая* сюжетная миссия.
            - Без изменений в стандартных сюжетных вещах, кроме того, что описано выше.

        * - Технически. Игрок всегда может покинуть миссию и начать заново.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-- Запуск остальных подключений.
include("callable")
include("randomext")
include("structuredmission")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")

local PirateGenerator = include("pirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Xsotan = include("story/xsotan")

mission._Debug = 0
mission._Name = "Да здравствует Императрица"

-- Инициализация
local llte_storymission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Да здравствует Императрица'...")

    if onServer() then
        if not _restoring then
            -- Стандартные данные миссии.
            mission.data.brief = mission._Name
            mission.data.title = mission._Name
            mission.data.autoTrackMission = true
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.priority = 9
            mission.data.description = {
                "Когда вы решите сразиться с Хранителем, Кавалеры готовы встать с вами плечом к плечу.",
                { text = "Прочитайте письмо от Адрианы", bulletPoint = true, fulfilled = false },
                -- Если в каком-либо из этих пунктов есть координаты X/Y, они будут обновлены с правильным местоположением при начале соответствующей фазы.
                { text = "Встретьтесь с Адрианой в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Уничтожьте Хранителя", bulletPoint = true, fulfilled = false, visible = false }
            }

            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .sector1
            -- .defeatedGuardian
            -- .reducedGuardian
            -- .empressBladeid
            -- .capitalsSpawned
            mission.data.custom.dangerLevel = 10 -- Это сюжетная миссия, поэтому мы держим всё предсказуемым.

            local missionReward = 1500000

            missionData_in = {location = nil, reward = {credits = missionReward}}

            llte_storymission_init(missionData_in)
        else
            -- Восстановление
            llte_storymission_init()
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
mission.globalPhase.triggers = {}

mission.globalPhase.onEntityDestroyed = function(_Index)
    local _MethodName = "Объект уничтожен"
    mission.Log(_MethodName, "Объект уничтожен.")
    if onServer() then
        local entity = Entity(_Index)
        if entity:hasScript("data/scripts/entity/story/wormholeguardian.lua") then
            llteStory5_finishAndReward()
        end
    end
end

mission.globalPhase.onAccomplish = function()
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Mail = Mail()
    if mission.data.custom.defeatedGuardian then
        _Mail.text = Format("%1% %2%!\n\nКогда нам удалось сломить группу пиратов, я думала, что мы достигли чего-то грандиозного. Однако, это меркнет по сравнению с тем, что мы достигли сегодня.\n\nРаны Галактики не затянутся сразу, но с поражением Ксотан и нашими продолжающимися усилиями по подавлению пиратства у нас есть шанс установить прочный и долговременный мир.\n\nСпасибо за всё, %2%. Было честью и привилегией сражаться рядом с вами. Желаю вам успехов в ваших будущих приключениях, %1%!\n\nИмператрица Адриана Сталь", _Rank, _Player.name)
    else
        _Mail.text = Format("%1% %2%!\n\nКогда нам удалось сломить группу пиратов, я думала, что мы достигли чего-то грандиозного. Однако, это меркнет по сравнению с тем, что вы достигли сегодня.\n\nРаны Галактики не затянутся сразу, но благодаря вашему поражению Ксотан и нашим продолжающимся усилиям по подавлению пиратства у нас есть шанс установить прочный и долговременный мир.\n\nСпасибо за всё, %2%. Желаю вам успехов в ваших будущих приключениях, %1%!\n\nИмператрица Адриана Сталь", _Rank, _Player.name)
    end
    _Mail.header = "Мир, наконец-то"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story5_mailwin"

    local _LMTCS = SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), Seed(1))
    _Mail:addItem(_LMTCS)

    _Player:addMail(_Mail)
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.sector1 = getNextLocation(1)
    local _X, _Y = mission.data.custom.sector1.x, mission.data.custom.sector1.y

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nЯ уверена, что вы уже знаете это, но в центре галактики вот уже 200 лет существует сила сопротивления, сражающаяся с Ксотан! Мы сами столкнулись с ними, когда имели дело с пиратами, нападавшими на местную фракцию. Они сказали нам, что Ксотан охраняют что-то в центре галактики, и не могут приблизиться из-за количества Ксотан. Каждая их попытка закончилась провалом!\n\nЕсли бы мы могли только выяснить, что они охраняют... это могло бы стать нашим шансом! Это могло бы стать нашим шансом победить Ксотан и принести истинный мир в галактику.\nЯ думала об артефакте, который мы нашли, когда путешествовали к центру галактики, и у меня есть план! Если вы хотите нашей помощи в борьбе с Ксотан, мы готовы! Приходите к нам в (%3%:%4%).\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _X, _Y)
    _Mail.header = "Победа над Ксотан"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story5_mail1"
    _Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            local _MethodName = "Фаза 1: письмо прочитано"
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story5_mail1" then
                    mission.Log(_MethodName, "Игрок прочитал " .. tostring(_Mail.id))
                    Player():setValue("encyclopedia_llte_xsotan_artifact_contd_found", true)
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].triggers = {}
mission.phases[2].triggers[1] = {
    condition = function()
        if onServer() then
            return true
        else
            if mission.data.custom.empressBladeid and Entity(mission.data.custom.empressBladeid) then
                local _ScriptUI = ScriptUI(mission.data.custom.empressBladeid)
                return _ScriptUI ~= nil
            else
                return false
            end
        end
    end,
    callback = function()
        if onClient() then
            onPhase2Dialog(mission.data.custom.empressBladeid)
        end
    end,
    repeating = false
}
mission.phases[2].triggers[2] = {
    condition = function()
        if onClient() then
            return true
        else
            local _Guardian = {Sector():getEntitiesByScript("player/missions/empress/story/story5/weakwormholeguardian.lua")}

            if #_Guardian > 0 then
                local _HPRatio = _Guardian[1].durability / _Guardian[1].maxDurability
                if _HPRatio <= 0.75 then
                    return true
                end
            end

            return false
        end
    end,
    callback = function()
        if onServer() then
            local _Sector = Sector()
            local _Guardian = {_Sector:getEntitiesByScript("player/missions/empress/story/story5/weakwormholeguardian.lua")}

            ESCCUtil.allXsotanDepart()
            _Sector:deleteEntityJumped(_Guardian[1])
            mission.data.custom.defeatedGuardian = true
            nextPhase()
        end
    end,
    repeating = false
}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].onBeginServer = function()
    local _MethodName = "Фаза 2: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.sector1
    mission.data.description[2].fulfilled = true
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[3].visible = true
    mission.data.description[4].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 2: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.capitalsSpawned then
        local _EmpressBlade = LLTEUtil.spawnBladeOfEmpress(false)
        mission.data.custom.empressBladeid = _EmpressBlade.id
        mission.data.custom.capitalsSpawned = true
    end
end

mission.phases[2].onAbandon = function()
    if mission.data.location then
        runFullSectorCleanup_llte()
    end
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = { x = 0, y = 0 }
    mission.data.description[3].fulfilled = true
    if not Entity(mission.data.custom.empressBladeid) then
        -- В (редком) случае, если Клинок Императрицы был вытолкнут из сектора из-за повреждений, отправить письмо с указанием игроку направиться в 0:0
        local _Player = Player()
        local _Rank = _Player:getValue("_llte_cavaliers_rank")
        local _Mail = Mail()
        _Mail.text = Format("%1% %2%!\n\nЧто это было? Это то, что Ксотан охраняют в центре галактики?\nОно исчезло с наших сканеров, так что, похоже, вам удалось выгнать его из сектора! Если оно на бегах, мы можем его добить! Направляйтесь в центр галактики! Я собираю остальной флот.\n\nИмператрица Адриана Сталь", _Rank, _Player.name)
        _Mail.header = "Направляйтесь в центр!"
        _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
        _Mail.id = "_llte_story5_mail2"
        _Player:addMail(_Mail)
    end
end

mission.phases[3].onBeginClient = function()
    local _MethodName = "Фаза 3: начало на клиенте"
    if Entity(mission.data.custom.empressBladeid) then
        onPhase3Dialog(mission.data.custom.empressBladeid)
    end
end

mission.phases[3].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 3: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    mission.phases[3].timers[1] = {
        time = 20,
        callback = function()
            -- возрождение Клинка Императрицы.
            local _EmpressBlade = LLTEUtil.spawnBladeOfEmpress(false)
            MissionUT.deleteOnPlayersLeft(_EmpressBlade)
            mission.data.custom.empressBladeid = _EmpressBlade.id
            local _AI = ShipAI(_EmpressBlade)
            _AI:setAggressive()

            -- спавн 3 обычных и 3 тяжёлых защитников.
            spawnCavalierShips(3, 3)

            -- настройка другого таймера для возрождения кораблей Кавалеров по мере необходимости.
            mission.phases[3].timers[2] = {
                time = 120,
                callback = function()
                    local _Sector = Sector()
                    local _X, _Y = _Sector:getCoordinates()
                    if _X ~= 0 or _Y ~= 0 then
                        return
                    end

                    local _EmpressBlade = ESCCUtil.countEntitiesByValue("_llte_empressblade")
                    if _EmpressBlade == 0 then
                        local _EmpressBlade = LLTEUtil.spawnBladeOfEmpress(false)
                        MissionUT.deleteOnPlayersLeft(_EmpressBlade)
                        mission.data.custom.empressBladeid = _EmpressBlade.id
                        local _AI = ShipAI(_EmpressBlade)
                        _AI:setAggressive()
                    end

                    local _Defenders = 0
                    local _HeavyDefenders = 0
                    local _CavShips = {Sector():getEntitiesByScriptValue("is_cavaliers")}
                    for _, _Cav in pairs(_CavShips) do
                        if _Cav:getValue("is_defender") then
                            if _Cav:getValue("is_heavy_defender") then
                                _HeavyDefenders = _HeavyDefenders + 1
                            else
                                _Defenders = _Defenders + 1
                            end
                        end
                    end
                    local _D2S = math.max(3 - _Defenders, 0)
                    local _HD2S = math.max(3 - _HeavyDefenders, 0)
                    mission.Log(_MethodName, "Спавн " .. tostring(_D2S) .. " защитников и " .. tostring(_HD2S) .. " тяжёлых защитников.")
                    spawnCavalierShips(_D2S, _HD2S)
                end,
                repeating = true
            }

            -- трансляция сообщения от Клинка Императрицы.
            local _Player = Player()
            local _PlayerName = _Player.name

            broadcastEmpressBladeMsg("Мы с вами, " .. _PlayerName .. "! Все корабли, атакуйте Ксотан!")
        end,
        repeating = false
    }
end

-- Вызов серверных функций
function getNextLocation(_Location)
    local _MethodName = "Получение следующего местоположения"

    mission.Log(_MethodName, "Получение местоположения.")
    local x, y = Sector():getCoordinates()
    local target = {}

    local _NxTable = {
        { _RingPos = 20, _InBarrier = true }
    }

    local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, _NxTable[_Location]._RingPos)
    target.x, target.y = MissionUT.getSector(_Nx, _Ny, 1, 4, false, false, false, false, _NxTable[_Location]._InBarrier)

    if target == nil or target.x == nil or target.y == nil then
        print("Не удалось получить местоположение - активация резервного варианта")
        target.x, target.y = MissionUT.getSector(x, y, 1, 20, false, false, false, false, _NxTable[_Location]._InBarrier)
    end

    return target
end

function spawnCavalierShips(_Defenders, _HeavyDefenders)
    local _Faction = Galaxy():findFaction("Кавалеры")
    local _Generator = AsyncShipGenerator(nil, onCavaliersFinished)
    _Generator:startBatch()

    if _Defenders > 0 then
        for _ = 1, _Defenders do
            _Generator:createDefender(_Faction, PirateGenerator.getGenericPosition())
        end
    end

    if _HeavyDefenders > 0 then
        for _ = 1, _HeavyDefenders do
            _Generator:createHeavyDefender(_Faction, PirateGenerator.getGenericPosition())
        end
    end

    _Generator:endBatch()
end

function onCavaliersFinished(_Generated)
    local _MethodName = "Кавалеры созданы"
    for _, _S in pairs(_Generated) do
        _S.title = "Кавалеры: " .. _S.title
        _S:setValue("npc_chatter", nil)
        _S:setValue("is_cavaliers", true)

        local _WithdrawData = {
            _Threshold = 0.15
        }

        _S:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        _S:removeScript("antismuggle.lua")
        LLTEUtil.rebuildShipWeapons(_S, Player():getValue("_llte_cavaliers_strength"))

        _S:addScript("entity/story/wormholeguardianally.lua")
        MissionUT.deleteOnPlayersLeft(_S)
        local _AI = ShipAI(_S)
        _AI:setAggressive()
    end
end

function broadcastEmpressBladeMsg(_Msg, ...)
    local _Sector = Sector()
    local _EmpressBlade = {_Sector:getEntitiesByScriptValue("_llte_empressblade")}
    _Sector:broadcastChatMessage(_EmpressBlade[1], ChatMessageType.Normal, _Msg, ...)
end

function runFullSectorCleanup_llte()
    local _X, _Y = Sector():getCoordinates()
    if _X == mission.data.location.x and _Y == mission.data.location.y then
        local _EntityTypes = ESCCUtil.allEntityTypes()
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
    else
        local _MX, _MY = mission.data.location.x, mission.data.location.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true, true)
    end
end

function llteStory5_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Name = _Player.name
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()

    local _WinMsgTable = {
        "Это оно, " .. _Name .. "! Мы сделали это! Мы победили Ксотан!"
    }

    _Player:setValue("_llte_story_5_accomplished", true)

    -- Увеличение репутации на 8
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + 8)
    _Player:sendChatMessage("Адриана Сталь", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)])
    reward()
    accomplish()
end

-- Вызов клиентских функций
function onPhase2Dialog(_ID)
    -- В начале миссии.
    local _MethodName = "Диалог фазы 2"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

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

    local _Talker = "Адриана Сталь"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    local _Talker2 = "Исследования"
    local _TalkerColor2 = ESCCUtil.getSaneColor(60, 100, 60)
    local _TextColor2 = ESCCUtil.getSaneColor(60, 100, 60)

    local _Player = Player()
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")
    local _PlayerName = _Player.name

    -- d0
    d0.text = _PlayerRank .. " " .. _PlayerName .. "! Рада видеть вас снова!"
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor
    d0.followUp = d1

    d1.text = "Когда будете готовы начать прорыв к центру, Кавалеры готовы сражаться с вами! Просто скажите слово, и мы будем там."
    d1.talker = _Talker
    d1.textColor = _TextColor
    d1.talkerColor = _TalkerColor
    d1.answers = {
        { answer = "Давайте начнём. Вы говорили, что у вас есть план?", followUp = d3 },
        { answer = "Спасибо, но я справлюсь сам.", followUp = d2 }
    }

    d2.text = "Хорошо! Я буду здесь, если передумаете. Делайте нас гордыми, " .. _PlayerRank .. "!"
    d2.talker = _Talker
    d2.textColor = _TextColor
    d2.talkerColor = _TalkerColor
    d2.onEnd = "onPhase2DialogEndNo"

    d3.text = "Да! Я говорила с нашей исследовательской командой об артефакте. Мы думаем, что можем настроить его, чтобы привлечь некоторых Ксотан-"
    d3.talker = _Talker
    d3.textColor = _TextColor
    d3.talkerColor = _TalkerColor
    d3.followUp = d4

    d4.text = "Исследовательский отсек? Это мост. У нас колебания мощности в вашей зоне и в ангаре. Вы проводите какие-то тесты?"
    d4.talker = _Talker
    d4.textColor = _TextColor
    d4.talkerColor = _TalkerColor
    d4.followUp = d5

    d5.text = "Насколько я знаю, мост. Дайте мне проверить-"
    d5.talker = _Talker2
    d5.textColor = _TextColor2
    d5.talkerColor = _TalkerColor2
    d5.followUp = d6

    d6.text = "Что там происходит? Колебания распространяются по всему кораблю!"
    d6.talker = _Talker
    d6.textColor = _TextColor
    d6.talkerColor = _TalkerColor
    d6.followUp = d7

    d7.text = "Эм... Я не знаю... дайте секунду. Мы исследовали артефакт, только начали сканирование и..."
    d7.talker = _Talker2
    d7.textColor = _TextColor2
    d7.talkerColor = _TalkerColor2
    d7.followUp = d8

    d8.text = "Показания подпространства зашкаливают! Что вы наделали?!"
    d8.talker = _Talker
    d8.textColor = _TextColor
    d8.talkerColor = _TalkerColor
    d8.followUp = d9

    d9.text = "Артефакт активировался сам! Мы не знаем, что он делает! Вы должны отключить питание исследовательских отсеков!"
    d9.talker = _Talker2
    d9.textColor = _TextColor2
    d9.talkerColor = _TalkerColor2
    d9.followUp = d10

    d10.text = "... Мост всем станциям! Начинаем процедуры экстренного отключения!"
    d10.talker = _Talker
    d10.textColor = _TextColor
    d10.talkerColor = _TalkerColor
    d10.followUp = d11

    d11.text = "ОТКЛЮЧИТЕ ЕГО!"
    d11.talker = _Talker2
    d11.textColor = _TextColor2
    d11.talkerColor = _TalkerColor2
    d11.onEnd = "onPhase2DialogEndYes"

    ScriptUI(_ID):interactShowDialog(d0, false)
end

function onPhase3Dialog(_ID)
    local _MethodName = "Диалог фазы 3"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

    local d0 = {}
    local d1 = {}

    local _Talker = "Адриана Сталь"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    d0.text = "Что... что это было?! Это то, что Ксотан охраняют в центре галактики?!"
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor
    d0.followUp = d1

    d1.text = "Мы загнали его в угол! Если мы продолжим атаку, мы сможем его добить! Направляйтесь в центр! Я соберу остальной флот!"
    d1.talker = _Talker
    d1.textColor = _TextColor
    d1.talkerColor = _TalkerColor
    d1.onEnd = "onPhase3DialogEnd"

    ScriptUI(_ID):interactShowDialog(d0, false)
end

-- Вызов клиентских/серверных функций
function onPhase2DialogEndYes()
    local _MethodName = "Конец диалога фазы 2 [ДА]"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase2DialogEndYes")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        mission.phases[2].timers[1] = {
            time = 2,
            callback = function()
                broadcastEmpressBladeMsg("Слишком поздно! Массивная сигнатура подпространства приближается! Готовьтесь к бою!")
            end,
            repeating = false
        }
        mission.phases[2].timers[2] = {
            time = 8,
            callback = function()
                Xsotan.createGuardian()
                local _Guardian = {Sector():getEntitiesByScript("data/scripts/entity/story/wormholeguardian.lua")}
                _Guardian[1]:removeScript("wormholeguardian.lua")
                _Guardian[1]:removeScript("legendaryloot.lua") -- На всякий случай?
                _Guardian[1]:addScriptOnce("player/missions/empress/story/story5/weakwormholeguardian.lua")

                local _XWGDura = Durability(_Guardian[1])
                _XWGDura.invincibility = 0.74

                local _EmpressAI = ShipAI(mission.data.custom.empressBladeid)
                _EmpressAI:setAggressive()
            end,
            repeating = false
        }

        -- Нет необходимости синхронизировать.
    end
end
callable(nil, "onPhase2DialogEndYes")

function onPhase2DialogEndNo()
    local _MethodName = "Конец диалога фазы 2 [НЕТ]"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase2DialogEndNo")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        local _EmpressBlade = Entity(mission.data.custom.empressBladeid)
        _EmpressBlade:addScriptOnce("player/missions/empress/story/story5/lltestory5empressblade.lua")

        -- Нет необходимости синхронизировать.
    end
end
callable(nil, "onPhase2DialogEndNo")

function onPhase3DialogEnd()
    local _MethodName = "Конец диалога фазы 3"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase3DialogEnd")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        local _Rgen = ESCCUtil.getRand()

        local _EmpressBlade = Entity(mission.data.custom.empressBladeid)
        _EmpressBlade:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
    end
end
callable(nil, "onPhase3DialogEnd")

--endregion