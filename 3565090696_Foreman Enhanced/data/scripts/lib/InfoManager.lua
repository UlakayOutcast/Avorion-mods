local InfoManager = {}
local infoWindow
local btnInfoNextPage
local btnInfoPrevPage
local infoWindowPicture
local infoWindowLabel
local infoPageIndex = 0

local infoPages = {
    [0] = {title = "Foreman - Introduction"%_t, picSizeX = 676 * 0.75, picSizeY = 341 * 0.75, picture = "data/pictures/introduction.png", text = [[
\c(0d0)Foreman\c() is a very powerful fleet assistance tool for your mining and salvaging carriers.
With Foreman, you are able to command several ships at once, automating valuable looting and automating mining and salvaging operations.
For a ship to be considered as a carrier, it needs a Foreman Subsystem installed.]]%_t},
    [1] = {title = "Foreman - Subsystem"%_t, picSizeX = 479 * 0.6, picSizeY = 386 * 0.6, picture = "data/pictures/subsystem.png", text = [[
Foreman Subsystems can be found throughout Trinium region and beyond.
Be mindful that these systems are extremely powerful and therefore, quite pricey.
\c(0d0)Asteroid Scanning Level\c()
This tells the asteroid material level your commanding ship is able to issue orders for squads.
\c(0d0)Sector Scanning\c()
Sector needs to be scanned for mineable asteroids after entering a new sector.
Scanning is faction wide inside a sector so only one player from a faction needs to scan.
\c(0d0)Fighter Pickup Loot\c()
When worthy loot is detected (turrets and subsystems), the closest fighter will gracefully surge after the loot and pick it up.
Very valuable feature.
\c(0d0)Fighter Cargo Pickup\c()
With this feature the ship doesn't need additional Transporter Software Subsystem for fighters to pickup resources (it DOES NOT totally replace Transporter Software Subsystem however).
Transport block is still needed.
\c(0d0)Mining Amount Accuracy\c()
Tells information about mineable resources in the sector depending on system installed:
-Sector has mineable asteroids (yes/no)
-Amount of asteroids to mine (e.g. 27 asteroids)
-Estimate (shows as 100k steps)
-Exact total
-Exact total + exact per material]]%_t},
    [2] = {title = "Foreman - Commander's Window"%_t, picSizeX = 307, picSizeY = 274, picture = "data/pictures/shiplist.png", text = [[
\c(0d0)Material filters\c()
The colored boxes act as a filter for different materials.
With some Foreman Subsystems installed, hovering mouse over a filter shows the material amount in the sector.
\c(0d0)Force refresh button\c()
In some rare cases, a ship won't get added to the ship list.
Pressing this button should fix that.
\c(0d0)Ship list\c()
The ship list shows all carriers in the sector with various information regarding the ship.
Information from left to right:
-\c(0d0)Cargo\c() fill percentage
-\c(0d0)Ship name\c() (color indicates the material the ship can mine/salvage)
-\c(0d0)Icon of 4 fighters\c() - Ship is not able to control all squads (add more fighter subsystems)
-\c(0d0)Captain icon\c() - Ship is missing captain
-\c(0d0)Pilot icon\c() - Missing pilots (color indicates how many, red alot, green few)
-\c(0d0)Fighter icon\c() - Missing fighters (color indicates how many, red alot, green few)
-\c(0d0)Player indicator\c() - If ships is piloted by a player
Hovering mouse over shows additional tooltip regarding that piece of information.]]%_t},
    [3] = {title = "Foreman - Scanning"%_t, picSizeX = 307, picSizeY = 274, picture = "data/pictures/scanning.png", text = [[
\c(0d0)Scanning asteroids\c()
Scanning is required to acquire sufficient information about a sectors mineral deposits and order your fleets mining squads.
A sector needs to be scanned once per faction and the information is kept as long as one ship of the faction stays in the sector.
\c(0d0)Wreckages\c() does not need to be scanned since they are actively being monitored.]]%_t},
    [4] = {title = "Foreman - Operations", picSizeX = 440, picSizeY = 309, picture = "data/pictures/mineraltrails.png", text = [[
\c(0d0)Minining Operation Functionality\c()
Orders all carriers to release their mining squads to a random asteroid continuing to nearest neighbour.
Squads will only go after asteroids they are able to mine.
Newly jumped carriers join the fun automatically.
When mining is done, the fighters return to circle the mothership so the resource trails can catch up
(like shown in the picture).
Mining fighters won't launch if there is no asteroids to mine with selected filters.
\c(0d0)Salvage Operation Functionality\c()
Works mostly like the mine operation. Distribute squads randomly. Then to nearest neighbour.
When Salvage operation is on. The fighters launch whenever a salvage is detected in the sector.
\c(0d0)Stopping an operation\c()
"Stop" forces all carriers to halt and immediately recall their mining or salvaging squads into the hangar.
"Recall full ships" button won't affect operating carriers with free cargo space available.]]%_t},
}
function InfoManager.checkIfFirstTimeLoad()
    local storage = io.open("./moddata/Foreman/firsttimecheck.txt", "r")
    if storage == nil then
        InfoManager.showInfo()
        createDirectory("./moddata/Foreman")
        storage = io.open("./moddata/Foreman/firsttimecheck.txt", "w")
        storage:write("true")
        storage:close()
        return
    end
    if storage ~= nil then
        storage:close()
    end
end
function InfoManager.showInfo()
    if infoWindow == nil then
        local res = getResolution()
        local size = vec2(res.x * 0.40, res.y * 0.65)
        infoWindow = Hud():createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
        infoWindow.caption = "Foreman - Info"%_t
        infoWindow.moveable = true
        infoWindow.showCloseButton = true
        infoWindowPicture = infoWindow:createPicture(Rect(5,5, 305, 305), "")
        infoWindowPicture.flipped = true
        local lX = (infoWindow.size.x) / 2
        local lY = infoWindow.size.y
        btnInfoNextPage = infoWindow:createButton(Rect(lX+5, lY-35, lX+105, lY-5), "Next page"%_t, "infoNextPagePressed")
        btnInfoPrevPage = infoWindow:createButton(Rect(lX-105, lY-35, lX-5, lY-5), "Prev. page"%_t, "infoPrevPagePressed")
        btnInfoPrevPage.active = false
        infoWindowLabel= infoWindow:createTextField(Rect(10, 5, infoWindow.size.x - 10, infoWindow.size.y - 10), "")
        infoWindowLabel.width = infoWindow.size.x - 10
        infoWindowLabel.fontSize = 14.5
    else
        infoWindow:show()
    end
    InfoManager.loadInfoPage()
end
function InfoManager.loadInfoPage()
    local infoPage = infoPages[infoPageIndex]
    infoWindow.caption = infoPage.title
    local picCenterX = (infoWindow.position.x + 5)
    infoWindowPicture.position = vec2(picCenterX, infoWindow.position.y + 5)
    infoWindowPicture.size = vec2(infoPage.picSizeX, infoPage.picSizeY)
    infoWindowPicture.picture = infoPage.picture
    infoWindowLabel.position = vec2(infoWindow.position.x, infoWindowPicture.position.y +  infoPage.picSizeY + 5)
    infoWindowLabel.text = infoPage.text
end
function InfoManager.infoNextPagePressed()
    infoPageIndex = infoPageIndex + 1
    InfoManager.loadInfoPage()
    if infoPageIndex == #infoPages then
        btnInfoNextPage.active = false
    end
    if infoPageIndex > 0 then
        btnInfoPrevPage.active = true
    end
end
function InfoManager.infoPrevPagePressed()
    infoPageIndex = infoPageIndex - 1
    InfoManager.loadInfoPage()
    if infoPageIndex == 0 then
        btnInfoPrevPage.active = false
    end
    if infoPageIndex < #infoPages then
        btnInfoNextPage.active = true
    end
end
-- Global callback functions are now defined in ForemanManager.lua
return InfoManager
