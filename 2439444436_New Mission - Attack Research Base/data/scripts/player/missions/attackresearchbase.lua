--[[
    Attack Research Base
    NOTES:
        N/A
    ADDITIONAL REQUIREMENTS TO DO THIS MISSION:
        N/A
    ROUGH OUTLINE
        - Go to the research base.
        - Destroy it.
        - Defenders will warp out once it is destroyed.
        - The player will be required to destroy the military outpost if it is there as well.
    DANGER LEVEL
        1+ - [These conditions are present regardless of danger level]
            - Research station present in sector
            - 4 initial defenders from medium threat table.
            - 3 respawning defenders
            - 2% Chance per danger level to drop chip with super secret ultra-difficult followup mission.
            - Respawning defenders spawn every 3 minutes.
        5 - [These conditions are present at danger level 5 and above]
            - 25% chance that Military Outpost is present in sector as well.
        6 - [These conditions are present at danger level 6 and above]
            - +1 (5 total) initial defenders.
            - Forced defender damage scale is doubled.
        10 - [These conditions are present at danger level 10]
            - +3 (8 total) initial defenders.
            - +1 (4 total) respawning defenders.
            - Respawning defenders spawn every 2 1/2 minutes.
            - Research base has +10% HP
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")
include("structuredmission")

ESCCUtil = include("esccutil")

local SectorGenerator = include ("SectorGenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include ("shiputility")
local Placer = include ("placer")
local UpgradeGenerator = include ("upgradegenerator")

mission._Debug = 0
mission._Test_Chip_Debug = 0
mission._Name = "Атака исследовательской базы"

--region #INIT

--Standard mission data.
mission.data.brief = "Атака исследовательской базы"
mission.data.title = "Атака исследовательской базы"
mission.data.description = {
    {text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    {text = "..." },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте все находящиеся там станции", bulletPoint = true, fulfilled = false, visible = false }
}

--Невозможно установить mission.data.reward.paymentMessage здесь, так как мы используем пользовательскую инициализацию.
mission.data.accomplishMessage = "Спасибо за уничтожение этой базы. Мы перевели награду на ваш счет."

local AttackResearchBase_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начинаем...")

    if onServer()then
        if not _restoring then
            mission.Log(_MethodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel) .. " - pirates : " .. tostring(_Data_in.pirates) .. " - enemy : " .. tostring(_Data_in.enemyFaction))

            local _Rgen = ESCCUtil.getRand()
            local _X, _Y = _Data_in.location.x, _Data_in.location.y

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)

            --[[=====================================================
                НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.pirates = _Data_in.pirates
            mission.data.custom.enemyName = ""
            if mission.data.custom.pirates then
                mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y)
                local _EnemyFaction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)

                mission.data.custom.enemyFaction = _EnemyFaction.index
                mission.Log(_MethodName, "Вражеская фракция: " .. tostring(_EnemyFaction.name))
                mission.data.custom.enemyName = "пираты"
            else
                mission.data.custom.enemyFaction = _Data_in.enemyFaction

                local _MissionDoer = Player().craftFaction or Player()
                local _Relation = _MissionDoer:getRelation(mission.data.custom.enemyFaction)
                local _EnemyFaction = Faction(mission.data.custom.enemyFaction)

                mission.data.custom.enemyRelationLevel = _Relation.level
                mission.data.custom.enemyRelationStatus = _Relation.status
                mission.Log(_MethodName, "Вражеская фракция: " .. tostring(_EnemyFaction.name))
                mission.data.custom.enemyName = _EnemyFaction.baseName
            end
            mission.data.custom.initialDefenders = 4
            mission.data.custom.respawningDefenders = 3
            mission.data.custom.spawnMilitary = false
            mission.data.custom.defenderRespawnTime = 180
            mission.data.custom.supplyPerCycle = 50
            mission.data.custom.supplyPerShip = 500

            --Установка значений в зависимости от уровня опасности.
            if mission.data.custom.dangerLevel >= 5 then
                mission.data.custom.spawnMilitary = _Rgen:getInt(1, 4) == 1
            end
            if mission.data.custom.dangerLevel >= 6 then
                mission.data.custom.initialDefenders = mission.data.custom.initialDefenders + 1 --Увеличение до 5
            end
            if mission.data.custom.dangerLevel == 10 then
                mission.data.custom.initialDefenders = mission.data.custom.initialDefenders + 2 --Увеличение до 7
                mission.data.custom.respawningDefenders = mission.data.custom.respawningDefenders + 1 --Увеличение до 4
                mission.data.custom.defenderRespawnTime = mission.data.custom.defenderRespawnTime - 30 --Увеличение до 2 1/2 минут.
                mission.data.custom.supplyPerCycle = 100
                mission.data.custom.supplyPerShip = 600
            end

            --[[=====================================================
                НАСТРОЙКА ОПИСАНИЯ МИССИИ:
            =========================================================]]
            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = { x = _X, y = _Y, enemyName = mission.data.custom.enemyName }
            mission.data.description[3].arguments = { _X = _X, _Y = _Y }

            --Запуск стандартной инициализации
            AttackResearchBase_init(_Data_in)
        else
            --Восстановление
            AttackResearchBase_init()
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

--endregion

--region #ВЫЗОВЫ ФАЗ

mission.globalPhase.noBossEncountersTargetSector = true

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
mission.phases[1].onTargetLocationEntered = function(_X, _Y) 
    local _MethodName = "Фаза 1: вход в целевой сектор"
    attackResearchBase_buildObjectiveSector(_X, _Y)
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true 
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 1: подтверждение прибытия в целевой сектор"
    mission.Log(_MethodName, "Начинаем...")

    if not mission.data.custom.pirates then
        local _MissionDoer = Player().craftFaction or Player()
        local _Faction = Faction(mission.data.custom.enemyFaction)

        if mission.data.custom.enemyRelationStatus ~= RelationStatus.War then
            mission.Log(_MethodName, "Локальная фракция еще не в состоянии войны с игроком. Объявляем войну.")
            local _Galaxy = Galaxy()
            _Galaxy:setFactionRelations(_Faction, _MissionDoer, -100000)
            _Galaxy:setFactionRelationStatus(_Faction, _MissionDoer, RelationStatus.War)
        end

        local _Entities = {Sector():getEntitiesByFaction(_Faction.index)}
        for _, _E in pairs(_Entities) do
            if _E.type == EntityType.Ship or _E.type == EntityType.Station then
                Sector():broadcastChatMessage(_E, ChatMessageType.Chatter, "Здесь вторженцы?! Немедленно уничтожить их!")
                break
            end
        end
    end

    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].triggers = {}

--region #ТРИГГЕРЫ ФАЗЫ 2

if onServer() then

--Триггер условия победы.
mission.phases[2].triggers[1] = {
    condition = function()
        local _MethodName = "Фаза 2: условие триггера 1"

        if atTargetLocation() then
            return ESCCUtil.countEntitiesByValue("attackresearchbase_mission_target") == 0
        else
            return false
        end
    end,
    callback = function()
        local _MethodName = "Фаза 2: обратный вызов триггера 1"
            
        mission.Log(_MethodName, "Миссия завершена - награждаем игрока.")
    
        if mission.data.custom.pirates then
            ESCCUtil.allPiratesDepart()
        else
            local _Rgen = ESCCUtil.getRand()
            local _MissionDoer = Player().craftFaction or Player()
            local _Faction = Faction(mission.data.custom.enemyFaction)
            local _Galaxy = Galaxy()
        
            local _Entities = {Sector():getEntitiesByFaction(_Faction.index)}
            for _, _E in pairs(_Entities) do
                if _E.type == EntityType.Ship then
                    _E:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
                end
            end
        
            _Galaxy:setFactionRelations(_Faction, _MissionDoer, mission.data.custom.enemyRelationLevel - 10000)
            _Galaxy:setFactionRelationStatus(_Faction, _MissionDoer, mission.data.custom.enemyRelationStatus)
        end
        
        attackResearchBase_finishAndReward()
    end,
    repeating = false
}

end

--endregion

--endregion

--region #СЕРВЕРНЫЕ ВЫЗОВЫ

function attackResearchBase_buildObjectiveSector(_X, _Y)
    local _MethodName = "Построить целевой сектор"

    mission.Log(_MethodName, "Главный сектор еще не построен - строим его сейчас.")
    local _Generator = SectorGenerator(_X, _Y)
    local _Rgen = ESCCUtil.getRand()
    --Добавить: исследовательскую станцию и, возможно, военный аванпост
    local _Faction = Faction(mission.data.custom.enemyFaction)
    if mission.data.custom.pirates then
        mission.Log(_MethodName, "Строим сектор для пиратской фракции уровня: " .. tostring(_Faction.name) .. " уровень " .. tostring(mission.data.custom.pirateLevel) .. " пираты")
    else
        mission.Log(_MethodName, "Строим сектор для стандартной фракции " .. tostring(_Faction.name))
    end 
    local _Stations = {}

    local _ResearchOutpost = _Generator:createResearchStation(_Faction)
    local _Pct = mission.data.custom.dangerLevel
    local _Chance = _Rgen:getInt(1, 100)
    mission.Log(_MethodName, "_Pct равно " .. tostring(_Pct) .. " и _Chance равно " .. tostring(_Chance))
    if MissionUT.checkSectorInsideBarrier(_X, _Y) and _Chance <= _Pct then
        --Не добавляйте чип, если миссия не происходит внутри барьера.
        mission.data.custom.addChip = true
    end
    --добавить редкое улучшение в добычу станции.
    local _upgradeGenerator = UpgradeGenerator()
    local _upgradeRarities = attackResearchBase_getSectorRarityTables(_X, _Y, _upgradeGenerator)
    Loot(_ResearchOutpost):insert(_upgradeGenerator:generateSectorSystem(_X, _Y, nil, _upgradeRarities))

    table.insert(_Stations, _ResearchOutpost)

    if mission.data.custom.spawnMilitary then
        local _MilitaryOutpost = _Generator:createMilitaryBase(_Faction)
        _MilitaryOutpost:setValue("attackresearchbase_military_outpost", true)
        table.insert(_Stations, _MilitaryOutpost)
    end

    --Разместить исследовательскую станцию в точке 0,0 и записать индекс.
    mission.data.custom.researchStationid = _ResearchOutpost.index
    _ResearchOutpost.position = Matrix()
    
    local _Dist = ESCCUtil.getDistanceToCenter(_X, _Y)

    --Обновить станции.
    for _, _Station in pairs(_Stations) do
        --Увеличить HP
        local _Dura = Durability(_Station)
        if _Dura then
            _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * 1.3
        end

        if mission.data.custom.dangerLevel < 8 or _Dist > 175 then
            local _StationBay = CargoBay(_Station)
            _StationBay:clear()
        end

        local _DuraFactor = 1.0
        local _ArtilleryFactor = 0
        if mission.data.custom.dangerLevel >= 6 then
            _DuraFactor = 1
            _ArtilleryFactor = 1
        end
        if mission.data.custom.dangerLevel == 10 then
            _DuraFactor = 1.1
            _ArtilleryFactor = 2
        end
        if _Station:getValue("attackresearchbase_military_outpost") then
            --Военная база.
            ShipUtility.addScalableArtilleryEquipment(_Station, 4.0 + _ArtilleryFactor, 1.0, false)
        else
            --Исследовательская лаборатория. Добавить бонус HP в зависимости от урона.
            ShipUtility.addScalableArtilleryEquipment(_Station, 1.0 + _ArtilleryFactor, 0.0, false)

            mission.Log(_MethodName, "Увеличение HP исследовательского аванпоста до фактора: " .. tostring(_DuraFactor))

            if _Dura then
                _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _DuraFactor
            end
        
            local _Shield = Shield(_Station)
            if _Shield then
                _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _DuraFactor
            end
        end
        local _ShipAI = ShipAI(_Station)
        _ShipAI:setAggressive()

        if mission.data.custom.pirates then
            _Station:setValue("is_pirate", true)
        end

        --Удалить скрипт потребителя / доски объявлений.
        _Station:removeScript("consumer.lua")
        _Station:removeScript("backup.lua")
        _Station:removeScript("bulletinboard.lua")
        _Station:removeScript("missionbulletins.lua")
        _Station:removeScript("story/bulletins.lua")
        _Station:setValue("attackresearchbase_mission_target", true)
    end
    Sector():removeScript("traders.lua")

    local _fields = random():getInt(3, 5)
    --Добавить: 3-5 небольших астероидных полей.
    for _ = 1, _fields do
        _Generator:createSmallAsteroidField()
    end

    --Добавить: стандартных защитников от угроз
    local _InitialDefenders = mission.data.custom.initialDefenders
    if mission.data.custom.pirates then
        local _SpawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _InitialDefenders, "Standard")
            
        local generator = AsyncPirateGenerator(nil, attackResearchBase_onDefendersFinished)
        generator.pirateLevel = mission.data.custom.pirateLevel

        generator:startBatch()
        
        for _, _Ship in pairs(_SpawnTable) do
            generator:createScaledPirateByName(_Ship, generator.getGenericPosition())
        end

        generator:endBatch()
    else
        local _SpawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _InitialDefenders, "Standard", true)

        local generator = AsyncShipGenerator(nil, attackResearchBase_onDefendersFinished)

        generator:startBatch()

        for _, _Ship in pairs(_SpawnTable) do
            generator:createDefenderByName(_Faction, generator.getGenericPosition(), _Ship)
        end

        generator:endBatch()
    end

    --наконец, добавить скрипт контроллера защиты.
    local _ForcedDamageScale = 3
    if mission.data.custom.dangerLevel >= 6 then
        _ForcedDamageScale = _ForcedDamageScale + 3
    end

    local _DCD = {}
    _DCD._DefenseLeader = mission.data.custom.researchStationid
    _DCD._DefenderCycleTime = mission.data.custom.defenderRespawnTime
    _DCD._DangerLevel = mission.data.custom.dangerLevel
    _DCD._MaxDefenders = mission.data.custom.respawningDefenders
    _DCD._DefenderHPThreshold = 0.5
    _DCD._DefenderOmicronThreshold = 0.5
    _DCD._ForceWaveAtThreshold = 0.5
    _DCD._ForcedDefenderDamageScale = _ForcedDamageScale
    _DCD._IsPirate = mission.data.custom.pirates
    _DCD._Factionid = mission.data.custom.enemyFaction
    _DCD._PirateLevel = mission.data.custom.pirateLevel
    _DCD._UseLeaderSupply = true
    _DCD._LowTable = "Standard"
    _DCD._NoHazard = true
    _DCD._SupplyPerLevel = 500
    _DCD._SupplyFactor = 0.1 --+10% buff per level.

    Sector():addScript("sector/background/defensecontroller.lua", _DCD)

    local _SCD = {}
    _SCD._ShipmentLeader = mission.data.custom.researchStationid
    _SCD._ShipmentCycleTime = mission.data.custom.defenderRespawnTime - 10
    _SCD._DangerLevel = mission.data.custom.dangerLevel
    _SCD._IsPirate = mission.data.custom.pirates
    _SCD._Factionid = mission.data.custom.enemyFaction
    _SCD._PirateLevel = mission.data.custom.pirateLevel
    _SCD._SupplyTransferPerCycle = mission.data.custom.supplyPerCycle
    _SCD._SupplyPerShip = mission.data.custom.supplyPerShip
    _SCD._SupplierExtraScale = 6
    _SCD._SupplierHealthScale = 0.1

    Sector():addScript("sector/background/shipmentcontroller.lua", _SCD)

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function attackResearchBase_getSectorRarityTables(_X, _Y, _upgradeGenerator)
    local _dangerLevel = mission.data.custom.dangerLevel
    local _rarities = _upgradeGenerator:getSectorRarityDistribution(_X, _Y)
    _rarities[-1] = 0 --no petty
    _rarities[0] = 0 --no common
    _rarities[1] = 0 --no uncommon
    _rarities[2] = 0 --no rare

    local _dangerFactors = {
        { _exceptional = 1, _exotic = 1}, --1
        { _exceptional = 1, _exotic = 1}, --2
        { _exceptional = 1, _exotic = 1}, --3
        { _exceptional = 1, _exotic = 1}, --4
        { _exceptional = 0.5, _exotic = 1}, --5
        { _exceptional = 0.5, _exotic = 1}, --6
        { _exceptional = 0.5, _exotic = 0.75}, --7
        { _exceptional = 0.25, _exotic = 0.75}, --8
        { _exceptional = 0.25, _exotic = 0.5}, --9
        { _exceptional = 0.12, _exotic = 0.5} --10
    }
    
    _rarities[3] = _rarities[3] * _dangerFactors[_dangerLevel]._exceptional
    _rarities[4] = _rarities[4] * _dangerFactors[_dangerLevel]._exotic

    return _rarities
