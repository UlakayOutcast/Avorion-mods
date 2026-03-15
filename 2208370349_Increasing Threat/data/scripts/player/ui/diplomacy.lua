local increasingThreatTraitTable = {"vengeful", "craven", "tempered", "covetous", "brutish", "wily"}

Diplomacy._Debug = 0

if onServer() then
    function Diplomacy.sendFactionsWithIncreasingThreatTraits()
        local _MethodName = "Send Factions With IT Traits"
        Diplomacy.Log(_MethodName, "sending factions w/ increasing threat traits")
        local player = Player(callingPlayer)
        if not player then return end

        local galaxy = Galaxy()
        if not galaxy then return end

        local _VisibleToidx = "_ITTraits_VisibleTo_" .. tostring(player.index)

        local factions = {}
        for level = 0, 32 do
            local pirateFaction = galaxy:getPirateFaction(level)
            if pirateFaction:getValue("_increasingthreat_traits2_set") and pirateFaction:getValue(_VisibleToidx) then
                local traitData = {}
                traitData["hasTraits"] = true
                for _, trait in pairs(increasingThreatTraitTable) do
                    traitData[trait] = pirateFaction:getTrait(trait)
                end

                factions[galaxy:getPirateFaction(level).index] = traitData
            else
                factions[galaxy:getPirateFaction(level).index] = { hasTraits = false }
            end
        end

        invokeClientFunction(player, "receiveFactionsWithIncreasingThreatTraits", factions)
    end
end

if onClient() then
    --Run the regular initialize first, then invoke an extra server function.
    local initialize_IncreasingThreat = Diplomacy.initialize
    function Diplomacy:initialize()
        self.factionsWithIncreasingThreatTraits = {}

        invokeServerFunction("sendFactionsWithIncreasingThreatTraits")

        initialize_IncreasingThreat(self)
    end

    function Diplomacy:receiveFactionsWithIncreasingThreatTraits(factions)
        local _MethodName = "Recieve Factions With IT Traits"
        Diplomacy.Log(_MethodName, "got factions")
        self.factionsWithIncreasingThreatTraits = factions
    end

    local updateTraits_IncreasingThreat = Diplomacy.updateTraits
    function Diplomacy:updateTraits(faction)
        local _MethodName = "Update Traits"
        Diplomacy.Log(_MethodName, "requesting factions w/ increasing threat traits")
        self:requestFactionsWithIncreasingThreatTraits()

        updateTraits_IncreasingThreat(self, faction)
        Diplomacy.Log(_MethodName, "running updateTraits on faction " .. faction.index)

        if not self.factionsWithIncreasingThreatTraits then
            Diplomacy.Log(_MethodName, "factions with increasing threat traits is nil. returning.")
            return
        else
            Diplomacy.Log(_MethodName, "continuing the update.")
        end

        local text

        if self.factionsWithIncreasingThreatTraits[faction.index] then
            local traitData = self.factionsWithIncreasingThreatTraits[faction.index]

            if traitData["hasTraits"] then
                Diplomacy.Log(_MethodName, "Faction has increasing threat traits")
                for _, trait in pairs(increasingThreatTraitTable) do
                    Diplomacy.Log(_MethodName, "eval " .. trait)
                    local value = traitData[trait] or 0
                    Diplomacy.Log(_MethodName, "trait value is " .. value)
                    if value >= 0.25 then
                        Diplomacy.Log(_MethodName, "value is notable. add to list.")
                        local name = self:getIncreasingThreatTraitName(trait, value)
                        local descriptions = self:getIncreasingThreatTraitDescription(trait, value)
                        if name then
                            if text then
                                text = text .. "\n"
                            else
                                text = ""
                            end

                            text = text .. "\\c()" .. name .. "\\c(777)"

                            if #descriptions > 0 then
                                for _, description in pairs(descriptions) do
                                    text = text .. "\n- " .. description
                                end
                            end

                            text = text .. "\n"
                        end
                    end
                    local temptext = text or "nil"
                    Diplomacy.Log(_MethodName, "final text " .. temptext)
                end

                if not text then
                    self.traitsLabel:hide()
                    text = ""
                else
                    self.traitsLabel:show()
                end

                self.traits.text = text
            end
        end
    end

    function Diplomacy:requestFactionsWithIncreasingThreatTraits()
        invokeServerFunction("sendFactionsWithIncreasingThreatTraits")
    end

    function Diplomacy:getIncreasingThreatTraitName(trait, value)
        if value < 0.25 then return end

        if value < 0.85 then
            return string.firstToUpper(trait%_t)
        end

        return "${trait} (Very)"%_t % {trait = string.firstToUpper(trait%_t)}
    end

    function Diplomacy:getIncreasingThreatTraitDescription(trait, value)
        local descriptions = {}

        if trait == "vengeful" then
            table.insert(descriptions, "Attacks hated factions more frequently") --pirateattack (hatred / notoriety) + decap strike => DONE
        elseif trait == "craven" then
            table.insert(descriptions, "Attacks civilized sectors less often") --pirateattack + decap strike => DONE
        elseif trait == "tempered" then
            table.insert(descriptions, "Does not build hatred as quickly") --pirateattack / decapstrike / deepfakedistress => DONE
            table.insert(descriptions, "Loses hatred more slowly over time") -- => DONE
            table.insert(descriptions, "Cannot be bribed") --bribe => DONE
        elseif trait == "covetous" then
            table.insert(descriptions, "Loses hatred more quickly over time") -- => DONE
            table.insert(descriptions, "Easier to bribe") --bribe => DONE
        elseif trait == "brutish" then
            table.insert(descriptions, "Sends more ships when attacking") --pirateattack + decap strike => DONE
        elseif trait == "wily" then
            table.insert(descriptions, "Sends specialized ships when attacking") --pirateattack + decap strike => DONE
        end

        return descriptions
    end
end

--Run the regular CreateNamespace first, then add some extra stuff.
local CreateNamespace_IncreasingThreat = Diplomacy.CreateNamespace
function Diplomacy.CreateNamespace()
    local IThreat_result = CreateNamespace_IncreasingThreat()
    local IThreat_instance = IThreat_result.instance

    if onServer() then
        IThreat_result.sendFactionsWithIncreasingThreatTraits = IThreat_instance.sendFactionsWithIncreasingThreatTraits

        callable(IThreat_result, "sendFactionsWithIncreasingThreatTraits")
    end

    if onClient() then
        IThreat_result.receiveFactionsWithIncreasingThreatTraits = function(...) return IThreat_instance:receiveFactionsWithIncreasingThreatTraits(...) end
    end

    return IThreat_result
end

--region #CLIENT / SERVER CALLS

function Diplomacy.Log(_MethodName, _Msg)
    if Diplomacy._Debug == 1 then
        print("[IT Diplomacy] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion