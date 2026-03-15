--[[
    MISSION 4: Gone in 60 Seconds
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local AsyncPirateGenerator = include ("asyncpirategenerator")
local AsyncShipGenerator = include ("asyncshipgenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Угнать за 60 секунд"

--region #INIT / DATA

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "Вы нанесли удар по таинственной группе, стоящей за зашифрованным чипом данных, и узнали их название. Оказывается, это публичная организация. Варланс пообещал связаться с вами, когда узнает о них больше." },
    { text = "Прочитайте письмо Варланса", bulletPoint = true, fulfilled = false },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте буксир", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте эскорт буксира", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Выведите из строя линкор", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Сопроводите Варланса к выведенному из строя линкору", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Защищайте Варланса, пока он не захватит линкор", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Рекомендуется) Уничтожьте AWACS", bulletPoint = true, fulfilled = false, visible = false }
}

--Пользовательские данные, которые нам понадобятся.
mission.data.custom.dangerLevel = 10 --Все основано на уровне опасности 10.
mission.data.custom.phase2Timer = 0
mission.data.custom.checkEscortCount = false
mission.data.custom.towSpawned = false
mission.data.custom.varlanceP2WarningSent = false
mission.data.custom.phase3Timer = 0
mission.data.custom.varlanceP3Chatter1Sent = false
mission.data.custom.varlanceP3Chatter2Sent = false
mission.data.custom.varlanceP4ChatterSent = false
mission.data.custom.waveState = 1 --1 = нет кораблей, можно создавать / 2 = корабли вышли + отправить чат Варланса / 3 = чат Варланса отправлен + можно сбросить
mission.data.custom.waveNumber = 1
mission.data.custom.awacsTimer = 0

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
            kothStory4_awacsDeparts()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
            kothStory4_awacsDeparts()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
            kothStory4_awacsDeparts()
        end
        runFullSectorCleanup(false)
    end
end

--Нет необходимости в onEnter / onLeave - игрок почти сразу проиграет, если Варланса больше нет в секторе с ними (то есть, если они выпрыгнут).
--region #GLOBALPHASE TIMER CALLLS

if onServer() then

mission.globalPhase.timers[1] = {
    time = 10,
    callback = function()
        if mission.data.custom.checkForVarlance and mission.data.custom.varlanceID then
            local _Varlance = Entity(mission.data.custom.varlanceID)

            if not _Varlance or not valid(_Varlance) then
                fail()
            end
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Получите сектор, который очень близок к внешнему краю барьера.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory4_getNextLocation(true)

    local _X = mission.data.custom.firstLocation.x
    local _Y = mission.data.custom.firstLocation.y

    mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y) --Установите уровень пиратов на основе первого местоположения.

    mission.data.description[3].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Отправить письмо игроку.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Привет, приятель.\n\nЯ провел небольшое расследование. Horizon Keepers, LTD. — одна из крупнейших корпораций в этой части галактики. Похоже, что их публичный фасад — это продажа радиолокационных установок, а также зондов и другого сенсорного оборудования. Никто не знает, чем они занимаются в других сферах, и меня довольно быстро заткнули, когда я начал задавать вопросы. Я проверил обломки грузовых кораблей, которые мы уничтожили ранее, и похоже, что капитанам удалось удалить журналы. Однако я нашел в трюмах несколько странных деталей ксотан.\n\nЯ бы сказал, что нам не повезло, так как ни одна из других запланированных поставок не появилась, но я слышал, что соседняя экспедиция в разлом обернулась к худшему. Я не могу сказать наверняка, но думаю, что Horizon могла быть причастна.\n\nМы собираемся украсть один из их кораблей.\n\nЕсли слухи правдивы, они должны буксировать один из своих тяжеловесов через (%1%:%2%). Встретьтесь со мной там и прикройте меня, пока моя команда его угоняет. Нам придется действовать быстро — мы не хотим дать им шанс уйти.\n\nВарланс", _X, _Y)
	_Mail.header = "Провел небольшое расследование"
	_Mail.sender = "Варланс @FrostbiteCompany"
	_Mail.id = "_horizon_story4_mail"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story4_mail" then
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
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.firstLocation

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_x, _y)
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true

    if onServer() then
        kothStory4_buildObjectiveSector(_x, _y)
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_x, _y)
    mission.data.custom.checkForVarlance = true
    HorizonUtil.varlanceChatter("Вот они. Уничтожьте этот буксир и выведите из строя двигатели линкора. Остальное я беру на себя.")
