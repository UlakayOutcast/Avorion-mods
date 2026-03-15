--[[
    Разрушительные последствия
    ПРИМЕЧАНИЯ:
        - Все обломки в каждом секторе автоматически помечаются тегом "wreckinghavoc_invalidredemption" при инициализации скрипта свалки.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ВЫПОЛНЕНИЯ ЭТОЙ МИССИИ:
        Отсутствуют
    ПРИМЕРНЫЙ ПЛАН
        - Игроку дается полчаса, чтобы сбросить как можно больше обломков в секторе свалки. Неважно, откуда они взялись.
        - Награда зависит от объема обломков, сброшенных в секторе свалки.
        - Используйте предложение Bubbet's для кода ремонтного дока для награды. (т.е. значение плана блока)
        - Может быть, дать игроку бесплатную лицензию на утилизацию, когда он закончит?
    УРОВЕНЬ ОПАСНОСТИ
        Н/Д - Нет присущего уровня опасности. То, как игрок получает обломки, зависит только от него.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

mission._Debug = 0
mission._Name = "Разрушительные последствия"
mission._Tag = "wreckinghavoc_invalidredemption"

--region #INIT

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    "", --Заполнитель
    "", --Заполнитель
    { text = "Сбросьте обломки в секторе (${location.x}:${location.y})", bulletPoint = true, fulfilled = false },
    { text = "Сброшено обломков: ${dropped}", bulletPoint = true, fulfilled = false }
}
mission.data.timeLimit = 30 * 60 --У игрока есть 30 минут.
mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
--Нельзя установить mission.data.reward.paymentMessage здесь, так как мы используем необычную настройку для получения наград.
mission.data.custom.accomplishMessage = "Спасибо за обломки. Мы перевели награду на ваш счет."
mission.data.custom.failMessage = "Мы видим, что вы не смогли сбросить ни одного обломка. Это очень жаль. В следующий раз повезет больше!"

--endregion

--region #PHASE CALLS

mission.phases[1] = {}
mission.phases[1].sectorCallbacks = {}
mission.phases[1].sectorCallbacks[1] = {
    name = "onEntityUndocked",
    func = function(_DockerID, _DockeeID)
        local _MethodName = "Фаза 1: Объект отстыкован"
        if onClient() then
            mission.Log(_MethodName, "Не на сервере - игнорировать этот обратный вызов.")
            return
        end

        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()

        if _X ~= mission.data.location.x or _Y ~= mission.data.location.y then
            mission.Log(_MethodName, "Не в целевом секторе свалки - игнорировать этот обратный вызов.")
            return
        end
        
        mission.Log(_MethodName, "Объект " .. tostring(_DockeeID) .. " был отстыкован от " .. tostring(_DockerID))
        local _Entity = Entity(_DockeeID)
        if _Entity.type == EntityType.Wreckage then
            if not _Entity:getValue(mission._Tag) then
                mission.data.custom.wreckagesDropped = mission.data.custom.wreckagesDropped + 1

                mission.Log(_MethodName, "Объект " .. tostring(_DockeeID) .. " является обломком и еще не был погашен.")
                local _Plan = _Entity:getMovePlan()
                local _Velocity = Velocity(_Entity)

                Sector():deleteEntity(_Entity) --Очистить старый объект.
    
                local _PlanValue = wreckingHavoc_getFullShipValue(_Plan)

                local _ActualWreck = _Sector:createWreckage(_Plan, _Entity.position)
                local _WreckVelocity = Velocity(_ActualWreck)
                _ActualWreck:setValue(mission._Tag, true)
                _WreckVelocity:addVelocity(_Velocity.velocityf)

                if _PlanValue > 0 then
                    mission.data.accomplishMessage = mission.data.custom.accomplishMessage
                    mission.data.reward.credits = mission.data.reward.credits + _PlanValue
                    mission.data.reward.relations = mission.data.reward.relations + 150
                    mission.Log(_MethodName, "Добавлена стоимость плана (" .. tostring(_PlanValue) .. ") к награде. Общая награда теперь: " .. tostring(mission.data.reward.credits) .. " кредитов за " .. tostring(mission.data.custom.wreckagesDropped) .. " обломков.")
                    mission.data.reward.paymentMessage = "Заработано %1% кредитов за сброс " .. tostring(mission.data.custom.wreckagesDropped) .. " обломков."
                else
                    mission.Log(_MethodName, "Стоимость плана была 0 и не была учтена в общем количестве.")
                end
            else
                mission.Log(_MethodName, "Объект " .. tostring(_DockeeID) .. " является обломком, но не является действительной целью для погашения.")
            end
        end

        mission.data.description[4].arguments = { dropped = mission.data.custom.wreckagesDropped }
        sync()
    end
}

mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: При начале на сервере"
    local _Giver = Entity(mission.data.giver.id)
    local _Sector = Sector()

    mission.data.custom.wreckagesDropped = 0

    mission.data.description[1] = "Вы получили следующий запрос от " .. _Sector.name .. " " .. _Giver.translatedTitle .. ":"
    mission.data.description[2] = wreckingHavoc_formatDescription(_Giver)
    mission.data.description[4].arguments = { dropped = mission.data.custom.wreckagesDropped }
    mission.data.accomplishMessage = mission.data.custom.failMessage
    --Пометить все обломки, уже находящиеся в секторе, которые не пристыкованы к кораблю игрока. На самом деле нам нужно сделать это здесь, на случай, если у игрока нет другого мода.
    
    local _Ships = {_Sector:getEntitiesByType(EntityType.Ship)}
    local _Wrecks = {_Sector:getEntitiesByType(EntityType.Wreckage)}

    mission.Log(_MethodName, "Пометить все обломки, кроме пристыкованных.")
    local _DockedWreckIDs = {}
    for _, _Ship in pairs(_Ships) do
        --Получить зажимы кораблей, которые не принадлежат свалке.
        if _Ship.factionIndex ~= _Giver.factionIndex then
            local _Clamps = DockingClamps(_Ship)
            if _Clamps then
                --Получить пристыкованные объекты в зажимах
                local _DockedEntities = {_Clamps:getDockedEntities()}
                --Не стоит проверять, если пристыкованных объектов 0.
                if #_DockedEntities > 0 then
                    for _, _DockedID in pairs(_DockedEntities) do
                        if Entity(_DockedID).type == EntityType.Wreckage then
                            _DockedWreckIDs[tostring(_DockedID)] = true
                        end
                    end
                end
            end
        end
    end

    for _, _Wreck in pairs(_Wrecks) do
        local _WreckIndex = tostring(_Wreck.id)
        local _Wreck = Entity(_Wreck.id)
        if not _DockedWreckIDs[_WreckIndex] or not _Wreck:hasComponent(ComponentType.MoneyDropper) then
            _Wreck:setValue(mission._Tag, true)
        end
    end

    mission.internals.fulfilled = true --Эта миссия будет выполнена в конце, а не провалена. Вопрос только в том, сколько денег получит игрок.
end

mission.phases[1].onAccomplish = function()
    if mission.data.custom.wreckagesDropped and mission.data.custom.wreckagesDropped > 0 then
        --Миссия выполняется только тогда, когда время истекает и не вознаграждается
        reward()
    else
        punish()
    end
end

--endregion

--region #SERVER CALLS

function wreckingHavoc_getFullShipValue(_Plan)
    local _PlanValue = _Plan:getMoneyValue()
    local _ResValue = {_Plan:getResourceValue()}

    for _MAT, _VAL in pairs(_ResValue) do
        _PlanValue = _PlanValue + (Material(_MAT - 1).costFactor * _VAL * 10)
    end

    --Вернуть полную стоимость. Мы будем использовать или изменять ее соответствующим образом в другом месте.
    return _PlanValue
end

--endregion

--region #MAKEBULLETIN CALL

function wreckingHavoc_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Нейтральный
    if _Aggressive > 0.5 then
        descriptionType = 2 --Агрессивный.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Мирный.
    end

    local descriptionOptions = {
        "Любым предприимчивым капитанам: у нас заканчиваются обломки, и нам нужно больше. Вот тут-то вы и пригодитесь. Мы готовы платить премию за любые дополнительные обломки, которые вы сможете доставить в этот сектор. Не нужно ничего особенного, когда вы сбрасываете обломки. Просто отстыкуйте их в этом секторе, и мы будем вести их учет. Удачи!", --Нейтральный
        "Мы ищем дополнительные обломки для сброса на эту свалку. Очевидно, мы сами способны уничтожать пиратов и ксотан, но они научились бояться нас, и мы не можем выследить столько, сколько нам хотелось бы. Вот тут-то вы и пригодитесь. Мы хотим, чтобы вы уничтожали корабли и сбрасывали их обломки здесь для нашего использования. Конечно, вы будете вознаграждены. Приступайте.", --Агрессивный
        "Нам нужны дополнительные обломки! Наши операции по утилизации не успевают за спросом, а наша армия недостаточно сильна, чтобы уничтожить все пиратские и ксотанские корабли, которые нам нужны. Мы готовы заплатить вам за доставку дополнительных обломков в этот сектор. Просто сбросьте их, и мы позаботимся обо всем остальном! Большое спасибо за ваше время!" --Мирный
    }

    return descriptionOptions[descriptionType]
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Создать объявление"
    mission.Log(_MethodName, "Создание объявления.")
    --Эта миссия происходит в том же секторе, в котором вы ее принимаете.
    local target = {}
    target.x, target.y = Sector():getCoordinates()

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x или Target.y не установлены - возвращается nil.")
        return 
    end
    
    local _Description = wreckingHavoc_formatDescription(_Station)

    reward = 0

    local bulletin =
    {
        -- данные для доски объявлений
        brief = mission.data.brief,
        title = mission.data.title,
        description = _Description,
        difficulty = "Переменная", --Зависит от того, как вы получаете обломки.
        reward = "Переменная",
        script = "missions/wreckinghavoc.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо за ваше покровительство! Мы заплатим вам в зависимости от того, сколько обломков вы сможете нам вернуть.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if player:hasScript("missions/wreckinghavoc.lua") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принимать дополнительные контракты на утилизацию! Откажитесь от текущего или завершите его.")
                return 0
            end
            return 1
        ]],
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],

        -- данные, важные для нашей собственной миссии
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = {credits = reward, relations = 0},
            punishment = { relations = 1000 }, --Ничего страшного. Просто небольшой укол.
            initialDesc = _Description
        }},
    }

    return bulletin
end

--endregion
