local StateManager = {}
AutomationManager = include("AutomationManager")
ShipValidation = include("ShipValidation")
function StateManager.onStateChanged(newState, oldState, window, fm)
    if newState == PlayerStateType.BuildCraft or newState == PlayerStateType.BuildTurret then
        if window and window.visible == true then
            fm.hide()
        end
    else
        if window and window.visible == false then
            local player = Player()
            if player and player.craft and ShipValidation.shipHasForemanModule(player.craft.id) then
                fm.show()
            end
        end
    end
end
function StateManager.updateAutomationButtonColors(autoScanLabel, autoMineLabel, autoDockLabel, autoDockWhenFullLabel, autoLootLabel)
    if onClient() then
        if autoScanLabel then
            autoScanLabel.color = AutomationManager.getAutoScanEnabled() and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        end
        if autoMineLabel then
            autoMineLabel.color = AutomationManager.getAutoMineEnabled() and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        end
        if autoDockLabel then
            autoDockLabel.color = AutomationManager.getAutoDockEnabled() and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        end
        if autoDockWhenFullLabel then
            autoDockWhenFullLabel.color = AutomationManager.getAutoDockWhenFull() and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        end
        if autoLootLabel then
            autoLootLabel.color = AutomationManager.getAutoLootEnabled() and ColorRGB(0,1,0) or ColorRGB(1,0,0)
        end
    end
end
function StateManager.updateCheckboxStates(fm, autoScanLabel, autoMineLabel, autoDockLabel, autoDockWhenFullLabel, autoLootLabel)
    if onClient() then
        StateManager.updateAutomationButtonColors(autoScanLabel, autoMineLabel, autoDockLabel, autoDockWhenFullLabel, autoLootLabel)
    end
end
return StateManager
