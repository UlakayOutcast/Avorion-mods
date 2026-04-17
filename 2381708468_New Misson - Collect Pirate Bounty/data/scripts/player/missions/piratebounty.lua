--[[
    Ambush Pirate Raiders
    NOTES:
        - Copy of the first side mission from Long Live The Empress - mission bulletin edition.
    ADDITIONAL REQUIREMENTS TO DO THIS MISSION:
        None
    ROUGH OUTLINE
        - Go to a sector.
        - After a few seconds, pirate raiders start to show up.
        - Kill them all. Very simple and straightforward.
    DANGER LEVEL
        1+ - [These conditions are present regardless of danger level]
            - N/A
        8 - [These conditions are present at danger level 8 and above]
            - 25% chance to be attacked by a group of headhunters after each jump as long as you have this mission active.
            - Headhunter group is the Galactic Headhunter Faction and not the Pirates, so does not count towards bounty.
        10 - [These conditions are present at danger level 10]
            - Chance of headhunter attack is 50%
            - Headhunters have 2 extra ships.  
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")
include ("randomext")
include ("faction")

ESCCUtil = include("esccutil")

local AsyncShipGenerator = include("asyncshipgenerator")
local Placer = include ("placer")
local Balancing = include("galaxy")
local SpawnUtility = include ("spawnutility")
local EventUT = include("eventutility")

mission._Debug = 0
mission._Name = "Collect Pirate Bounty"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    {text = "Вы получили следующий запрос от ${sectorName} ${giverTitle}:" }, --Placeholder
    {text = "..." },
    { text = "${killedTargets} / ${targets} целей уничтожено", bulletPoint = true, fulfilled = false },
}
mission.data.timeLimit = 60 * 60 * 4 --У вас есть 4 часа.
mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
mission.data.failMessage = "Срок действия контракта на награду истек. Спасибо за вашу усердную работу."

mission.data.accomplishMessage = "Спасибо за выполнение контракта на награду. Мы перевели награду на ваш счет."

local PirateBounty_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начало...")

    if onServer() then
        --Нам это не нужно на клиенте. Мы не можем использовать встроенный в structuredmission, потому что в нем отсутствует SectorChangeType.
        Player():registerCallback("onSectorEntered", "collectPirateBounty_pirateBountyOnSectorEntered")

        if not _restoring then
            mission.Log(_MethodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel) .. " - enemy : " .. tostring(_Data_in.targetFaction))

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)
            --[[=====================================================
                CUSTOM MISSION DATA:
                .dangerLevel
                .pirateFaction
                .targets
                .killedTargets
                .blockHunters
                .timePassed
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.pirateFaction = _Data_in.targetFaction
            mission.data.custom.targets = _Data_in.targets
            mission.data.custom.killedTargets = 0
            mission.data.custom.timePassed = 0
            mission.data.custom.playerSwitchedViaJump = false
            mission.data.custom.freeSectorSwitches = 3

            local _TargetFaction = Faction(mission.data.custom.pirateFaction)

            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = { targets = tostring(mission.data.custom.targets), targetFaction = _TargetFaction.name }
            mission.data.description[3].arguments = { targetFaction = _TargetFaction.name, targets = tostring(mission.data.custom.targets), killedTargets = "0" }

            --Запустить стандартную инициализацию
            PirateBounty_init(_Data_in)
        else
            --Восстановление
            PirateBounty_init()
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

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].triggers = {}

if onServer() then

mission.phases[1].triggers[1] = {
    condition = function()
        local _MethodName = "Phase 1 Trigger 1 Condition"
        return mission.data.custom.killedTargets >= mission.data.custom.targets
    end,
    callback = function()
        local _MethodName = "Phase 1 Trigger 1 Callback"
        collectPirateBounty_finishAndReward()
    end,
    repeating = false    
}

end

mission.phases[1].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Phase 1 On Entity Destroyed"
    local _DestroyedEntity = Entity(_ID)
    local _EntityDestroyer = Entity(_LastDamageInflictor)

    if not _EntityDestroyer or not valid(_EntityDestroyer) or not _DestroyedEntity or not valid(_DestroyedEntity) then
        mission.Log(_MethodName, "Уничтоженный объект / объект-разрушитель равен нулю - возвращаемся.")
        return
    end

    if (_DestroyedEntity.type == EntityType.Ship or _DestroyedEntity.type == EntityType.Station) and (_EntityDestroyer.type == EntityType.Ship or _EntityDestroyer.type == EntityType.Station) then
        mission.Log(_MethodName, "И разрушитель, и разрушенный были кораблями / станциями - проверяем индексы фракций.")
        local _dfindex = _EntityDestroyer.factionIndex -- индекс "фракции разрушителя"
        local _pfindex = mission.data.custom.pirateFaction -- индекс "пиратской фракции"
        local _player = Player()
        local _pindex = _player.index

        if _DestroyedEntity.factionIndex == _pfindex and (_dfindex == _pindex or (_player.allianceIndex and _dfindex == _player.allianceIndex)) then
            mission.data.custom.killedTargets = mission.data.custom.killedTargets + 1
            mission.data.description[3].arguments.killedTargets = mission.data.custom.killedTargets
            sync()
        end
    end
end

mission.phases[1].onSectorArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Phase 1 On Sector Arrival Confirmed"
    if mission.data.custom.playerSwitchedViaJump and mission.data.custom.dangerLevel >= 8 then
        
        local _PirateCount = ESCCUtil.countEntitiesByValue("is_pirate")

        if _PirateCount == 0 then
            local _Rgen = ESCCUtil.getRand()
            local _HunterChance = 4
            if mission.data.custom.dangerLevel == 10 then
                --50% chance instead of 25%
                _HunterChance = 2
            end

            local _TimePassed = mission.data.custom.timePassed
            local _Hours = math.max(math.floor(_TimePassed / 3600), 1)

            _HunterChance = _HunterChance * _Hours --снижает частоту появления, удваивая знаменатель на 2-м часу, утраивая на 3-м часу. Срок действия миссии истекает после 4-го часа, поэтому это не имеет значения.

            mission.Log(_MethodName, "Пираты не найдены. Рассчитываем шанс появления охотников за головами как 1 к " .. tostring(_HunterChance))
            local _SpawnHunters = _Rgen:getInt(1, _HunterChance) == 1

            local _Player = Player()
            local _HX, _HY = _Player:getHomeSectorCoordinates()
            if _X == _HX and _Y == _HY then
                _SpawnHunters = false
                mission.Log(_MethodName, "Не создавайте охотников за головами в домашнем секторе игрока.")
            end

            if not EventUT.persecutorEventAllowed() then
                _SpawnHunters = false
                mission.Log(_MethodName, "Утилита событий говорит, что события преследователя нет - устанавливаем для появления охотников значение false.")
            end

            if mission.data.custom.blockHunters then
                mission.Log(_MethodName, "Охотники за головами недавно появлялись. Блокируем появление.")
                mission.data.custom.blockHunters = false
            else
                if _SpawnHunters then
                    mission.data.custom.blockHunters = true
                    mission.Log(_MethodName, "Создаем охотников за головами.")
                    mission.phases[1].timers[1] = {
                        time = 5, 
                        callback = function() collectPirateBounty_spawnHunters() end, 
                        repeating = false
                    }
                end
            end
        end
    end
end

mission.phases[1].update = function(_TimeStep)
    mission.data.custom.timePassed = (mission.data.custom.timePassed or 0) + _TimeStep
end

--endregion

--region #SERVER CALLS

function collectPirateBounty_pirateBountyOnSectorEntered(player, x, y, changeType)
    local methodName = "Pirate Bounty On Sector Entered"
    mission.Log(methodName, "Проверяем тип прибытия. Игрок прибыл через " .. tostring(changeType))

    if changeType == SectorChangeType.Jump or changeType == SectorChangeType.Gate or changeType == SectorChangeType.Wormhole then
        mission.Log(methodName, "Игрок прибыл через прыжок. Охотники могут появиться, если это применимо.")
        mission.data.custom.playerSwitchedViaJump = true
    else
        mission.data.custom.playerSwitchedViaJump = false
        if changeType == SectorChangeType.Switch then
            mission.Log(methodName, "Игрок прибыл через переключение. Проверяем наличие бесплатных переключений...")
            mission.data.custom.freeSectorSwitches = mission.data.custom.freeSectorSwitches - 1
            if mission.data.custom.dangerLevel == 10 and random():test(0.5) then
                mission.data.custom.freeSectorSwitches = mission.data.custom.freeSectorSwitches - 1
            end

            if mission.data.custom.freeSectorSwitches <= 0 then --Если у нас закончились бесплатные переключения, считаем, что игрок совершил прыжок.
                mission.Log(methodName, "У игрока закончились бесплатные переключения. Считаем это прыжком.")
                mission.data.custom.playerSwitchedViaJump = true
            end
        end
    end
end

function collectPirateBounty_getHeadHunterFaction()
    local _X, _Y = Sector():getCoordinates()

    return EventUT.getHeadhunterFaction(_X, _Y)
end

function collectPirateBounty_spawnHunters()
    local _MethodName = "Spawn Hunters"
    local _HeadHunterFaction = collectPirateBounty_getHeadHunterFaction()
    local _Rgen = ESCCUtil.getRand()

    local _HunterGenerator = AsyncShipGenerator(nil, collectPirateBounty_onHuntersFinished)
    _HunterGenerator:startBatch()
    
    local _Volume = Balancing_GetSectorShipVolume(Sector():getCoordinates())
    local _HunterPositions = _HunterGenerator:getStandardPositions(200, 6)
    local _RandomExtraVolume = _Rgen:getInt(1, 3) - 1

    local _BlockerPosition = 4
    if mission.data.custom.dangerLevel == 10 then
        _BlockerPosition = 6
    end

    _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[1], _Volume * 4)
    _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[2], _Volume * 4)
    _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[3], _Volume * 4)
    if mission.data.custom.dangerLevel == 10 then
        _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[4], _Volume * (4 + _RandomExtraVolume))
        _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[5], _Volume * (4 + _RandomExtraVolume))
    end
    _HunterGenerator:createBlockerShip(_HeadHunterFaction, _HunterPositions[_BlockerPosition], _Volume * 2)

    _HunterGenerator:endBatch()
