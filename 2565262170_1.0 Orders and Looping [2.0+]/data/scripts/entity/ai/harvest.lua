function AIHarvest:canContinueHarvesting()
    -- prevent terminating script before it even started
    if not self.harvestMaterial then return true end

    -- fully automated harvesting is only possible with captain or pilot
    -- if Entity():getCaptain() then
    --     return false
    -- end

    return valid(self.harvestLoot) or valid(self.objectToHarvest) or not self.noTargetsLeft
end

function AIHarvest:finalize()
    --Entity():invokeFunction("orderchain.lua", "sendOrderCompletedMessage")
    Entity():invokeFunction("orderchain.lua", "orderCompleted")
    ShipAI():setPassive()
    terminate()
end