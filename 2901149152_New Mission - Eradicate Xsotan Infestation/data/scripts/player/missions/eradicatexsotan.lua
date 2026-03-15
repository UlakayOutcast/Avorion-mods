--[[
    Rank 2 side mission.
    Eradicate Xsotan Infestation
    ADDITIONAL REQUIREMENTS TO DO THIS MISSION:
        - Rank 2
    ROUGH OUTLINE
        - Jump to the target sector.
        - Start killing Xsotan.
        - An infestor will show up after you've killed 25 of them.
        - Kill that and you're done. That's literally it.
    DANGER LEVEL
        1+ - [These conditions are present regardless of danger level]
            - Maximum # of Xsotan in the sector is 10.
            - Xsotan will be size 1 to 3
            - Infestor size is 3 + max size + min size and has a +60% damage buff. In addition, it is always a summoner.
        6 - [These conditions are present at danger level 6 and above]
            - The first Xsotan in each wave has a 50% chance to be quantum.
        8 - [These conditions are present at danger level 8 and above]
            - Increases the maximum # of Xsotan by 1 (to 11)
            - Increases the maximum size of Xsotan by 1 (size 1 to 4)
        10 - [These conditions are present at danger level 10]
            - You have to kill 30 Xsotan instead of 25.
            - The first Xsotan in each wave is guaranteed to be quantum.
            - The second Xsotan in each wave has a 50% chance to be a summoner. This obviously has no effect if there is only 1 xsotan in a wave.
            - Increases the maximum # of Xsotan by 1 (to 12)
            - Increases the minimum and maximum size of Xsotan by 1 (size 2 to 5)
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

ESCCUtil = include("esccutil")

local Xsotan = include("story/xsotan")
local SpawnUtility = include ("spawnutility")
local SectorGenerator = include ("SectorGenerator")
local Balancing = include ("galaxy")

mission._Debug = 0
mission._TestSpecials = 0
mission._Name = "Искоренить заражение Ксотан"

--region #INIT
--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    { text = "..." }, --Placeholder
    { text = "Отправляйтесь в сектор (${_X}:${_Y}) и уничтожьте всех присутствующих ксотан", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте Заразителя ксотан", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Спасибо за уничтожение ксотан! Мы перевели награду на ваш счет."

local EradicateXsotan_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начало...")

    if onServer()then
        if not _restoring then
            mission.Log(_MethodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel))

            local _X, _Y = _Data_in.location.x, _Data_in.location.y

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)
            --[[=====================================================
                CUSTOM MISSION DATA:
                .dangerLevel
                .maximumXsotan
                .xsotanSizeBonus
                .xsotanKilled
                .xsotanKillreq
                .infestorSpawned
                .inBarrier
                .killedGuardian
                .xsoDamageMultiplier
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.maximumXsotan = 10
            mission.data.custom.maximumQuantum = 2
            mission.data.custom.xsotanSizeBonus = { min = 0, max = 2 }
            mission.data.custom.xsotanKilled = 0
            mission.data.custom.xsotanKillreq = 25
            mission.data.custom.infestorSpawned = false
            mission.data.custom.inBarrier = _Data_in.inbarrier
            mission.data.custom.xsoDamageMultiplier = 1

            if mission.data.custom.inBarrier then
                local _KilledGuardian = Player():getValue("wormhole_guardian_destroyed")
                if _KilledGuardian then
                    mission.Log(_MethodName, "Игрок убил стража. Устанавливаем режим джокера.")
                    mission.data.custom.killedGuardian = true
                end
            end

            if mission.data.custom.dangerLevel >= 8 then
                mission.data.custom.maximumXsotan = mission.data.custom.maximumXsotan + 1
                mission.data.custom.xsotanSizeBonus.max = mission.data.custom.xsotanSizeBonus.max + 1
            end
            if mission.data.custom.dangerLevel == 10 then
                mission.data.custom.maximumXsotan = mission.data.custom.maximumXsotan + 1
                mission.data.custom.xsotanSizeBonus.min = mission.data.custom.xsotanSizeBonus.min + 1
                mission.data.custom.xsotanSizeBonus.max = mission.data.custom.xsotanSizeBonus.max + 1
                mission.data.custom.xsotanKillreq = mission.data.custom.xsotanKillreq + 2
            end

            if mission.data.custom.inBarrier then
                mission.data.custom.xsotanSizeBonus.min = mission.data.custom.xsotanSizeBonus.min + 2
                mission.data.custom.xsotanSizeBonus.max = mission.data.custom.xsotanSizeBonus.max + 2

                if mission.data.custom.killedGuardian then
                    mission.Log(_MethodName, "В барьере и убит страж - увеличиваем сложность и награды.")
                    mission.data.custom.xsoDamageMultiplier = mission.data.custom.xsoDamageMultiplier + 1
                    _Data_in.reward.credits = _Data_in.reward.credits * 3
                    _Data_in.reward.relations = _Data_in.reward.relations + 2000
                    
                    if mission.data.custom.dangerLevel == 10 then
                        mission.data.custom.maximumXsotan = mission.data.custom.maximumXsotan + 1
                        mission.data.custom.xsoDamageMultiplier = mission.data.custom.xsoDamageMultiplier + 1.5
                        mission.data.custom.xsotanKillreq = mission.data.custom.xsotanKillreq + 2
                        mission.data.custom.maximumQuantum = mission.data.custom.maximumQuantum + 1
                    end
                end
            end

            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = { x = _X, y = _Y }
            mission.data.description[3].arguments = { _X = _X, _Y = _Y }

            --Run standard initialization
            EradicateXsotan_init(_Data_in)
        else
            --Restoring
            EradicateXsotan_init()
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

--region #PHASE CALLS
--Try to keep the timer calls outside of onBeginServer / onSectorEntered / onSectorArrivalConfirmed unless they are non-repeating and 30 seconds or less.

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
mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 1 При входе в целевую локацию"
    mission.Log(_MethodName, "Начало...")

    eradicateXsotan_spawnObjectiveSector(x, y)
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onTargetLocationEntered = function(x, y)
    --Give the player a 30 second window before any sunmakers, longinus(es?), or ballistyx start shooting again.
    --Дайте игроку 30 секунд до того, как солнцеделы, лонгины или баллистиксы снова начнут стрелять.
    local _Sector = Sector()

    local _func = "resetTimeToActive"
    local _time = 30

    local _Sunmakers = {_Sector:getEntitiesByScriptValue("is_sunmaker")}
    for _, _sunmaker in pairs(_Sunmakers) do
        _sunmaker:invokeFunction("stationsiegegun.lua", _func, _time)
    end

    local _Longinus_plural = {_Sector:getEntitiesByScriptValue("is_longinus")}
    for _, _longinus in pairs(_Longinus_plural) do
        _longinus:invokeFunction("lasersniper.lua", _func, _time)
    end
    
    local _Ballistyx_plural = {_Sector:getEntitiesByScriptValue("is_ballistyx")}
    for _, _ballistyx in pairs(_Ballistyx_plural) do
        _ballistyx:invokeFunction("torpedoslammer.lua", _func, _time)
    end
end

mission.phases[2].onTargetLocationLeft = function(x, y)
    local _MethodName = "Фаза 2 При выходе из целевой локации"
    mission.Log(_MethodName, "Начало...")
    --Reset.
    --Сброс.
    mission.data.custom.xsotanKilled = 0
    mission.data.custom.infestorSpawned = false
end

mission.phases[2].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 2 Обновление целевой локации"

    local _XKR = mission.data.custom.xsotanKillreq
    if mission.data.custom.xsotanKilled >= _XKR and not mission.data.custom.infestorSpawned then
        mission.Log(_MethodName, tostring(_XKR) .. "+ Ксотан уничтожено. Порождаем Заразителя.")
        eradicateXsotan_spawnXsotanInfestor()   

        mission.data.description[4].visible = true
        showMissionUpdated("Уничтожить Заражение Ксотан")

        mission.data.custom.infestorSpawned = true
        sync()
    end
end

mission.phases[2].onEntityDestroyed = function(id, lastDamageInflictor)
    local _MethodName = "Фаза 2 При уничтожении сущности"

    if atTargetLocation() then
        local entity = Entity(id)
        if valid(entity) and entity:getValue("_infestation_xsotan") then
            mission.data.custom.xsotanKilled = mission.data.custom.xsotanKilled + 1
        end
    
        if entity:getValue("is_infestor") then
            local rgen = ESCCUtil.getRand()
            local _Xsos = {Sector():getEntitiesByScriptValue("is_xsotan")}
            if _Xsos then
                for _, _Xso in pairs(_Xsos) do
                    _Xso:addScriptOnce("utility/delayeddelete.lua", rgen:getFloat(5, 9))
                end
            end
    
            eradicateXsotan_finishAndReward()
        end
        
        mission.Log(_MethodName, tostring(mission.data.custom.xsotanKilled) .. " Ксотан уничтожено на данный момент.")
    end
end

--region #PHASE 2 timers

if onServer() then

mission.phases[2].timers[1] = {
    time = 60,
    callback = function()
        if atTargetLocation() then
            eradicateXsotan_spawnXsotanWave()
        end
    end,
    repeating = true
}
    
 end

--endregion

--endregion

--region #SERVER CALLS

function eradicateXsotan_spawnObjectiveSector(x, y)
    local _MethodName = "Порождение сектора"

    local rgen = ESCCUtil.getRand()
    mission.Log(_MethodName, "Генерация астероидных полей.")
    local generator = SectorGenerator(x, y)
    for _ = 1, rgen:getInt(2,6) do
        generator:createSmallAsteroidField()
    end

    mission.Log(_MethodName, "Генерация ксотан.")
    --Spawn the maximum number of Xsotan.
    --Порождаем максимальное количество ксотан.
    eradicateXsotan_spawnXsotanWave()

    mission.data.custom.cleanUpSector = true
end

function eradicateXsotan_spawnXsotanWave()
    local _MethodName = "Порождение волны ксотан"
    
    local _SpawnCount = mission.data.custom.maximumXsotan - ESCCUtil.countEntitiesByValue("_infestation_xsotan")
    if mission.data.custom.xsotanKilled >= 200 then
        _SpawnCount = 0 --if you're silly enough to kill two hundred of these without killing the infestor, we'll throw you a bone.
        --если вы достаточно глупы, чтобы убить двести из них, не убив заразителя, мы вам поможем.
    end
    local rgen = ESCCUtil.getRand()
    local _Generator = SectorGenerator(Sector():getCoordinates())
    local _Players = {Sector():getPlayers()}
    local _XsotanByNameTable = {}
    local _XsotanTable = {}

    mission.Log(_MethodName, "Порождаем " .. tostring(_SpawnCount) .. " кораблей ксотан.")
    --Use the same method for spawning a background Xsotan in the swarm event.
    --Используйте тот же метод для порождения фонового ксотана в событии роя.
    --If danger level is 6+, 50% chance to add a quantum to each wave.
    --Если уровень опасности 6+, 50% шанс добавить квант в каждую волну.
    local _AddSmn = false
    local _AddQuantum = false
    local _AddSpecial = false
    if mission.data.custom.dangerLevel >= 6 and rgen:test(0.5) then
        mission.Log(_MethodName, "Добавляем квант опасности 6 в таблицу порождения")
        _AddQuantum = true
    end
    --If danger level is 10, 100% chance to add a quantum and a 25% chance to add a summoner to each wave.
    --Если уровень опасности 10, 100% шанс добавить квант и 25% шанс добавить призывателя в каждую волну.
    if mission.data.custom.dangerLevel == 10 then
        mission.Log(_MethodName, "Добавляем квант опасности 10 в таблицу порождения")
        _AddQuantum = true
        if rgen:test(0.25) == 1 then 
            mission.Log(_MethodName, "Добавляем призывателя в таблицу порождения")
            _AddSmn = true 
        end
    end
    --If there's already a summoner here, don't spawn another one.
    --Если здесь уже есть призыватель, не порождайте еще одного.
    local _Sector = Sector()
    local _Summoners = {_Sector:getEntitiesByScript("enemies/summoner.lua")}
    if #_Summoners > 0 then
        _AddSmn = false
    end

    local _Quantums = {_Sector:getEntitiesByScript("enemies/blinker.lua")}
    if #_Quantums >= mission.data.custom.maximumQuantum then
        _AddQuantum = false
    end

    local _ChanceToAddSpecialXsotan = mission.data.custom.dangerLevel * 0.02
    if not mission.data.custom.inBarrier then
        _ChanceToAddSpecialXsotan = _ChanceToAddSpecialXsotan / 2 --10% chance max outside barrier.
        --максимум 10% шанс вне барьера.
    end
    if (mission.data.custom.inBarrier and mission.data.custom.killedGuardian) then
        _ChanceToAddSpecialXsotan = _ChanceToAddSpecialXsotan * 4 --Up to 80%
        --До 80%
    end
    if rgen:test(_ChanceToAddSpecialXsotan) then
        mission.Log(_MethodName, "Добавляем специального ксотана.")
        _AddSpecial = true
    end

    if mission._TestSpecials == 1 then
        _AddSpecial = true
    end

    --Build our Xsotan name table.
    --Создаем нашу таблицу имен ксотан.
    if _SpawnCount >= 1 and _AddQuantum then table.insert(_XsotanByNameTable, "Quantum") end
    if _SpawnCount >= 1 and _AddSmn then table.insert(_XsotanByNameTable, "Summoner") end
    if _SpawnCount >= 1 and _AddSpecial then table.insert(_XsotanByNameTable, "Special") end
    if _SpawnCount - #_XsotanByNameTable > 0 then
        for _ = 1, _SpawnCount - #_XsotanByNameTable do
            table.insert(_XsotanByNameTable, "Ship")
        end
    end
    
    mission.Log(_MethodName, "Порождаем окончательное количество " .. tostring(#_XsotanByNameTable) .. " кораблей ксотан.")
    --Spawn Xsotan based on what's in the nametable.
    --Порождаем ксотан на основе того, что находится в таблице имен.
    for xidx = 1, #_XsotanByNameTable do
        local xsoSize = 1.0 + rgen:getInt(mission.data.custom.xsotanSizeBonus.min, mission.data.custom.xsotanSizeBonus.max)
        local _Xsotan = nil
        local _Dist = 1500
        if _XsotanByNameTable[xidx] == "Summoner" then
            _Xsotan = Xsotan.createSummoner(_Generator:getPositionInSector(_Dist), xsoSize)
        elseif _XsotanByNameTable[xidx] == "Quantum" then
            _Xsotan = Xsotan.createQuantum(_Generator:getPositionInSector(_Dist), xsoSize)
        elseif _XsotanByNameTable[xidx] == "Special" then
            local _SpecialSize = mission.data.custom.xsotanSizeBonus.max * 2
            local _XsotanFunction = getRandomEntry(Xsotan.getSpecialXsotanFunctions())

            _Xsotan = _XsotanFunction(_Generator:getPositionInSector(_Dist), _SpecialSize)
        else
            _Xsotan = Xsotan.createShip(_Generator:getPositionInSector(_Dist), xsoSize)
        end

        if _Xsotan then
            if valid(_Xsotan) then
                for _, p in pairs(_Players) do
                    ShipAI(_Xsotan.id):registerEnemyFaction(p.index)
                end
                ShipAI(_Xsotan.id):setAggressive()
            end
            _Xsotan:setValue("_infestation_xsotan", true)
            _Xsotan.damageMultiplier = (_Xsotan.damageMultiplier or 1 ) * mission.data.custom.xsoDamageMultiplier
            table.insert(_XsotanTable, _Xsotan)
        else
            mission.Log(_MethodName, "ОШИБКА - Xsotan был nil")
        end
    end

    SpawnUtility.addEnemyBuffs(_XsotanTable)
end

function eradicateXsotan_spawnXsotanInfestor()
    local _MethodName = "Порождение Заразителя Ксотан"
    mission.Log(_MethodName, "Начало...")

    local _InfestorSize = mission.data.custom.xsotanSizeBonus.min + mission.data.custom.xsotanSizeBonus.max + 3

    local extraLoot = mission.data.custom.dangerLevel == 10 --This doesn't just drop an extra turret :D
    --Это не просто сбрасывает дополнительную турель :D

    local _X, _Y = Sector():getCoordinates()
    local _Generator = SectorGenerator(_X, _Y)
    local _XsotanInfestor = Xsotan.createInfestor(_Generator:getPositionInSector(2500), _InfestorSize, extraLoot)

    if mission.data.custom.killedGuardian and mission.data.custom.dangerLevel == 10 then
        _XsotanInfestor:addScript("internal/common/entity/background/legendaryloot.lua")
    end

    local _Players = {Sector():getPlayers()}
    if valid(_XsotanInfestor) then
        for _, p in pairs(_Players) do
            ShipAI(_XsotanInfestor.id):registerEnemyFaction(p.index)
        end
        ShipAI(_XsotanInfestor.id):setAggressive()
    end
    
    local _XsotanInfestorTable = {}
    table.insert(_XsotanInfestorTable, _XsotanInfestor)
    SpawnUtility.addEnemyBuffs(_XsotanInfestorTable)
    invokeClientFunction(Player(), "startBossCameraAnimation", _XsotanInfestor.id)
end

function eradicateXsotan_finishAndReward()
    local _MethodName = "Завершение и Награда"
    mission.Log(_MethodName, "Запускаем условие победы.")

    reward()
    accomplish()
end

--endregion

--region #MAKEBULLETIN CALL

function eradicateXsotan_formatDescription(_Station, _insideBarrier)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionTable = {
        "Наши разведчики обнаружили активность ксотан в секторе (${x}:${y}). Это серьезная угроза для наших операций, и с этим нужно разобраться. Мы предлагаем награду любому капитану, достаточно смелому, чтобы отправиться в сектор и уничтожить их. Мы будем ждать вашего возвращения.", --Neutral
        "Ксотан - пятно на галактике, и их необходимо уничтожить. Однако наши силы истощены несколькими недавними конфликтами и не могут адекватно отреагировать на них. Мы обнаружили некоторую активность ксотан в секторе (${x}:${y}). Отправляйтесь туда и уничтожьте каждый из их жалких кораблей, которые вы встретите.", --Aggressive
        "Недавно мы обнаружили вторжение ксотан в секторе (${x}:${y}). Наши силы не готовы отреагировать, и если мы оставим ксотан на произвол судьбы, они могут убить миллионы людей. Нам нужна ваша помощь. Пожалуйста, отправляйтесь туда и уничтожьте любые корабли ксотан, которые вы встретите. Мы заплатим вам за ваши усилия." --Peaceful
    }

    local finalDescription = descriptionTable[descriptionType]

    if _insideBarrier and _Station.title == "Resistance Outpost" then
        if random():test(0.5) then
            finalDescription = "Прилив ксотан бесконечен! Как и наша воля к их победе - но иногда нам нужна помощь. В секторе (${x}:${y}) есть особенно плохой кластер сигнатур ксотан. Нам нужна помощь в их очистке - наши собственные силы истощены, и нам потребуется некоторое время для восстановления."
        end
    end

    return finalDescription
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _Sector = Sector()
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local x, y = _Sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 2, 15, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Средний"
    if insideBarrier then
        _Difficulty = "Сложный"
        if _DangerLevel == 10 then
            _Difficulty = "Экстремальный"
        end
    else
        if _DangerLevel == 10 then
            _Difficulty = "Сложный"
        end
    end

    local _Description = eradicateXsotan_formatDescription(_Station, insideBarrier)

    local _BaseReward = 73000
    local _BaseRelReward = 6000
    if _DangerLevel >= 5 then
        _BaseReward = _BaseReward + 5000
    end
    if _DangerLevel == 10 then
        _BaseReward = _BaseReward + 12000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 3
        _BaseRelReward = _BaseRelReward + 4000
    end

    reward = _BaseReward * Balancing.GetSectorRewardFactor(Sector():getCoordinates()) --SET REWARD HERE
    relreward = _BaseRelReward

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/eradicatexsotan.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "The Xsotan are in \\s(%1%:%2%). Please destroy them.",
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
            reward = {credits = reward, relations = relreward, paymentMessage = "Заработано %1% кредитов за уничтожение Ксотана." },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            inbarrier = insideBarrier
        }},
    }

    return bulletin
end

--endregion