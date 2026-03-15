local ITUtil = include("increasingthreatutility")

local IncreasingThreat_initialize = Persecutor.initialize
function Persecutor.initialize()
    IncreasingThreat_initialize()

    if onServer() then
        Entity():registerCallback("onDestroyed", "onDestroyed")
    end
end

function Persecutor.onDestroyed()
    local ship = Entity()
    local piratefaction = Faction(ship.factionIndex)

    local damagers = {ship:getDamageContributors()}
    local _IncreasedHatredFor = {}
    local players = {Sector():getPlayers()}

    for _, damager in pairs(damagers) do
        local faction = Faction(damager)
        if faction and (faction.isPlayer or faction.isAlliance) then
            if faction.isPlayer and not _IncreasedHatredFor[faction.index] then
                self.increaseHatred(faction, piratefaction)
                _IncreasedHatredFor[faction.index] = true
            end
            if faction.isAlliance then
                for _, _Pl in pairs(players) do
                    if faction:contains(_Pl.index) and not _IncreasedHatredFor[_Pl.index] then
                        self.increaseHatred(_Pl, piratefaction)
                        _IncreasedHatredFor[_Pl.index] = true
                    end
                end
            end
        end
    end
end

function Persecutor.increaseHatred(_Faction, _MyFaction)
    local xmultiplier = 1
    local _Difficulty = GameSettings().difficulty
    if _Difficulty == Difficulty.Veteran then
        xmultiplier = 1.15
    elseif _Difficulty == Difficulty.Expert then
        xmultiplier = 1.3
    elseif _Difficulty > Difficulty.Expert then
        xmultiplier = 1.5
    end

    local hatredindex = "_increasingthreat_hatred_" .. _MyFaction.index
    local hatred = _Faction:getValue(hatredindex)
    local hatredincrement = random():getInt(2, 5)

    local _Tempered = _MyFaction:getTrait("tempered")
    if _Tempered then
        local _TemperedFactor = 1.0
        if _Tempered >= 0.25 then
            _TemperedFactor = 0.8
        end
        if _Tempered >= 0.75 then
            _TemperedFactor = 0.7
        end
        hatredincrement = hatredincrement * _TemperedFactor
    end
    hatredincrement = math.ceil(hatredincrement)

    if hatred then
        hatred = hatred + hatredincrement
    else
        hatred = hatredincrement
    end
    _Faction:setValue(hatredindex, hatred)
    if hatred >= 700 then
        ITUtil.setIncreasingThreatTraits(_MyFaction)
    end
end