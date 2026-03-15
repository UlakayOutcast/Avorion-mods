
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("defaultscripts")
include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace BoardingUtility
BoardingUtility = {}

local forbidden = {}
forbidden["data/scripts/entity/antismuggle.lua"] = true
forbidden["data/scripts/entity/blocker.lua"] = true
forbidden["data/scripts/entity/civilship.lua"] = true
forbidden["data/scripts/entity/claim.lua"] = true
forbidden["data/scripts/entity/claimalliance.lua"] = true
forbidden["data/scripts/entity/deleteonplayersleft.lua"] = true
forbidden["data/scripts/entity/restoreshipcountondelete.lua"] = true

if onServer() then

    -- Store Vanilla Function Incase They Are Needed
    BoardingUtility.OldInitialize = BoardingUtility.initialize
    BoardingUtility.OldOnBoardingSuccessful = BoardingUtility.onBoardingSuccessful
    BoardingUtility.OldClearScriptValues = BoardingUtility.clearScriptValues
    BoardingUtility.OldClearScriptValues = BoardingUtility.clearScriptValues
    BoardingUtility.OldUpdateScripts = BoardingUtility.updateScripts

    function BoardingUtility.initialize()
        local sector = Sector()
        sector:registerCallback("onBoardingSuccessful", "onBoardingSuccessful")
    end

    function BoardingUtility.onBoardingSuccessful(id, oldFactionIndex, newFactionIndex)
        local newFaction = Faction(newFactionIndex)
        if not newFaction then return end

        -- only update scripts if a player now owns the craft
        if not newFaction.isAIFaction then

            local entity = Entity(id)

            print(entity.name)
            print(entity.title)

            local Num = entity.volume + entity.numCargos + oldFactionIndex + newFactionIndex + appTimeMs()
            local Chance = Random(Seed(Num)):getInt(0, 100)
            local Defunct = true
        
            -- 75% Chance to get a Functional Station
            if Chance <= 75 then
                --print("Claiming A Functional Station")
                Defunct = false 
            end

            entity.damageMultiplier = 1.0
            entity.dockable = true

            local cargoBay = CargoBay(id)
            if cargoBay then
                cargoBay.fixedSize = false
            end

            local shield = Shield(id)
            if shield then shield:resetResistance() end

            local durability = Durability(id)
            if durability then 
                durability:resetWeakness() 
                durability.invincibility = 0.0
            end

            BoardingUtility.updateScripts(entity, Defunct)
            BoardingUtility.clearScriptValues(entity, Defunct)

            if Defunct == true and entity.isStation then
                Player(newFactionIndex):sendChatMessage("Boarding Party", 0, "Станция повреждена, функции станции неработоспособны и не подлежат восстановлению.")
            elseif entity.isStation then
                Player(newFactionIndex):sendChatMessage("Boarding Party", 0, "Станция повреждена, но станция работает, и все гражданские лица, не участвующие в боевых действиях, готовы сотрудничать.")
            end

        end

    end

    function BoardingUtility.clearScriptValues(entity, defunct)

        -- Remove All Values
        entity:clearValues()

        -- Add Equipment Dock Values Back In If Functional
        if defunct == false then         
            for index, name in pairs(entity:getScripts()) do
                if string.match(name, "data/scripts/entity/merchants/equipmentdock") then
                    --print("Replacing Default Equipment Dock Values")
                    entity:setValue("remove_permanent_upgrades", "true")
                end
            end
        end 

    end

    function BoardingUtility.updateScripts(entity, defunct)
        
        --print("Updating Scripts")

        for index, name in pairs(entity:getScripts()) do

            if defunct == false then -- Functional

                if string.match(name, "data/scripts/entity/ai/") or
                string.match(name, "data/scripts/entity/dialogs/") or
                string.match(name, "data/scripts/entity/story/") then
    
                    --print("Removing Script '" .. name .. "'")
                    entity:removeScript(index)
    
                elseif forbidden[name] then

                    --print("removing script  '" .. name .. "'")
                    entity:removeScript(index)

                end

            else -- Defunct

                if string.match(name, "data/scripts/entity/ai/") or
                string.match(name, "data/scripts/entity/dialogs/") or
                string.match(name, "data/scripts/entity/story/") or
                string.match(name, "data/scripts/entity/merchants/") then
    
                    --print("Removing Script '" .. name .. "'")
                    entity:removeScript(index)
    
                elseif forbidden[name] then

                    --print("removing script  '" .. name .. "'")
                    entity:removeScript(index)

                end

            end
        end

        if entity.type == EntityType.Ship then
            AddDefaultShipScripts(entity)

        elseif entity.type == EntityType.Station then
            AddDefaultStationScripts(entity)
            SetBoardingDefenseLevel(entity)        

            -- If Non-Functional
            if defunct == true then

                local type = entity:getValue("factory_type")
                if type and type == "mine" then
                    entity:addScript("data/scripts/entity/derelictminefounder.lua")
                else
                    entity:addScript("data/scripts/entity/derelictstationfounder.lua")
                end

            end

        end
    end

end
