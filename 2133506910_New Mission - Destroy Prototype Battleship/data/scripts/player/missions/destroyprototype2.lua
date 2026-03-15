--[[
    NAME HERE
    NOTES:
        - Man, it's been a long, long time since I made this mission. Feels like an eternity ago.
        - But now, I'm much better at this and I have much better tools at my disposal. Time to make this a fight for the ages. :3
    ADDITIONAL REQUIREMENTS TO DO THIS MISSION:
        - None. Take it from a mission board.
    ROUGH OUTLINE
        - Go to location. Destroy Battleship. Ez.
    DANGER LEVEL
        1+  - [These conditions are present regardless of danger level]
            - A group of 4-6 ships will spawn with the prototype, chosen from the standard threat level.
            - Prototype Scale will be 40.
            - Prototype Turret / Damage factor will be 3.
            - Prototype Loot = 4 guaranteed turrets.
            - Prototype will get 1 randomly chosen defensive script (adaptive / iron curtain / phasemode)
        6-7 - [These conditions are present at danger level 6-7 and above]
            - Prototype Scale will be 50.
            - Prototype Turret Factor will be 4
            - The prototype will get 1 randomly chosen offensive script (overdrive / frenzy / avenger)
            - +1 initial defender
        8-9 - [These conditions are present at danger level 8-9 and above]
            - Prototype Durability will increase by 25%
            - Prototype Damage will increase by 20%
            - Prototype Turret Factor will be 5
            - Prototype has Blocker.
            - Whenever the prototype drops to 50% health, or the initial bandits are destroyed, a group of 6 reinforcement ships will spawn in from the chosen table.
            - The prototype will get a 2nd randomly chosen offensive and defensive script.
            - +1 initial defender
        9 - [These conditions are present at danger level 9 and above]
            - The prototype gets allybooster
        10 - [These conditions are present at danger level 10]
            - Prototype Durability will increase by 25% (50% total)
            - Prototype Damage will increase by 20% (40% total)
            - Prototype Turret Factor will be 6
            - Prototype Damage Factor will be 4
            - Prototype Loot = 6 guaranteed turrets + 3 guaranteed systems.
            - Prototype has Megablocker.
            - All pirate ships are chosen from the High threat table now, instead of the standard threat table.
            - The prototype will get either the torpedoslammer, lasersniper, or siege gun script, chosen at random.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

ESCCUtil = include("esccutil")

local Balancing = include ("galaxy")
local PrototypeGenerator = include("destroyprotogenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local PirateGenerator = include("pirategenerator")
local SpawnUtility = include ("spawnutility")

mission._Debug = 0
mission._Name = "Уничтожить прототип линкора"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    { text = "..." }, --Placeholder
    { text = "Направляйтесь в сектор (${location.x}:${location.y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте Прототип", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.timeLimit = 60 * 60 --Player has 60 minutes.
mission.data.timeLimitInDescription = true --Show the player how much time is left.

mission.data.accomplishMessage = "..." --Placeholder, varies by faction.
mission.data.failMessage = "..." --Placeholder, varies by faction.

local DestroyPrototype_init = initialize
function initialize(_Data_in)
    local methodName = "initialize"
    mission.Log(methodName, "Beginning...")

    if onServer()then
        if not _restoring then
            mission.Log(methodName, "Calling on server - dangerLevel : " .. tostring(_Data_in.dangerLevel))

            local _X, _Y = _Data_in.location.x, _Data_in.location.y

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)
            --[[=====================================================
                CUSTOM MISSION DATA SETUP
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.spawnedSecondWave = false
            mission.data.custom.friendlyFaction = _Giver.factionIndex
            mission.data.custom.battleshipName = ""

            --[[=====================================================
                MISSION DESCRIPTION SETUP:
            =========================================================]]
            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = {x = _X, y = _Y }

            mission.data.icon = _Data_in.iconIn
            mission.data.accomplishMessage = _Data_in.winMsg
            mission.data.failMessage = _Data_in.loseMsg

            --Run standard initialization
            DestroyPrototype_init(_Data_in)
        else
            --Restoring
            DestroyPrototype_init()
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

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

--region #GLOBALPHASE TIMERS

if onServer() then

mission.globalPhase.timers[1] = {
    time = 10,
    callback = function()
        local methodName = "Global Phase Timer"
        mission.Log(methodName, "Beginning.")

        if atTargetLocation() and mission.data.custom.dangerLevel >= 8 and not mission.data.custom.spawnedSecondWave then
            local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}

            if #_Pirates == 1 then
                mission.data.custom.spawnedSecondWave = true
                destroyPrototype_spawnSecondWave()
            end
        end
    end,
    repeating = true
}
    
end

--endregion

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onTargetLocationEntered = function(_X, _Y)
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    destroyPrototype_spawnPrototype()
    destroyPrototype_spawnInitialDefenders()

    mission.data.custom.cleanUpSector = true
end
mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _Prototypes = {Sector():getEntitiesByScriptValue("is_prototype")}

    local entryTaunts = {
        "Вы никогда этого не ожидали!",
        "Кажется, нас обнаружили! Уничтожьте их!",
        "Похоже, это конец. По крайней мере, мы заберем вас с собой.",
        "Узрите нас!",
        "Никогда не думал, что мы умрем, убегая от добродетеля.",
        "В бесконечность! И дальше!",
        "Один выстоит! Один падет!",
        "Цель подтверждена, начинаем боевые действия.",
        "Это будет наша первая и последняя битва!",
        "Посмотрим, на что способна эта крошка, хм?",
        "Полагаю, хороший прототип нуждается в тестировании...",
        "Вам следовало отступить, когда у вас был шанс!",
        "Приготовьтесь!",
        "Готов или нет, я иду!"
    }

    Sector():broadcastChatMessage(_Prototypes[1], ChatMessageType.Chatter, getRandomEntry(entryTaunts))
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].sectorCallbacks = {}
mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _func = "resetTimeToActive"
    local _time = 30 --Дайте игроку передышку, прежде чем линкор снова начнет палить.
    local _BattleShips = {Sector():getEntitiesByScriptValue("is_prototype")}
    local _BattleShip = _BattleShips[1]

    if _BattleShip and valid(_BattleShip) and _BattleShip:getValue("_prototype_superweapon_script") then
        local _script = _BattleShip:getValue("_prototype_superweapon_script")
        _BattleShip:invokeFunction(_script, _func, _time)
    end
end

mission.phases[2].onFail = function()
    if atTargetLocation() then
        local _sector = Sector()
        local _Prototypes = {_sector:getEntitiesByScriptValue("is_prototype")}
        local _prototype = _Prototypes[1]

        local goodbyeTaunts = {
            "Ха! Эта штука неуязвима!",
            "Наконец-то! Гипердвигатель перезаряжен! Уходим отсюда!",
            "Не могу дождаться, чтобы раскрасить город в красный цвет с помощью этого...",
            "Увидимся! Не хотел бы я быть тобой.",
            "Посредственно, капитан!",
            "Все впадут в отчаяние перед нашей мощью!",
            "АхахахахаАХАХАХААХАХАХАХА!!!",
            "Двигатель заряжен, жми!",
            "Как бы мне ни нравился наш маленький танец, пришло время смыться.",
            "Я ожидал от вас большего, капитан. Может быть, в следующий раз."
        }

        _sector:broadcastChatMessage(_prototype, ChatMessageType.Chatter, getRandomEntry(goodbyeTaunts))

        local _protoDurability = Durability(_prototype)
        _prototype:setValue("escc_active_ironcurtain", true) --имитируем активный железный занавес, чтобы phasemode не отключал его.
        if _protoDurability then
            _protoDurability.invincibility = 0.01
        end

        ESCCUtil.allPiratesDepart()
    end
end

--region #PHASE 2 SECTOR CALLBACKS

if onServer() then

mission.phases[2].sectorCallbacks[1] = {
    name = "onDamaged",
    func = function(_Entityidx, _Amount, _Inflictor, _DmgSrc, _DmgType)
        if mission.data.custom.dangerLevel >= 8 and not mission.data.custom.spawnedSecondWave then
            local _DamagedEntity = Entity(_Entityidx)

            if not _DamagedEntity or not valid(_DamagedEntity) then
                return
            end

            if _DamagedEntity:getValue("is_prototype") then
                local _Hull = _DamagedEntity.durability
                local _HullThreshold = _DamagedEntity.maxDurability / 2
                if _Hull < _HullThreshold then
                    mission.data.custom.spawnedSecondWave = true
                    destroyPrototype_spawnSecondWave()
                end
            end
        end
    end
}

end

--endregion

mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _DestroyedEntity = Entity(_ID)

    local _Sector = Sector()

    if atTargetLocation() and _DestroyedEntity:getValue("is_prototype") then
        local _Pirates = {_Sector:getEntitiesByScriptValue("is_pirate")}

        if #_Pirates > 0 then
            for _, _Pirate in pairs(_Pirates) do
                if not _Pirate:getValue("is_prototype") then
                    local _Lines = {
                        "Нет!!! НЕТ!!!",
                        "Проклятье! Мы это запомним!",
                        "Мы еще встретимся!",
                        "Мы будем наблюдать и ждать. Когда вы меньше всего этого ожидаете... тогда мы и нанесем удар.",
                        "Вы еще захлебнетесь вакуумом за это!",
                        "День сегодня ваш, но месть будет за нами!"
                    }
        
                    _Sector:broadcastChatMessage(_Pirate, ChatMessageType.Chatter, getRandomEntry(_Lines))
    
                    break
                end
            end

            for _, _Pirate in pairs(_Pirates) do
                if not _Pirate:getValue("is_prototype") then
                    _Pirate:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))
                end
            end
        end

        destroyPrototype_finishAndReward()
    end
end

mission.phases[2].onAbandon = function()
    destroyPrototype_failAndPunish()
end

--endregion

--region #SERVER CALLS

function destroyPrototype_spawnPrototype()
    local methodName = "Spawn Prototype"
    mission.Log(methodName, "Beginning.")

    local _Rgen = random()

    PirateGenerator.pirateLevel = Balancing_GetPirateLevel(mission.data.location.x, mission.data.location.y)
    local _Scale = 40
    local _DuraFactor = 1.5
    local _DamageFactor = 1.0
    if mission.data.custom.dangerLevel >= 6 then
        _Scale = 50
    end
    if mission.data.custom.dangerLevel >= 8 then
        _DuraFactor = 1.75
        _DamageFactor = 1.2
    end
    if mission.data.custom.dangerLevel == 10 then
        _DuraFactor = 2
        _DamageFactor = 1.4
    end

    local _Danger = mission.data.custom.dangerLevel
    local _Faction = Faction(mission.data.custom.friendlyFaction)
    local _PirateFaction = PirateGenerator:getPirateFaction()
    local _BattleShip =  PrototypeGenerator.create(PirateGenerator.getGenericPosition(), _Faction, _PirateFaction, _Danger, _Scale)

    mission.data.custom.battleshipName = _BattleShip.name
    
    --Add some scripts.
    local _DefensiveScriptsct = 1
    local _OffensiveScriptsct = 0
    local _AddBlocker = false
    local _BlockerToAdd = ""

    if _Danger >= 5 then
        _OffensiveScriptsct = _OffensiveScriptsct + 1
    end
    if _Danger >= 8 then
        _DefensiveScriptsct = _DefensiveScriptsct + 1
        _OffensiveScriptsct = _OffensiveScriptsct + 1
        _AddBlocker = true
        _BlockerToAdd = "blocker.lua"
    end
    if _Danger >= 9 then
        _BattleShip:addScriptOnce("allybooster.lua")
    end
    if _Danger == 10 then
        _DefensiveScriptsct = _DefensiveScriptsct + 1 --Just add them all
        _OffensiveScriptsct = _OffensiveScriptsct + 1
        _BlockerToAdd = "megablocker.lua"
    end

    if _AddBlocker then
        mission.Log(methodName, "Adding blocker script.")
        _BattleShip:addScriptOnce(_BlockerToAdd)
    end

    local _DefensiveScripts = {
        { scriptName = "adaptivedefense.lua" },
        { scriptName = "phasemode.lua", },
        { scriptName = "ironcurtain.lua" }
    }
    local _OffensiveScripts = {
        { scriptName = "overdrive.lua", scriptArgs = { incrementOnPhaseOut = true, incrementOnPhaseOutValue = 0.15 } },
        { scriptName = "avenger.lua" },
        { scriptName = "frenzy.lua", scriptArgs = { _UpdateCycle = 5, _IncreasePerUpdate = 0.3 } }
    }

    shuffle(random(), _DefensiveScripts)
    shuffle(random(), _OffensiveScripts)

    if _DefensiveScriptsct > 0 then
        for idx = 1, _DefensiveScriptsct do
            local _Script = _DefensiveScripts[idx]
            mission.Log(methodName, "Adding defensive script : " .. tostring(_Script.scriptName) .. " script args is : " .. tostring(_Script.scriptArgs))
            _BattleShip:addScriptOnce(_Script.scriptName, _Script.scriptArgs)
        end
    end

    if _OffensiveScriptsct > 0 then
        for idx = 1, _OffensiveScriptsct do
            local _Script = _OffensiveScripts[idx]
            mission.Log(methodName, "Adding offensive script : " .. tostring(_Script.scriptName) .. " script args is : " .. tostring(_Script.scriptArgs))
            _BattleShip:addScriptOnce(_Script.scriptName, _Script.scriptArgs)
        end
    end

    --Add durability.
    local durability = Durability(_BattleShip)
    if durability then 
        local _Factor = (durability.maxDurabilityFactor or 1) * _DuraFactor
        mission.Log(methodName, "Setting durability factor of the prototype to : " .. tostring(_Factor))
        durability.maxDurabilityFactor = _Factor
    end

    --Add damage.
    local _FinalDamageFactor = (_BattleShip.damageMultiplier or 1) * _DamageFactor
    mission.Log(methodName, "Setting final damage factor to : " .. tostring(_FinalDamageFactor))
    _BattleShip.damageMultiplier = _FinalDamageFactor

    --Add the superweapon script.
    if _Danger == 10 then
        local _X, _Y = Sector():getCoordinates()
        local insideBarrier = MissionUT.checkSectorInsideBarrier(_X, _Y)

        local _StaticMult = true
        if insideBarrier then
            _StaticMult = false
        end
        
        --local _Type = 3
        local _Type = _Rgen:getInt(1, 3)
        local sectorWeaponDPS = Balancing_GetSectorWeaponDPS(_X, _Y)
        
        if _Type == 1 then
            mission.Log(methodName, "Torpedo type chosen.")
            --Torpedo
            local _TorpValues = {
                _ROF = 6,
                _DurabilityFactor = 10,
                _TimeToActive = 30,
                _DamageFactor = 4,
                _UseEntityDamageMult = true,
                _UseStaticDamageMult = _StaticMult,
                _AccelFactor = 2,
                _VelocityFactor = 2,
                _TurningSpeedFactor = 2.5,
                _ShockwaveFactor = 2,
                _FireBarrage = true,
                _BarrageCount = 3,
                _BarrageDelay = 0.75
            }
            _BattleShip:addScriptOnce("torpedoslammer.lua", _TorpValues)
            _BattleShip:setValue("_prototype_superweapon_script", "torpedoslammer.lua")
        elseif _Type == 2 then
            mission.Log(methodName, "Siege Gun type chosen.")
            --Siege Gun
            local _SiegeGunValues = {
                _Velocity = 150,
                _ShotCycle = 30,
                _ShotCycleSupply = 0,
                _ShotCycleTimer = 0,
                _UseSupply = false,
                _FragileShots = false,
                _TargetPriority = 1,
                _BaseDamagePerShot = sectorWeaponDPS * 2500,
                _TimeToActive = 30,
                _UseEntityDamageMult = true,
                _UseStaticDamageMult = _StaticMult
            }
            _BattleShip:addScriptOnce("stationsiegegun.lua", _SiegeGunValues)
            _BattleShip:setValue("_prototype_superweapon_script", "stationsiegegun.lua")
        elseif _Type == 3 then
            mission.Log(methodName, "Laser Sniper type chosen.")
            --Laser sniper
            local distToCenter = length(vec2(_X, _Y))
            local laserSniperFactor = 125 --Same damage as a longinus
            if distToCenter > 360 then
                mission.Log(methodName, "No shields available - cut damage in half.")
                laserSniperFactor = 62 --Cut it in half to compensate for lack of shields.
            end

            local _LaserSniperValues = {
                _DamagePerFrame = sectorWeaponDPS * laserSniperFactor,
                _TimeToActive = 30,
                _UseEntityDamageMult = true,
                _UseStaticDamageMult = _StaticMult
            }
            _BattleShip:addScriptOnce("lasersniper.lua", _LaserSniperValues)
            _BattleShip:setValue("_prototype_superweapon_script", "lasersniper.lua")
        end
    end

    --Attach the boss script.
    if mission.data.custom.dangerLevel == 10 then
        _BattleShip:addScriptOnce("esccbossdespair.lua")
    else
        _BattleShip:addScriptOnce("esccbossblades.lua")
    end
end

function destroyPrototype_spawnInitialDefenders()
    local methodName = "Spawn Initial Defenders"
    mission.Log(methodName, "Beginning.")

    local _Table = "Standard"
    if mission.data.custom.dangerLevel == 10 then
        _Table = "High"
    end

    local _Rgen = ESCCUtil.getRand()

    local _LowBound = 4
    local _HighBound = 6
    local _Piratect = _Rgen:getInt(_LowBound, _HighBound)
    if mission.data.custom.dangerLevel >= 6 then
        _Piratect = _Piratect + 1
    end
    if mission.data.custom.dangerLevel >= 8 then
        _Piratect = _Piratect + 1
    end

    mission.Log(methodName, "Spawning table of " .. tostring(_Piratect) .. " " .. tostring(_Table) .. " pirates.")

    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _Piratect, _Table, false)
    local _CreatedPirateTable = {}

    PirateGenerator.pirateLevel = Balancing_GetPirateLevel(mission.data.location.x, mission.data.location.y)
    for _, _Pirate in pairs(_PirateTable) do
        table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
    end

    SpawnUtility.addEnemyBuffs(_CreatedPirateTable)