end

mission.phases[2].updateTargetLocationServer = function(_timeStep)
    local _MethodName = "Phase 2 Update Target Location Server"
    --проверьте буксир. Если он находится рядом в течение 60 секунд, мы проиграем.
    --Будьте осторожны с включением журналов в этом методе - они будут публиковаться каждую секунду.
    local _towCt = ESCCUtil.countEntitiesByValue("_horizon4_towship")
    local _towDestroyed = false
    local _escortsDestroyed = false
    local _bshipDisabled = false

    mission.data.custom.phase2Timer = mission.data.custom.phase2Timer + _timeStep

    if mission.data.custom.towSpawned then
        if _towCt > 0 then
            if mission.data.custom.phase2Timer >= 30 and not mission.data.custom.varlanceP2WarningSent then
                HorizonUtil.varlanceChatter("Обнаружен скачок напряжения! Буксир пытается сбежать!")
                mission.data.custom.varlanceP2WarningSent = true
            end
    
            if mission.data.custom.phase2Timer >= 60 then
                fail()
            end
        else
            --mission.Log(_MethodName, "Tow is destroyed.")
            mission.data.description[4].fulfilled = true
            _towDestroyed = true
        end
    end

    local _pirateCt = ESCCUtil.countEntitiesByValue("_horizon4_escort")
    if mission.data.custom.checkEscortCount and _pirateCt == 0 then
        --mission.Log(_MethodName, "Escorts are destroyed.")
        mission.data.description[5].fulfilled = true
        _escortsDestroyed = true
    end

    local _horizonBShip = Entity(mission.data.custom.horizonBattleshipid)
    local _bShipHPThreshold = _horizonBShip.durability / _horizonBShip.maxDurability
    if _bShipHPThreshold < 0.26 then
        --mission.Log(_MethodName, "Battleship is disabled.")
        mission.data.description[6].fulfilled = true
        _bshipDisabled = true
    end

    sync() --Синхронизируйте обновленные цели с клиентом.
    if _towDestroyed and _escortsDestroyed and _bshipDisabled then
        nextPhase()
    end
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    mission.data.description[7].visible = true
end

mission.phases[3].onBeginServer = function()
    local _hBattleship = Entity(mission.data.custom.horizonBattleshipid)
    local _varlanceAI = ShipAI(mission.data.custom.varlanceID)

    _varlanceAI:stop()
    _varlanceAI:setPassiveShooting(true)
    _varlanceAI:registerFriendEntity(mission.data.custom.horizonBattleshipid)
    _varlanceAI:setFollow(_hBattleship, false)

    HorizonUtil.varlanceChatter("Хорошая работа. Сближаюсь с нашей добычей, чтобы начать абордаж.")
end

mission.phases[3].updateTargetLocationServer = function(_timeStep)
    mission.data.custom.phase3Timer = mission.data.custom.phase3Timer + _timeStep

    if mission.data.custom.phase3Timer >= 30 and not mission.data.custom.varlanceP3Chatter1Sent then
        HorizonUtil.varlanceChatter("Невозможно, чтобы мы помешали им подать сигнал бедствия. Удивлен, что мы еще не видели подкреплений.")
        mission.data.custom.varlanceP3Chatter1Sent = true
    end

    if mission.data.custom.phase3Timer >= 60 and not mission.data.custom.varlanceP3Chatter2Sent then
        HorizonUtil.varlanceChatter("... Очень удивлен.")
        mission.data.custom.varlanceP3Chatter2Sent = true
    end

    local _hBattleship = Entity(mission.data.custom.horizonBattleshipid)
    local _varlance = Entity(mission.data.custom.varlanceID)

    if _hBattleship:getNearestDistance(_varlance) < 500 then
        nextPhase()
    end
