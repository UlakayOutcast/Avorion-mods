package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local Balancing = include ("galaxy")
local PirateGen = include("pirategenerator")
local AsyncPirateGen = include ("asyncpirategenerator")
local PrototypeGenerator = include("destroyprotogenerator")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include ("shiputility")
MissionUT = include("missionutility")
include("relations")
include("mission")
include("utility")
include("stringutility")
include("callable")

missionData.brief = "Уничтожить прототип линкора"%_t --missionData.brief shows on the left-hand side in the list.
missionData.title = "Уничтожить прототип линкора"%_t --missionData.title shows whenever the mission is accepted / accomplished / abandoned.

function getUpdateInterval()
    return 2
end

function initialize(giverId, x, y, reward, punishment, dangerValue)

    initMissionCallbacks()

    if onClient() then
        sync()
	else
		Player():registerCallback("onSectorEntered", "onSectorEntered")
		Player():registerCallback("onSectorLeft", "onSectorLeft")
		Player():registerCallback("onSectorArrivalConfirmed", "onSectorArrivalConfirmed")
    end
	
	if onServer() and not _restoring then
		local station = Entity(giverId)
		local offeringFaction = Faction(station.factionIndex)
		local dAggroValue = offeringFaction:getTrait("aggressive")	

		missionData.giver = station.id
		missionData.factionIndex = station.factionIndex
		missionData.location = {x = x, y = y}
		missionData.dangerValue = dangerValue
		missionData.stationName  = station.name
		missionData.stationTitle = station.translatedTitle
		missionData.reward = reward
		missionData.punishment = punishment
		--Get the description / accomplish + fail messages -- these are initialized here instead of being static values at the start of the script (unlike most other misisons)
		--this is because they depend on the aggressive trait value of the faction (and the random danger value), which is impossible to determine before the script has run.
		local bulletinDescription = fmtMissionDescription(dAggroValue, missionData.dangerValue)
		missionData.description = {}
		missionData.description[1] = "Вы получили следующий запрос от " .. Sector().name .. " " .. station.translatedTitle .. ":"
		missionData.description[2] = bulletinDescription % missionData.location
		missionData.description[3] = "- Исследовать (${x}:${y})" % missionData.location
		missionData.accomplishMessage = fmtWinMessage(dAggroValue)
		missionData.failMessage = fmtFailMessage(dAggroValue)
		--Variables used to keep various events from happening twice.
		missionData.spawnedEnemies = false
		missionData.spawnedSecondWave = false
		missionData.bshipTauntSent = false
	end
end

--mimics structuredmission.reward, becasue Mission doesn't have a similar function call. Pretty boilerplate but eh, what can you do.
function giveReward()
	if onClient() then return end

	local receiver = Player().craftFaction or Player()
	local r = missionData.reward
	
	if r.credits
		or r.iron
		or r.titanium
		or r.naonite
		or r.trinium
		or r.xanion
		or r.ogonite
		or r.avorion then
		
		receiver:receive(r.paymentMessage or "", r.credits or 0, r.iron or 0, r.titanium or 0, r.naonite or 0, r.trinium or 0, r.xanion or 0, r.ogonite or 0, r.avorion or 0)
	end
	
    if r.relations and missionData.factionIndex then
        local faction = Faction(missionData.factionIndex)
        if faction and faction.isAIFaction then
            changeRelations(receiver, faction, r.relations, r.relationChangeType, true, false)
        end
    end
end

function givePunishment()
	if onClient() then return end

    local punishee = Player().craftFaction or Player()
    local p = missionData.punishment

    if p.credits
        or p.iron
        or p.titanium
        or p.naonite
        or p.trinium
        or p.xanion
        or p.ogonite
        or p.avorion then

        punishee:pay(p.paymentMessage or "", 
					math.abs(p.credits or 0),
					math.abs(p.iron or 0),
					math.abs(p.titanium or 0),
					math.abs(p.naonite or 0),
					math.abs(p.trinium or 0),
					math.abs(p.xanion or 0),
					math.abs(p.ogonite or 0),
					math.abs(p.avorion or 0))
    end

	if p.relations and missionData.factionIndex then
        local faction = Faction(missionData.factionIndex)
        if faction and faction.isAIFaction then
            changeRelations(punishee, faction, -math.abs(p.relations), nil)
        end
    end
end