end

function destroyPrototype_spawnSecondWave()
    local methodName = "Spawn Pirate Wave"
    mission.Log(methodName, "Beginning.")

    local _Table = "Standard"
    if mission.data.custom.dangerLevel == 10 then
        _Table = "High"
    end

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 6, _Table, false)

    local generator = AsyncPirateGenerator(nil, destroyPrototype_onSecondWaveFinished)
    generator.pirateLevel = Balancing_GetPirateLevel(mission.data.location.x, mission.data.location.y)

    generator:startBatch()

    local distance = 250 --_#DistAdj
    if mission.data.custom.dangerLevel == 10 then
        distance = 350
    end
    local pirate_positions = generator:getStandardPositions(#waveTable, distance)
    for posCtr, p in pairs(waveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCtr])
    end

    generator:endBatch()
end
function destroyPrototype_onSecondWaveFinished(_Generated)
    SpawnUtility.addEnemyBuffs(_Generated)

    local _Name = mission.data.custom.battleshipName
    local _Taunts = {
        "Подкрепление на станции! Держитесь, " .. _Name,
        "Мы разорвем вас на куски!",
        "Если " .. _Name .. " будет уничтожен, все это зря! Защитите его любой ценой!",
        "Всем кораблям, оружие на полную! В бой! В бой! В бой!",
        "Держись, " .. _Name .. ", кавалерия здесь!",
        "Не возражаете, если мы вмешаемся?"
    }

    Sector():broadcastChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(_Taunts))
