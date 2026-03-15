package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("galaxy")
include("callable")
include("productions")
include("weapontype")

local PirateGenerator = include("pirategenerator") --needed for lotw - do not remove.
local AsyncPirateGenerator = include("asyncpirategenerator")
local SpawnUtility = include("spawnutility")
local ShipUtility = include("shiputility")
local TorpedoGenerator = include("torpedogenerator")
local Xsotan = include ("story/xsotan")
local Balancing = include ("galaxy")
--ITR scripts
local EnvironmentalEffectUT = include("dlc/rift/sector/effects/environmentaleffectutility")
local EnvironmentalEffectType = include("dlc/rift/sector/effects/environmentaleffecttype")

--/run Entity():addScript("lib/esccdbg.lua")
local window

local numButtons = 0
function ButtonRect(w, h, p, wh)

    local width = w or 280
    local height = h or 35
    local padding = p or 10
    local wh = wh or window.size.y - 60

    local space = math.floor(wh / (height + padding))

    local row = math.floor(numButtons % space)
    local col = math.floor(numButtons / space)

    local lower = vec2((width + padding) * col, (height + padding) * row)
    local upper = lower + vec2(width, height)

    numButtons = numButtons + 1

    return Rect(lower, upper)
end

local function MakeButton(tab, rect, caption, func)
    local button = tab:createButton(rect, caption, func)
    button.uppercase = false
    return button
end

function interactionPossible(player)
    return true, ""
end

function initialize()
end

function initUI()
    --Up to TAB10
    local res = getResolution()
    local size = vec2(1200, 650)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "ESCC Debug"
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "~esccdev")

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    local topLevelTab = tabbedWindow:createTab("Entity", "data/textures/icons/ship.png", "ESCC General")
    local window = topLevelTab:createTabbedWindow(Rect(topLevelTab.rect.size))
    local shipsTab = window:createTab("", "data/textures/icons/ship.png", "ESCC Ships")
    numButtons = 0
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Jammer", "onSpawnJammerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Stinger", "onSpawnStingerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Scorcher", "onSpawnScorcherButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Bomber", "onSpawnBomberButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Sinner", "onSpawnSinnerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Prowler", "onSpawnProwlerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Pillager", "onSpawnPillagerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Devastator", "onSpawnDevastatorButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Pirate Flagship", "onSpawnPirateFlagshipButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Slammer", "onSpawnTorpedoSlammerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Deadshot", "onSpawnDeadshotButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "SeigeGun", "onSpawnSeigeGunButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Absolute PD", "onSpawnAbsolutePDButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Curtain", "onSpawnIronCurtainButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Eternal", "onSpawnEternalButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Overdrive", "onSpawnOverdriveButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Adaptive", "onSpawnAdaptiveButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Afterburn", "onSpawnAfterburnerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Avenger", "onSpawnAvengerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Meathook", "onSpawnMeathookButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Booster", "onSpawnBoosterButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Booster Healer", "onSpawnBoosterHealerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Phaser", "onSpawnPhaserButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Frenzied", "onSpawnFrenziedButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Secondaries", "onSpawnSecondariesButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Thorns", "onSpawnThornsButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Linker", "onSpawnLinkerButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Nemean", "onSpawnNemeanButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Rampage", "onSpawnRampageButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Distributor", "onSpawnDistributorButtonPressed")
    MakeButton(shipsTab, ButtonRect(nil, nil, nil, shipsTab.height), "Thunderstrike", "onSpawnThunderstrikeButtonPressed")

    local xsotanTab = window:createTab("Entity", "data/textures/icons/xsotan.png", "ESCC Xsotan")
    numButtons = 0
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Infestor", "onSpawnXsotanInfestorButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Oppressor", "onSpawnXsotanOppressorButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Sunmaker", "onSpawnXsotanSunmakerButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Ballistyx", "onSpawnXsotanBallistyxButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Longinus", "onSpawnXsotanLonginusButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Pulverizer", "onSpawnXsotanPulverizerButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Warlock", "onSpawnXsotanWarlockButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Tributary", "onSpawnXsotanTributaryButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Levinstriker", "onSpawnXsotanLevinstrikerButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Parthenope", "onSpawnXsotanParthenopeButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Hierophant", "onSpawnXsotanHierophantButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Caduceus", "onSpawnXsotanCaduceusButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Dreadnought", "onSpawnXsotanDreadnoughtButtonPressed")
    MakeButton(xsotanTab, ButtonRect(nil, nil, nil, xsotanTab.height), "Xsotan Schismatic", "onSpawnXsotanSchismaticButtonPressed")

    local bossTab = window:createTab("Entity", "data/textures/icons/edge-crack.png", "ESCC Bosses")
    numButtons = 0
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner", "onSpawnExecutionerButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner II", "onSpawnExecutioner2ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner III", "onSpawnExecutioner3ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner IV", "onSpawnExecutioner4ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner V", "onSpawnExecutioner5ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner VI", "onSpawnExecutioner6ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner VII", "onSpawnExecutioner7ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Executioner VIII", "onSpawnExecutioner8ButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Spawn Katana BOSS", "onKatanaBossButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Spawn Phoenix BOSS", "onPhoenixBossButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Spawn Hunter BOSS", "onHunterBossButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Spawn Hellcat BOSS", "onHellcatBossButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Spawn Goliath BOSS", "onGoliathBossButtonPressed")
    MakeButton(bossTab, ButtonRect(nil, nil, nil, bossTab.height), "Spawn Shield BOSS", "onShieldBossButtonPressed")

    local aiTestTab = window:createTab("Entity", "data/textures/icons/computation-mainframe.png", "AI Test")
    numButtons = 0
    MakeButton(aiTestTab, ButtonRect(nil, nil, nil, aiTestTab.height), "Fly to me", "onFlyToMeButtonPressed")
    MakeButton(aiTestTab, ButtonRect(nil, nil, nil, aiTestTab.height), "Shoot me", "onShootMeButtonPressed")
    MakeButton(aiTestTab, ButtonRect(nil, nil, nil, aiTestTab.height), "Use Pursuit", "onAttachTindalosButtonPressed")

    local dataDumpTab = window:createTab("Entity", "data/textures/icons/solar-cell.png", "Data Dumps")
    numButtons = 0
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Turret Data Dump", "onTurretDataDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Upgrade Data Dump", "onUpgradeDataDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Trait Data Dump", "onTraitDataDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Station List Dump", "onStationListDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Server Value Dump", "onServerValueDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Player Value Dump", "onPlayerValueDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Material Value Dump", "onMaterialDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Sector DPS Dump", "onSectorDPSDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Reward Data Dump", "onSectorRewardDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Material Cost Factor Dump", "onMaterialCostFactorDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Invincibility Data Dump", "onInvincibilityDataDumpButtonPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Weapon Type Data Dump", "onWeaponTypeDataDumpPressed")
    MakeButton(dataDumpTab, ButtonRect(nil, nil, nil, dataDumpTab.height), "Material Probabilities 0-500", "onMatlProbabilities0550Pressed")

    local otherTab = window:createTab("Entity", "data/textures/icons/papers.png", "Other")
    numButtons = 0
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Run Scratch Script", "onRunScratchScriptButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Load Torpedoes", "onLoadTorpedoesButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Zero Resources", "onZeroOutResourcesButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Test Pariah Spawn", "onTestPariahSpawnButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Repair All Ships", "onRepairAllShipsButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Run SectorDPS", "onRunSectorDPSPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Get Position", "onGetPositionPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Center Position", "onCenterPositionPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Get Distance", "onDistanceButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Test OOS Attack", "onTestOOSButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Reset XWG", "onLLTEResetXWGButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Add Acid Fog Intensity 1", "onAcidFogIntensity1Pressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Add Acid Fog Intensity 2", "onAcidFogIntensity2Pressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Add Acid Fog Intensity 3", "onAcidFogIntensity3Pressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Add Radiation Intensity 1", "onRadiationIntensity1Pressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Remove All Weather", "onRemoveWeatherPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Run ESCC MinVec Test", "onRunESCCMinVecTestButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Get Distance To Center", "onRunGetDistToCenterButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Get Own Translation", "onGetTranslationButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Clear All Wreckages", "onClearAllWrecksButtonPressed")
    MakeButton(otherTab, ButtonRect(nil, nil, nil, otherTab.height), "Check Sector Info", "onCheckSectorSpecificsButtonPressed")
    
    local weaponTab = tabbedWindow:createTab("Entity", "data/textures/icons/gunner.png", "ESCC Turrets")
    numButtons = 0
    local _TurretNames = {
        "Tesla",
        "Salvage",
        "Launcher",
        "Repair",
        "Railgun",
        "Pulse",
        "Plasma",
        "Mining",
        "Lightning",
        "Laser",
        "Force",
        "Chaingun",
        "Cannon",
        "Bolter"
    }
    for _, _Name in pairs(_TurretNames) do
        local _Button = MakeButton(weaponTab, ButtonRect(nil, nil, nil, weaponTab.height), "Build " .. tostring(_Name), "onBuildATurretButtonPressed")
        _Button.tooltip = _Name
    end

    --Build ESCC campaign mod table.
    local modTable = {}
    local bulletinTable = {}

    modTable = getDebugModules(modTable)
    bulletinTable = getBulletinMissionModules(bulletinTable)

    if #modTable > 0 or #bulletinTable > 0 then

        local topLevelTab = tabbedWindow:createTab("Entity", "data/textures/icons/wormhole.png", "ESCC Campaigns")
        local window = topLevelTab:createTabbedWindow(Rect(topLevelTab.rect.size))

        if #bulletinTable > 0 then
            local missionTab = window:createTab("", "data/textures/icons/bars.png", "Bulletin Missions")
            numButtons = 0

            for idx, mBulletin in pairs(bulletinTable) do
                local _Button = MakeButton(missionTab, ButtonRect(nil, nil, nil, missionTab.height), mBulletin._Caption, "onAddBulletinButtonPressed")
                _Button.tooltip = mBulletin._Tooltip
            end
        end

        if #modTable > 0 then
            for idx, dbgmodule in pairs(modTable) do
                dbgmodule(window)
            end
        end
    end
