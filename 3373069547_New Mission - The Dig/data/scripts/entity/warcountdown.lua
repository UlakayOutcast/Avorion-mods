package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--namespace WarCountdown
WarCountdown = {}
local self = WarCountdown

self._Data = {}

self._Debug = 0

function WarCountdown.initialize()
    local methodName = "Initialize"
    self.Log(methodName, "Инициализация War Countdown v2")

    self._Data._TimeToWar = 300
end

function WarCountdown.getUpdateInterval()
    return 1
end

function WarCountdown.updateServer(_TimeStep)
    local methodName = "Update Server"

    if not self._Data._RunDiplomacyCheck then
        self.checkDiplomacy() --Terminates script if already @ war with player.
        self._Data._RunDiplomacyCheck = true
    end

    local _sector = Sector()
    local _entity = Entity()

    self._Data._TimeToWar = self._Data._TimeToWar - _TimeStep

    if not self._Data._SentInitialMessage then
        self.Log(methodName, "Время до войны " .. tostring(self._Data._TimeToWar) .. " - отправка начального сообщения")
        _sector:broadcastChatMessage(_entity, ChatMessageType.Chatter, "У вас есть пять минут, чтобы покинуть этот сектор, иначе мы объявим боевые действия! Вы были предупреждены.")
        self._Data._SentInitialMessage = true
    end

    if self._Data._TimeToWar <= 60 and not self._Data._SentOneMinuteMessage then
        self.Log(methodName, "Время до войны " .. tostring(self._Data._TimeToWar) .. " - отправка сообщения об одной минуте")
        _sector:broadcastChatMessage(_entity, ChatMessageType.Chatter, "У вас осталась одна минута. Покиньте этот сектор, или мы начнем боевые действия.")
        self._Data._SentOneMinuteMessage = true
    end

    if self._Data._TimeToWar <= 0 then
        self.Log(methodName, "Время до войны " .. tostring(self._Data._TimeToWar) .. " - объявление войны!")
        _sector:broadcastChatMessage(_entity, ChatMessageType.Chatter, "Цели подтверждены. Начинаем боевые действия.")
        self.declareWar()
        
        terminate()
        return
    end
end

function WarCountdown.checkDiplomacy()
    local methodName = "Check Diplomacy"
    self.Log(methodName, "Запуск Check Diplomacy")

    local anyNotAtWar = false

    local _Entity = Entity()
    local _EntityFaction = Faction(_Entity.factionIndex)
    local _Factions = {Sector():getPresentFactions()}

    for _, _Factionidx in pairs(_Factions) do
        local _Faction = Faction(_Factionidx)
        if _Faction.index ~= _Entity.factionIndex and (_Faction.isPlayer or _Faction.isAlliance) then
            self.Log(methodName, "Проверка отношений между фракцией : " .. tostring(_EntityFaction.name) .. " и фракцией : " .. tostring(_Faction.name))
            local _Relations = _EntityFaction:getRelation(_Faction.index)
            if _Relations.status ~= RelationStatus.War then
                self.Log(methodName, "Игрок не находится в состоянии войны с текущей фракцией - этот скрипт не будет завершен.")
                anyNotAtWar = true
            end
        end
    end

    if not anyNotAtWar then
        terminate()
        return
    end
end

function WarCountdown.declareWar()
    local _MethodName = "Declare War"
    self.Log(_MethodName, "Запуск...")
    --Declare war on every present player / alliance every 10 seconds.
    --Объявлять войну каждому присутствующему игроку / альянсу каждые 10 секунд.
    local _Entity = Entity()
    local _EntityFaction = Faction(_Entity.factionIndex)
    local _Galaxy = Galaxy()
    local _Factions = {Sector():getPresentFactions()}
    
    for _, _Factionidx in pairs(_Factions) do
        local _Faction = Faction(_Factionidx)
        if _Faction.index ~= _Entity.factionIndex and (_Faction.isPlayer or _Faction.isAlliance) then
            self.Log(_MethodName, "Проверка отношений между фракцией : " .. tostring(_EntityFaction.name) .. " и фракцией : " .. tostring(_Faction.name))
            local _Relations = _EntityFaction:getRelation(_Faction.index)
            if _Relations.status ~= RelationStatus.War then
                self.Log(_MethodName, "Отношения не в состоянии войны - объявление войны.")
                _Galaxy:setFactionRelations(_EntityFaction, _Faction, -100000)
                _Galaxy:setFactionRelationStatus(_EntityFaction, _Faction, RelationStatus.War)
            end

            ShipAI(_Entity.id):registerEnemyFaction(_Faction.index)
        end
    end
end

--region #CLIENT / SERVER functions

function WarCountdown.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[WarCountdown] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function WarCountdown.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Сохранение self._Data")
    return self._Data
end

function WarCountdown.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Восстановление self._Data")
    self._Data = _Values
end

--endregion