end

function destroyPrototype_finishAndReward()
    local methodName = "Завершение и награда"
    mission.Log(methodName, "Выполнение условия победы.")

    reward()
    accomplish()
end

function destroyPrototype_failAndPunish()
    local methodName = "Провал и наказание"
    mission.Log(methodName, "Выполнение условия проигрыша.")

    punish()
    fail()
end

--endregion

--region #MAKEBULLETIN CALL

function destroyPrototype_formatWinMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Нейтральный / 2 = Агрессивный / 3 = Мирный

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = 
    { 
        "Спасибо. Вот ваша награда, как и было обещано.",
        "Спасибо, что разобрались с этим отребьем. Мы перевели награду на ваш счет.",
        "Спасибо за ваши хлопоты. Мы перевели награду на ваш счет."
    }

    return _Msgs[_MsgType]
end

function destroyPrototype_formatLoseMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Нейтральный / 2 = Агрессивный / 3 = Мирный

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = {
        "Вы не смогли его уничтожить? Очень жаль. Мы найдем кого-нибудь другого, кто позаботится об этом.",
        "Мы видим, что вы не справились с задачей. Неприятно, но неудивительно. Нам следовало позаботиться об этом самим.",
        "Вы не смогли его уничтожить? Это плохо... у нас и так было мало вариантов..."
    }

    return _Msgs[_MsgType]
