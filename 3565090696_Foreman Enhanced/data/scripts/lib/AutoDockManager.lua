local AutoDockManager = {}
AutomationManager = include("AutomationManager")

function AutoDockManager.delayedAutoDock(getMineableAmountInVicinity, AutomationManager)
    AutomationManager.delayedAutoDockWrapper(getMineableAmountInVicinity, function(factionIndex, playerIndex)
        invokeServerFunction("returnMiningSquads", factionIndex, playerIndex)
    end)
end

return AutoDockManager
