package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include ("SectorGenerator")
local Placer = include("placer")
include("music")

local SectorTemplate = {}

--
-- Sector Settings
--
-- Chance for the sector to be used
local SectorGenerationChance = 150;
-- Probability for resource asteroids in a resource rich variant
local ResourceRichProbability = 0.8;

-- Probability for larger multiblock asteroids
local MultiblockAsteroidProbability = 0.35;

-- Number of asteroidfields to be generated
local NumAsteroidFields = 7


-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y, seed, factionIndex, innerArea)
    return SectorGenerationChance
end

function SectorTemplate.offgrid(x, y)
    return true
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

-- this function returns how many ships there will be in the sector (from, to)
function SectorTemplate.ships(x, y)
    return 0, 0
end

-- this function returns how many stations there will be in the sector (from, to)
function SectorTemplate.stations(x, y)
    return 0, 0
end

function SectorTemplate.musicTracks()
    local good = {
        primary = TrackCollection.HappyNoParticle(),
        secondary = TrackCollection.HappyNeutral(),
    }

    local neutral = {
        primary = TrackCollection.Neutral(),
        secondary = TrackCollection.HappyNeutral(),
    }

    local bad = {
        primary = TrackCollection.Middle(),
        secondary = TrackCollection.Neutral(),
    }

    return good, neutral, bad
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    print("Generating normal rich asteroid sector!");

    math.randomseed(seed)

    local generator = SectorGenerator(x, y)

    for i = 1, NumAsteroidFields do
        local position = generator:createAsteroidField(ResourceRichProbability)
        if math.random() < MultiblockAsteroidProbability then generator:createBigAsteroid(position) end
    end

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate