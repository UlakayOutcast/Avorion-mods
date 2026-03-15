--[[
    MISSION 1: Hunt Pirate Fleet
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local SectorGenerator = include ("SectorGenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Охота на пиратский флот"

--region #INIT / DATA

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "Вы получили следующий запрос от ${sectorName} ${giverTitle}:" }, --Placeholder
    { text = "..." }, --Placeholder
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте остатки пиратского флота", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте первую волну пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте вторую волну пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте третью волну пиратов", bulletPoint = true, fulfilled = false, visible = false }
}

mission.data.accomplishMessage = "Отличная работа, капитан - компания Frostbite благодарит вас. Мы перевели награду на ваш счет."

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.advancePhase = false --Allows for the phase to advance.
mission.data.custom.givenChip = false
mission.data.custom.spawnedRemnants = false
mission.data.custom.spawnedAsteroids = false

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

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

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --Player has 5 minutes to head back to the sector.
    mission.data.timeLimitInDescription = true --Show the player how much time is left.
end

--region #GLOBALPHASE TIMERS
if onServer() then

mission.globalPhase.timers[1] = {
    time = 10, 
    callback = function() 
        local _MethodName = "Global Phase Timer 1 Callback"

        if atTargetLocation() then
            --Don't do any of this unless we're on location
            --Не делайте ничего из этого, если мы не на месте
            local _pirateCt = ESCCUtil.countEntitiesByValue("is_pirate")

            mission.Log(_MethodName, "Количество пиратов : " .. tostring(_pirateCt) .. " таймеру разрешено продвигаться : " .. tostring(mission.data.custom.advancePhase))

            if mission.data.custom.advancePhase and _pirateCt == 0 then
                mission.data.custom.advancePhase = false
                nextPhase()
            end
        end
    end,
    repeating = true
}

