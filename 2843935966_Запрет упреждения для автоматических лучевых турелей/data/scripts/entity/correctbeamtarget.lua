local turrets
local isPiloted = false

function initialize()
  local entity = Entity()
  entity:registerCallback("onTurretAdded", "AddTurret")
  entity:registerCallback("onTurretDestroyed", "UpdateTurrets")
  entity:registerCallback("onTurretRemoved", "UpdateTurrets")
  entity:registerCallback("onTurretRemovedByPlayer", "UpdateTurrets")
  entity:registerCallback("onCraftSeatEntered", "OnCraftSeatEntered")
  entity:registerCallback("onCraftSeatLeft", "OnCraftSeatLeft")
  --isPiloted = entity:getPilotIndices() ~= nil
end

function AddTurret(shipId, turretIndex)
  if turrets == nil then turrets = {} end
  local turret = Entity(turretIndex)
  if turret then
    local weapons = Weapons(turret)
    if weapons.shotSpeed == math.huge then
      table.insert(turrets, {turret = Turret(turret), tAI = TurretAI(turret), weapons = weapons})
    end
  end
end

function UpdateTurrets()
  turrets = {}
  for _, t in pairs({Entity():getTurrets()}) do
    local weapons = Weapons(t)
    if weapons.shotSpeed == math.huge then
      table.insert(turrets, {turret = Turret(t), tAI = TurretAI(t), weapons = weapons})
    end
  end
end

function updatePiloted(piloted)
  isPiloted = piloted
end

function OnCraftSeatEntered(entityId, seat, playerIndex, firstPlayer)
  if firstPlayer then
    isPiloted = true
  end
end

function OnCraftSeatLeft(entityId, seat, playerIndex, playersRemaining)
  if not playersRemaining then
    isPiloted = false
  end
end

function getUpdateInterval()
  if isPiloted then
    return 0
  end
  return 1
end

function updateServer(tick)
  if not isPiloted then return end
  local cached = turrets
  if cached == nil then return end
  for _, turret_tuple in pairs(cached) do
    local turret = turret_tuple.turret
    if valid(turret) then
      local tAI = turret_tuple.tAI
      if not turret.weaponsPlayerControlled then
        local target
        if tAI.targetedEntity ~= nil then
          target = Entity(tAI.targetedEntity)
        end
        if valid(target) and target.isShip then
          tAI.aimedPosition = target.translationf
        end
      end
    end
  end
end