end

function attackResearchBase_onDefendersFinished(_Generated)
    for _, _Defender in pairs(_Generated) do
        _Defender:setValue("_ESCC_bypass_hazard", true)
    end
    SpawnUtility.addEnemyBuffs(_Generated)
end

function attackResearchBase_finishAndReward()
    local _MethodName = "Завершить и наградить"
    mission.Log(_MethodName, "Запускаем условие победы.")

    if mission.data.custom.addChip or mission._Test_Chip_Debug == 1 then
        mission.Log(_MethodName, "Добавляем чип последующей миссии в инвентарь игрока.")
        Player():getInventory():addOrDrop(UsableInventoryItem("superweaponchip.lua", Rarity(RarityType.Legendary), mission.data.giver.factionIndex))
    end

    reward()
    accomplish()
end

--endregion

--region #ВЫЗОВЫ MAKEBULLETIN

function attackResearchBase_formatDescription(_Station, _DangerValue)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive < 0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionP1Table = {
        "Нам нужна ваша помощь. Наши разведчики обнаружили поблизости исследовательскую базу, принадлежащую вражеской фракции. Крайне важно как можно быстрее уничтожить ее, чтобы сорвать любые проекты, которые там исследуются. Не волнуйтесь - мы компенсируем ваши усилия. Награда должна быть достаточной для этой задачи.", --Neutral
        "Наши разведчики обнаружили вражескую исследовательскую базу. Обычно для наших сил не составило бы труда уничтожить ее, но наши военные заняты в другом месте и не могут заниматься дополнительными стратегическими целями. Поэтому нам нужно обратиться за помощью извне. Мы хотим, чтобы вы атаковали базу и уничтожили все, что там создается.", --Aggressive
        "Мы обнаружили поблизости вражескую исследовательскую базу. К сожалению, наши дипломатические усилия провалились, и они отказались переехать. Мы понятия не имеем, что они могут исследовать на этом месте - его необходимо уничтожить, чтобы защитить наши интересы. Наша армия недостаточно сильна, чтобы атаковать ее. Нам понадобится ваша помощь." --Peaceful
    }

    local finalDescription = descriptionP1Table[descriptionType]

    local descriptionP2Table = {
        "\n\nПо нашим данным, база хорошо защищена. Будьте осторожны при атаке.", --Neutral
        "\n\nПо всем признакам, база хорошо защищена. Принесите свое лучшее оружие.", --Aggressive
        "\n\nМы считаем, что база сильно укреплена. Будьте осторожны при атаке." --Peaceful
    }

    if _DangerValue >= 6 then
        finalDescription = finalDescription .. descriptionP2Table[descriptionType]
    end

    local descriptionP3Table = {
        "\n\nБаза расположена в секторе (${x}:${y}). Она контролируется ${enemyName}.", --Neutral
        "\n\nБаза расположена в секторе (${x}:${y}). Она контролируется ${enemyName}. Сожгите ее дотла.", --Aggressive
        "\n\nБаза расположена в секторе (${x}:${y}). Она контролируется ${enemyName} - пожалуйста, сделайте то, что необходимо." --Peaceful
    }

    finalDescription = finalDescription .. descriptionP3Table[descriptionType]

    return finalDescription
