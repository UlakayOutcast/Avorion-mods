package.path = package.path .. ";data/scripts/lib/?.lua"

-- Запуск остальных подключений.
include("galaxy")
include("stringutility")
include("callable")
include("relations")
Dialog = include("dialogutility")
ESCCUtil = include("esccutil")

-- Не удаляйте это, иначе скрипт может сломаться.
-- namespace CavaliersContact
CavaliersContact = {}
local self = CavaliersContact

self.hailedPlayer = nil
self.contactPlayer = nil
self._GiveAllMissions = false -- ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ - УСТАНОВИТЕ В FALSE ДЛЯ РЕЛИЗА

self._Debug = 0

-- Инициализация
function CavaliersContact.initialize()
    local _MethodName = "initialize"
    self.Log(_MethodName, "Инициализация скрипта контакта с Кавалерами - игрок должен быть вызван немедленно")
    -- Начать вызов игрока немедленно.
    local playerIndex = Entity():getValue("_llte_playercontact_idx")
    self.contactPlayer = Player(playerIndex)
end

function CavaliersContact.getUpdateInterval()
    return 1.0
end

-- Вызов серверных функций
function CavaliersContact.updateServer(timeStep)
    if not self.hailedPlayer then
        deferredCallback(30, "onServerHailTimeout")
        invokeClientFunction(self.contactPlayer, "startHailing")
        self.hailedPlayer = true
    end
end

function CavaliersContact.onServerHailTimeout()
    local _MethodName = "On Server Hail Timeout"
    self.Log(_MethodName, "Начало тайм-аута вызова на сервере - игрок ответил: " .. tostring(self.playerResponded))
    if self.playerResponded then return end

    invokeClientFunction(self.contactPlayer, "onClientHailTimeout")
end

-- Вызов клиентских функций
function CavaliersContact.startHailing()
    ScriptUI():startHailing("startTalk", "warpOut")
end

function CavaliersContact.onClientHailTimeout()
    ScriptUI():stopHailing()
    self.warpOut()
end

