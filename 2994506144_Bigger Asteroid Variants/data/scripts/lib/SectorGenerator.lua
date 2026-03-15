local AsteroidPlanGenerator = include ("asteroidplangenerator")


function SectorGenerator:createBigAsteroidField(probability)
    -- BigAsteroidField Settings
    -- Number of asteroids per asteroid field
    local bigAsteroidNums = 50;
    -- Minimum size of an asteroid
    local bigAsteroidMinSize = 30;
    -- Maximum size of an asteroid 
    local bigAsteroidMaxSize = 60;
    -- Radius of asteroidfield to spread asteroids onto
    local bigAsteroidFieldSize = 3000;

    local amount = getFloat(0.75, 1.25);
    local size = getFloat(0.75, 1.5)

    local generator = AsteroidFieldGenerator(self.coordX, self.coordY)
    return generator:createAsteroidFieldEx(bigAsteroidNums * amount, bigAsteroidFieldSize * size, bigAsteroidMinSize, bigAsteroidMaxSize, true, probability);
end

function SectorGenerator:createHugeAsteroidField(probability)
    -- HugeAsteroidField Settings
    -- Number of asteroids per asteroid field
    local hugeAsteroidNums = 20;
    -- Minimum size of an asteroid
    local hugeAsteroidMinSize = 65;
    -- Maximum size of an asteroid 
    local hugeAsteroidMaxSize = 105;
    -- Radius of asteroidfield to spread asteroids onto
    local hugeAsteroidFieldSize = 5000;

    local amount = getFloat(0.75, 1.25);
    local size = getFloat(0.75, 1.5)

    local generator = AsteroidFieldGenerator(self.coordX, self.coordY)
    return generator:createAsteroidFieldEx(hugeAsteroidNums * amount, hugeAsteroidFieldSize * size, hugeAsteroidMinSize, hugeAsteroidMaxSize, true, probability);
end

function SectorGenerator:createBigMultiAsteroid(position)
    local bigMultiAsteroidMinSize = 65;
    local bigMultiAsteroidMaxSize = 75;
    local bigMultiAsteroidSizeFactor = 2.5;

    local bigMultiAsteroidSize = getFloat(bigMultiAsteroidMinSize, bigMultiAsteroidMaxSize) * bigMultiAsteroidSizeFactor;
    local position = position or self:getPositionInSector()
    return self:createBigAsteroidEx(position, bigMultiAsteroidSize, true)
end

function SectorGenerator:createHugeMultiAsteroid(position)
    local hugeMultiAsteroidMinSize = 100;
    local hugeMultiAsteroidMaxSize = 115;
    local hugeMultiAsteroidSizeFactor = 2.5;

    local hugeMultiAsteroidSize = getFloat(hugeMultiAsteroidMinSize, hugeMultiAsteroidMaxSize) * hugeMultiAsteroidSizeFactor;
    local position = position or self:getPositionInSector()
    return self:createBigAsteroidEx(position, hugeMultiAsteroidSize, true)
end