end

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    mission.data.description[7].fulfilled = true
    mission.data.description[8].visible = true
end

mission.phases[4].onBeginServer = function()
    HorizonUtil.varlanceChatter("Начинаю абордаж. Установлены заряды для пробития корпуса! Держитесь, пока мы не закончим, приятель.")
end

mission.phases[4].updateTargetLocationServer = function(_timeStep)
    local _MethodName = "Phase 4 Update Target Location Server"
    --Обновите статус волны, если остался 1 пират - линкор Horizon считается пиратом.
    local _pirateCt = ESCCUtil.countEntitiesByValue("is_pirate")
    if _pirateCt == 1 then
        if mission.data.custom.waveState == 2 then
            mission.Log(_MethodName, "Sending varlance chat for " .. tostring(mission.data.custom.waveNumber) .. " and resetting wave state.")

            local _lineidx = mission.data.custom.waveNumber - 1
            local _varlanceLines = {
                "Внешний корпус пробит. Палубы 55-42 чисты.",
                "Зачистка палуб 42-15. Приближаемся к машинному отделению.",
                "Проверка машинного отделения и жилых помещений на наличие ловушек...",
                "Пока все хорошо. БИЦ зачищен, двигаемся к мостику.",
                "Совсем немного осталось. Команда устанавливает заряды у дверей мостика.",
                "Линкор наш! Хорошая работа, приятель! Устанавливаю координаты гиперпространства!"
            }

            HorizonUtil.varlanceChatter(_varlanceLines[_lineidx])
            kothStory4_explodeBShip()

            mission.data.custom.waveState = 3
        elseif mission.data.custom.waveState == 3 then
            mission.Log(_MethodName, "Resetting wave state. Ships may spawn now.")
            mission.data.custom.waveState = 1
        end

        if mission.data.custom.waveNumber == 7 then
            nextPhase()
        end
    end
end

mission.phases[4].onEntityDestroyed = function(id, lastDamageInflictor)
    local _MethodName = "Phase 4 On Entity Destroyed"
    local _destroyedEntity = Entity(id)
    if _destroyedEntity:getValue("is_horizon_awacs") then
        mission.Log(_MethodName, "AWACS destroyed.")
        --Снимите скрипты с артиллерийских крейсеров и верните им базовый.
        local _artyCruisers = { Sector():getEntitiesByScriptValue("is_horizon_artycruiser") }

        for _, _arty in pairs(_artyCruisers) do
            while _arty:hasScript("torpedoslammer.lua") do
                _arty:removeScript("torpedoslammer.lua") --снимите все торпедные установки.
            end

            local _artyAI = ShipAI(_arty)
            local _varlance = Entity(mission.data.custom.varlanceID)
            _artyAI:stop()
            _artyAI:setPassiveShooting(false)
            _artyAI:setAttack(_varlance) --Атакуйте его нормально, когда AWACS исчезнет.

            local torpSlammerValues = {
                _TimeToActive = 5,
                _ROF = 6,
                _PreferWarheadType = 3, --Fusion
                _PreferBodyType = 7, --Osprey
                _DurabilityFactor = 4,
                _TargetPriority = 2, --Script value
                _TargetTag = "is_varlance"
            }

            _arty:addScript("torpedoslammer.lua", torpSlammerValues)
        end
        mission.data.description[9].fulfilled = true
        sync()
    end
end

--region #PHASE 4 TIMER CALLS

if onServer() then

