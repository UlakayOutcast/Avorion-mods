package.path = package.path .. ";data/scripts/lib/?.lua"

include("callable")

--Don't remove / alter or else yo might break the script.
--namespace Annihilatorium
Annihilatorium = {}
local self = Annihilatorium

self._Debug = 0

self.interactionThreshold = -50000

self.data = {}

function Annihilatorium.interactionPossible(playerIndex, option)
    local _Enemies = {Sector():getEnemies(playerIndex)}

    if #_Enemies > 0 then
        return false
    end

    if not Player():hasScript("annihilatorium.lua") then
        return false
    end

    return CheckFactionInteraction(playerIndex, self.interactionThreshold)
end

function Annihilatorium.initialize(dangerLevel)
    if onServer() and not _restoring then
        local _Station = Entity()
        _Station.title = "Annihilatorium"

        self.data = {}

        self.data.cleanWreckages = true
        self.data.pullLoot = true
        self.data.dangerLevel = dangerLevel or 1
        
        local ownPosition = _Station.translationf
        local dir = random():getDirection()
        dir = normalize(dir) * 350 --should be 3.5 km
        local lootZoneCenter = ownPosition + dir

        self.data.lootZoneCenter = { x = lootZoneCenter.x, y = lootZoneCenter.y, z = lootZoneCenter.z}

        self.sync()
    end

    if onClient() then
        EntityIcon().icon = "data/textures/icons/pixel/crossed_swords.png"
    end
end

function Annihilatorium.initUI()
    local methodName = "Init UI"
    self.Log(methodName, "Running...")

    local res = getResolution()
    local menu = ScriptUI()

    --[[=====================================================
        CREATE NEXT WAVE WINDOW:
    =========================================================]]
    local nextWaveSize = vec2(600, 75)

    local nextWaveWindow = menu:createWindow(Rect(res * 0.5 - nextWaveSize * 0.5, res * 0.5 + nextWaveSize * 0.5))

    local nextWaveSplitter = UIArbitraryVerticalSplitter(Rect(nextWaveWindow.size), 10, 15, 325, 575)

    local nextWaveLabelRect = nextWaveSplitter:partition(0)
    local nextWavelrUpper = nextWaveLabelRect.topLeft
    local nextWavelrLower = nextWaveLabelRect.bottomRight
    nextWavelrUpper = nextWavelrUpper + vec2(0, 15)
    local descLabel = nextWaveWindow:createLabel(Rect(nextWavelrUpper, nextWavelrLower), "Убедитесь, что вы готовы. Пути назад нет.", 14)

    local buttonRect = nextWaveSplitter:partition(1)
    local button = nextWaveWindow:createButton(buttonRect, "Start", "onStartPressed")

    nextWaveWindow.caption = "Start Next Wave"
    nextWaveWindow.showCloseButton = 1
    nextWaveWindow.moveable = 1

    --[[=====================================================
        REGISTER UI:
    =========================================================]]
    menu:registerWindow(nextWaveWindow, "Start Next Wave", 4)

    if self.data.dangerLevel > 5 then
        --[[=====================================================
            CREATE MASTER OF THE ARENA WINDOW:
        =========================================================]]
        local motaSize = vec2(600, 310)

        local motaWindow = menu:createWindow(Rect(res * 0.5 - motaSize * 0.5, res * 0.5 + motaSize * 0.5))

        local motaSplitter = UIArbitraryVerticalSplitter(Rect(motaWindow.size), 10, 15, 325, 575)

        local motaDescriptionSplitter = UIArbitraryHorizontalSplitter(motaSplitter:partition(0), 10, 15, 40, 65, 90, 115, 140, 165, 190, 220)

        local labelTable = {
            "Включите режим "Мастер Арены".",
			"Это приведет к следующему результату:",
			" - У обычных врагов х3 л.с./ урон",
			" - Все боссы заменены на палачей",
			" - Все боссы гарантированно будут хардкорными +",
			" - Примерно 3:30 между волнами",
			" - Выход из сектора приводит к поражению",
			" - 3-кратная награда боссам за прохождение всех волн",
			"Удачи!"
        }

        for idx, txt in pairs(labelTable) do
            local partitionidx = idx - 1
            local motaLabelRect = motaDescriptionSplitter:partition(partitionidx)
            local motalrUpper = motaLabelRect.topLeft
            local motalrLower = motaLabelRect.bottomRight

            local motaDescLabel = motaWindow:createLabel(Rect(motalrUpper, motalrLower), txt, 14)
        end

        local motaButtonSplitter = UIArbitraryHorizontalSplitter(motaSplitter:partition(1), 10, 15, 200)

        local motaButtonRect = motaButtonSplitter:partition(1)
        local motaButton = motaWindow:createButton(motaButtonRect, "Engage", "onEnableMOTAPressed")

        motaWindow.caption = "Master Of The Arena"
        motaWindow.showCloseButton = 1
        motaWindow.moveable = 1

        menu:registerWindow(motaWindow, "Master Of The Arena", 3)
    end
    
    menu:registerInteraction("Clean Wreckages", "onToggleCleanWrecks", 2)
    menu:registerInteraction("Pull Loot", "onTogglePullLoot", 1)