end

function destroyPrototype_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local _DescriptionType = 1 --Нейтральный
    if _Aggressive > 0.5 then
        _DescriptionType = 2 --Агрессивный.
    elseif _Aggressive <= -0.5 then
        _DescriptionType = 3 --Мирный.
    end

    local _Desc = {
        "Нам нужна ваша помощь. Наш новый линкор был угнан пиратами, и мы не можем позволить себе оставить его в руках врага, иначе они смогут скопировать его и использовать экспериментальные технологии для улучшения своих кораблей. Нам нужно, чтобы вы его уничтожили. Не волнуйтесь - мы вознаградим вас за это. Мы считаем, что компенсация достаточна для этой задачи.\n\nМы считаем, что его сопровождают дополнительные пиратские корабли. Будьте осторожны при приближении.\n\nПохоже, они не отключили маяк слежения корабля. Он показывает, что корабль в настоящее время находится в (${x}:${y}).",
        "Какие-то отмороженные пираты украли один из наших новых линкоров! Он должен был стать гордостью нашего нового флота, но теперь он годится только на металлолом! Нужно преподать урок. Потеря материалов прискорбна, но те, кто крадет у нас, должны осознать последствия своих действий.\n\nРазведка сообщает, что некоторые из бандитов сбежали со своим призом. Это не имеет значения. Они заплатят вместе с остальными.\n\nМы отследили его до (${x}:${y}). Уничтожьте корабль и убейте всех причастных.",
        "Мы разрабатывали прототип системы самообороны, когда он был захвачен бандой пиратов! Мы сожалеем, что все так обернулось, но система должна быть уничтожена, прежде чем у них появится шанс скопировать технологию и улучшить свои корабли. Или, что еще хуже, продать ее нашим врагам. К сожалению, наших сил недостаточно для этой задачи.\n\nСигналы с радиолокационного модуля линкора показывают, что его сопровождают. Будьте осторожны при приближении.\n\nТрекер на украденном корабле показывает, что он находится в (${x}:${y}). Пожалуйста, сделайте то, что необходимо."
    }

    return _Desc[_DescriptionType]
