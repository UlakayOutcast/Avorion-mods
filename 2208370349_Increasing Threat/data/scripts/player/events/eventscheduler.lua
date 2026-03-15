local _Debug = 0
local _TargetIndex = nil

for _Idx, _Event in pairs(events) do
    --Figure out where to yeet fake distress signal.
    if _Event.script and _Event.script == "events/fakedistresssignal" then
        if _Debug == 1 then
            print("Found fake distress signal event at index " .. tostring(_Idx))
        end
        _TargetIndex = _Idx
    end
end
if _TargetIndex then
    table.remove(events, _TargetIndex)
    if _Debug == 1 then
        print("Removed standard fake distress signal event.")
    end
end
--replaces the vanilla event.
table.insert(events, {schedule = random():getInt(60, 80) * 60, localEvent = false, script = "events/itfakedistresssignal", arguments = {true}, to = 560})
--new events.
table.insert(events, {schedule = random():getInt(60, 80) * 60, localEvent = true,  script = "events/sectoreventstarter", arguments = {"decapstrike.lua"}, to = 560})
table.insert(events, {schedule = random():getInt(45, 60) * 60, localEvent = false, script = "events/deepfakedistress", arguments = {true}, to = 560})
--Add second / third version of the vanilla events to balance out the massive # of Xsotan attacks going + make the player a little scared :)
table.insert(events, {schedule = random():getInt(50, 70) * 60,   localEvent = true,  script = "events/sectoreventstarter", arguments = {"pirateattack.lua"}, to = 560, centralFactor = 0.5, outerFactor = 1, noMansFactor = 1.2})
table.insert(events, {schedule = random():getInt(90, 130) * 60,   localEvent = false,  script = "events/passiveplayerattackstarter.lua"})

function EventScheduler.unPause()
    if _Debug == 1 then
        local _Player = Player()
        print("Unpausing events for " .. tostring(_Player.name))
    end
    self.pauseTime = 0
end