mission.globalPhase.timers[2] = {
    time = 180, --He doesn't have the resources of Adriana, can't respawn as quickly.
    --У него нет ресурсов Адрианы, не может так быстро возродиться.
    callback = function()
        local _MethodName = "Global Phase Timer 2 Callback"

        if atTargetLocation() then
            mission.Log(_MethodName, "На месте - возрождаем Варланса, если необходимо.")

            kothStory1_spawnVarlance()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[1] = {}
mission.phases[1].onBegin = function()
    local _Giver = Entity(mission.data.giver.id)

    mission.data.description[1].arguments = { sectorName = Sector().name, giverTitle = _Giver.translatedTitle }
    mission.data.description[2].text = kothStory1_formatDescription()
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
end

mission.phases[1].updateServer = function(_timestep)
    if atTargetLocation() then
        local _pirateCt = ESCCUtil.countEntitiesByValue("is_pirate")

        if _pirateCt == 1 and not mission.data.custom.sentDistress then
            mission.data.custom.sentDistress = true
            kothStory1_sendDistressCall()
        end
    end
end

mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Phase 1 On Target Location Entered"
    mission.Log(_MethodName, "Начинаем...")
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    if onServer() then
        kothStory1_createAsteroidFields(x, y)
        kothStory1_spawnVarlance()
        kothStory1_spawnPirateRemnants()

        showMissionUpdated(mission._Name)
    end
end

mission.phases[2] = {}
mission.phases[2].showUpdateOnStart = true
mission.phases[2].onBegin = function()
    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
end

mission.phases[2].onBeginServer = function()
    local _MethodName = "Phase 2 On Begin Server"
    mission.Log(_MethodName, "Начинаем...")
    kothStory1_spawnPirateWave(1)
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnStart = true
mission.phases[3].timers = {}
mission.phases[3].onBegin = function()
    mission.data.description[5].fulfilled = true
    mission.data.description[6].visible = true
end

mission.phases[3].onBeginServer = function()
    local _MethodName = "Phase 3 On Begin Server"
    mission.Log(_MethodName, "Начинаем...")
    kothStory1_spawnPirateWave(2)
end

--region #PHASE 3 TIMERS

if onServer() then

mission.phases[3].timers[1] = {
    time = 15,
    callback = function()
        if atTargetLocation() then
            kothStory1_spawnTorpedoStrike()
        end
    end,
    repeating = false
}

end

--endregion

mission.phases[4] = {}
mission.phases[4].showUpdateOnStart = true
mission.phases[4].onBegin = function()
    mission.data.description[6].fulfilled = true
    mission.data.description[7].visible = true
end

mission.phases[4].onBeginServer = function()
    local _MethodName = "Phase 4 On Begin Server"
    mission.Log(_MethodName, "Начинаем...")
    kothStory1_spawnPirateWave(3)
end

mission.phases[4].updateServer = function(_timeStep)
    --If the chip has not been given yet...
    --Если чип еще не выдан...
    if atTargetLocation() and mission.data.custom.advancePhase then
        kothStory1_givePlayerChip()
    end
end

mission.phases[5] = {}
mission.phases[5].onBegin = function()
    mission.data.description[7].fulfilled = true
end

mission.phases[5].onBeginServer = function()
    --Spawn Varlance if he doesn't already exist.
    --Создать Варланса, если он еще не существует.
    kothStory1_spawnVarlance()

    --Give the player the chip if somehow phase 4 hasn't given them the chip yet.
    --Дать игроку чип, если по какой-то причине фаза 4 еще не дала им чип.
    kothStory1_givePlayerChip()

    --Get varlance and his ID.
    --Получить Варланса и его ID.
    local _Varlance = Entity(mission.data.custom.varlanceID)

    invokeClientFunction(Player(), "kothStory1_onPhase5Dialog", _Varlance.id)
end

local kothStory1_onPhase5DialogEnd = makeDialogServerCallback("kothStory1_onPhase5DialogEnd", 5, function()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    kothStory1_finishAndReward()
end)

--endregion

--region #SERVER CALLS

function kothStory1_createAsteroidFields(x, y)
    local methodName = "Создать поля астероидов"

    if not mission.data.custom.spawnedAsteroids then
        local _Generator = SectorGenerator(x, y)

        _Generator:createAsteroidField()
    
        local _fields = random():getInt(3, 5)
        --Add: 3-5 small asteroid fields.
        --Добавить: 3-5 небольших поля астероидов.
        for _ = 1, _fields do
            _Generator:createSmallAsteroidField()
        end

        mission.data.custom.spawnedAsteroids = true

        mission.data.custom.cleanUpSector = true
    end
end

function kothStory1_spawnVarlance()
    local _MethodName = "Создать Варланса"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Варланса - создаем его.")

        local _Varlance = HorizonUtil.spawnVarlanceNormal(true)
        local _VarlanceAI = ShipAI(_Varlance)
    
        _VarlanceAI:setAggressive()

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory1_spawnPirateRemnants()
    local _MethodName = "Создать остатки пиратов"
    mission.Log(_MethodName, "Running.")
    mission.Log(_MethodName, "Выполняется.")

    if not mission.data.custom.spawnedRemnants then
        local generator = AsyncPirateGenerator(nil, kothStory1_onPirateRemnantsFinished)

        generator:startBatch()
    
        generator:createScaledPirateByName("Outlaw", generator.getGenericPosition())
        generator:createScaledPirateByName("Outlaw", generator.getGenericPosition())
        generator:createScaledPirateByName("Outlaw", generator.getGenericPosition())
        generator:createScaledPirateByName("Bandit", generator.getGenericPosition())
        generator:createScaledPirateByName("Bandit", generator.getGenericPosition())
        generator:createScaledPirateByName("Pirate", generator.getGenericPosition())
        generator:createScaledPirateByName("Scorcher", generator.getGenericPosition())
        generator:createScaledPirateByName("Devastator", generator.getGenericPosition())
    
        generator:endBatch()

        mission.data.custom.spawnedRemnants = true
    end
end

function kothStory1_onPirateRemnantsFinished(_Generated)
    mission.data.custom.advancePhase = true

    local xrand = random()

    for _, _ship in pairs(_Generated) do
        local duraFactor = xrand:getFloat(.2, .5)
        _ship.durability = _ship.maxDurability * duraFactor
        _ship:removeScript("fleeondamaged.lua") --They already ran.
        --Они уже убежали.
    end

    SpawnUtility.addEnemyBuffs(_Generated)
end

function kothStory1_sendDistressCall()
	--print("sending distress call")
    --print("отправка сигнала бедствия")
    local _sector = Sector()
    local x, y = _sector:getCoordinates()
    local _pirates = {_sector:getEntitiesByScriptValue("is_pirate")}

	local lastShip = _pirates[1]

	local helpCalls = {
		"Нас убивают! Помогите! ПОМОГИТЕ!!!",
		"Это " .. lastShip.name .. "! Все остальные мертвы! Пришлите помощь!",
		"Это сигнал бедствия! Наша позиция (" .. x .. ":" .. y .. ")! Мы под атакой!",
		"Mayday! Все остальные корабли уничтожены, и мы критически повреждены! Mayday!",
		"Спасите нас! Спасите нас! Ударьте их! Ударьте их!",
		"Поднимите флот по тревоге! Они убьют нас всех!",
		"Нет!!! НЕТ!!! Не так! Не так!"
	}
    shuffle(random(), helpCalls)
    
	_sector:broadcastChatMessage(lastShip, ChatMessageType.Chatter, helpCalls[1])
	Player():sendChatMessage("", 3, "The pirate ship is broadcasting a distress signal!")
	Player():sendChatMessage("", 3, "Пиратский корабль передает сигнал бедствия!")
end

function kothStory1_spawnPirateWave(_waveNo)
    local _MethodName = "Spawn Pirate Wave"
    local _MethodName = "Создать волну пиратов"
    mission.Log(_MethodName, "Spawning wave " .. tostring(_waveNo))
    mission.Log(_MethodName, "Создаем волну " .. tostring(_waveNo))

    --Get a pirate table to spawn based on the wave #
    --Получить таблицу пиратов для создания на основе номера волны
    local _WaveData = {
        { ct = 4, tbl = "Standard", lvl = math.ceil(mission.data.custom.dangerLevel * 0.5), func = kothStory1_onPirateWaveFinished },
        { ct = 4, tbl = "Standard", lvl = math.ceil(mission.data.custom.dangerLevel * 0.75), func = kothStory1_onPirateWaveFinished },
        { ct = 5, tbl = "High", lvl = mission.data.custom.dangerLevel, func = kothStory1_onFinalPirateWaveGenerated }
    }

    local _WaveTable = ESCCUtil.getStandardWave(_WaveData[_waveNo].lvl, _WaveData[_waveNo].ct, _WaveData[_waveNo].tbl, false)

    local _WaveGenerator = AsyncPirateGenerator(nil, _WaveData[_waveNo].func)

    _WaveGenerator:startBatch()

    local _posDistance = 250 --#DistAdj

    local _piratePositions = _WaveGenerator:getStandardPositions(#_WaveTable, _posDistance)

    for posIdx, p in pairs(_WaveTable) do
        _WaveGenerator:createScaledPirateByName(p, _piratePositions[posIdx])
    end

    _WaveGenerator:endBatch()
end

function kothStory1_onPirateWaveFinished(_Generated)
    mission.data.custom.advancePhase = true

    SpawnUtility.addEnemyBuffs(_Generated)
end

function kothStory1_onFinalPirateWaveGenerated(_Generated)
    mission.data.custom.advancePhase = true

    --Add a deadshot script to the first pirate. Make it as powerful as a stock longinus.
    --Добавить скрипт Deadshot первому пирату. Сделайте его таким же мощным, как и стандартный Longinus.
    local _Sector = Sector()
    local x, y = _Sector:getCoordinates()
    local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 125

    local _MiniBoss = _Generated[1]
    
    local _LaserSniperValues = { --#LONGINUS_SNIPER
        _DamagePerFrame = _dpf,
        _TimeToActive = 5,
        _TargetCycle = 15,
        _TargetingTime = 2.25, --Take longer than normal to target.
        --Требуется больше времени, чем обычно, для прицеливания.
        _TargetPriority = 4,
        _pindex = Player().index
    }

    ESCCUtil.setDeadshot(_MiniBoss)
    _MiniBoss:addScriptOnce("lasersniper.lua", _LaserSniperValues)

    SpawnUtility.addEnemyBuffs(_Generated)

    --Get Varlance and have him warn the player.
    --Получите Варланса и попросите его предупредить игрока.
    local _Varlance = { _Sector:getEntitiesByScriptValue("is_varlance") }
    if #_Varlance > 0 then
        _Sector:broadcastChatMessage(_Varlance[1], ChatMessageType.Chatter, "Это Deadshot, тяжелая лазерная платформа. Похоже, он охотится за вами - оставайтесь мобильными и следите за его лучом наведения.")
    end
end

--Torp strike
--Торпедный удар
function kothStory1_spawnTorpedoStrike()
    local _MethodName = "Spawning Torpedo Strike"
    local _MethodName = "Создание торпедного удара"

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 3, "High", false) --They're only in for 8-9 seconds. Make them the larger ships.
    --Они здесь всего 8-9 секунд. Сделайте их более крупными кораблями.

    local generator = AsyncPirateGenerator(nil, kothStory1_onTorpStrikePirateSpawned)

    generator:startBatch()

    for _, p in pairs(waveTable) do
        mission.Log(_MethodName, "Создание пирата для торпедного удара " .. tostring(_) .. " из 3")
        generator:createScaledPirateByName(p, generator.getGenericPosition())
    end

    generator:endBatch()
end

function kothStory1_givePlayerChip()
    if not mission.data.custom.givenChip then
        local _Player = Player()
        local items = _Player:getInventory():getItemsByType(InventoryItemType.VanillaItem)
        local _PlayerHasChip = false
        for _, slot in pairs(items) do
            local item = slot.item

            -- we assume they're stackable, so we return here
            -- мы предполагаем, что они складываются в стопку, поэтому возвращаемся сюда
            if item:getValue("subtype") == "HorizonStoryDataChip" then
                _PlayerHasChip = true
                break
            end
        end

        if _PlayerHasChip then
            mission.data.custom.givenChip = true
        else
            if ESCCUtil.countEntitiesByValue("is_pirate") == 0 then
                _Player:getInventory():add(HorizonUtil.getEncryptedDataChip())
                mission.data.custom.givenChip = true
            end
        end
    end
end

function kothStory1_onTorpStrikePirateSpawned(_Generated)
    for _, _Ship in pairs(_Generated) do
        local _TorpSlamValues = {
            _ROF = 2,
            _DurabilityFactor = 2,
            _TimeToActive = 0,
            _DamageFactor = 3,
            _UseEntityDamageMult = true,
            _TargetPriority = 5,
            _pindex = Player().index
        }

        _Ship:addScriptOnce("torpedoslammer.lua", _TorpSlamValues)
        _Ship:addScriptOnce("utility/delayeddelete.lua", random():getFloat(8, 9)) --Should give it enough time to fire 3x and peace out.
        --Должно дать достаточно времени, чтобы выстрелить 3 раза и уйти.
        ESCCUtil.setBombardier(_Ship)
    end

    Placer.resolveIntersections(_Generated)

    SpawnUtility.addEnemyBuffs(_Generated)
end

function kothStory1_finishAndReward()
    local _MethodName = "Finish and Reward"
    local _MethodName = "Завершить и наградить"
    mission.Log(_MethodName, "Running win condition.")
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _player = Player()
    _player:setValue("_horizonkeepers_story_stage", 2)
    _player:setValue("encyclopedia_koth_frostbite", true)
    _player:setValue("encyclopedia_koth_varlance", true)

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT DIALOG CALLS

function kothStory1_onPhase5Dialog(_VarlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}

    d0.text = "Вот как сражается независимый капитан."
    d0.followUp = d1

    d1.text = "Говорят, война никогда не меняется. Но в последнее время... кажется, что-то изменилось. Тяжелые лазерные платформы. Торпедные удары с шоковым прыжком... Такое ощущение, что галактика находится на острие ножа. В любой момент фракции могут оказаться под Дамокловым мечом, рассекающим их шею."
    d1.followUp = d2

    d2.text = "Полагаю, для этого и нужны такие люди, как мы. Люди, которые не боятся запятнать руки кровью... неважно, нашей или чужой."
    d2.followUp = d3

    d3.text = "Что ж, теперь мы боевые товарищи. Так что позвольте мне помочь вам - похоже, вы подобрали зашифрованный чип данных. Я знаю кого-то, кто может взломать это шифрование. Нужно только выяснить, где они залегли на дно."
    d3.followUp = d4

    d4.text = "Я свяжусь с вами. Постарайтесь не умереть там."
    d4.answers = {
        { answer = "I'll do my best.", onSelect = kothStory1_onPhase5DialogEnd },
        { answer = "Я сделаю все возможное.", onSelect = kothStory1_onPhase5DialogEnd },
        { answer = "Thank you.", followUp = d5 }
        { answer = "Спасибо.", followUp = d5 }
    }

    d5.text = "Не стоит благодарности. Если повезет, мы еще встретимся."
    d5.onEnd = kothStory1_onPhase5DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4, d5}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(_VarlanceID):interactShowDialog(d0, false)
