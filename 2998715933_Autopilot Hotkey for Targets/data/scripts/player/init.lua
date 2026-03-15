
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

if onServer() then
    Player():addScriptOnce("data/scripts/player/contextualautopilothotkey.lua")
end