mission.phases[4].timers[1] = {
    time = 60,
    callback = function()
        local _MethodName = "Phase 4 Timer 1 Callback"
        mission.Log(_MethodName, "Running phase 4 timer 1")

        --Не делайте ничего, если мы не на месте. Технически это не нужно, так как выпрыгивание игрока приводит к провалу миссии в этот момент.
        if atTargetLocation() then
            if mission.data.custom.waveState == 1 and mission.data.custom.waveNumber < 7 then
                mission.Log(_MethodName, "Spawning pirate wave " .. tostring(mission.data.custom.waveNumber))
                kothStory4_spawnPirateWave()
                if mission.data.custom.waveNumber == 6 then
                    kothStory4_spawnHorizonWave()
                end
    
                if not mission.data.custom.varlanceP4ChatterSent then
                    HorizonUtil.varlanceChatter("Вот они. Потребовалось много времени.")
                    mission.data.custom.varlanceP4ChatterSent = true
                end
    
                mission.data.custom.waveNumber = mission.data.custom.waveNumber + 1
            end
        end
    end,
    repeating = true
}

mission.phases[4].timers[2] = {
    time = 5,
    callback = function()
        local _MethodName = "Phase 4 Timer 2 Callback"
        --AWACS уходит, когда взрываются артиллерийские крейсеры, независимо от того, сколько пиратов осталось.
        local _artyCt = ESCCUtil.countEntitiesByValue("is_horizon_artycruiser")
        if _artyCt == 0 then
            kothStory4_awacsDeparts()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].onBeginServer = function()
    local _hBattleship = Entity(mission.data.custom.horizonBattleshipid)
    local _Faciton = HorizonUtil.getFriendlyFaction()

    _hBattleship.factionIndex = _Faciton.index
    _hBattleship:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
end

local kothStory4_onPhase5VarlanceDialogEnd = makeDialogServerCallback("kothStory4_onPhase5VarlanceDialogEnd", 5, function()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    kothStory4_finishAndReward()
end)

--region #PHASE 5 TIMER CALLS

if onServer() then

mission.phases[5].timers[1] = {
    time = 5,
    callback = function()
        invokeClientFunction(Player(), "kothStory4_onPhase5Dialog", mission.data.custom.varlanceID)
    end,
    repeating = false
}

end

--endregion

--endregion

--region #SERVER CALLS