end

function collectPirateBounty_onHuntersFinished(_Generated)
    local _MethodName = "On Hunters Finished"
    local _Player = Player()

    for _, _Ship in pairs(_Generated) do
        local _AI = ShipAI(_Ship)
        _AI:setAggressive()
        _AI:registerEnemyFaction(_Player.index)
        _AI:registerFriendFaction(mission.data.custom.pirateFaction) --Очень маловероятно, что это вступит в игру.
        if _Player.allianceIndex then
            _AI:registerEnemyFaction(_Player.allianceIndex)
        end

        _Ship:setValue("secret_contractor", mission.data.custom.pirateFaction)
        MissionUT.deleteOnPlayersLeft(_Ship)
        _Ship:setValue("is_persecutor", true)

        mission.Log(_MethodName, "Название корабля - " .. _Ship.title)

        if string.match(_Ship.title, "Persecutor") then
            _Ship.title = "Охотник за головами"%_T
        end
    end

    local note = collectPirateBounty_makeHeadHunterNote(Player(), Faction(mission.data.custom.pirateFaction), mission.data.custom.dangerLevel)
    Loot(_Generated[1]):insert(note)

    Placer.resolveIntersections(_Generated)

    SpawnUtility.addEnemyBuffs(_Generated)

    local headhunterMessages =
    {
        "Это ${player}! Именно его хочет наш клиент!"%_T,
        "Нашел тебя, ${player}. Давай собьем его и получим свои деньги. Быстро."%_T,
        "Вот они. Ладно, ${player}, ничего личного, это просто работа."%_T,
        "Ты думал, они сделают это легким для тебя?",
        "Время умирать, ${player}."
    }

    _Player:sendChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(headhunterMessages) % {player = _Player.name})

    mission.data.custom.playerSwitchedViaJump = false --Сброс на случай, если игрок выйдет из системы / снова войдет в систему. OnSectorArrivalConfirmed для миссии будет запущен до пользовательского обратного вызова.
    mission.data.custom.freeSectorSwitches = 3 --Сброс до 3 переключений.