--Functional calls
function onSectorLeft(player, x, y)
	if missionData.location and missionData.location.x and missionData.location.y then
		if x == missionData.location.x and y == missionData.location.y then
			if onTargetLocationLeft then
				onTargetLocationLeft(x, y)
			end
		end
	end
end

function onSectorArrivalConfirmed(player, x, y)
	if missionData.location and missionData.location.x and missionData.location.y then
		if x == missionData.location.x and y == missionData.location.y then
			if onTargetLocationConfirmed then
				onTargetLocationConfirmed(x, y)
			end
		end
	end
end

function onTargetLocationEntered(x, y)
	if not missionData.spawnedEnemies then
		--Spawn enemies
		spawnEnemies(missionData.dangerValue)
		missionData.spawnedEnemies = true
	end
end

function onTargetLocationLeft(x, y)
	local sender = missionData.stationTitle
    Player():sendChatMessage(sender, 0, missionData.failMessage)
	fail()
	givePunishment()
end
function onTargetLocationConfirmed(x, y)
	if missionData.spawnedEnemies and not missionData.bshipTauntSent then
		--print("sending taunt")
		local bshiptaunts = {
			"Вы никогда этого не ожидали!"%_t,
			"Кажется, нас обнаружили! Уничтожьте их немедленно!"%_t,
			"Похоже, это конец. По крайней мере, мы заберем вас с собой."%_t,
			"Узрите нас!"%_t,
			"Никогда бы не подумал, что мы умрем, убегая от добродетеля."%_t,
			"В бесконечность! И дальше!"%_t
			}
		local bshiptaunt = bshiptaunts[random():getInt(1, #bshiptaunts)]
		Sector():broadcastChatMessage(bship, ChatMessageType.Chatter, bshiptaunt)
		missionData.bshipTauntSent = true
	end
end

function onRestore()
	--Re-register callback for battleship just in case the player quit / restarted the game mid-mission.
	--if missionData.bshipID then
	--	print("Attempting to reattach callbacks to main ship")
	--else
	--	print("No battleship ID saved")
	--end
	bship = Entity(missionData.bshipID)
	bship:registerCallback("onDestroyed", "DestroyPrototype_onTargetDestroyed")
	if missionData.dangerValue == 10 then
		bship:registerCallback("onDamaged", "DestroyPrototype_onTargetDamaged")
	end
		for _, ship in pairs({Sector():getEntitiesByFaction(PirateGen:getPirateFaction().index)}) do
		if ship.isShip then
			ship:addScript("deleteonplayersleft.lua")
		end
    end
end

function updateServer(timeStep)
    updateMission(timeStep)

    if missionData.dangerValue == 10 and not missionData.spawnedSecondWave then
		--Check # of ships left.
		local counter = 0
		for _, ship in pairs({Sector():getEntitiesByFaction(PirateGen:getPirateFaction().index)}) do
			if ship.isShip then
				counter = counter + 1
			end
		end
		
		if counter == 1 then
			--only 1 ship left -- almost certainly the prototype. Spawn the 2nd wave.
			spawnSecondWave()
		end
	end
end

--Custom callbacks.
function DestroyPrototype_onTargetDestroyed()
	--When the prototype is destroyed, that's it. The mission is won.
	--Have all remaining pirates warp out + one of them send a curse to the player.
	local sentTaunt = false
	for _, ship in pairs({Sector():getEntitiesByFaction(PirateGen:getPirateFaction().index)}) do
		if ship.isShip and not sentTaunt then
			--It doesn't make sense for the main enemy ship to send the taunt after it was destroyed.
			if ship.id.string ~= missionData.bshipID.string then
				local defeatedtaunts = {
					"Нет!!! НЕТ!!!"%_t,
					"Проклятье! Мы это запомним!"%_t,
					"В следующий раз мы вас достанем!"%_t,
					"Мы будем наблюдать и ждать. Когда вы меньше всего этого ожидаете... тогда мы и нанесем удар."%_t,
					"Мы еще увидим, как вы будете глотать вакуум за это!"%_t,
					"День сегодня ваш, но месть будет за нами!"%_t
					}
				local defeatedtaunt = defeatedtaunts[random():getInt(1, #defeatedtaunts)]
				Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, defeatedtaunt)
				sentTaunt = true
			end
		end
        ship:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))
    end
	
	local sender = missionData.stationTitle
    Player():sendChatMessage(sender, 0, missionData.accomplishMessage)
	finish()
	giveReward()
end

function DestroyPrototype_onTargetDamaged()
	local bshiphull = bship.durability
	local bshiphullThreshold = bship.maxDurability / 2
	if bshiphull < bshiphullThreshold and not missionData.spawnedSecondWave then
		spawnSecondWave()
	end
end

function onSecondWaveSpawned(generated)
	SpawnUtility.addEnemyBuffs(generated)
	local sentTaunt = false
	local bshipName = Entity(missionData.bshipID).name
	for _, ship in pairs(generated) do
        if not sentTaunt then
			local reinforcementtaunts = {
				"Подкрепление на станции! Держись, " .. bshipName .. "!"%_t,
				"Мы разорвем вас на куски!"%_t,
				"Если " .. bshipName .. " будет уничтожен, все это зря! Защитите его любой ценой!"%_t,
				"Всем кораблям, оружие на полную мощность! В бой! В бой! В бой!"%_t,
				"Держись крепче, " .. bshipName .. ", кавалерия здесь!"%_t,
				"Не возражаете, если мы вмешаемся?"%_t
				}
			local reinforcementtaunt = reinforcementtaunts[random():getInt(1, #reinforcementtaunts)]
			Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, reinforcementtaunt)
			sentTaunt = true
		end
		ship:addScript("deleteonplayersleft.lua")
    end
end

--Custom (but still 'functional') calls.
function spawnEnemies(dangerValue)
	--print("attempting to spawn enemies")
	--Get nearest pirate faction.
	--Spawn one large + powerful ship -- this is the battleship in question.
	PirateGen.pirateLevel = Balancing_GetPirateLevel(missionData.location.x, missionData.location.y) --This prevents PirateGen / AsyncPirateGen from creating pirates from different factions.
	bship = PrototypeGenerator.create(DestroyPrototype_getEnemyPosition(), Faction(missionData.factionIndex), PirateGen:getPirateFaction(), dangerValue)
	bship:registerCallback("onDestroyed", "DestroyPrototype_onTargetDestroyed")
	bship:addScript("deleteonplayersleft.lua")
	
	missionData.bshipID = bship.id
	print("mission battleship id is: " .. missionData.bshipID.string)
	
	--If dangerValue is high enough, spawn additonal enemies.
	local firstWaveMin = 2
	local firstWaveMax = 4
	if dangerValue >= 8 then
		firstWaveMax = firstWaveMax + 1
	end
	if dangerValue == 10 then
		firstWaveMin = firstWaveMin + 1
		firstWaveMax = firstWaveMax + 1
	end

	--Spawn the first wave. Appears on danger value 6+
	if dangerValue > 5 then
		local firstWaveCount = random():getInt(firstWaveMin, firstWaveMax)

		for idx=1,firstWaveCount,1 do
			bandit = PirateGen.createBandit(DestroyPrototype_getEnemyPosition())
			bandit:addScript("deleteonplayersleft.lua")
		end
	end
	--If dangerValue is max (10) -- spawn another wave of enemies after the battleship hits 50%.
	if dangerValue == 10 then
		bship:registerCallback("onDamaged", "DestroyPrototype_onTargetDamaged")
	end
end

function spawnSecondWave()
	missionData.spawnedSecondWave = true --Don't spawn it again.
	--We'll rip this from wave generator.
	--Make 1-3 bandits, 1-2 pirates, 0-1 marauder, 0-1 raider
	local banditCount = random():getInt(1, 3)
	local pirateCount = random():getInt(1, 2)
	local marauderCount = random():getInt(0, 1)
	local raiderCount = random():getInt(0, 1)
	
	--Get values for matrix.
	local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1000
    local distance = 150
	
	local sWaveGen = AsyncPirateGen(nil, onSecondWaveSpawned)
    sWaveGen:startBatch()

    local counter = 0
	
	for idx=1,banditCount,1 do
		sWaveGen:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
		counter = counter + 1
	end
	for idx=1,pirateCount,1 do
		sWaveGen:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
		counter = counter + 1
	end
	if marauderCount > 0 then
		sWaveGen:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
		counter = counter + 1
	end
	if raiderCount > 0 then
		sWaveGen:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
		counter = counter + 1
	end
	
	sWaveGen:endBatch()
end

function DestroyPrototype_getEnemyPosition()
	local pos = random():getVector(-1000,1000)
	return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
end

--getBulletin and getBulletin related values / calls, including messages, etc.
--No real need to allow these to be acessible outside this mod -- they are just mission descriptions that vary by the aggressive value of the faction and the danger value of the mission.
--Peaceful description
local psDesc1 = [[Мы разрабатывали прототип системы самообороны, когда он был захвачен бандой пиратов! Мы сожалеем, что все дошло до этого, но систему необходимо уничтожить, прежде чем у них появится шанс скопировать технологию и улучшить свои корабли. Или, что еще хуже, продать ее нашим врагам. К сожалению, наших сил недостаточно для этой задачи.]]
local psDesc2 = [[Сигналы с радара линкора показывают, что его сопровождают. Будьте осторожны при приближении.]]
local psDesc3 = [[Трекер на украденном корабле показывает, что он находится в (${x}:${y}). Пожалуйста, сделайте то, что необходимо.]]

--Aggressive description
local asDesc1 = [[Какие-то отмороженные пираты украли один из наших новых линкоров! Он должен был стать гордостью нашего нового флота, а теперь он годится только на металлолом! Нужно преподать урок. Потеря материала достойна сожаления, но те, кто крадет у нас, должны осознать последствия своих действий.]]
local asDesc2 = [[Разведка сообщает, что некоторые бандиты сбежали со своим призом. Это не имеет значения. Они заплатят вместе с остальными.]]
local asDesc3 = [[Мы отследили его до (${x}:${y}). Уничтожьте корабль и убейте всех причастных.]]

--Moderate description
local msDesc1 = [[Нам нужна ваша помощь. Наш новый линкор был угнан пиратами, и мы не можем позволить, чтобы он попал в руки врага, иначе они смогут скопировать его и использовать экспериментальную технологию для улучшения своих кораблей. Нам нужно, чтобы вы его уничтожили. Не волнуйтесь - мы вознаградим вас за это. Мы считаем, что компенсация достаточна для этой задачи.]]
local msDesc2 = [[Мы считаем, что его сопровождают дополнительные пиратские корабли. Будьте осторожны при приближении.]]
local msDesc3 = [[Похоже, они не отключили маяк слежения корабля. Он показывает, что корабль в настоящее время находится в (${x}:${y}).]]

--Accomplish messages.
local winMsg = {
	[[Спасибо. Вот ваша награда, как и было обещано.]], --Moderate
	[[Спасибо, что разобрались с этим отребьем. Мы перевели награду на ваш счет.]], --Aggressive
	[[Спасибо за ваши хлопоты. Мы перевели награду на ваш счет.]] --Peaceful
}

--Failure messages.
local failMsg = {
	[[Вы не смогли его уничтожить? Это очень плохо. Мы найдем кого-нибудь другого, кто позаботится об этом.]], --Moderate
	[[Мы видим, что вы не справились с задачей. Неудачно, но неудивительно. Нам следовало позаботиться об этом самим.]], --Aggressive
	[[Вы не смогли его уничтожить? Это плохо... у нас и так было мало вариантов...]] --Peaceful
}

function fmtMissionDescription(aggroVal, dangerValue)
	local descriptionType = 1 --Moderate
	if aggroVal >= 0.5 then
		descriptionType = 2 --Aggressive
	elseif aggroVal <= -0.5 then
		descriptionType = 3 --Peaceful
	end
	
	local description = ""
	if descriptionType == 1 then
		description = msDesc1
		if dangerValue >= 6 then
			description = description .. "\n\n" .. msDesc2
		end
		description = description .. "\n\n" .. msDesc3
	elseif descriptionType == 2 then
		description = asDesc1
		if dangerValue >= 6 then
			description = description .. "\n\n" .. asDesc2
		end
		description = description .. "\n\n" .. asDesc3
	elseif descriptionType == 3 then
		description = psDesc1
		if dangerValue >= 6 then
			description = description .. "\n\n" .. psDesc2
		end
		description = description .. "\n\n" .. psDesc3
	end

	return description
end

function fmtFailMessage(aggroVal)
	local msgType = 1 --Moderate
	if aggroVal >= 0.5 then
		msgType = 2 --Aggressive
	elseif aggroVal <= -0.5 then
		msgType = 3 --Peaceful
	end

	return failMsg[msgType]
end

function fmtWinMessage(aggroVal)
	local msgType = 1 --Moderate
	if aggroVal >= 0.5 then
		msgType = 2 --Aggressive
	elseif aggroVal <= -0.5 then
		msgType = 3 --Peaceful
	end
	
	return winMsg[msgType]
end

--Add this mission to bulletin boards of stations.
function getBulletin(station)
	--This is not offered from player / alliance stations. There's too much stuff that either breaks or doesn't make sense. How would a player not realize one of their own ships got hijacked?
	local offeringFaction = Faction(station.factionIndex)
	if offeringFaction and (offeringFaction.isPlayer or offeringFaction.isAlliance) then return end
	--[[Script: Player jumps into sector and kills the prototype battleship -- a very large and powerful enemy. Very simple and straightforward -- not much of a twist to this one.	
	]]
	--print("running getBulletin")
	--Get coordinates first.
	local target = {}
	local x, y = Sector():getCoordinates()
	local giverInsideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
	target.x, target.y = MissionUT.getSector(x, y, 7, 20, false, false, false, false)
	
	if not target.x or not target.y or giverInsideBarrier ~= MissionUT.checkSectorInsideBarrier(target.x, target.y) then return end

	local fFaction = Faction(station.factionIndex)
	local dAggroValue = fFaction:getTrait("aggressive")	
	--I don't like how formulaic most Avorion missions are, so we'll throw in a hidden "danger value" to spice things up a bit.
	--[[Danger value effects:
		Please note that these effects are cumulative -- i.e. the mission listed difficulty / description will change at danger level 6-7, but also at 8+ as well.
		- Danger Value 1 - 5
			Prototype Scale = 40
			Prototype Turret Factor = 3
			Prototype Damage Factor = 3
			Prototype Loot = 3 Turrets guaranteed
		- Danger Value 6 - 7
			Initial group of 2-4 bandits spawns with Prototype
			Prototype Scale = +10 (50 total)
			Prototype Turret Factor = +1 (4 total)
			Mission listed difficulty / description changed slightly to hint that this one is harder.
		- Danger Value 8 - 9
			Initial group of 2-5 (+1 max) bandits spawns with Prototype
			Prototype Scale = +10 (60 total)
			Prototype Turret Factor = +1 (5 total)
		- Danger Value 10
			Initial group of 3-6 (+1 min, +1 max) bandits spawns with Prototype
			Prototype Scale = +10 (70 total)
			Prototype Turret Factor = +1 (6 total)
			Prototype Damage Factor = +1 (4 total)
			Prototype Loot = +1 (total 4) Turrets guaranteed
			When either of the following conditions are met, an additional wave of 1-3 Bandits, 1-2 Pirates, 0-1 Marauders, and 0-1 Raiders spawn
				- Prototype drops to 50% health or lower
				- All ships other than the Prototype are destroyed
		- Danger Value [Any]
			Prototype always gets a random bonus to its damage factor ranging from (1 to [Danger Level]) / 50 -- this means it gets anywhere from a 2 to 20% bonus.
	]]
	local dangerValue = random():getInt(1, 10)
	
	local description = fmtMissionDescription(dAggroValue, dangerValue)
	local sDifficulty = "Сложно /*difficulty*/"%_t
	if dangerValue >= 6 then
		sDifficulty = "Экстремально /*difficulty*/"%_t
	end

	local _BaseReward = 100000
	if dangerValue >= 5 then
		_BaseReward = _BaseReward + 10000
	end
	if dangerValue == 10 then
		_BaseReward = _BaseReward + 15000
	end
	_BaseReward = _BaseReward * Balancing.GetSectorRewardFactor(Sector():getCoordinates())
	if giverInsideBarrier then
		_BaseReward = _BaseReward * 2
	end
	local _Version = GameVersion()
    if _Version.major > 1 then
        _BaseReward = _BaseReward * 1.33
    end

    reward = {credits = _BaseReward, relations = 8000, paymentMessage = "За уничтожение прототипа получено %1%."}
	punishment = {relations = reward.relations}

    local bulletin =
    {
        brief = "Уничтожить прототип линкора"%_t,
        description = description,
        difficulty = sDifficulty,
        reward = "$${reward}",
        script = "missions/destroyprototype.lua",
        arguments = {station.index, target.x, target.y, reward, punishment, dangerValue},
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward.credits)},
        msg = "Спасибо. Мы отследили линкор до \\s(%i:%i). Пожалуйста, уничтожьте его.",
        entityTitle = station.title,
        entityTitleArgs = station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            local title = self.entityTitle % self.entityTitleArgs
            player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]]
    }

    return bulletin
end
