--[[
    Секретная миссия
    Уничтожить супероружие
    ПРИМЕЧАНИЯ:
        - Специально сделано чрезвычайно сложным.
        - Я хочу, чтобы это был супербосс, которого почти невозможно победить.
        - Очень устал от игроков, хвастающихся тем, какие у них крутые корабли с 500 бажиллионами хп / щита / омикрона и насколько легкие миссии.
        - Супероружие должно иметь либо осадное орудие, которое наносит от 233 до 300 миллионов урона за выстрел, либо лазер мгновенного убийства а-ля лазерный босс.
        - ^ Осадное орудие должно убивать корабль с 700 миллионами HP примерно за 3 выстрела. Очевидно, что лазер мгновенного убийства убивает вещи мгновенно. << >>
        - Вторичное оружие на супероружии должно быть невероятно мощным. Используйте либо дальнобойные лазеры, либо самонаводящиеся ракеты.
        - Боссы типа осадного орудия получают значительный бонус к урону для банков вторичного оружия.
        - Добавьте оборудование для защиты от торпед, конечно.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ВЫПОЛНЕНИЯ ЭТОЙ МИССИИ:
        - Найдите чип на базе исследований атаки.
    ПРИМЕРНЫЙ ПЛАН
        - Отправляйтесь в сектор.
        - Сразитесь с супероружием.
        - Убейте его, если сможете.
    УРОВЕНЬ ОПАСНОСТИ
        Н/Д - Сложность этой миссии всегда одинакова.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")
include("structuredmission")

ESCCUtil = include("esccutil")
PariahUtility = include("pariahutility")

mission._Debug = 0
mission._Name = "Destroy Superweapon"

--region #INIT

--Стандартные данные миссии.
mission.data.brief = "Destroy Superweapon"
mission.data.title = "Destroy Superweapon"
mission.data.icon = "data/textures/icons/hazard-sign.png"
mission.data.priority = 8
mission.data.description = {
    "В руинах исследовательской лаборатории вы нашли схемы и данные о местоположении чрезвычайно мощного супероружия.",
    { text = "Судя по схемам, его будет почти невозможно победить. Вы, несомненно, будете считаться героем ${_FACTION}, если вам удастся его уничтожить." },
    { text = "Супероружие, похоже, находится в секторе (${location.x}:${location.y})." },
    { text = "Уничтожьте супероружие", bulletPoint = true, fulfilled = false }
}

local attackresearchbase_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Beginning...")

    if onServer()then
        if not _restoring then
            mission.Log(_MethodName, "Calling on server.")

            local _Rgen = ESCCUtil.getRand()

            --[[=====================================================
                CUSTOM MISSION DATA:
                .friendlyFaction
                .mainType
                .secondaryWeapons
                .gordianKnotid
            =========================================================]]
            mission.data.custom.friendlyFaction = _Data_in.friendlyFaction
            mission.data.custom.mainType = _Data_in.superweaponMain
            mission.data.custom.secondaryWeapons = _Data_in.superweaponSecondary

            mission.data.description[2].arguments = { _FACTION = Faction(mission.data.custom.friendlyFaction).name}

            _Data_in.reward = { credits = 100000000000, paymentMessage = "Earned %1% credits for destroying the Superweapon." }

            --Запустить стандартную инициализацию
            attackresearchbase_init(_Data_in)
        else
            --Восстановление
            attackresearchbase_init()
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

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.phases[1] = {}
mission.phases[1].onTargetLocationEntered = function(_X, _Y) 
    local _MethodName = "Phase 1 on Target Location Entered"
    
    if not mission.data.custom.gordianKnotid then
        local _GordianKnot = PariahUtility.spawnSuperWeapon(mission.data.custom.mainType, mission.data.custom.secondaryWeapons)
        mission.data.custom.gordianKnotid = _GordianKnot.id
    end

    --Дайте игроку льготный период, прежде чем он начнет взрывать.
    local _func = "resetTimeToActive"
    local _gk = Entity(mission.data.custom.gordianKnotid)

    --gk всегда имеет torp slammer.
    _gk:invokeFunction("torpedoslammer.lua", _func, 15)

    if _gk and valid(_gk) and _gk:getValue("_gk_superweaponscript") then
        local _script = _gk:getValue("_gk_superweaponscript")
        _gk:invokeFunction(_script, _func, 30)
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Phase 1 on Target Location Arrival Confirmed"
    mission.Log(_MethodName, "Beginning...")

    local _Rgen = ESCCUtil.getRand()

    local _Taunts = {
        "Давай сразимся, капитан. Мы решим это в бою.",
        "Приготовься!",
        "Ты не хочешь меня в качестве врага.",
        "Пришло время.",
        "Ты далеко от дома, не так ли?",
        "Помни, ты этого хотел.",
        "Хватит ли у тебя сил?",
        "Что это у нас здесь?",
        "Мы все совершаем ошибки. Ты так не думаешь, капитан?",
        "О, страдания."
    }

    local _GordianKnot = Entity(mission.data.custom.gordianKnotid)
    Sector():broadcastChatMessage(_GordianKnot, ChatMessageType.Chatter, _Taunts[_Rgen:getInt(1, #_Taunts)])
end

mission.phases[1].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Phase 1 On Entity Destroyed"
    mission.Log(_MethodName, "Beginning...")

    if _ID == mission.data.custom.gordianKnotid then
        destroySuperWeapon_finishAndReward()
    end
end

--endregion

--region #SERVER CALLS

function destroySuperWeapon_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    --Мы должны вручную установить репутацию здесь, потому что мы не можем перенести дающего из предыдущей миссии в чип в эту миссию.
    local _MissionDoer = Player().craftFaction or Player()
    local _Faction = Faction(mission.data.custom.friendlyFaction)
    local _Relation = _MissionDoer:getRelation(mission.data.custom.friendlyFaction)
    local _Galaxy = Galaxy()

    _Galaxy:setFactionRelations(_Faction, _MissionDoer, 100000)
    if _Relation.status ~= RelationStatus.Neutral and _Relation.status ~= RelationStatus.Allies then
        _Galaxy:setFactionRelationStatus(_Faction, _MissionDoer, RelationStatus.Neutral)
    end

    Player():sendChatMessage(_Faction.name, 0, "Это... это было невероятно! Вы действительно герой. Пожалуйста, примите эту награду.")
    reward()
    accomplish()
end

--endregion