end

function collectPirateBounty_makeHeadHunterNote(player, huntingFaction, dangerLevel)
    local x, y = Sector():getCoordinates()
    local money = round(math.max(50000, 500000 * Balancing_GetSectorRichnessFactor(x, y)) / 10000) * 10000
    if dangerLevel == 10 then
        money = money * 3
    end
    local reward = "¢${money}" % {money = createMonetaryString(money)}
    local shipName = "Неизвестно"%_t

    local craft = player.craft
    if valid(craft) then
        if craft.name and craft.name ~= "" then
            shipName = craft.name
        end
    end

    local note = VanillaInventoryItem()
    note.name = "Чип награды"%_t
    note.price = 1000

    local rarity = Rarity(RarityType.Common)
    note.rarity = rarity
    note:setValue("subtype", "BountyChip")
    note.icon = "data/textures/icons/bounty-chip.png"
    note.iconColor = rarity.color
    note.stackable = true

    local tooltip = Tooltip()
    tooltip.icon = note.icon
    tooltip.rarity = rarity

    local title = note.name

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = note.rarity.tooltipFontColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "Награда"%_t
    line.icon = "data/textures/icons/cash.png"
    line.iconColor = ColorRGB(1, 1, 1)
    line.rtext = reward
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "Цель"%_t
    line.rtext = "${faction:"..player.index.."}"
    line.icon = "data/textures/icons/player.png"
    line.iconColor = ColorRGB(1, 1, 1)
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Корабль"%_t
    line.rtext = shipName
    line.icon = "data/textures/icons/ship.png"
    line.iconColor = ColorRGB(1, 1, 1)
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Цель должна быть мертва."%_t
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Для получения награды требуется подтверждение уничтожения корабля."%_t
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = " - ${faction:"..huntingFaction.index.."}"
    tooltip:addLine(line)


    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Похоже, кто-то нажил себе врагов."%_t
    line.lcolor = ColorRGB(0.4, 0.4, 0.4)
    tooltip:addLine(line)

    note:setTooltip(tooltip)

    return note