end

--endregion

--region #MAKEBULLETIN CALL

function kothStory1_formatDescription()
    return "Всем независимым капитанам: это капитан Варланс из наемнической группы Frostbite Company. Наш флот отразил ожесточенную пиратскую атаку на местную фракцию, но нескольким их поврежденным кораблям удалось отступить, прежде чем мы смогли их добить. Я собираюсь преследовать их, но мне нужна поддержка - дело в том, что мы не знаем, насколько хорошо они оснащены, и большинство кораблей моей группы нуждаются в ремонте. Помогите мне выследить остатки этого пиратского флота. Я позабочусь о том, чтобы вы получили компенсацию за свою работу."
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    local _MethodName = "Сделать объявление"
    mission.Log(_MethodName, "Making Bulletin.")
    mission.Log(_MethodName, "Делаем объявление.")

    local target = {}
    --GET TARGET HERE:
    --ПОЛУЧИТЬ ЦЕЛЬ ЗДЕСЬ:
    local x, y = Sector():getCoordinates()
    target.x, target.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, false)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x или Target.y не установлены - возвращаем nil.")
        return 
    end

    reward = ESCCUtil.clampToNearest(600000 * Balancing.GetSectorRewardFactor(x, y), 5000, "Up") --SET REWARD HERE
    --УСТАНОВИТЬ НАГРАДУ ЗДЕСЬ

    local bulletin =
    {
        -- data for the bulletin board
        -- данные для доски объявлений
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = kothStory1_formatDescription(),
        difficulty = "Средний",
        difficulty = "Средний",
        reward = "¢${reward}",
        script = "missions/horizon/horizonstory1.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Мы отследили флот до \\s(%1%:%2%). Встретьтесь со мной там, и мы уничтожим их.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if player:hasScript("missions/horizon/horizonstory1.lua") 
               or player:getValue("_horizonkeepers_story_stage") > 1 then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "You cannot accept this mission again.")
                return 0
            end
            return 1
        ]],
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],

        -- data that's important for our own mission
        -- данные, важные для нашей собственной миссии
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = {credits = reward, paymentMessage = "Заработано %1% кредитов за уничтожение пиратского флота."}
        }},
    }

    return bulletin
end

--endregion
