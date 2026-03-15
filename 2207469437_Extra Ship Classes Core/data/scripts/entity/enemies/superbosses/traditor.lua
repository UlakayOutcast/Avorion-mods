package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--Don't remove the namespace comment!!! The script could break.
--namespace Traditor
Traditor = {}
local self = Traditor

self._Data = {}

self._Debug = 0