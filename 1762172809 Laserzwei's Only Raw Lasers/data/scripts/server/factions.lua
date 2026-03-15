

local onlyRawMining_InitPlayer = initializePlayer
function initializePlayer(player)
    onlyRawMining_InitPlayer(player)
    local cargoupgrade = SystemUpgradeTemplate("data/scripts/systems/startercargo.lua", Rarity(RarityType.Exotic), Random():createSeed())
    player:getInventory():add(cargoupgrade, false)

end
