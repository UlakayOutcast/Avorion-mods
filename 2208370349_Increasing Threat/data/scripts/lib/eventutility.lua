function EventUT.OOSattackEventAllowed()
    local sector = Sector()

    if sector:getValue("neutral_zone") then
        -- print ("No attack events in neutral zones.")
        return false
    end

    if sector:getEntitiesByScriptValue("no_attack_events") then
        -- print ("an entity prevented an attack")
        return false
    end

    return true
end