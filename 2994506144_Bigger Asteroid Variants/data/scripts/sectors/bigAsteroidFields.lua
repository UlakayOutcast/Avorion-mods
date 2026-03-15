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
local SectorGenerationChance = 125;
-- Probability for asteroids to have resources
local ResourceProbability = 0.1;
-- Chance for the sector to be resource rich
local ResourceRichChance = 0.3;
-- Probability for resource asteroids in a resource rich variant
local ResourceRichProbability = 0.8;

-- Probability for larger multiblock asteroids
local MultiblockAsteroidProbability = 0.1;
local RichMultiblockAsteroidProbability = 0.4;

-- Number of asteroidfields to be generated
local NumAsteroidFields = getFloat(2,4);
local NumNormalAsteroidFields = getFloat(3,6);



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
    math.randomseed(seed)
    
    local isResourceRich = math.random() < ResourceRichChance;
    local resProbability = ResourceProbability
    local multiProbability = MultiblockAsteroidProbability;

    if isResourceRich then
        resProbability = ResourceRichProbability;
        multiProbability = RichMultiblockAsteroidProbability;
    end

    if isResourceRich then
        print("Generating big resource rich asteroid sector!");
    else
        print("Generating big asteroid sector!")
    end

    local generator = SectorGenerator(x, y)

    for i = 1, NumAsteroidFields do
        local position = generator:createBigAsteroidField(resProbability)
        if math.random() < multiProbability then generator:createBigMultiAsteroid(position) end
    end

    for i = 1, NumNormalAsteroidFields do
        local position = generator:createAsteroidField(resProbability)
    end

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate