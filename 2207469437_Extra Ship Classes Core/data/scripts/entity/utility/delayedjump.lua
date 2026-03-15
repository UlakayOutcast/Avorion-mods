package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--Don't remove or alter the following comment.
--namespace DelayedJump
DelayedJump = {}
local self = DelayedJump

function DelayedJump.initialize(_X, _Y, _JumpDelay)
    self._JumpTarget = { x = _X, y = _Y }
    self._JumpDelay = _JumpDelay
    self._Timer = 0
end

function DelayedJump.getUpdateInterval()
    return 0.5
end

function DelayedJump.updateServer(_TimeStep)
    local _Faction = Faction()
    --Don't attach this to player or alliance entities.
    if not _Faction or _Faction.isPlayer or _Faction.isAlliance then
        terminate()
        return
    end

    self._Timer = self._Timer + _TimeStep

    if self._Timer >= self._JumpDelay then
        Sector():transferEntity(Entity(), self._JumpTarget.x, self._JumpTarget.y, SectorChangeType.Jump)
        terminate()
        return
    end
end

function DelayedJump.secure()
    return { _Target = self._JumpTarget, _Delay = self._JumpDelay, _Timer = self._Timer}
end

function DelayedJump.restore(_Data_in)
    self._JumpTarget = _Data_in._Target
    self._JumpDelay = _Data_in._Delay
    self._Timer = _Data_in._Timer
end