end

function collectPirateBounty_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Запускаем условие победы.")

    --Дайте игроку бонус, если ему придется иметь дело с охотниками.
    if mission.data.custom.dangerLevel >= 8 then
        mission.data.reward.paymentMessage = mission.data.reward.paymentMessage .. " Это включает в себя бонус."
        mission.data.reward.credits = mission.data.reward.credits * 1.2
    end

    reward()
    accomplish()
end

--endregion

--region #MAKEBULLETIN CALL

function collectPirateBounty_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionTable = {
        "Любым капитанам, обладающим некоторым боевым опытом, - мы хотели бы, чтобы вы взяли на себя ${targetFaction} для нас. У нас было много проблем с тем, что они нападали на грузовые суда и другие гражданские цели, и мы хотели бы, чтобы вы это прекратили. Уничтожения ${targets} их кораблей или станций должно быть достаточно. Вы будете вознаграждены за свою работу.",
        "Слушайте, капитан! ${targetFaction} Нужно немного урезать. Мы могли бы легко уничтожить их сами, но наши военные заняты в другом месте, и мы не можем позволить себе разделить наши силы. С этой целью мы готовы заплатить вам за охоту на ${targets} кораблей или станций, принадлежащих ${targetFaction}. Нам все равно, как и где вы их найдете, главное, чтобы вы от них избавились.",
        "Мир вам, капитан. Наши дипломатические усилия потерпели неудачу, и ${targetFaction} безудержно бесчинствуют в наших секторах. Мы сожалеем, что до этого дошло, но нам нужно, чтобы вы уничтожили ${targets} их кораблей или станций. За это вам тоже полагается награда. Пожалуйста. Если мы не остановим ${targetFaction} в ближайшее время, невозможно предсказать, какой ущерб они нанесут."
    }

    return descriptionTable[descriptionType]
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"

    local _random = random()
    local _sector = Sector()

    local _X, _Y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(_X, _Y)

    local _PirateLevel = Balancing_GetPirateLevel(_X, _Y)
    local _TargetFaction = Galaxy():getPirateFaction(_PirateLevel)
    --Нет целевого сектора. Просто возьмите его и сохраните.
    
    local _Description = collectPirateBounty_formatDescription(_Station)

    local _DangerLevel = _random:getInt(1, 10)
    --local _DangerLevel = 10
    local _MaxTargets = 22
    local _Difficulty = "Лёгкий"
    local _Targets = _random:getInt(5, _MaxTargets)

    local _BaseReward = 5500
    if _DangerLevel == 10 then
        _Targets = math.min(_Targets + 5, _MaxTargets) --Добавьте смещение в сторону большего количества целей, но не превышайте максимум.
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    reward = _BaseReward * _Targets * Balancing.GetSectorRewardFactor(_sector:getCoordinates())

    local bulletin =
    {
        -- data for the bulletin board
        brief = "Собрать пиратскую награду",
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/piratebounty.lua",
        formatArguments = {targetFaction = _TargetFaction.name, targets = tostring(_Targets), reward = createMonetaryString(reward)},
        msg = "Спасибо! Мы отправим вашу награду, когда пираты будут уничтожены.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if player:hasScript("missions/piratebounty.lua") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принять дополнительные контракты на пиратскую награду! Откажитесь от текущего или завершите его.")
                return 0
            end
            return 1
        ]],
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg)
        ]],

        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = nil,
            reward = {credits = reward, relations = 6000, paymentMessage = "Заработано %1% кредитов за сбор награды за " .. _TargetFaction.name .. "."},
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            targetFaction = _TargetFaction.index,
            targets = _Targets
        }},
    }

    return bulletin
end

--endregion