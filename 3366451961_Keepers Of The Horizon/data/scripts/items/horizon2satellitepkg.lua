package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ESCCUtil = include("esccutil")
local PlanGenerator = include("plangenerator")
include("stringutility")

function create(item, rarity)

    rarity = Rarity(RarityType.Exceptional)

    item.stackable = true
    item.depleteOnUse = true
    item.name = "Subspace Research Satellite"
    item.price = 0
    item.icon = "data/textures/icons/satellite.png"
    item.rarity = rarity
    item:setValue("subtype", "HorizonStory2ResearchSatellite")

    local tooltip = Tooltip()
    tooltip.icon = item.icon
    tooltip.rarity = rarity

    local title = "Subspace Research Satellite"

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = rarity.tooltipFontColor
    tooltip:addLine(line)

    -- empty line
    local line = TooltipLine(14, 14)
    tooltip:addLine(line)

    local line = TooltipLine(20, 15)
    line.ltext = "Depleted on Use"%_t
    line.lcolor = ColorRGB(1.0, 1.0, 0.3)
    tooltip:addLine(line)

    -- empty line
    local line = TooltipLine(14, 14)
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Can be deployed by the player."
    tooltip:addLine(line)

    local line = TooltipLine(14, 14)
    tooltip:addLine(line)

    --Part of a sentence. Full sentence: 'Deploy this satellite in a sector to suppress energy signatures and to hide any activity from persecutors. Lasts twice as long as a Mk. I.'
    local line = TooltipLine(18, 14)
    line.ltext = "Deploy this satellite in a sector"
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "to research subspace signals"
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "for the hacker."
    tooltip:addLine(line)

    item:setTooltip(tooltip)

    return item
end

local function getPositionInFront(craft, distance)

    local position = craft.position
    local right = position.right
    local dir = position.look
    local up = position.up
    local position = craft.translationf

    local pos = position + dir * (craft.radius + distance)

    return MatrixLookUpPosition(right, up, pos)
end

function activate(item)

    local craft = Player().craft
    if not craft then return false end

    local desc = EntityDescriptor()
    desc:addComponents(
       ComponentType.Plan,
       ComponentType.BspTree,
       ComponentType.Intersection,
       ComponentType.Asleep,
       ComponentType.DamageContributors,
       ComponentType.BoundingSphere,
       ComponentType.BoundingBox,
       ComponentType.Velocity,
       ComponentType.Physics,
       ComponentType.Scripts,
       ComponentType.ScriptCallback,
       ComponentType.Title,
       ComponentType.Owner,
       ComponentType.Durability,
       ComponentType.PlanMaxDurability,
       ComponentType.InteractionText,
       ComponentType.EnergySystem
       )

    local faction = ESCCUtil.getNeutralSmugglerFaction()
    local plan = PlanGenerator.makeStationPlan(faction)
    plan:forceMaterial(Material(MaterialType.Iron))

    local s = 15 / plan:getBoundingSphere().radius
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = true

    desc.position = getPositionInFront(craft, 20)
    desc:setMovePlan(plan)
    desc.factionIndex = faction.index

    local satellite = Sector():createEntity(desc)
    satellite:setValue("horizon2_research_satellite", true)
    satellite.title = "Subspace Research Satellite"

    return true
end