end

function Annihilatorium.getUpdateInterval()
    if onServer() then
        return 2
    else
        return 0
    end
end

function Annihilatorium.updateServer(timeStep)
    local methodName = "Update Server"

    local _sector = Sector()
    local pirates = { _sector:getEntitiesByScriptValue("is_pirate") }
    local station = Entity()
    local totalLaserCt = 0

    if #pirates == 0 then
        --Clean wrecks
        if self.data.cleanWreckages then
            local wreckages = { _sector:getEntitiesByType(EntityType.Wreckage) }
            local wreckCt = 0

            shuffle(random(), wreckages)

            for _, wreck in pairs(wreckages) do
                if wreckCt < 10 then
                    broadcastInvokeClientFunction("zapWreckage", station.translationf, wreck.translationf, wreck.index, 5)
                    _sector:deleteEntity(wreck)
                end
                wreckCt = wreckCt + 1
                totalLaserCt = totalLaserCt + 1
            end
        end

        --Pull loot into the loot zone
        if self.data.pullLoot then
            local loots = {_sector:getEntitiesByType(EntityType.Loot)}

            shuffle(random(), loots)

            for _, loot in pairs(loots) do
                local lootDist = distance(station.translationf, loot.translationf)

                if totalLaserCt < 25 and lootDist > 600 then
                    if not self.data.lootZoneCenter then
                        self.Log(methodName, "!!ERROR!! LOOT ZONE CENTER IS NULL !!ERROR!!")
                    end
                    local nPos = vec3(self.data.lootZoneCenter.x, self.data.lootZoneCenter.y, self.data.lootZoneCenter.z)
                    local dir = random():getDirection()
                    dir = normalize(dir)

                    nPos = nPos + (dir * random():getInt(10, 50))

                    broadcastInvokeClientFunction("zapItem", station.translationf, loot.translationf, loot.index, nPos)

                    loot.translation = dvec3(nPos.x, nPos.y, nPos.z)

                    totalLaserCt = totalLaserCt + 1
                end
            end
        end
    end

    self.sync()
end

function Annihilatorium.updateClient(timeStep)
    if self.data.lootZoneCenter and not self.lootZoneSphere then
        self.makeLootZoneSphere()
    end
end

function Annihilatorium.onDelete()
    self.deleteLootZoneLasers()
end

--region #WAVE MANGEMENT

function Annihilatorium.onStartPressed()
    local methodName = "Start Pressed"
    self.Log(methodName, "Running...")

    invokeServerFunction("sendNextWave")
    ScriptUI():stopInteraction()
end

function Annihilatorium.sendNextWave()
    local methodName = "Send Next Wave"
    self.Log(methodName, "Running...")

    local _sector = Sector()
    local players = {_sector:getPlayers()}
    local playerHasMissionScript = false
    for idx, _player in pairs(players) do
        if _player:hasScript("annihilatorium.lua") then
            playerHasMissionScript = true
        end
    end

    if playerHasMissionScript then
        _sector:sendCallback("onAnnihilatoriumSpawnWave")
    else
        _sector:broadcastMessage("", 3, "You've defeated all the waves!")
    end
end
callable(Annihilatorium, "sendNextWave")

--endregion

--region #MASTER OF THE ARENA

function Annihilatorium.onEnableMOTAPressed()
    local methodName = "Enable MOTA Pressed"
    self.Log(methodName, "Running...")

    invokeServerFunction("enableMOTA")
    ScriptUI():stopInteraction()
end

function Annihilatorium.enableMOTA()
    local methodName = "Enable MOTA"
    self.Log(methodName, "Running...")

    local _sector = Sector()
    local players = {_sector:getPlayers()}
    local playerHasMissionScript = false
    for idx, _player in pairs(players) do
        if _player:hasScript("annihilatorium.lua") then
            playerHasMissionScript = true
        end
    end

    if playerHasMissionScript then
        _sector:sendCallback("onEnableMOTAMode")
    end
end
callable(Annihilatorium, "enableMOTA")

--endregion

--region #WRECK MANAGEMENT

function Annihilatorium.onToggleCleanWrecks()
    local methodName = "On Toggle Clean Wrecks"
    self.Log(methodName, "Calling onToggleCleanWrecks")

    if onClient() then
        invokeServerFunction("onToggleCleanWrecks")

        local d0 = {}

        if self.data.cleanWreckages then
            d0.text = "Мы перестанем убирать обломки."
        else
            d0.text = "Мы начнем убирать обломки. Наслаждайтесь световым шоу!"
        end

        ScriptUI():showDialog(d0)
    else
        if self.data.cleanWreckages then
            self.data.cleanWreckages = false
        else
            self.data.cleanWreckages = true
        end

        self.Log(methodName, "Clean wreckages is now: " .. tostring(self.data.cleanWreckages))

        Annihilatorium.sync()
    end
