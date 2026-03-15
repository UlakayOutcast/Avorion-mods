if onServer() then
  function initialize()
    Player():registerCallback("onSectorArrivalConfirmed", "PlayerArrived")
    --Player():registerCallback("onCraftChanged", "UpdatePiloted")
  end

  function PlayerArrived(playerIndex)
    local ship = Player(playerIndex).craft
    if ship ~= nil and ship:hasScript("data/scripts/entity/correctbeamtarget.lua") then
      ship:invokeFunction("data/scripts/entity/correctbeamtarget.lua", "UpdateTurrets")
    end
  end

  --[[function UpdatePiloted(newId, oldId)
    local newShip = Entity(newId)
    local oldShip = Entity(oldId)
    print("Exited from "..tostring(oldShip)..", to "..tostring(newShip))
    if oldShip ~= nil and oldShip:hasScript("data/scripts/entity/correctbeamtarget.lua") then
      oldShip:invokeFunction("data/scripts/entity/correctbeamtarget.lua", "UpdatePiloted", false)
    end
    if newShip ~= nil and newShip:hasScript("data/scripts/entity/correctbeamtarget.lua") then
      newShip:invokeFunction("data/scripts/entity/correctbeamtarget.lua", "UpdatePiloted", true)
    end
  end]]
end