end

mission.makeBulletin = function(_Station)
    local methodName = "Make Bulletin"

    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _Rgen = ESCCUtil.getRand()
    local _sector = Sector()

    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 7, 20, insideBarrier)

    if not target.x or not target.y then
        mission.Log(methodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)

    local _IconIn = nil
    local _Difficulty = "Сложный"
    if _DangerLevel > 5 then
        _Difficulty = "Экстремальный"
    end
    if _DangerLevel == 10 then
        _IconIn = "data/textures/icons/hazard-sign.png"
        _Difficulty = "Death Sentence"
    end
    
    local _Description = destroyPrototype_formatDescription(_Station)
    local _WinMsg = destroyPrototype_formatWinMessage(_Station)
    local _LoseMsg = destroyPrototype_formatLoseMessage(_Station)

    local _BaseReward = 500000
    if _DangerLevel > 5 then
        _BaseReward = _BaseReward + 200000
    end
    if _DangerLevel == 10 then
        _BaseReward = _BaseReward + 300000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    local rewardFactor = Balancing.GetSectorRewardFactor(_sector:getCoordinates())
    reward = _BaseReward * rewardFactor --SET REWARD HERE
    reputation = 8000 + (8000 * (0.0175 * _DangerLevel) * rewardFactor) --Anywhere from 8000 to 64500
    punishRep = reputation / 2
    if reputation > 20000 then
        punishRep = reputation / 2.5
    end
    if _DangerLevel == 10 then
        reputation = reputation * 1.5
    end

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        icon = _IconIn,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/destroyprototype2.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо. Мы отследили линкор до \\s(%i:%i). Пожалуйста, уничтожьте его.",
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
            reward = { credits = reward, relations = reputation, paymentMessage = "Заработано %1% за уничтожение прототипа." },
            punishment = { relations = punishRep },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            winMsg = _WinMsg,
            loseMsg = _LoseMsg,
            iconIn = _IconIn
        }},
    }

    return bulletin
end

--endregion