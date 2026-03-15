local LLTE_PlanGenerator_SelectMaterial = PlanGenerator.selectMaterial
function PlanGenerator.selectMaterial(_Faction)
    if _Faction.name == "The Cavaliers" then
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()

        local _Probabilities = Balancing_GetTechnologyMaterialProbability(_X, _Y)
        local _Material = Material(getValueFromDistribution(_Probabilities))

        local _Dist = length(vec2(_X, _Y))
        --Don't spawn avorion cavaliers outside the barrier, even if they are strength 5.
        if _Material.value == 6 and _Dist > Balancing_GetBlockRingMin() then
            _Material.value = 5
        end

        return _Material
    else
        return LLTE_PlanGenerator_SelectMaterial(_Faction)
    end
end