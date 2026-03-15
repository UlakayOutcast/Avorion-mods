package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("stringutility")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")
MissionUT = include("missionutility")

local ShipGenerator = include("shipgenerator")
local SpawnUtility = include("spawnutility")

function create(item, rarity, allyIndex)
    --print("Создание предмета.")

    -- Это ДОЛЖНО быть исключительным, иначе его нельзя будет купить у Кавалеров.
    rarity = Rarity(RarityType.Exceptional)

    --print("Найдена фракция - установка тултипа.")

    item.stackable = false
    item.depleteOnUse = false
    item.name = "Передатчик подкреплений Кавалеров"
    item.price = 12000000
    item.icon = "data/textures/icons/firing-ship.png"
    item.iconColor = rarity.color
    item.rarity = rarity
    item:setValue("subtype", "ReinforcementsTransmitter")
    item:setValue("factionIndex", allyIndex)

    local tooltip = Tooltip()
    tooltip.icon = item.icon
    tooltip.rarity = rarity

    local title = "Передатчик подкреплений Кавалеров"

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = item.rarity.color
    tooltip:addLine(line)

    -- пустая строка
    tooltip:addLine(TooltipLine(14, 14))
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "Союзник"
    line.rtext = "${faction:"..allyIndex.."}"
    line.icon = "data/textures/icons/flying-flag.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Корабли"
    line.rtext = "5 - 7"
    line.icon = "data/textures/icons/ship.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- пустая строка
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "Время восстановления"
    line.rtext = "1ч"
    line.icon = "data/textures/icons/recharge-time.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- пустая строка
    tooltip:addLine(TooltipLine(14, 14))
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "Может быть активирован игроком"
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Вызывает подкрепление от Кавалеров"
    tooltip:addLine(line)

    item:setTooltip(tooltip)

    --print("Тултип установлен.")

    return item
end

function activate(item)
    -- проверка, доступна ли фракция
    local _Player = Player()
    local allyIndex = item:getValue("factionIndex")
    if not allyIndex then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа.")
        return false
    end

    local faction = Faction(allyIndex)
    if not faction then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа.")
        return false
    end

    if not faction.isAIFaction then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа.")
        return false
    end

    local sender = "Кавалеры"

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()

    local _Rank = _Player:getValue("_llte_cavaliers_ranklevel")
    local _PlayerInBarrier = MissionUT.checkSectorInsideBarrier(_X, _Y)
    local _CavsInBarrier = _Player:getValue("_llte_cavaliers_inbarrier")

    if _Rank < 2 then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "Мы отправляем боевую поддержку только тем, кто доказал свою преданность нам.")
        return false
    end

    if _PlayerInBarrier and not _CavsInBarrier then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "Мы не можем отправить вам подкрепление!")
        return false
    end

    local craft = _Player.craft
    if not craft then
        _Player:sendChatMessage(sender, ChatMessageType.Error, "Вы должны находиться на корабле, чтобы использовать это!")
        return false
    end

    local key = "reinforcements_requested_" .. faction.index
    local timeStamp = _Player:getValue(key)
    local now = Server().unpausedRuntime

    if timeStamp then
        local ago = now - timeStamp
        local wait = 60 * 60

        if ago < wait then
            _Player:sendChatMessage(sender, ChatMessageType.Normal, "Мы не можем отправить подкрепление так быстро снова! Вам придётся подождать ещё %i минут!", math.ceil((wait - ago)/60))
            return false
        end
    end

    _Player:setValue(key, now)

    local position = craft.translationf

    -- пусть подкрепление появляется позади игрока
    local dir = normalize(normalize(position) + vec3(0.01, 0.0, 0.0))
    local pos = position + dir * 750
    local up = vec3(0, 1, 0)
    local look = -dir

    local right = normalize(cross(dir, up))

    local _Rgen = ESCCUtil.getRand()

    local _ShipsToSend = _Rgen:getInt(5, 7)
    -- всегда добавляем 3 защитника и 2 тяжёлых защитника.
    local ships = {}
    table.insert(ships, ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos)))
    table.insert(ships, ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos + right * 100)))
    table.insert(ships, ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos - right * 100)))
    table.insert(ships, ShipGenerator.createHeavyDefender(faction, MatrixLookUpPosition(look, up, pos + right * 200)))
    table.insert(ships, ShipGenerator.createHeavyDefender(faction, MatrixLookUpPosition(look, up, pos - right * 200)))
    if _ShipsToSend >= 6 then
        table.insert(ships, ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos + right * 300)))
    end
    if _ShipsToSend >= 7 then
        table.insert(ships, ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos - right * 300)))
    end

    SpawnUtility.addEnemyBuffs(ships)

    local _EnemyEntities = {_Sector:getEnemies(_Player.index)}

    for _, ship in pairs(ships) do
        local _ShipAI = ShipAI(ship)
        for _, enemy in pairs(_EnemyEntities) do
            if enemy.factionIndex then
                _ShipAI:registerEnemyFaction(enemy.factionIndex)
            end
        end

        local _WithdrawData = {
            _Threshold = 0.15
        }

        ship.title = "Кавалеры: " .. ship.title
        MissionUT.deleteOnPlayersLeft(ship)
        ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        ship:removeScript("antismuggle.lua")
        LLTEUtil.rebuildShipWeapons(ship, _Player:getValue("_llte_cavaliers_strength"))
        ship:setValue("npc_chatter", nil)
        ship:setValue("is_cavaliers", true)

        _ShipAI:setAggressive()
    end

    return true
end
