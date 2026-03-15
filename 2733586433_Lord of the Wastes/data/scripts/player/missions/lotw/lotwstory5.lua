--[[
    Повелитель Пустошей
    ЗАМЕТКИ:
        - ЗДЕСЬ ЗАМЕТКИ
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Завершить четвёртую миссию LOTW.
    ПРИМЕРНЫЙ ПЛАН:
        - Прибыть в место, сразиться со Свенксом. Достаточно просто!
    УРОВЕНЬ ОПАСНОСТИ:
        5 - Свенкс + 7 приспешников.
        5 - Каждые 25% здоровья Свенкс становится неуязвимым на 30-40 секунд и призывает ещё 4 приспешников.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")

local PirateGenerator = include("pirategenerator")
local Balancing = include("galaxy")
local SectorTurretGenerator = include("sectorturretgenerator")

mission._Debug = 0
mission._Name = "Повелитель Пустошей"

-- Настройка данных миссии
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/silicium.png"
mission.data.description = {
    { text = "Вы получили следующий запрос от ${factionName}:" },
    { text = "Наконец-то. Потери, которые понесли пираты в ходе последних операций, были настолько велики, что их босс наконец-то оказался уязвимым. Наши разведданные последний раз зафиксировали его в секторе (${location.x}:${location.y}). Найдите и уничтожьте его раз и навсегда." },
    { text = "Направляйтесь в сектор (${location.x}:${location.y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте Свенкса", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Невероятно! Вы сделали это! Внешние сектора стали безопаснее благодаря вашим усилиям. Мы перевели вознаграждение на ваш счёт."

local LOTW_Mission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало...")

    if onServer() then
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()

        if not _restoring then
            local _Player = Player()

            mission.data.custom.dangerLevel = 5
            mission.data.custom.friendlyFaction = _Player:getValue("_lotw_faction")

            local missionReward = ESCCUtil.clampToNearest(200000 + (50000 * Balancing.GetSectorRewardFactor(_Sector:getCoordinates())), 5000, "Up")

            missionData_in = {location = lotwStory5_getNextLocation(), reward = {credits = missionReward, relations = 12000, paymentMessage = "Получено %1% кредитов за уничтожение Свенкса."}}

            LOTW_Mission_init(missionData_in)

            lotwStory5_setMissionFactionData(_X, _Y)
        else
            LOTW_Mission_init()
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

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.phases[1] = {}
mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: Начало на сервере"
    mission.Log(_MethodName, "Начало...")

    local _Faction = Faction(mission.data.custom.friendlyFaction)

    mission.data.description[1].arguments = { factionName = _Faction.name }
    mission.data.description[2].arguments = { x = mission.data.location.x, y = mission.data.location.y }
    mission.data.description[3].arguments = { x = mission.data.location.x, y = mission.data.location.y }
end

mission.phases[1].onTargetLocationEntered = function(x, y)
    local _sector = Sector()

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    local ships = { _sector:getEntitiesByType(EntityType.Ship) }
    for _, ship in pairs(ships) do
        if ship.playerOrAllianceOwned then
            local ai = ShipAI(ship)
            ai:stop()
        end
    end

    lotwStory5_spawnSwenks()
    _sector:addScriptOnce("deleteentitiesonplayersleft.lua")
end

mission.phases[1].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Фаза 2: Уничтожение объекта"
    mission.Log(_MethodName, "Начало...")

    local _Entity = Entity(_ID)

    if _Entity:getValue("is_swenks") then
        Player():setValue("swenks_beaten", true)
        mission.Log(_MethodName, "Это цель.")
        ESCCUtil.allPiratesDepart()
        lotwStory5_finishAndReward()
    end
end

function lotwStory5_setMissionFactionData(_X, _Y)
    local _MethodName = "Установка данных фракции миссии"
    mission.Log(_MethodName, "Начало...")
    local _Faction = Faction(Player():getValue("_lotw_faction"))
    mission.data.giver = {}
    mission.data.giver.id = _Faction.index
    mission.data.giver.factionIndex = _Faction.index
    mission.data.giver.coordinates = { x = _X, y = _Y }
    mission.data.giver.baseTitle = _Faction.name
end

function lotwStory5_getNextLocation()
    local _MethodName = "Получение следующего сектора"
    mission.Log(_MethodName, "Поиск сектора...")
    local x, y = Sector():getCoordinates()
    local target = {}

    target.x, target.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, false)

    mission.Log(_MethodName, "Координата X следующего сектора: " .. tostring(target.x) .. ", координата Y следующего сектора: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function lotwStory5_spawnSwenks()
    local _MethodName = "Спавн Свенкса"

    local function piratePosition()
        local pos = random():getVector(-1000, 1000)
        return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
    end

    local boss = PirateGenerator.createFlagship(piratePosition())
    boss:setTitle("Босс Свенкс"%_T, {})
    boss.dockable = false

    local _pirates = {}
    table.insert(_pirates, boss)
    table.insert(_pirates, PirateGenerator.createRaider(piratePosition()))
    table.insert(_pirates, PirateGenerator.createRavager(piratePosition()))
    table.insert(_pirates, PirateGenerator.createMarauder(piratePosition()))
    table.insert(_pirates, PirateGenerator.createPirate(piratePosition()))
    table.insert(_pirates, PirateGenerator.createPirate(piratePosition()))
    table.insert(_pirates, PirateGenerator.createBandit(piratePosition()))
    table.insert(_pirates, PirateGenerator.createBandit(piratePosition()))

    local _Sector = Sector()
    local x, y = _Sector:getCoordinates()

    local _random = random()
    Loot(boss.index):insert(InventoryTurret(SectorTurretGenerator():generate(x, y, 0, Rarity(RarityType.Exotic))))
    Loot(boss.index):insert(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Exceptional), Seed(_random:getInt(1, 20000))))
    Loot(boss.index):insert(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Exotic), Seed(_random:getInt(1, 20000))))

    for _, pirate in pairs(_pirates) do
        MissionUT.deleteOnPlayersLeft(pirate)

        local _Player = Player()
        if not _Player then break end
        local allianceIndex = _Player.allianceIndex
        local ai = ShipAI(pirate.index)
        ai:registerFriendFaction(_Player.index)
        if allianceIndex then
            ai:registerFriendFaction(allianceIndex)
        end
    end

    if Server():getValue("swoks_beaten") then
        mission.Log(_MethodName, "Установка статуса победы над Своксом")
        boss:setValue("swoks_beaten", true)
    end

    boss:removeScript("icon.lua")
    boss:addScript("icon.lua", "data/textures/icons/pixel/skull_big.png")
    boss:addScript("player/missions/lotw/mission5/swenks.lua")
    boss:addScript("story/swenksspecial.lua")
    boss:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
    boss:addScriptOnce("avenger.lua")
    boss:setValue("is_pirate", true)
    boss:setValue("is_swenks", true)

    Boarding(boss).boardable = false
end

function lotwStory5_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local runTime = Server().unpausedRuntime

    _Player:setValue("_lotw_story_stage", 6)
    _Player:setValue("_lotw_story_complete", true)
    _Player:setValue("_lotw_last_side1", runTime)
    _Player:setValue("_lotw_last_side2", runTime)

    reward()
    accomplish()
end