end
mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local x, y = Sector():getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getSector(x, y, 2, 15, false, false, false, false, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x или Target.y не установлены - возвращаем nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)
    
    local _Description = attackResearchBase_formatDescription(_Station, _DangerLevel)

    local _Pirates = _Rgen:getInt(1, 2) == 1
    local _Faction = _Station.factionIndex
    local _EnemyFaction = nil
    _EnemyFactionName = nil
    local _Difficulty = "Средний"
    if _DangerLevel >= 5 then
        _Difficulty = "Сложный"
    end
    if _DangerLevel >= 8 then
        _Difficulty = "Экстремальный"
    end

    if not _Pirates then
        --Find a nearby faction that can attack the player.
        local _Neighbors = MissionUT.getNeighboringFactions(_Faction, 125)
        shuffle(random(), _Neighbors)
        
        if #_Neighbors > 0 then
            _EnemyFaction = _Neighbors[1].index
            _EnemyFactionName = "The " .. _Neighbors[1].baseName
            mission.Log(_MethodName, "Название вражеской фракции: " .. tostring(_EnemyFactionName))
        else
            _Pirates = true
        end
        if _Station.factionIndex == _EnemyFaction then
            _Pirates = true
        end
    end
    if _Pirates then
        _EnemyFactionName = "пираты"
    end

    local _BaseReward = 70000
    if _DangerLevel >= 5 then
        _BaseReward = _BaseReward + 6000
    end
    if _DangerLevel == 10 then
        _BaseReward = _BaseReward + 12000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    reward = _BaseReward * Balancing.GetSectorRewardFactor(Sector():getCoordinates())
    reputation = 6000

    local bulletin =
    {
        -- data for the bulletin board
        brief = "Атаковать исследовательскую базу",
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/attackresearchbase.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward), enemyName = _EnemyFactionName},
        msg = "Исследовательская база находится в секторе \\s(%1%:%2%). Пожалуйста, уничтожьте ее.",
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
            reward = {credits = reward, relations = reputation, paymentMessage = "За уничтожение исследовательской базы получено %1% кредитов."},
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            pirates = _Pirates,
            enemyFaction = _EnemyFaction
        }},
    }

    return bulletin
end

--endregion