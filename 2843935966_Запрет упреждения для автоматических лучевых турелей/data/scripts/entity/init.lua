if onServer() then
  local entity = Entity()
  if entity.playerOrAllianceOwned and (entity.isShip or entity.isStation) then
     entity:addScriptOnce("correctbeamtarget.lua")
  end
end
