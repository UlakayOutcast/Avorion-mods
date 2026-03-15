if onServer() then
    local entity = Entity()
    if (entity.isShip or entity.isStation) then
        local _Script = "data/scripts/lib/esccdbg.lua"
        if entity:hasScript(_Script) then
            entity:removeScript(_Script)
        end
    end
end