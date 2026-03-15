local SettingsRequestManager = {}
function SettingsRequestManager.requestLoadFromServer()
    if onClient() then
        invokeServerFunction("loadSettingsFromServer")
    end
end
function SettingsRequestManager.loadSettingsFromServer()
    SettingsManager.loadSettingsFromServer()
end
function SettingsRequestManager.receiveLoadedSettings(scan, mine, dock, dockWhenFull, loot, yieldVisible, fm, yieldVisiblePreference, yieldWindow)
    SettingsManager.receiveLoadedSettings(scan, mine, dock, dockWhenFull, loot, yieldVisible, fm, yieldVisiblePreference, yieldWindow)
end
return SettingsRequestManager
