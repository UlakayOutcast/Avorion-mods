local initialize_IncreasingThreat = SmugglersMarket.initialize
function SmugglersMarket.initialize()
    initialize_IncreasingThreat()

    if onServer() then
        local station = Entity()
        station:addScriptOnce("merchants/informant.lua")
        station:addScriptOnce("merchants/briber.lua")
    end
end