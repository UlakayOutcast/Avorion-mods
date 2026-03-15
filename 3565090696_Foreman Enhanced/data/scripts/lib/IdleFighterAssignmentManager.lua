local IdleFighterAssignmentManager = {}
function IdleFighterAssignmentManager.assignIdleFightersToTargets(factionIndex, factionData, salvageAssignments, salvageTargets, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, assignSquadToWreckage)
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] IdleFighterAssignmentManager.assignIdleFightersToTargets called for faction %d", factionIndex))
    end
    
    local fData = factionData[factionIndex]
    if not fData or not fData.salvage or not fData.salvageStandbyMode then 
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] IdleFighterAssignment: Faction %d not in salvage standby mode (salvage: %s, standby: %s)", 
                factionIndex, 
                fData and fData.salvage and "true" or "false",
                fData and fData.salvageStandbyMode and "true" or "false"))
        end
        return
    end
    
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] IdleFighterAssignment: Faction %d is in salvage standby mode, checking for idle squads", factionIndex))
    end
    
    -- BATCH ASSIGNMENT: Collect all idle squads first, then assign efficiently
    local idleSquads = {}
    local availableWreckages = {}
    
    -- Get all unassigned wreckages once, but first check for depleted wreckages
    local UnifiedWreckageCache = include("UnifiedWreckageCache")
    
    -- Check if any wreckages have been depleted and refresh cache if needed
    local cacheRefreshed = UnifiedWreckageCache.checkForDepletedWreckages()
    if cacheRefreshed and SALVAGE_DEBUG_ENABLED then
        print("[SALVAGE DEBUG] Batch Assignment: Cache refreshed due to depleted wreckages")
        -- Wait for cache refresh to complete before proceeding with batch assignment
        -- This prevents race conditions where assignments use stale cache data
    end
    
    -- Debug: Check if cache has any wreckages at all
    if SALVAGE_DEBUG_ENABLED then
        local allWreckages = UnifiedWreckageCache.getAllWreckages()
        local totalCount = 0
        for _ in pairs(allWreckages) do totalCount = totalCount + 1 end
        print(string.format("[SALVAGE DEBUG] Cache has %d total wreckages", totalCount))
        
        if totalCount == 0 then
            print("[SALVAGE DEBUG] WARNING: Cache is empty! No wreckages found in sector.")
        end
    end
    
    -- We'll get fresh unassigned wreckages for each squad to ensure we have the latest state
    
    -- Collect all idle squads
    local totalShips = 0
    local totalSquads = 0
    for shipIndex, shipData in pairs(fData.ships) do
        totalShips = totalShips + 1
        local salvageSquads = shipData.salvageSquads or {}
        for _ in pairs(salvageSquads) do
            totalSquads = totalSquads + 1
        end
    end
    
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] IdleFighterAssignment: Checking %d ships with %d total salvage squads", totalShips, totalSquads))
    end
    
    for shipIndex, shipData in pairs(fData.ships) do
        local ship = Entity(Uuid(shipIndex))
        if not valid(ship) then goto continue end
        local controller = FighterController(ship.id)
        local hangar = Hangar(ship.id)
        if not controller or not hangar then goto continue end
        local salvageSquads = shipData.salvageSquads or {}
        for i, _ in pairs(salvageSquads) do
            local isAssigned = false
            for wreckageId, assignment in pairs(salvageAssignments) do
                if assignment.squads then
                    local squadKey = string.format("%s_%d", shipIndex, i)
                    if assignment.squads[squadKey] then
                        isAssigned = true
                        break
                    end
                end
            end
            local hasActiveOrders = false
            local deployedFighters = {controller:getDeployedFighters(i)}
            if deployedFighters and #deployedFighters > 0 then
                for _, fighter in pairs(deployedFighters) do
                    if valid(fighter) then
                        local fighterAI = FighterAI(fighter.id)
                        if fighterAI then
                            local currentOrders = fighterAI.orders
                            local currentTarget = fighterAI.target
                            -- Squad is considered active if it has attack orders (regardless of target validity)
                            -- This prevents ping-ponging when targets become invalid during attack
                            if currentOrders == FighterOrders.Attack then
                                hasActiveOrders = true
                                if valid(Entity(currentTarget)) then
                                    if SALVAGE_DEBUG_ENABLED then
                                        print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: ACTIVE - has attack orders on valid target %s", shipIndex, i, tostring(currentTarget)))
                                    end
                                else
                                    if SALVAGE_DEBUG_ENABLED then
                                        print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: ACTIVE - has attack orders on invalid target %s (will complete mission)", shipIndex, i, tostring(currentTarget)))
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
            
            -- Only consider squad for assignment if it's truly idle (not assigned AND no active orders)
            if not isAssigned and not hasActiveOrders then
                if SALVAGE_DEBUG_ENABLED then
                    print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: IDLE - available for assignment", shipIndex, i))
                end
                -- Add to idle squads list for batch processing
                table.insert(idleSquads, {
                    shipIndex = shipIndex,
                    ship = ship,
                    controller = controller,
                    hangar = hangar,
                    squadIndex = i
                })
            else
                if SALVAGE_DEBUG_ENABLED then
                    if isAssigned then
                        print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: SKIPPED - already assigned to a wreckage", shipIndex, i))
                    elseif hasActiveOrders then
                        print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: SKIPPED - has active attack orders", shipIndex, i))
                    end
                end
            end
        end
        ::continue::
    end
    
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] Batch Assignment: Found %d idle squads", #idleSquads))
        if #idleSquads == 0 then
            print("[SALVAGE DEBUG] No idle squads found - checking why...")
        end
    end
    
    -- Track assigned wreckages to prevent conflicts
    local assignedWreckages = {}
    
    -- NEW SEQUENTIAL ASSIGNMENT SYSTEM
    -- Process squads one at a time to ensure proper proximity-based assignment
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] Starting sequential assignment for %d idle squads", #idleSquads))
    end
    
    -- Force a cache refresh to ensure we have the latest wreckage data
    UnifiedWreckageCache.refreshCache(true)
    if SALVAGE_DEBUG_ENABLED then
        print("[SALVAGE DEBUG] Forced cache refresh to detect new wreckages")
    end
    
    for squadIndex, squadData in ipairs(idleSquads) do
        local shipIndex = squadData.shipIndex
        local ship = squadData.ship
        local controller = squadData.controller
        local hangar = squadData.hangar
        local i = squadData.squadIndex
        
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] === SEQUENTIAL ASSIGNMENT %d/%d ===", squadIndex, #idleSquads))
            print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: Processing for proximity-based assignment", shipIndex, i))
        end
        
        local squadMaxMaterial = 0
        if hangar then
            local ok, result = pcall(function() return hangar:getHighestMaterialInSquadMainCategory(i) end)
            if ok and result then
                squadMaxMaterial = result.value + 1
            else
                if SALVAGE_DEBUG_ENABLED then
                    print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: Failed to get squad material level", shipIndex, i))
                end
                goto continue
            end
        else
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: No hangar found", shipIndex, i))
            end
            goto continue
        end
        
        -- Get CURRENT unassigned wreckages (this changes as we assign squads)
        local unassignedWreckages = UnifiedWreckageCache.getUnassignedWreckages()
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: Found %d currently unassigned wreckages", shipIndex, i, #unassignedWreckages))
        end
        
        if #unassignedWreckages == 0 then
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: No unassigned wreckages available - forcing cache refresh", shipIndex, i))
            end
            -- Force a cache refresh to detect new wreckages
            UnifiedWreckageCache.refreshCache(true)
            -- Try again with refreshed cache
            unassignedWreckages = UnifiedWreckageCache.getUnassignedWreckages()
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: After cache refresh, found %d unassigned wreckages", shipIndex, i, #unassignedWreckages))
            end
            if #unassignedWreckages == 0 then
                goto continue
            end
        end
        
        -- Find the BEST suitable wreckage (considering proximity to other active squads)
        local selectedWreckage = nil
        local bestScore = math.huge
        local fData = factionData[factionIndex]
        
        -- Get the current squad's position (from deployed fighters, not mothership)
        local squadPosition = ship.translationf -- Default to ship position if no fighters deployed
        local deployedFighters = {controller:getDeployedFighters(i)}
        if deployedFighters and #deployedFighters > 0 then
            for _, fighter in pairs(deployedFighters) do
                if valid(fighter) then
                    squadPosition = fighter.translationf
                    if SALVAGE_DEBUG_ENABLED then
                        print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: Using deployed fighter position (%.1f, %.1f, %.1f)", 
                            shipIndex, i, squadPosition.x, squadPosition.y, squadPosition.z))
                    end
                    break -- Use first valid fighter's position
                end
            end
        else
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: No deployed fighters, using ship position (%.1f, %.1f, %.1f)", 
                    shipIndex, i, squadPosition.x, squadPosition.y, squadPosition.z))
            end
        end
        
        -- Get list of currently active squad positions for mop-up logic
        local activeSquadPositions = {}
        for _, activeSquadData in ipairs(idleSquads) do
            if activeSquadData.shipIndex ~= shipIndex or activeSquadData.squadIndex ~= i then
                -- This is a different squad, check if it has active orders
                local activeController = activeSquadData.controller
                local activeHangar = activeSquadData.hangar
                local activeSquadIndex = activeSquadData.squadIndex
                
                if activeHangar then
                    local activeDeployedFighters = {activeController:getDeployedFighters(activeSquadIndex)}
                    if activeDeployedFighters and #activeDeployedFighters > 0 then
                        for _, fighter in pairs(activeDeployedFighters) do
                            if valid(fighter) then
                                local fighterAI = FighterAI(fighter.id)
                                if fighterAI and fighterAI.orders == FighterOrders.Attack then
                                    -- This squad is actively attacking, add its actual position
                                    table.insert(activeSquadPositions, fighter.translationf)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        
        for _, wreckage in ipairs(unassignedWreckages) do
            -- Basic validation
            if wreckage.data and valid(wreckage.data.entity) and wreckage.data.resourceAmount >= MIN_WRECKAGE_RESOURCES then
                -- Material compatibility check
                if wreckage.data.material and wreckage.data.material.value <= (squadMaxMaterial + 2) then
                    -- Mining filter check
                    if fData and fData.miningFilters and fData.miningFilters[wreckage.data.material.value] == true then
                        -- Calculate distance from squad's actual position
                        local squadDist = distance2(wreckage.data.translationf, squadPosition)
                        
                        -- Calculate proximity to other active squads (mop-up bonus)
                        local mopUpBonus = 0
                        if #activeSquadPositions > 0 then
                            local minActiveDist = math.huge
                            for _, activePos in ipairs(activeSquadPositions) do
                                local activeDist = distance2(wreckage.data.translationf, activePos)
                                if activeDist < minActiveDist then
                                    minActiveDist = activeDist
                                end
                            end
                            -- If wreckage is close to active squads, give it a bonus (lower score = better)
                            if minActiveDist < 500000 then -- Within 500km of active squads
                                mopUpBonus = minActiveDist * 0.1 -- 10% bonus for proximity to active squads
                                if SALVAGE_DEBUG_ENABLED then
                                    print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: Mop-up bonus applied to wreckage %s (active dist: %.1f, bonus: %.1f)", 
                                        shipIndex, i, wreckage.id, minActiveDist, mopUpBonus))
                                end
                            end
                        end
                        
                        -- Calculate final score (lower is better)
                        local finalScore = squadDist - mopUpBonus
                        
                        if finalScore < bestScore then
                            bestScore = finalScore
                            selectedWreckage = {
                                id = wreckage.id,
                                entity = wreckage.data.entity,
                                translationf = wreckage.data.translationf,
                                material = wreckage.data.material,
                                resourceAmount = wreckage.data.resourceAmount
                            }
                        end
                    end
                end
            end
        end
        
        if selectedWreckage then
            local ok, err = pcall(function()
                SalvageTargetManager = include("SalvageTargetManager")
                SalvageTargetManager.addSquadsToWreckage(selectedWreckage.id, selectedWreckage.translationf, factionIndex, shipIndex, {i}, salvageTargets)
                local squadKey = string.format("%s_%d", shipIndex, i)
                UnifiedWreckageCache.assignSquadToWreckage(selectedWreckage.id, squadKey)
                controller:setSquadOrders(i, FighterOrders.Attack, selectedWreckage.entity.id)
            end)
            if ok then
                if SALVAGE_DEBUG_ENABLED then
                    local squadDist = distance2(selectedWreckage.translationf, squadPosition)
                    print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: ASSIGNED to best wreckage %s (squad distance: %.1f, score: %.1f, material: %d, resources: %.1f)", 
                        shipIndex, i, selectedWreckage.id, squadDist, bestScore, selectedWreckage.material.value, selectedWreckage.resourceAmount))
                end
            else
                if SALVAGE_DEBUG_ENABLED then
                    print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: FAILED to assign to wreckage %s: %s", shipIndex, i, selectedWreckage.id, tostring(err)))
                end
            end
        else
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] Ship %s Squad %d: No suitable wreckage found (squad max material: %d)", shipIndex, i, squadMaxMaterial))
            end
        end
        ::continue::
    end
    
    -- After all assignments are complete, check if we should refresh cache for newly available small wreckages
    if #idleSquads > 0 and SALVAGE_DEBUG_ENABLED then
        print("[SALVAGE DEBUG] Batch Assignment: Checking for newly available wreckages after assignments")
        local hasNewWreckages = UnifiedWreckageCache.checkForDepletedWreckages()
        if hasNewWreckages then
            print("[SALVAGE DEBUG] Batch Assignment: Found newly available wreckages, cache refreshed")
        end
    end
end
return IdleFighterAssignmentManager