function kothStory4_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Getting a location.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Получите сектор, который очень близок к внешнему краю барьера.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 6, 16, false)
    end

    mission.Log(_MethodName, "X coordinate of next location is : " .. tostring(target.x) .. " Y coordinate of next location is : " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Could not find a suitable mission location. Terminating script.")
        terminate()
        return
    end

    return target
end

--endregion
function kothStory4_buildObjectiveSector(_x, _y)
    local _MethodName = "Build Objective Sector"
    mission.Log(_MethodName, "Начало.")

    local _random = random()
    local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)

    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local _basepos = ESCCUtil.getVectorAtDistance(pos, 4000, true)
    local matrix = MatrixLookUpPosition(look, up, _basepos)
    --Create tow ship
    local generator = AsyncShipGenerator(nil, kothStory4_onTowingShipFinished)
    generator:createTradingShip(_Faction, matrix)

    local _towLook = matrix.look
    local _towLookn = normalize(_towLook)
    local _bshipPos = _basepos + (_towLookn * -300) --Should spawn the battleship .3 km behind the tow ship.
    local _bshipMatrix = MatrixLookUpPosition(look, up, _bshipPos)

    --Create Horizon battleship
    local hbattleship = HorizonUtil.spawnHorizonBattleship(false, _bshipMatrix, _Faction)
    hbattleship:addScriptOnce("player/missions/horizon/story4/horizonstory4battleship.lua")
    hbattleship:setValue("is_pirate", true)
    mission.data.custom.horizonBattleshipid = hbattleship.index
    
    --Create group of 6 pirates @ threat level 4
    local pirateGenerator = AsyncPirateGenerator(nil, kothStory4_onPirateEscortsFinished)
    pirateGenerator.pirateLevel = mission.data.custom.pirateLevel

    local _PirateTable = ESCCUtil.getStandardWave(4, 6, "Standard")

    local _GetEscortPosition = function(_cpos)
        local vec = ESCCUtil.getVectorAtDistance(_cpos, 1000, false)
        local look = vec3(math.random(), math.random(), math.random())
        local up = vec3(math.random(), math.random(), math.random())

        return MatrixLookUpPosition(look, up, vec)
    end

    pirateGenerator:startBatch()

    for _, _Pirate in pairs(_PirateTable) do
        pirateGenerator:createPirateByName(_Pirate, _GetEscortPosition(_basepos))
    end

    pirateGenerator:endBatch()

    kothStory4_spawnVarlance()

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function kothStory4_onTowingShipFinished(_Generated)
    local _MethodName = "On Towing Ship Finished"
    mission.Log(_MethodName, "Начало.")
    
    _Generated.title = "Буксир"
    ESCCUtil.removeCivilScripts(_Generated)
    _Generated:setValue("is_pirate", true)
    _Generated:setValue("_horizon4_towship", true)
    _Generated:setValue("bDisableXAI", true) --Disable any Xavorion AI

    local _ShipAI = ShipAI(_Generated)
    local _ShipPos = _Generated.position

    _ShipAI:setPassiveShooting(true)
    _ShipAI:setFlyLinear(_ShipPos.look * 20000, 0, false)

    local durability = Durability(_Generated)
	if durability then 
        durability.maxDurabilityFactor = (durability.maxDurabilityFactor or 0) * 2.5
    end
    
    mission.data.custom.towSpawned = true
end

function kothStory4_onPirateEscortsFinished(_Generated)
    mission.data.custom.checkEscortCount = true

    for _, _Escort in pairs(_Generated) do
        _Escort:setValue("_horizon4_escort", true)
    end

    SpawnUtility.addEnemyBuffs(_Generated)

    Placer.resolveIntersections()
end

function kothStory4_spawnVarlance()
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Варланса - создаю его.")

        local _Varlance = HorizonUtil.spawnVarlanceNormal(false)
        local _VarlanceAI = ShipAI(_Varlance)
    
        _VarlanceAI:setAggressive()

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory4_explodeBShip()
    local _MethodName = "Explode Battleship"
    local _hBattleship = Entity(mission.data.custom.horizonBattleshipid)
    local _Pos = _hBattleship.translationf
    local _Rad = _hBattleship:getBoundingSphere().radius

    _hBattleship.durability = _hBattleship.maxDurability * 0.25
    _hBattleship.shieldDurability = 0

    local _SecondRadMinScale = 0.4
    local _SecondRadMaxScale = 0.9
    local _MinOffset = -9
    local _MaxOffset = math.abs(_MinOffset) * 2

    mission.Log(_MethodName, "Создаю основной взрыв")
    kothStory4_spawnExplosion(_Pos, _Rad)

    local xRand = random()
    local secondaryCt = xRand:getInt(2, 4)
    
    for _ = 1, secondaryCt do
        local vecX = _Pos.x + (_MinOffset + xRand:getInt(0, _MaxOffset))
        local vecY = _Pos.y + (_MinOffset + xRand:getInt(0, _MaxOffset))
        local vecZ = _Pos.z + (_MinOffset + xRand:getInt(0, _MaxOffset))
        local _XPosition = vec3(vecX, vecY, vecZ)
        local _XRad = _Rad * xRand:getFloat(_SecondRadMinScale, _SecondRadMaxScale)

        mission.Log(_MethodName, "Откладываю вторичные взрывы. Vec is " .. tostring(_XPosition) .. " and rad is " .. tostring(_XRad))

        deferredCallback(xRand:getFloat(0.8, 2.2), "kothStory4_spawnExplosion", _XPosition, _XRad)
    end
