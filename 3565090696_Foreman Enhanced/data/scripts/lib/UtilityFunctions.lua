local UtilityFunctions = {}
function UtilityFunctions.getOreAmountEstimate(resourcesToMine)
    if resourcesToMine == 0 then
        return 0
    end
    local a = resourcesToMine
    local b = 0
    while a > 100000 do
        b = b + 100
        a = a - 100000
    end
    if b == 0 then
        return "<100k"
    else
        return ">"..b.."k"
    end
end
return UtilityFunctions
