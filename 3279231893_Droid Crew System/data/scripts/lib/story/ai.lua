package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
include ("randomext")
include ("utility")
include ("stringutility")
SectorTurretGenerator = include ("sectorturretgenerator")
ShipUtility = include ("shiputility")
include("weapontype")


function AI.spawn(x, y)

    -- no double spawning
    if Sector():getEntitiesByScript("entity/story/aibehaviour.lua") then return end

    local faction = AI.getFaction()

    local plan = LoadPlanFromFile("data/plans/the_ai.xml")

    local s = 1.5
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = false

    local pos = random():getVector(-1000, 1000)
    pos = MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)

    local boss = Sector():createShip(faction, "", plan, pos)

    boss.shieldDurability = boss.shieldMaxDurability
    boss.title = "The AI"%_T
    boss.name = ""
    boss.crew = boss.idealCrew
    boss:addScriptOnce("story/aibehaviour")
    boss:addScriptOnce("story/aidialog")
    boss:addScriptOnce("deleteonplayersleft")

    WreckageCreator(boss.index).active = false
    Loot(boss.index):insert(InventoryTurret(SectorTurretGenerator():generate(x, y, 0, Rarity(RarityType.Exotic))))
    Loot(boss.index):insert(InventoryTurret(SectorTurretGenerator():generate(x, y, 0, Rarity(RarityType.Exotic))))
	Loot(boss.index):insert(SystemUpgradeTemplate("data/scripts/systems/controlcomputer.lua", Rarity(RarityType.Legendary), Seed()))
    boss:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
    boss:addScriptOnce("utility/buildingknowledgeloot.lua", Material(MaterialType.Naonite))

    -- create custom plasma turrets
    AI.addTurrets(boss, 25)

    Boarding(boss).boardable = false
    boss.dockable = false

    AI.checkForDrop()

    return boss
end