function CavaliersContact.startTalk()
    local _MethodName = "Начало разговора"
    self.Log(_MethodName, "Инициация разговора с игроком")

    self.playerHasBeenContacted()
    local rgen = ESCCUtil.getRand()
    local _Rank = self.contactPlayer:getValue("_llte_cavaliers_rank")
    local _RankLevel = self.contactPlayer:getValue("_llte_cavaliers_ranklevel")
    local _Story2Done = self.contactPlayer:getValue("_llte_story_2_accomplished")
    local _Story3Done = self.contactPlayer:getValue("_llte_story_3_accomplished")
    local _HaveAvo = self.contactPlayer:getValue("_llte_cavaliers_have_avorion")
    local empress = self.contactPlayer:getValue("adriana_empress")

    local greetings = {"Здравствуйте", "Приветствуем", "Салют"}
    local d0mid = {"Рады видеть вас здесь"}
    if empress then
        table.insert(d0mid, "Императрица передаёт вам привет")
    else
        table.insert(d0mid, "Император передаёт вам привет")
    end
    local missionconfirms = {"Мы свяжемся с вами с деталями.", "Вот задание.", "Вот подробности.", "Загружаем данные миссии."}
    local goodbyes = {"До свидания!", "Прощайте!", "Увидимся!", "До встречи!", "Будьте осторожны!"}

    local dialog0 = {}
    local dialog1 = {}
    local dialog2 = {}

    -- Определяем варианты побочных миссий в зависимости от ранга игрока. Всегда добавляем хотя бы одну. 50% шанс добавить вторую. 25% шанс добавить третью.
    local missionTable = { "EscortShipment", "DestroyRaiders" }
    local availableMissionTable = {}
    -- Если игрок поддержал императора, даём ему проклятую кость.
    if not empress then
        table.insert(missionTable, "FutileResistance")
    end
    if _RankLevel >= 2 then
        table.insert(missionTable, "DestroyXsotan")
    end
    if _RankLevel >= 3 then
        table.insert(missionTable, "DestroyOutpost")
    end
    if _Story3Done and _HaveAvo then
        table.insert(missionTable, "DeliverMaterials")
    end
    if self._GiveAllMissions then
        for _, _Mission in pairs(missionTable) do
            table.insert(availableMissionTable, _Mission)
        end
    else
        self.Log(_MethodName, "Добавление первой миссии...")
        local firstMission = missionTable[rgen:getInt(1, #missionTable)]
        table.remove(missionTable, ESCCUtil.getIndex(missionTable, firstMission))
        table.insert(availableMissionTable, firstMission)
        if rgen:getInt(1, 2) == 1 and #missionTable >= 1 then
            self.Log(_MethodName, "Добавление второй миссии...")
            local secondMission = missionTable[rgen:getInt(1, #missionTable)]
            table.remove(missionTable, ESCCUtil.getIndex(missionTable, secondMission))
            table.insert(availableMissionTable, secondMission)
        end
        if #availableMissionTable >= 1 and rgen:getInt(1, 4) == 1 and #missionTable >= 1 then
            self.Log(_MethodName, "Добавление третьей миссии...")
            local thirdMission = missionTable[rgen:getInt(1, #missionTable)]
            table.remove(missionTable, ESCCUtil.getIndex(missionTable, thirdMission))
            table.insert(availableMissionTable, thirdMission)
        end
    end
    if _Story3Done and not _HaveAvo then
        -- всегда добавляем Deliver Materials, если выполнена история 3 и ещё не выполнена
        table.insert(availableMissionTable, "DeliverMaterials")
    end
    if _RankLevel >= 3 and _Story2Done and not _Story3Done then
        -- всегда добавляем Order from Chaos, если доступно - добавляем в начало таблицы.
        table.insert(availableMissionTable, 1, "OrderfromChaos")
    end

    local noThanksText = "Без проблем. До встречи. " .. goodbyes[rgen:getInt(1, #goodbyes)]

    dialog0.text = greetings[rgen:getInt(1, #greetings)] .. ", " .. _Rank .. " " .. self.contactPlayer.name .. "! " .. d0mid[rgen:getInt(1, #d0mid)] .. ". Вы сейчас заняты?"
    dialog0.answers = {
        {answer = "Я свободен.", followUp = dialog1 },
        {answer = "Я занят.", onSelect = "warpOut", text = noThanksText}
    }
    dialog1.text = "Отлично! Мы могли бы использовать вашу помощь."
    dialog1.answers = {
        {answer = "Что вы хотите, чтобы я сделал?", followUp = dialog2 }
    }
    dialog2.text = "Есть несколько задач, с которыми вы могли бы нам помочь. Вот что доступно."
    dialog2.answers = {}
    for _, mission in pairs(availableMissionTable) do
        local missionAcceptText = "Спасибо за помощь. " .. missionconfirms[rgen:getInt(1, #missionconfirms)]
        if mission == "EscortShipment" then
            table.insert(dialog2.answers, {answer = "Сопроводить груз", onSelect = "escortShipment", text = missionAcceptText})
        elseif mission == "DestroyRaiders" then
            table.insert(dialog2.answers, {answer = "Засада на рейдеров", onSelect = "destroyRaiders", text = missionAcceptText})
        elseif mission == "FutileResistance" then
            table.insert(dialog2.answers, {answer = "Разгромить сопротивление", onSelect = "destroyResistance", text = missionAcceptText})
        elseif mission == "DestroyXsotan" then
            table.insert(dialog2.answers, {answer = "Уничтожить Ксотан", onSelect = "destroyXsotan", text = missionAcceptText})
        elseif mission == "DestroyOutpost" then
            table.insert(dialog2.answers, {answer = "Уничтожить аванпост", onSelect = "destroyOutpost", text = missionAcceptText})
        elseif mission == "OrderfromChaos" then
            table.insert(dialog2.answers, {answer = "Порядок из хаоса", onSelect = "orderfromChaos", text = "Императрица свяжется с вами."})
        elseif mission == "DeliverMaterials" then
            table.insert(dialog2.answers, {answer = "Доставить материалы", onSelect = "deliverMaterials", text = missionAcceptText})
        end
    end
    table.insert(dialog2.answers, {answer = "На второй мысли, я бы предпочёл не делать ничего из этого.", onSelect = "warpOut", text = noThanksText})

    ScriptUI():interactShowDialog(dialog0, false)
end

-- Вызов клиентских/серверных функций
function CavaliersContact.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Cavaliers Contact] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

function CavaliersContact.warpOut()
    -- Нет штрафа за отказ от контакта с ними. Они понимают.
    if onClient() then
        invokeServerFunction("warpOut")
        return
    end

    local entity = Entity()
    local rgen = ESCCUtil.getRand()

    entity:addScriptOnce("utility/delayeddelete.lua", rgen:getFloat(3, 6))
end
callable(CavaliersContact, "warpOut")

function CavaliersContact.playerHasBeenContacted()
    local _MethodName = "Игрок контактировал"
    self.Log(_MethodName, "Начало...")
    if onClient() then
        invokeServerFunction("playerHasBeenContacted")
        return
    end

    self.playerResponded = true
end
callable(CavaliersContact, "playerHasBeenContacted")

-- Инициализация миссий
-- СОПРОВОЖДЕНИЕ ГРУЗА
function CavaliersContact.escortShipment()
    local _MethodName = "Сопровождение груза"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("escortShipment")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/side/lltesidemission2.lua")
    self.warpOut()
end
callable(CavaliersContact, "escortShipment")

-- ЗАСАДА НА РЕЙДЕРОВ
function CavaliersContact.destroyRaiders()
    local _MethodName = "Засада на рейдеров"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("destroyRaiders")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/side/lltesidemission1.lua")
    self.warpOut()
end
callable(CavaliersContact, "destroyRaiders")

-- РАЗГРОМИТЬ СОПРОТИВЛЕНИЕ
function CavaliersContact.destroyResistance()
    local _MethodName = "Разгромить сопротивление"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("destroyResistance")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/side/lltesidemission3.lua")
    self.warpOut()
end
callable(CavaliersContact, "destroyResistance")

-- УНИЧТОЖИТЬ КСОТАН
function CavaliersContact.destroyXsotan()
    local _MethodName = "Уничтожить Ксотан"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("destroyXsotan")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/side/lltesidemission4.lua")
    self.warpOut()
end
callable(CavaliersContact, "destroyXsotan")

-- УНИЧТОЖИТЬ АВАНПОСТ
function CavaliersContact.destroyOutpost()
    local _MethodName = "Уничтожить аванпост"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("destroyOutpost")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/side/lltesidemission5.lua")
    self.warpOut()
end
callable(CavaliersContact, "destroyOutpost")

-- ДОСТАВИТЬ МАТЕРИАЛЫ
function CavaliersContact.deliverMaterials()
    local _MethodName = "Доставить материалы"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("deliverMaterials")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/side/lltesidemission6.lua")
    self.warpOut()
end
callable(CavaliersContact, "deliverMaterials")

-- ПОРЯДОК ИЗ ХАОСА (СЮЖЕТНАЯ МИССИЯ 3)
function CavaliersContact.orderfromChaos()
    local _MethodName = "Порядок из хаоса"
    if onClient() then
        self.Log(_MethodName, "Вызов на сервере")
        invokeServerFunction("orderfromChaos")
        return
    end

    self.Log(_MethodName, "Добавление скрипта миссии игроку.")
    self.contactPlayer:addScript("data/scripts/player/missions/empress/story/lltestorymission3.lua")
    self.warpOut()
end
callable(CavaliersContact, "orderfromChaos")
