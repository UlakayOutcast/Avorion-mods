local UpdateLoopManager = {}
ShipValidation = include("ShipValidation")
WindowManager = include("WindowManager")
function UpdateLoopManager.update(timeStep, fm, window, shouldUpdate, minimized, 
    periodicSaveTimeLeft, periodicSaveInterval, cargoTimeLeft, cargoRefheshInterval,
    uiRefreshtimeLeft, uiRefreshInterval, autoDockPending, autoDockTimer, autoDockDelay,
    sectorScanned, sectorScanTimeRemaining, sectorScanTime, shipHasForemanSystem,
    scanAccuracy, harvest, salvage, ships, miningAmountLeftLabel, scanProgress,
    startMiningButton, stopMiningButton, yieldSalvageCountLabel, filterCheckBoxes,
    salvageCountUpdateLeft, salvageCountUpdateInterval)
    if onClient() then
        periodicSaveTimeLeft = periodicSaveTimeLeft - timeStep
        if periodicSaveTimeLeft <= 0 then
            periodicSaveTimeLeft = periodicSaveInterval
            fm.periodicSaveSettings(true) -- true = called from update loop
        end
        if Player().craft and not ShipValidation.shipHasForemanModule(Player().craft.id) then
            fm.hide()
        end
        if window and shouldUpdate then
            cargoTimeLeft = cargoTimeLeft - timeStep
            if salvage and yieldSalvageCountLabel and window.visible then
                salvageCountUpdateLeft = salvageCountUpdateLeft - timeStep
                if salvageCountUpdateLeft <= 0 then
                    salvageCountUpdateLeft = salvageCountUpdateInterval
                    YieldUIManager.updateSalvageCount(fm.getSalvageTargetCount)
                end
            end
            if window.visible then
                local clientPos = WindowManager.getClientWindowLastPos()
                if clientPos and (window.position.x ~= clientPos.x or window.position.y ~= clientPos.y) then
                    local pos = window.position
                    if minimized then
                        pos.y = pos.y - 230
                    end
                    WindowManager.setClientWindowLastPos(window.position)
                    invokeServerFunction("saveWindowPos_server", pos)
                end
                if sectorScanned then
                    uiRefreshtimeLeft = uiRefreshtimeLeft - timeStep
                    if uiRefreshtimeLeft <= 0 then
                        uiRefreshtimeLeft = uiRefreshInterval
                        if shipHasForemanSystem then
                            local wantsPerOre = (scanAccuracy == 4) or (scanAccuracy == 2)
                            local resourcesLeftTotal, asteroidCount, resources = fm.getMineableAmountInVicinity(true, wantsPerOre)
                            YieldUIManager.setMiningAmountLabelText(resourcesLeftTotal, asteroidCount, resources, scanAccuracy, filterCheckBoxes)
                            fm.updateYieldUI(resourcesLeftTotal, asteroidCount, (wantsPerOre and resources) or nil)
                            if salvage and yieldSalvageCountLabel then
                                YieldUIManager.updateSalvageCount(fm.getSalvageTargetCount)
                            elseif yieldSalvageCountLabel then
                                YieldUIManager.clearSalvageCount()
                            end
                            if harvest and resourcesLeftTotal == 0 then
                                harvest = false
                                invokeServerFunction("sendForemanInfo", "Sector cleared from mineable asteroids")
                                startMiningButton.active = true
                                stopMiningButton.active = false
                                if AutomationManager.getAutoDockEnabled() then
                                    autoDockPending = true
                                    autoDockTimer = autoDockDelay
                                    invokeServerFunction("sendForemanInfo", "Auto-dock starting in " .. tostring(autoDockDelay) .. " seconds...")
                                else
                                    invokeServerFunction("returnMiningSquads", Player().craft.factionIndex, Player().index)
                                end
                            end
                        else
                            miningAmountLeftLabel.caption = "No mining systems available"%_t
                        end
                    end
                else
                    miningAmountLeftLabel.caption = ""
                end
                if cargoTimeLeft <= 0 then
                    cargoTimeLeft = cargoRefheshInterval
                    fm.updateShipListFreeCargo()
                    if AutomationManager.getAutoDockWhenFull() then
                        AutomationManager.checkAutoDockWhenFull(ships, harvest, salvage)
                    end
                end
                if autoDockPending then
                    autoDockTimer = autoDockTimer - timeStep
                    if autoDockTimer <= 0 then
                        autoDockPending = false
                        fm.delayedAutoDock()
                        if miningAmountLeftLabel then miningAmountLeftLabel:hide() end
                    else
                        local secondsLeft = math.ceil(autoDockTimer)
                        if math.floor(autoDockTimer * 10) % 10 == 0 then  -- Update every 0.1 seconds but only when seconds change
                            if miningAmountLeftLabel then miningAmountLeftLabel:show(); miningAmountLeftLabel.caption = "Auto-dock in " .. secondsLeft .. " seconds..." end
                        end
                    end
                end
                if sectorScanTimeRemaining ~= nil then
                    if sectorScanTimeRemaining >= 0 then
                        sectorScanTimeRemaining = sectorScanTimeRemaining - timeStep
                        if scanProgress then
                            scanProgress.progress = (sectorScanTime-sectorScanTimeRemaining) / sectorScanTime
                        end
                    else
						-- Local timer elapsed but server didn't push completion yet.
						-- Hide UI and request a status sync to avoid hanging state.
						if fm and fm.hideScan then fm.hideScan() end
						if fm and fm.getSectorScanStatus then
							local factionIndex = nil
							if fm.getActiveScanFactionIndex then factionIndex = fm.getActiveScanFactionIndex() end
							if not factionIndex then
								local craft = Player() and Player().craft
								if craft then factionIndex = craft.factionIndex end
							end
							if factionIndex then fm.getSectorScanStatus(factionIndex) end
						end
						sectorScanTimeRemaining = nil
                    end
                end
            end
        end
    end
    return periodicSaveTimeLeft, cargoTimeLeft, uiRefreshtimeLeft, autoDockPending, autoDockTimer, sectorScanTimeRemaining, harvest, salvageCountUpdateLeft
end
return UpdateLoopManager