end

--How to add a tab:
--1 - add esccdbg.lua to your mod folder
--2 - add a local replacement of getDebugModule - i.e. local lotw_getDebugModules = getDebugModules
--3 - define a debug function - local dbgmodule = function(window) - you can call it something appropriate for your mod, like lotw_dbgmodule
--4 - add buttons inside of the dbg function. Make sure you are adding them to the tab. So if your tab is tab12, make sure to do MakeButton(tab12, etc.
--5 - table.insert the debug function building the tab into modTable
--6 - define appropriate functions inside esccdbg later in the file
--7 - return the defined local replacement (so in the example in step 2, return lotw_getDebugModules(modTable))
--8 - this will chain call the function for all mods and add a campaign tab for each
--9 - !!!MAKE SURE YOU DO NOT PUT function getDebugModules(modTable) ELSEWHERE IN THE FILE! THIS WILL CAUSE THE WHOLE THING TO STOP WORKING!!!
--[[Example:

local lotw_getDebugModules = getDebugModules
function getDebugModules(modTable)
    local dbgmodule = function(window)
        numButtons = 0
        local tab11 = window:createTab("", "data/textures/icons/silicium.png", "Lord of the Wastes")

        MakeButton(tab11, ButtonRect(nil, nil, nil, tab11.height), "Mission 1", "onLOTWMission1ButtonPressed")
        --cut some for brevity
    end

    table.insert(modTable, dbgmodule)

    return lotw_getDebugModules(modTable)
end

--Other functions are defined below:
function onLOTWMission1Buttonpressed()
    --Function stuff goes here
end

]]
function getDebugModules(modTable)
    return modTable
end

--How to add a bulletin mission module:
-- - add esccdbg.lua to your mod folder
-- - add a local replacement of getBulletinMissionModules - i.e. AmbushRaiders_getBulletinMissionModules = getBulletinMissionModules
-- - table.insert a new table into modTable - structure it like this: { _Caption = "Ambush Pirate Raiders", _Tooltip = "ambushraiders" }
-- - return the defined local replacement (in the above example, return AmbushRaiders_getBulletinMissionModules(modTable))
-- - This will chain call the function for all mods and add a bulletin mission button for each
--[[Example:

local AmbushRaiders_getBulletinMissionModules = getBulletinMissionModules
function getBulletinMissionModules(modTable)
    table.insert(modTable, { _Caption = "Ambush Pirate Raiders", _Tooltip = "ambushraiders" })

    return AmbushRaiders_getBulletinMissionModules(modTable)
end

]]
function getBulletinMissionModules(modTable)
    return modTable
end

--region #OTHER

local function getPositionInFrontOfPlayer()
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 500

    return MatrixLookUpPosition(-dir, up, pos)
end

--Misc Callbacks
function onPiratesGenerated(generated)
    local _Debug = 0
    if _Debug == 1 then
        for _, _g in pairs(generated) do
            local _gShield = Shield(_g)
            if _gShield then
                print("Max dura factor of Shield is " .. tostring(_gShield.maxDurabilityFactor))
            end
            local _gDurability = Durability(_g)
            if _gDurability then
                print("Max dura factor of Durability is " .. tostring(_gDurability.maxDurabilityFactor))
            end
        end
    end
    SpawnUtility.addEnemyBuffs(generated)
end

function onMegaLaserPiratesGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do
        ShipUtility.addMegaLasers(_S, 10)
    end
end

function onMegaSeekerPiratesGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do
        ShipUtility.addMegaSeekers(_S, 10)
    end
end

function onSlammerGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do
        local _TorpSlammerValues = {}
        _TorpSlammerValues._ForwardAdjustFactor = 2.5
        _S:addScript("torpedoslammer.lua", _TorpSlammerValues)
        _S:addScript("icon.lua", "data/textures/icons/pixel/torpedoboatex.png")
    end
end

function onDeadshotGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do
        local _TitleArgs = _S:getTitleArguments()
        _S:setTitle("${toughness}${lasername}${title}", {toughness = _TitleArgs.toughness, title = _TitleArgs.title, lasername = "Deadshot "})

        _S:addScript("lasersniper.lua")
        _S:addScript("icon.lua", "data/textures/icons/pixel/laserboat.png")
    end
end

function onSpawnSeigeGunGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do

        local _sgargs = {}
        _sgargs._CodesCracked = true
        _sgargs._Velocity = 400
        _sgargs._ShotCycle = 30
        _sgargs._ShotCycleSupply = 0
        _sgargs._ShotCycleTimer = 30
        _sgargs._UseSupply = false
        _sgargs._FragileShots = false
        _sgargs._TargetPriority = 1 --Target a random enemy.
        _sgargs._UseEntityDamageMult = true --Use the entity damage multiplier. Fun with the overdrive / avenger scripts :)
        _sgargs._BaseDamagePerShot = 100000 --Enough to notice but not enough to really heck the player up

        _S:addScript("stationsiegegun.lua", _sgargs)
    end
