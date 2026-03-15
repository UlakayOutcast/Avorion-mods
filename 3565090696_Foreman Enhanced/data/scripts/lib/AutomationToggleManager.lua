local AutomationToggleManager = {}
AutomationManager = include("AutomationManager")

function AutomationToggleManager.onAutoDockWhenFullToggle(fm)
    AutomationManager.setAutoDockWhenFull(not AutomationManager.getAutoDockWhenFull())
    fm.updateAutomationButtonColors()
    fm.saveAutomationSettings()
end

function AutomationToggleManager.onAutoScanChecked(checkbox, value, fm)
    AutomationManager.setAutoScanEnabled(value)
    fm.updateAutomationButtonColors()
    fm.saveAutomationSettings()
end

function AutomationToggleManager.onAutoMineChecked(checkbox, value, fm)
    AutomationManager.setAutoMineEnabled(value)
    fm.updateAutomationButtonColors()
    fm.saveAutomationSettings()
end

function AutomationToggleManager.onAutoDockChecked(checkbox, value, fm)
    AutomationManager.setAutoDockEnabled(value)
    fm.updateAutomationButtonColors()
    fm.saveAutomationSettings()
end

return AutomationToggleManager