end
callable(Annihilatorium, "onToggleCleanWrecks")

function Annihilatorium.zapWreckage(from, to, idx, anims)
    local methodName = "Zap Wreckage"
    --Spams like crazy. Be careful enabling this.
    --self.Log(methodName, "Running...")

    local _Sector = Sector()

    local _entity = Entity(idx)
    local _random = random()
    for _ = 1, anims do
        local dir = _random:getDirection()
        _Sector:createHyperspaceJumpAnimation(_entity, dir, ColorRGB(0.5, 0.5, 1.0), 0.3)
    end

    local laser = _Sector:createLaser(from, to, ESCCUtil.getSaneColor(0, 27, 255), 12)

    laser.maxAliveTime = 1.0
    laser.collision = false
end

--endregion

--region #LOOT MANAGEMENT

function Annihilatorium.onTogglePullLoot()
    local methodName = "On Toggle Pull Loot"
    self.Log(methodName, "Calling onTogglePullLoot")

    if onClient() then
        invokeServerFunction("onTogglePullLoot")

        local d0 = {}

        if self.data.pullLoot then
            d0.text = "Мы перестанем собирать добычу."
            self.deleteLootZoneLasers()
        else
            d0.text = "Мы начнем собирать добычу. Наслаждайтесь световым шоу!"
            self.drawLootZoneLasers()
        end

        ScriptUI():showDialog(d0)
    else
        if self.data.pullLoot then
            self.data.pullLoot = false
        else
            self.data.pullLoot = true
        end

        self.Log(methodName, "Pull loot is now: " .. tostring(self.data.pullLoot))

        Annihilatorium.sync()
    end
end
callable(Annihilatorium, "onTogglePullLoot")

function Annihilatorium.zapItem(from, to, idx, npos)
    local methodName = "Zap Item"
    --Spams like crazy. Be careful enabling this.
    --self.Log(methodName, "Running...")

    local _Sector = Sector()

    local laser = _Sector:createLaser(from, to, ESCCUtil.getSaneColor(0, 27, 255), 12)

    local lootItem = Entity(idx)
    lootItem.translation = dvec3(npos.x, npos.y, npos.z)

    laser.maxAliveTime = 1.0
    laser.collision = false
end

function Annihilatorium.makeLootZoneSphere()
    if self.lootZoneSphere then
        return
    end
    self.lootZoneSphere = {}

    local limit = ClientSettings().particlesQuality*40
	local pi = math.pi
    local lootZoneCenter = vec3(self.data.lootZoneCenter.x, self.data.lootZoneCenter.y, self.data.lootZoneCenter.z)

    local n_pi = -pi/2
	local a_max = 150
	for a = 0, a_max, 0.1 / ((limit == 0 and 200 or limit)/120) do
		local ratio = (a/a_max)*pi
		local cos = math.cos(n_pi + ratio)
		table.insert(self.lootZoneSphere, vec3(math.cos(a) * cos, math.sin(a) * cos, -math.sin(n_pi + ratio)) * 100 + lootZoneCenter)
	end

    self.drawLootZoneLasers()
end

function Annihilatorium.drawLootZoneLasers()
    local _sector = Sector()
    self.lootZoneLasers = {}
	local color = ColorHSV(1,1,1)
	for k, v in pairs(self.lootZoneSphere) do
		--local color = ColorHSV(k, 1, 1)
		local v1 = self.lootZoneSphere[k-1] --or self.sphere[#self.sphere]
		if v1 then
			table.insert(self.lootZoneLasers, _sector:createLaser(v1, v, color, 100/300))
		end
	end
end

function Annihilatorium.deleteLootZoneLasers()
    if not self.lootZoneLasers then
        return
    end
    local _sector = Sector()
    for k, v in pairs(self.lootZoneLasers) do
        _sector:removeLaser(v)
    end
end

--endregion

--region #LOG / SYNC / SECURE / RESTORE

function Annihilatorium.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[Annihilatorium Station] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function Annihilatorium.sync(data_in)
    local methodName = "Sync"
    --This spams like crazy. Be careful enabling it.
    --self.Log(methodName, "Syncing...")

    if onServer() then
        broadcastInvokeClientFunction("sync", self.data)
    else
        if data_in then
            self.data = data_in
        else
            invokeServerFunction("sync")
        end
    end
end
callable(Annihilatorium, "sync")

function Annihilatorium.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing...")

    return self.data
end

function Annihilatorium.restore(values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring...")

    self.data = values

    Annihilatorium.sync() --need to sync on restore.
end

--endregion