end

function onAbsolutePDGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do
        _S:addScript("absolutepointdefense.lua")
    end
end

function onIronCurtainGenerated(_Generated)
    onPiratesGenerated(_Generated)
    for _, _S in pairs(_Generated) do
        _S:addScript("ironcurtain.lua")
    end
end

function onEternalEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding eternal script to enemy")
    for _, _S in pairs(_Generated) do
        _S:addScript("eternal.lua")
    end
end

function onOverdriveEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding overdrive script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("overdrive.lua")
    end
end

function onAdaptiveEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding adaptive defense script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("adaptivedefense.lua")
    end
end

function onAfterburnerEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding afterburner script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("afterburn.lua")
    end
end

function onAvengerEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding avenger script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("avenger.lua")
    end
end

function onMeathookEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding meathook script to enemy. Mmmmm... meaty...")
    for _, _S in pairs(_Generated) do
        _S:addScript("meathook.lua")
    end
end

function onBoosterEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding booster script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("allybooster.lua")
    end
end

function onBoosterHealerEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding booster + args script to enemy.")
    for _, _S in pairs(_Generated) do
        local boosterValues = {
            _HealWhenBoosting = true, 
            _HealPctWhenBoosting = 33, 
            _MaxBoostCharges = 5
            }
        _S:addScript("allybooster.lua", boosterValues)
    end
end

function onPhaserEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding phaser script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("phasemode.lua")
    end   
end

function onFrenziedEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding frenzy script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("frenzy.lua")
    end
end

function onSecondariedEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding secondary weapon script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("secondaryweapons.lua")
    end
end

function onThornsEnemyGenerated(_Generated)
    onPiratesGenerated(_Generated)
    print("adding thorns script to enemy.")
    for _, _S in pairs(_Generated) do
        _S:addScript("thorns.lua")        
    end
end

function onLinkerEnemyGenerated(generated)
    onPiratesGenerated(generated)
    print("adding linker script to enemy")
    for _, ship in pairs(generated) do
        ship:addScript("escclinker.lua")
    end
end

function onNemeanEnemyGenerated(generated)
    onPiratesGenerated(generated)
    print("adding ironcurtain / phasemode to enemy.")
    for _, ship in pairs(generated) do
        ship:addScriptOnce("phasemode.lua")
        ship:addScriptOnce("ironcurtain.lua")
    end
end

function onRampageEnemyGenerated(generated)
    onPiratesGenerated(generated)
    print("adding rampage to enemy.")
    for _, ship in pairs(generated) do
        ship:addScriptOnce("rampage.lua")
    end
end

function onDistributorEnemyGenerated(generated)
    onPiratesGenerated(generated)
    print("adding distributor to enemy.")
    for _, ship in pairs(generated) do
        ship:addScriptOnce("distributor.lua")
    end
end

function onThunderstrikeEnemyGenerated(generated)
    onPiratesGenerated(generated)
    print("adding thunderstrike to enemy")
    for _, ship in pairs(generated) do
        ship:addScriptOnce("thunderstrike.lua")
    end
end

--endregion

--region #SHIPSTAB

function onSpawnJammerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnJammerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledJammer(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnJammerButtonPressed")

function onSpawnStingerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnStingerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledStinger(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnStingerButtonPressed")

function onSpawnScorcherButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnScorcherButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledScorcher(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnScorcherButtonPressed")

function onSpawnBomberButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnBomberButtonPressed")
        return
    end
    
    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledBomber(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnBomberButtonPressed")

function onSpawnSinnerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSinnerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledSinner(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnSinnerButtonPressed")

function onSpawnProwlerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnProwlerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledProwler(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnProwlerButtonPressed")

function onSpawnPillagerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnPillagerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledPillager(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnPillagerButtonPressed")

function onSpawnDevastatorButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDevastatorButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnDevastatorButtonPressed")

function onSpawnPirateFlagshipButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnPirateFlagshipButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledFlagship(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnPirateFlagshipButtonPressed")

--The following functions spawn Devastators with some special test scripts.
function onSpawnTorpedoSlammerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnTorpedoSlammerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onSlammerGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnTorpedoSlammerButtonPressed")

function onSpawnDeadshotButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDeadshotButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onDeadshotGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnDeadshotButtonPressed")

function onSpawnSeigeGunButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSeigeGunButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onSpawnSeigeGunGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnSeigeGunButtonPressed")

function onSpawnAbsolutePDButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnAbsolutePDButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onAbsolutePDGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnAbsolutePDButtonPressed")

function onSpawnIronCurtainButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnIronCurtainButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onIronCurtainGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnIronCurtainButtonPressed")

function onSpawnEternalButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnEternalButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onEternalEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnEternalButtonPressed")

function onSpawnOverdriveButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnOverdriveButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onOverdriveEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnOverdriveButtonPressed")

function onSpawnAdaptiveButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnAdaptiveButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onAdaptiveEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnAdaptiveButtonPressed")

function onSpawnAfterburnerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnAfterburnerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onAfterburnerEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnAfterburnerButtonPressed")

function onSpawnAvengerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnAvengerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onAvengerEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnAvengerButtonPressed")

function onSpawnMeathookButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnMeathookButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onMeathookEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnMeathookButtonPressed")

function onSpawnBoosterButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnBoosterButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onBoosterEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()    
end
callable(nil, "onSpawnBoosterButtonPressed")

function onSpawnBoosterHealerButtonPressed()
    if onClient() then 
        invokeServerFunction("onSpawnBoosterHealerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onBoosterHealerEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()    
end
callable(nil, "onSpawnBoosterHealerButtonPressed")

function onSpawnPhaserButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnPhaserButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onPhaserEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()    
end
callable(nil, "onSpawnPhaserButtonPressed")

function onSpawnFrenziedButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFrenziedButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onFrenziedEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()    
end
callable(nil, "onSpawnFrenziedButtonPressed")

function onSpawnSecondariesButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSecondariesButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onSecondariedEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()   
end
callable(nil, "onSpawnSecondariesButtonPressed")

function onSpawnThornsButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnThornsButtonPressed")
        return
    end
    
    local generator = AsyncPirateGenerator(nil, onThornsEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnThornsButtonPressed")

function onSpawnLinkerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnLinkerButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onLinkerEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnLinkerButtonPressed")

function onSpawnNemeanButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnNemeanButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onNemeanEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnNemeanButtonPressed")

function onSpawnRampageButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnRampageButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onRampageEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnRampageButtonPressed")

function onSpawnDistributorButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDistributorButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onDistributorEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnDistributorButtonPressed")

function onSpawnThunderstrikeButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnThunderstrikeButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator(nil, onThunderstrikeEnemyGenerated)
    generator:startBatch()

    generator:createScaledDevastator(getPositionInFrontOfPlayer())

    generator:endBatch()
end
callable(nil, "onSpawnThunderstrikeButtonPressed")

--endregion

--region #XSOTANTAB

function onSpawnXsotanInfestorButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanInfestorButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createInfestor(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanInfestorButtonPressed")

function onSpawnXsotanOppressorButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanOppressorButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createOppressor(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanOppressorButtonPressed")

function onSpawnXsotanSunmakerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanSunmakerButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createSunmaker(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanSunmakerButtonPressed")

function onSpawnXsotanBallistyxButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanBallistyxButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createBallistyx(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanBallistyxButtonPressed")

function onSpawnXsotanLonginusButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanLonginusButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createLonginus(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanLonginusButtonPressed")

function onSpawnXsotanPulverizerButtonPressed()
    if onClient() then 
        invokeServerFunction("onSpawnXsotanPulverizerButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createPulverizer(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanPulverizerButtonPressed")

function onSpawnXsotanWarlockButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanWarlockButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createWarlock(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanWarlockButtonPressed")

function onSpawnXsotanTributaryButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanTributaryButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createTributary(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanTributaryButtonPressed")

function onSpawnXsotanLevinstrikerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanLevinstrikerButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createLevinstriker(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanLevinstrikerButtonPressed")

function onSpawnXsotanParthenopeButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanParthenopeButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createParthenope(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanParthenopeButtonPressed")

function onSpawnXsotanHierophantButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanHierophantButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createHierophant(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanHierophantButtonPressed")

function onSpawnXsotanCaduceusButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanCaduceusButtonPressed")
        return
    end

    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createCaduceus(MatrixLookUpPosition(-dir, up, pos))
end
callable(nil, "onSpawnXsotanCaduceusButtonPressed")

function onSpawnXsotanDreadnoughtButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanDreadnoughtButtonPressed")
        return
    end

    local dangerFactor = random():getInt(1, 10)
    print("Creating danger " .. tostring(dangerFactor) .. " Dreadnought")

    Xsotan.createDreadnought(nil, dangerFactor)
end
callable(nil, "onSpawnXsotanDreadnoughtButtonPressed")

function onSpawnXsotanSchismaticButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanSchismaticButtonPressed")
        return
    end

    print("Creating Schismatic")
    Xsotan.createSchismatic(nil, nil)
end
callable(nil, "onSpawnXsotanSchismaticButtonPressed")

--endregion

--region #BOSSTAB

function tab3SpawnExecutioner(_Power)
    local generator = AsyncPirateGenerator(nil, onPiratesGenerated)
    generator:startBatch()

    generator:createScaledExecutioner(getPositionInFrontOfPlayer(), _Power)

    generator:endBatch()
end

function onSpawnExecutionerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutionerButtonPressed")
        return
    end

    tab3SpawnExecutioner(0)
end
callable(nil, "onSpawnExecutionerButtonPressed")

function onSpawnExecutioner2ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner2ButtonPressed")
        return
    end

    tab3SpawnExecutioner(500)
end
callable(nil, "onSpawnExecutioner2ButtonPressed")

function onSpawnExecutioner3ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner3ButtonPressed")
        return
    end

    tab3SpawnExecutioner(1000)
end
callable(nil, "onSpawnExecutioner3ButtonPressed")

function onSpawnExecutioner4ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner4ButtonPressed")
        return
    end

    tab3SpawnExecutioner(10000)
end
callable(nil, "onSpawnExecutioner4ButtonPressed")

function onSpawnExecutioner5ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner5ButtonPressed")
        return
    end

    tab3SpawnExecutioner(50000)
end
callable(nil, "onSpawnExecutioner5ButtonPressed")

function onSpawnExecutioner6ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner6ButtonPressed")
        return
    end

    tab3SpawnExecutioner(100000)
end
callable(nil, "onSpawnExecutioner6ButtonPressed")

function onSpawnExecutioner7ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner7ButtonPressed")
        return
    end

    tab3SpawnExecutioner(1000000)
end
callable(nil, "onSpawnExecutioner7ButtonPressed")

function onSpawnExecutioner8ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnExecutioner8ButtonPressed")
        return
    end

    tab3SpawnExecutioner(10000000)
end
callable(nil, "onSpawnExecutioner8ButtonPressed")

function spawnITBoss(_BossType)
    local generator = AsyncPirateGenerator(nil, nil)
    local ESCCBoss = include("esccbossutil")
    ESCCBoss.spawnESCCBoss(generator:getPirateFaction(), _BossType)
end

function onKatanaBossButtonPressed()
    if onClient() then
        invokeServerFunction("onKatanaBossButtonPressed")
        return
    end

    spawnITBoss(1)
end
callable(nil, "onKatanaBossButtonPressed")

function onPhoenixBossButtonPressed()
    if onClient() then
        invokeServerFunction("onPhoenixBossButtonPressed")
        return
    end

    spawnITBoss(6)
end
callable(nil, "onPhoenixBossButtonPressed")

function onHunterBossButtonPressed()
    if onClient() then
        invokeServerFunction("onHunterBossButtonPressed")
        return
    end

    spawnITBoss(4)
end
callable(nil, "onHunterBossButtonPressed")

function onHellcatBossButtonPressed()
    if onClient() then
        invokeServerFunction("onHellcatBossButtonPressed")
        return
    end

    spawnITBoss(3)
end
callable(nil, "onHellcatBossButtonPressed")

function onGoliathBossButtonPressed()
    if onClient() then
        invokeServerFunction("onGoliathBossButtonPressed")
        return
    end

    spawnITBoss(2)
end
callable(nil, "onGoliathBossButtonPressed")

function onShieldBossButtonPressed()
    if onClient() then
        invokeServerFunction("onShieldBossButtonPressed")
        return
    end

    spawnITBoss(5)
end
callable(nil, "onShieldBossButtonPressed")

--endregion

--region #AITESTTAB

function onFlyToMeButtonPressed()
    if onClient() then
        invokeServerFunction("onFlyToMeButtonPressed")
        return
    end

    local craftidx = Player(callingPlayer).craftIndex
    local playerShip = Entity(craftidx)

    --Get the enemy ship components we need.
    local eCtlUnit = ControlUnit(Entity())
    local eAIUnit = ShipAI(Entity())
    local eEngUnit = Engine(Entity())

    --Set existing AI to idle.
    eAIUnit:setIdle()
    --Command it to fly to the player's position at maximum speed.
    print(
        "sending fly order... flying to " ..
            tostring(playerShip.translationf) .. " ... flying from " .. tostring(Entity().translationf)
    )
    eAIUnit:setFlyLinear(playerShip.translationf, 100, false)
    --eCtlUnit:flyToLocation(playerShip.translationf, eEngUnit.maxVelocity)
    local ctlActions = eCtlUnit:getAllControlActions()
end
callable(nil, "onFlyToMeButtonPressed")

function onShootMeButtonPressed()
    if onClient() then
        invokeServerFunction("onShootMeButtonPressed")
        return
    end

    local craftidx = Player(callingPlayer).craftIndex
    local playerShip = Entity(craftidx)

    --Get the enemy ship components we need.
    local eCtlUnit = ControlUnit(Entity())
    local eAIUnit = ShipAI(Entity())

    print("enabling shooting")
    eAIUnit:setPassiveShooting(true)
end
callable(nil, "onShootMeButtonPressed")

function onAttachTindalosButtonPressed()
    if onClient() then
        invokeServerFunction("onAttachTindalosButtonPressed")
        return
    end

    print("adding custom Tindalos AI to entity.")
    Entity():addScript("data/scripts/entity/ai/custom/pursuitai.lua")
end
callable(nil, "onAttachTindalosButtonPressed")

--endregion

--region #DATADUMPTAB

function onTurretDataDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onTurretDataDumpButtonPressed")
        return
    end

    local _Ship = Entity()
    local _Faction = Faction(_Ship.factionIndex)

    local _TurretTemplates = _Faction:getInventory():getItemsByType(InventoryItemType.TurretTemplate)
    local _Items = {}
    for _, _Itm in pairs(_TurretTemplates) do
        local _Turret = _Itm.item
        table.insert(_Items, _Turret)
    end

    for _, _TurretItem in pairs(_Items) do
        print("=== NEW TURRET ===")
        print("name : " .. tostring(_TurretItem.name))
        print("icon : " .. tostring(_TurretItem.weaponIcon))
        print("weapon name : " .. tostring(_TurretItem.weaponName))
        print("avg tech : " .. tostring(_TurretItem.averageTech))
        print("max tech : " .. tostring(_TurretItem.maxTech))
        print("material : " .. tostring(_TurretItem.material))
        print("damage : " .. tostring(_TurretItem.damage))
        print("damage type : " .. tostring(_TurretItem.damageType))
        print("omicron : " .. tostring(_TurretItem.dps))
        print("rarity : " .. tostring(_TurretItem.rarity))
    end
end
callable(nil, "onTurretDataDumpButtonPressed")

function onUpgradeDataDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onUpgradeDataDumpButtonPressed")
        return
    end

    local _Ship = Entity()
    local _Faction = Faction(_Ship.factionIndex)

    local _UpgradeTemplates = _Faction:getInventory():getItemsByType(InventoryItemType.SystemUpgrade)
    local _Items = {}
    for _, _Itm in pairs(_UpgradeTemplates) do
        local _Upgrade = _Itm.item
        table.insert(_Items, _Upgrade)
    end

    for _, _UpgradeItem in pairs(_Items) do
        print("=== NEW UPGRADE ===")
        print("script : " .. tostring(_UpgradeItem.script))
    end
end
callable(nil, "onUpgradeDataDumpButtonPressed")

function onTraitDataDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onTraitDataDumpButtonPressed")
        return
    end

    local _Ship = Entity()
    local _Faction = Faction(_Ship.factionIndex)

    local _Traits = _Faction:getTraits()

    for _K, _T in pairs(_Traits) do
        print("name : " .. tostring(_K) .. " || value : " .. tostring(_T))
    end
end
callable(nil, "onTraitDataDumpButtonPressed")

function onStationListDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onStationListDumpButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _PlayerShipNames = {_Player:getShipNames()}
    print("This isn't that useful unfortunately since it is not possible to load entities remotely.")

    for _, _S in pairs(_PlayerShipNames) do
        local _ShipType = _Player:getShipType(_S)
        if _ShipType == EntityType.Station then
            --Yeah apparently the only way to do this is load the sector, then grab the sector and load the station out of it.
            local _X, _Y = _Player:getShipPosition(_S)
            print(tostring(_S) .. " is a station located at (" .. tostring(_X) .. ":" .. tostring(_Y) .. ")")
        end
    end
end
callable(nil, "onStationListDumpButtonPressed")

function onServerValueDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onServerValueDumpButtonPressed")
        return
    end

    local _Server = Server()
    local _ServerValues = _Server:getValues()
    for _K, _V in pairs(_ServerValues) do
        print("Server value name: " .. tostring(_K) .. " is: " .. tostring(_V))
    end
end
callable(nil, "onServerValueDumpButtonPressed")

function onPlayerValueDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onPlayerValueDumpButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _PlayerValues = _Player:getValues()
    for _K, _V in pairs(_PlayerValues) do
        print("Player value name: " .. tostring(_K) .. " is: " .. tostring(_V))
    end
end
callable(nil, "onPlayerValueDumpButtonPressed")

function onMaterialDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onMaterialDumpButtonPressed")
        return
    end

    local _MatlTable = Balancing_GetTechnologyMaterialProbability(Sector():getCoordinates())
    for _k, _v in pairs(_MatlTable) do
        print("key : " .. tostring(_k) .. " value : " .. tostring(_v))
    end
end
callable(nil, "onMaterialDumpButtonPressed")

function onSectorDPSDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onSectorDPSDumpButtonPressed")
        return
    end

    for idx = 499, 0, -1 do
        local _dps = Balancing_GetSectorWeaponDPS(0, idx) --Just do 0, idx
        print("distance : " .. tostring(idx) .. " dps : " .. tostring(_dps))
    end
end
callable(nil, "onSectorDPSDumpButtonPressed")

function onSectorRewardDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onSectorRewardDumpButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    print("Sector richness factor: " .. tostring(Balancing.GetSectorRichnessFactor(x, y)))
    print("Sector reward factor: " .. tostring(Balancing.GetSectorRewardFactor(x, y)))
end
callable(nil, "onSectorRewardDumpButtonPressed")

function onMaterialCostFactorDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onMaterialCostFactorDumpButtonPressed")
        return
    end

    for matlIdx = 1, 7 do
        local matl = Material(matlIdx - 1)

        local matlName = matl.name
        local matlCostFactor = matl.costFactor
        local matlTypicalVal = matl.costFactor * 10

        print("Material name: " .. tostring(matlName) .. " Cost factor: " .. tostring(matlCostFactor) .. " Typical value: " .. tostring(matlTypicalVal))
    end
end
callable(nil, "onMaterialCostFactorDumpButtonPressed")

function onInvincibilityDataDumpButtonPressed()
    if onClient() then
        invokeServerFunction("onInvincibilityDataDumpButtonPressed")
        return
    end

    local _entity = Entity()
    local _durability = Durability(_entity)
    print("Entity invincible: " .. tostring(_entity.invincible) .. " Entity invincibility: " .. tostring(_durability.invincibility))
end
callable(nil, "onInvincibilityDataDumpButtonPressed")

function onWeaponTypeDataDumpPressed()
    if onClient() then
        invokeServerFunction("onWeaponTypeDataDumpPressed")
        return
    end

    print("k/v for WeaponType")
    for k, v in pairs(WeaponType) do
        print("k : " .. tostring(k) .. " v : " .. tostring(v))
    end
    print("k/v for all armed types")
    for k, v in pairs(WeaponTypes.armedTypes) do
        print("k : " .. tostring(k) .. " v : " .. tostring(v))
    end
    print("k/v for all unarmed types")
    for k, v in pairs(WeaponTypes.unarmedTypes) do
        print("k : " .. tostring(k) .. " v : " .. tostring(v))
    end
    print("k/v for all defensive types")
    for k, v in pairs(WeaponTypes.defensiveTypes) do
        print("k : " .. tostring(k) .. " v : " .. tostring(v))
    end
end
callable(nil, "onWeaponTypeDataDumpPressed")

function onMatlProbabilities0550Pressed()
    if onClient() then
        invokeServerFunction("onMatlProbabilities0550Pressed")
        return
    end

    for x = 0, 500 do
        local matls = Balancing_GetMaterialProbability(x, 0)

        local str = "dist is " .. tostring(x) .. " / "

        for key, value in pairs(matls) do
            local matl = Material(key)

            str = str .. " matl name: " .. matl.name .. " probability: " .. tostring(value) .. " / "
        end

        print(str)
    end

end
callable(nil, "onMatlProbabilities0550Pressed")

--endregion

--region #OTHERTAB

function onRunScratchScriptButtonPressed()
    if onClient() then
        --Put client script here.

        invokeServerFunction("onRunScratchScriptButtonPressed")
        return
    end
    --Put server script here.

end
callable(nil, "onRunScratchScriptButtonPressed")

function onLoadTorpedoesButtonPressed()
    if onClient() then
        invokeServerFunction("onLoadTorpedoesButtonPressed")
        return
    end

    local _TorpGenerator = TorpedoGenerator()
    local _Player = Player(callingPlayer)
    local _Craft = _Player.craft
    local _Launcher = TorpedoLauncher(_Craft.index)
    local _Shafts = {_Launcher:getShafts()}
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()

    local _Torpedo = _TorpGenerator:generate(_X, _Y)

    print("Adding torpedos directly to all " .. tostring(#_Shafts) .. " launchers.")

    local _Shafts = {_Launcher:getShafts()}

    for _, _Shaft in pairs(_Shafts) do
        print(
            "K : " ..
                tostring(_) ..
                    " - V : " .. tostring(_Shaft) .. " - Frre Slots : " .. tostring(_Launcher:getFreeSlots(_Shaft))
        )
    end

    print("numShafts : " .. tostring(_Launcher.numShafts) .. " - maxShafts : " .. tostring(_Launcher.maxShafts))

    for _, _Shaft in pairs(_Shafts) do
        while _Launcher:getFreeSlots(_Shaft) > 0 and _Launcher:getFreeSlots(_Shaft) ~= 15 do
            print("Free slots in shaft " .. tostring(_) .. " : " .. tostring(_Launcher:getFreeSlots(_)))
            _Launcher:addTorpedo(_Torpedo, _Shaft)
        end
    end

    print("Adding torpeodes to storage.")

    while _Launcher.freeStorage > _Torpedo.size do
        print("Launcher storage remaining : " .. tostring(_Launcher.freeStorage))
        _Launcher:addTorpedo(_Torpedo)
    end
end
callable(nil, "onLoadTorpedoesButtonPressed")

function onZeroOutResourcesButtonPressed()
    if onClient() then
        invokeServerFunction("onZeroOutResourcesButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local money = 0
    _Player.money = money
    _Player:setResources(money, money, money, money, money, money, money, money, money, money, money) -- as Boxelware says, too much, don't care
end
callable(nil, "onZeroOutResourcesButtonPressed")

function onTestPariahSpawnButtonPressed()
    if onClient() then
        invokeServerFunction("onTestPariahSpawnButtonPressed")
        return
    end

    local PariahUtil = include("pariahutility")
    PariahUtil.spawnSuperWeapon()
end
callable(nil, "onTestPariahSpawnButtonPressed")

function onRepairAllShipsButtonPressed()
    if onClient() then
        invokeServerFunction("onRepairAllShipsButtonPressed")
        return
    end

    local _Player = Player(callingPlayer)
    local _PlayerEntities = {Sector():getEntitiesByFaction(_Player.index)}
    for _, _Entity in pairs(_PlayerEntities) do
        if _Entity.type == EntityType.Ship then
            local _PerfectShipPlan = _Player:getShipPlan(_Entity.name)
            if _PerfectShipPlan then
                _PerfectShipPlan:resetDurability()
                _Entity:setMalusFactor(1.0, MalusReason.None)
                _Entity:setMovePlan(_PerfectShipPlan)
                _Entity.durability = _Entity.maxDurability
            end
        end
    end
end
callable(nil, "onRepairAllShipsButtonPressed")

function onRunSectorDPSPressed()
    if onClient() then
        invokeServerFunction("onRunSectorDPSPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local _MaxDPS = 0
    local _MinDPS = 0

    for _Attempts = 1, 10000 do
        local _dps, _tech = Balancing_GetSectorWeaponDPS(x, y)

        if _Attempts == 1 or _dps < _MinDPS then
            _MinDPS = _dps
        end

        if _dps > _MaxDPS then
            _MaxDPS = _dps
        end
    end

    print("MAX DPS -- " .. tostring(_MaxDPS) .. " -- MIN DPS -- " .. tostring(_MinDPS))
end
callable(nil, "onRunSectorDPSPressed")

function onGetPositionPressed()
    local _Ship = Player().craft
    print(tostring(_Ship.translationf))
end

function onCenterPositionPressed()
    local _Ship = Player().craft
    _Ship.position = Matrix()
end

function onDistanceButtonPressed()
    local _Ship = Player().craft
    local _Target = _Ship.selectedObject

    print("DISTANCE: " .. tostring(distance(_Ship.translationf, _Target.translationf)))
    print("DISTANCE2: " .. tostring(distance2(_Ship.translationf, _Target.translationf)))
end

function onTestOOSButtonPressed()
    if onClient() then
        invokeServerFunction("onTestOOSButtonPressed")
        return
    end

    print("Testing OOS attack")
    local _Player = Player(callingPlayer)
    _Player:addScriptOnce("events/passiveplayerattackstarter.lua")
end
callable(nil, "onTestOOSButtonPressed")

function onLLTEResetXWGButtonPressed()
    if onClient() then
        invokeServerFunction("onLLTEResetXWGButtonPressed")
        return
    end

    print("Resetting XWG! It will spawn in 1 second.")
    local _Server = Server()
    _Server:setValue("guardian_respawn_time", 1)
    _Server:setValue("xsotan_swarm_active", nil)
    _Server:setValue("xsotan_swarm_success", nil)
    _Server:setValue("xsotan_swarm_time", nil)
    _Server:setValue("xsotan_swarm_duration", nil)
end
callable(nil, "onLLTEResetXWGButtonPressed")

function onAcidFogIntensity1Pressed()
    if onClient() then
        invokeServerFunction("onAcidFogIntensity1Pressed")
        return
    end

    print("Adding acid fog @ 1")
    EnvironmentalEffectUT.addEffect(EnvironmentalEffectType.AcidFog, 1)
end
callable(nil, "onAcidFogIntensity1Pressed")

function onAcidFogIntensity2Pressed()
    if onClient() then
        invokeServerFunction("onAcidFogIntensity2Pressed")
        return
    end

    print("Adding acid fog @ 2")
    EnvironmentalEffectUT.addEffect(EnvironmentalEffectType.AcidFog, 2)
end
callable(nil, "onAcidFogIntensity2Pressed")

function onAcidFogIntensity3Pressed()
    if onClient() then
        invokeServerFunction("onAcidFogIntensity3Pressed")
        return
    end

    print("Adding acid fog @ 3")
    EnvironmentalEffectUT.addEffect(EnvironmentalEffectType.AcidFog, 3)
end
callable(nil, "onAcidFogIntensity3Pressed")

function onRadiationIntensity1Pressed()
    if onClient() then
        invokeServerFunction("onRadiationIntensity1Pressed")
        return
    end

    print("Adding radiation @ 1")
    EnvironmentalEffectUT.addEffect(EnvironmentalEffectType.Radiation, 1)
end
callable(nil, "onRadiationIntensity1Pressed")

function onRemoveWeatherPressed()
    if onClient() then
        invokeServerFunction("onRemoveWeatherPressed")
        return
    end

    print("Removing all weather")
    EnvironmentalEffectUT.removeAllEffects()
end
callable(nil, "onRemoveWeatherPressed")

function onRunESCCMinVecTestButtonPressed()
    if onClient() then
        invokeServerFunction("onRunESCCMinVecTestButtonPressed")
        return
    end

    local ESCCUtil = include("esccutil")
    local _mypos = Entity().translationf

    print("Testing at min dist 2000")
    local _testvec = ESCCUtil.getVectorAtDistance(_mypos, 2000, true)
    print("VECTOR IS " .. tostring(_testvec) .. " DISTANCE FROM _mypos is " .. tostring(distance(_mypos, _testvec)))

    print("Testing at max dist 2000")
    _testvec = ESCCUtil.getVectorAtDistance(_mypos, 2000, false)
    print("VECTOR IS " .. tostring(_testvec) .. " DISTANCE FROM _mypos is " .. tostring(distance(_mypos, _testvec)))
end
callable(nil, "onRunESCCMinVecTestButtonPressed")

function onRunGetDistToCenterButtonPressed()
    _Sector = Sector()
    local x, y = _Sector():getCoordinates()

    local cpos = vec2(x, y)
    print("Distance : " .. tostring(distance(cpos, vec2(0,0))))
end

function onGetTranslationButtonPressed()
    local _entity = Entity()

    print("Translationf is " .. tostring(_entity.translationf))
end

function onClearAllWrecksButtonPressed()
    if onClient() then
        invokeServerFunction("onClearAllWrecksButtonPressed")
        return
    end

    local _sector = Sector()
    local wreckages = { _sector:getEntitiesByType(EntityType.Wreckage)}
    local wreckageCt = #wreckages

    for _, wreck in pairs(wreckages) do
        _sector:deleteEntity(wreck)
    end

    print("Cleared " .. tostring(wreckageCt) .. " wreckages from sector.")
end
callable(nil, "onClearAllWrecksButtonPressed")

function onCheckSectorSpecificsButtonPressed()
    if onClient() then
        invokeServerFunction("onCheckSectorSpecificsButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local SectorSpecifics = include ("sectorspecifics")
    local specs = SectorSpecifics()

    local regular, offgrid, blocked, home, dust, factionIndex, centralArea = specs:determineContent(x, y, Server().seed)

    local FactionsMap = include ("factionsmap")
    local fm = FactionsMap(Server().seed)

    local getFactionValue = fm:getFaction(x, y)

    print("regular : " .. tostring(regular))
    print("offgrid : " .. tostring(offgrid))
    print("blocked : " .. tostring(blocked))
    print("home : " .. tostring(home))
    print ("dust : " .. tostring(dust))
    print("factionIndex : " .. tostring(factionIndex))
    print("centralArea : " .. tostring(centralArea))
    print("getFaction : " .. tostring(getFactionValue))

    --Scratchpad for testing faction expansion missions - no need to enable this.
    --print("PRINTING FORWARD OUTPOST TABLE:")
    --local forwardOutpostTable = getGlobal("forwardOutpost_sectors")
    --if forwardOutpostTable then
    --    for k, v in pairs(forwardOutpostTable) do
    --        for ky, vy in pairs(forwardOutpostTable[k]) do
    --            print("k : " .. tostring(k) .. " v : " .. tostring(v) .. " ky : " .. tostring(ky) .. " vy: " .. tostring(vy))
    --        end
    --    end
    --end
end
callable(nil, "onCheckSectorSpecificsButtonPressed")

--endregion

--region #WEAPONTAB

function getGoodsForTurret(_TurretName)
    local _ExtendedGoodsTable = {}

    _ExtendedGoodsTable["Tesla"] = {
        "Industrial Tesla Coil",
        "Electromagnetic Charge",
        "Energy Inverter",
        "Conductor",
        "Power Unit",
        "Copper",
        "Energy Cell",
        "Targeting System"
    }
    _ExtendedGoodsTable["Salvage"] = {
        "Laser Compressor",
        "Laser Modulator",
        "High Capacity Lens",
        "Conductor",
        "Steel",
        "Targeting System"
    }
    _ExtendedGoodsTable["Launcher"] = {
        "Servo",
        "Rocket",
        "High Pressure Tube",
        "Fuel",
        "Targeting Card",
        "Steel",
        "Wire",
        "Targeting System"
    }
    _ExtendedGoodsTable["Repair"] = {
        "Nanobot",
        "Transformator",
        "Laser Modulator",
        "Conductor",
        "Gold",
        "Steel",
        "Targeting System"
    }
    _ExtendedGoodsTable["Railgun"] = {
        "Servo",
        "Electromagnetic Charge",
        "Electro Magnet",
        "Gauss Rail",
        "High Pressure Tube",
        "Steel",
        "Copper",
        "Targeting System"
    }
    _ExtendedGoodsTable["Pulse"] = {
        "Servo",
        "Steel Tube",
        "Ammunition S",
        "Steel",
        "Copper",
        "Energy Cell",
        "Targeting System"
    }
    _ExtendedGoodsTable["Plasma"] = {
        "Plasma Cell",
        "Energy Tube",
        "Conductor",
        "Energy Container",
        "Power Unit",
        "Steel",
        "Crystal",
        "Targeting System"
    }
    _ExtendedGoodsTable["Mining"] = {
        "Laser Compressor",
        "Laser Modulator",
        "High Capacity Lens",
        "Conductor",
        "Steel",
        "Targeting System"
    }
    _ExtendedGoodsTable["Lightning"] = {
        "Military Tesla Coil",
        "High Capacity Lens",
        "Electromagnetic Charge",
        "Conductor",
        "Power Unit",
        "Copper",
        "Energy Cell",
        "Targeting System"
    }
    _ExtendedGoodsTable["Laser"] = {
        "Laser Head",
        "Laser Compressor",
        "High Capacity Lens",
        "Laser Modulator",
        "Power Unit",
        "Steel",
        "Crystal",
        "Targeting System"
    }
    _ExtendedGoodsTable["Force"] = {
        "Force Generator",
        "Energy Inverter",
        "Energy Tube",
        "Conductor",
        "Steel",
        "Zinc",
        "Targeting System"
    }
    _ExtendedGoodsTable["Chaingun"] = {
        "Servo",
        "Steel Tube",
        "Ammunition S",
        "Steel",
        "Aluminum",
        "Lead",
        "Targeting System"
    }
    _ExtendedGoodsTable["Cannon"] = {
        "Servo",
        "Warhead",
        "High Pressure Tube",
        "Explosive Charge",
        "Steel",
        "Wire",
        "Targeting System"
    }
    _ExtendedGoodsTable["Bolter"] = {
        "Servo",
        "High Pressure Tube",
        "Ammunition M",
        "Explosive Charge",
        "Steel",
        "Aluminum",
        "Targeting System"
    }

    return _ExtendedGoodsTable[_TurretName]
end

function onBuildATurretButtonPressed(_Button)
    if onClient() then
        invokeServerFunction("onBuildATurretButtonPressed", _Button.tooltip)
        return
    end

    local entity = Player(callingPlayer).craft

    local _GoodsTable = getGoodsForTurret(_Button)

    print("Adding goods for a " .. tostring(_Button))
    for _, _Good in pairs(_GoodsTable) do
        local _GoodsToAdd = 1000
        if _Good == "Targeting System" then
            _GoodsToAdd = 100
        end
        print("Adding " .. tostring(_GoodsToAdd) .. " : " .. tostring(_Good))
        CargoBay(entity):addCargo(goods[_Good]:good(), _GoodsToAdd)
    end
end
callable(nil, "onBuildATurretButtonPressed")

--endregion

--region #MISSION TAB

function onAddBulletinButtonPressed(_Button)
    if onClient() then
        invokeServerFunction("onAddBulletinButtonPressed", _Button.tooltip)
        return
    end

    local _station = Entity()
    if _station.type ~= EntityType.Station then
        print("Can't add missions to non-station entities.")
    else
        if _station.playerOrAllianceOwned then
            print("Can't add missions to player or alliance stations.")
        else
            print("Adding " .. tostring(_Button) .. " bulletin.")
            local _MissionPath = "data/scripts/player/missions/" .. _Button .. ".lua"
            local ok, bulletin=run(_MissionPath, "getBulletin", _station)
            _station:invokeFunction("bulletinboard", "removeBulletin", bulletin.brief)
            _station:invokeFunction("bulletinboard", "postBulletin", bulletin)
        end
    end
end
callable(nil, "onAddBulletinButtonPressed")

--endregion