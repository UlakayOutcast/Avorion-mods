package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include ("reconstructionutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace tFT
tFT = {}
local constructionTime
local timeUntilFinished
local name
local buyer
local withCrew

function tFT.initialize()
	if onServer() then
		Entity():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
	else
		invokeServerFunction("sendVars")
	end
end

function tFT.sendVars()
	if onServer() then
		broadcastInvokeClientFunction("setVars", constructionTime, timeUntilFinished, name, buyer, withCrew)
	end
end
callable(tFT, "sendVars")

function tFT.setVars(pConstructionTime, pTimeUntilFinished, pName, pBuyer, pWithCrew)
	if pConstructionTime == nil or pTimeUntilFinished == nil or pName == nil or pBuyer == nil or pWithCrew == nil then
		print("Nothing set", pConstructionTime, pTimeUntilFinished, pName, pBuyer, pWithCrew)
	end
	constructionTime = pConstructionTime
	timeUntilFinished = pTimeUntilFinished
	name = pName
	buyer = pBuyer
	withCrew = pWithCrew
end

function onRestoredFromDisk(time)
	tFT.update(time)
end

function tFT.getUpdateInterval()
	return 1
end

function tFT.update(timestep)
	if not timeUntilFinished then return end
	timeUntilFinished = timeUntilFinished - timestep

	if timeUntilFinished <= 0 and onServer() then
		local ship = Entity()
		if buyer then
			ship.name = name

			-- add base crew
			local crew = Crew()
			if withCrew then
				crew = ship.idealCrew
			end
			ship.crew = crew
			buyerFaction = Faction(buyer)
			buyerFaction:sendChatMessage("Shipyard",ChatMessageType.Normal, "Your ship: %s has finished production" % _t, (ship.name or "(unnamed)" % _t))
			ship.invincible = false
			ship.factionIndex = buyer

			local senderInfo = makeCallbackSenderInfo(Entity())
			buyerFaction:sendCallback("onShipCreationFinished", senderInfo, ship.id)

			if GameSettings().difficulty <= Difficulty.Veteran and GameSettings().reconstructionAllowed then
				local kit = createReconstructionKit(ship)
				buyerFaction:getInventory():addOrDrop(kit, true)
			end

			terminate()
		else
			print(string.format("[Advanced Shipyard Mod] No owner found for ship (-index): %s   in sector: (%i:%i)", ship.index.string, Sector():getCoordinates()))
			terminate()
		end
	end
end

function tFT.renderUIIndicator(px, py, size)
	if timeUntilFinished then
		local x = px - size / 2
		local y = py + size / 2 + 6

		-- outer rect
		local sx = size + 2
		local sy = 4

		drawRect(Rect(x, y, sx + x, sy + y), ColorRGB(0, 0, 0))

		-- inner rect
		sx = sx - 2
		sy = sy - 2

		sx = sx * (constructionTime - (timeUntilFinished or 0)) / constructionTime
		drawRect(Rect(x + 1, y + 1, sx + x + 1, sy + y + 1), ColorRGB(0.66, 0.66, 1.0))
	end
end

function tFT.restore(data)
	tFT.setVars(data.constructionTime, data.time, data.name, data.buyer, data.withCrew or data.captain)
end

function tFT.secure()
	local data = {}
	data.constructionTime = constructionTime
	data.time = timeUntilFinished
	data.name = name
	data.buyer = buyer
	data.withCrew = withCrew
	return data
end