end

function kothStory4_spawnPirateWave()
    --common vals
    local _WaveDanger = 4 + mission.data.custom.waveNumber
    local _Distance = 250 --_#DistAdj
    local _ct = 4

    local _spawnFunc = function(onSpawnFunc)
        local wingGenerator = AsyncPirateGenerator(nil, onSpawnFunc)
        wingGenerator.pirateLevel = mission.data.custom.pirateLevel

        local wingTable = ESCCUtil.getStandardWave(_WaveDanger, _ct, "Standard", false)
        local wingPositions = wingGenerator:getStandardPositions(_Distance, _ct)

        wingGenerator:startBatch()

        for posIdx, _pirate in pairs(wingTable) do
            wingGenerator:createScaledPirateByName(_pirate, wingPositions[posIdx])
        end

        wingGenerator:endBatch()
    end

    --spawn alpha wing
    _spawnFunc(kothStory4_onSpawnAlphaWingFinished)

    --spawn beta wing
    _spawnFunc(kothStory4_onSpawnBetaWingFinished)
end

function kothStory4_onSpawnAlphaWingFinished(_Generated)
    mission.data.custom.waveState = 2

    --Attacks Varlance
    local _TargetPriorityData = {
        _TargetPriority = 1,
        _TargetTag = "is_varlance"
    }

    for _, _ship in pairs(_Generated) do
        _ship:addScript("ai/priorityattacker.lua", _TargetPriorityData)
    end

    SpawnUtility.addEnemyBuffs(_Generated)

    Placer.resolveIntersections()
end

function kothStory4_onSpawnBetaWingFinished(_Generated)
    mission.data.custom.waveState = 2

    --Attacks the player
    local _TargetPriorityData = {
        _TargetPriority = 2
    }

    for _, _ship in pairs(_Generated) do
        _ship:addScript("ai/priorityattacker.lua", _TargetPriorityData)
    end

    SpawnUtility.addEnemyBuffs(_Generated)

    Placer.resolveIntersections()
end

function kothStory4_spawnHorizonWave()
    local _MethodName = "Spawn Horizon Wave"
    mission.Log(_MethodName, "Начало.")

    local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)

    local HorizonBattleship = Entity(mission.data.custom.horizonBattleshipid)
    local hBshipPos = HorizonBattleship.translationf
    local look = HorizonBattleship.translationf
    local up = HorizonBattleship.up
    local pos1 = ESCCUtil.getVectorAtDistance(hBshipPos, 3000, true)
    local pos2 = ESCCUtil.getVectorAtDistance(pos1, 1000, false) --Get one reasonably close

    local _random = random()
    local look2 = _random:getVector(-100, 100)
    local up2 = _random:getVector(-100, 100)
    local pos3 = ESCCUtil.getVectorAtDistance(hBshipPos, 4500, true)

    --Spawn 2x arty cruisers
    local _arty1 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos1), _Faction)
    local _arty2 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos2), _Faction)

    local _artyTable = { _arty1, _arty2 }
    for _, _arty in pairs(_artyTable) do
        local _artyAI = ShipAI(_arty)
        
        _artyAI:setIdle()
        _artyAI:setPassiveShooting(true)
        _artyAI:setFlyLinear(hBshipPos, 2500, false)

        local torpSlammerValues = {
            _TimeToActive = 5,
            _ROF = 6,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 7, --Osprey
            _DurabilityFactor = 4,
            _TargetPriority = 2, --Script value
            _TargetTag = "is_varlance"
        }

        local torpSlammerValues2 = {
            _TimeToActive = 30,
            _ROF = 4,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 7, --Osprey
            _DurabilityFactor = 8,
            _TargetPriority = 2, --Script value
            _TargetTag = "is_varlance"
        }

        local torpSlammerValues3 = {
            _TimeToActive = 60,
            _ROF = 2,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 8, --Eagle
            _DurabilityFactor = 16,
            _TargetPriority = 2, --Script value
            _TargetTag = "is_varlance",
            _AccelFactor = 1.5,
            _VelocityFactor = 1.5,
            _ShockwaveFactor = 2
        }

        --The death torps - he won't be able to stay alive for super long under this type of pressure.
        --Encourage the player to hit the AWACS first.
        local torpSlammerValues4 = {
            _TimeToActive = 90,
            _ROF = 2,
            _PreferWarheadType = 2, --Neutron
            _PreferBodyType = 9, --Hawk
            _DurabilityFactor = 72,
            _TargetPriority = 2, --Script value
            _TargetTag = "is_varlance",
            _AccelFactor = 3,
            _VelocityFactor = 2,
            _ShockwaveFactor = 6
        }

        _arty:addScript("torpedoslammer.lua", torpSlammerValues)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues2)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues3)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues4)
        _arty:setValue("is_pirate", true)
    end

    --Spawn AWACS
    local _awacs = HorizonUtil.spawnHorizonAWACS(false, MatrixLookUpPosition(look2, up2, pos3), _Faction)
    local _awacsAI = ShipAI(_awacs)
    _awacsAI:setFlyLinear(hBshipPos, 4000, false)
    _awacsAI:setPassiveShooting(true)

    HorizonUtil.varlanceChatter("Устал посылать своих пешек напоследок, я вижу. Приоритизируйте AWACS - он координирует действия с этими артиллерийскими крейсерами.")
    mission.data.description[9].visible = true
    sync()
end

function kothStory4_awacsDeparts()
    local _awacsPlural = { Sector():getEntitiesByScriptValue("is_horizon_awacs") }
    if #_awacsPlural > 0 then
        local _awacs = _awacsPlural[1]
        _awacs:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
        mission.data.description[9].fulfilled = true
    end
end

function kothStory4_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _player = Player()

    local _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."
    local _BaseReward = 19600000

    _player:setValue("_horizonkeepers_story_stage", 5)
    _player:setValue("encyclopedia_koth_horizonkeepers", true)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward, paymentMessage = "Захват линкора принес %1% кредитов." }

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #SERVER / CLIENT CALLS

function kothStory4_spawnExplosion(_Pos, _Rad)
    local _MethodName = "Spawn Explosion"
    if not _Pos  or not _Rad then return end

    if onServer() then
        mission.Log(_MethodName, "Вызов на сервере => Вызов на клиенте")
        invokeClientFunction(Player(), "kothStory4_spawnExplosion", _Pos, _Rad)
        return
    end

    mission.Log(_MethodName, "Вызвано на клиенте")
    --vec3 gets sent to client as table - have to unpack it
    local cPos = vec3(_Pos.x, _Pos.y, _Pos.z)
    Sector():createExplosion(cPos, _Rad, false)
end

--endregion

--region #CLIENT CALLS

function kothStory4_onPhase5Dialog(_VarlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "У них был скелетный экипаж на борту, но мы ударили быстро и сильно. Достаточно быстро, чтобы помешать им что-либо удалить, к счастью."
    d0.followUp = d1

    d1.text = "Их автоматизированная система очистки была повреждена в экспедиции, и они не удосужились ее отремонтировать. Небрежная работа, если вы спросите меня."
    d1.followUp = d2

    d2.text = "Мы накажем их за их самодовольство. Это займет некоторое время, но я просмотрю их банки данных и посмотрю, куда мы можем ударить, чтобы им было больнее всего."
    d2.followUp = d3

    d3.text = "Хорошая работа сегодня. Я свяжусь с вами, когда у меня будет больше информации."
    d3.onEnd = kothStory4_onPhase5VarlanceDialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(_VarlanceID):interactShowDialog(d0, false)
end

--endregion