package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
---@class NameSpacer
--namespace NameSpacer
local NameSpacer = {namespaces = {}}

local function IF_Handler(current_namespace_string, functionName, ...)
	local current_namespace = NameSpacer.namespaces[current_namespace_string].current_namespace
	current_namespace[functionName](current_namespace, ...) -- TODO implement my own callable so calls can't be abused.
end

function NameSpacer:initialize(parent_namespace, current_namespace, current_namespace_string, suppressRegistering)
	self.parent_namespace = parent_namespace
	self.parent_path = getScriptPath()
	self.current_namespace = current_namespace
	self.current_namespace_string = current_namespace_string
	self.suppressRegistering = suppressRegistering
	parent_namespace["NameSpacer_invokeFunctionHandler"] = IF_Handler
	callable(parent_namespace, "NameSpacer_invokeFunctionHandler")
	NameSpacer.namespaces[current_namespace_string] = self
	return self
end

function NameSpacer:registerCallback(object, callback, functionName)
	if not functionName then functionName = callback end
	local parent_name = self:makeNamespacedName(functionName)
	if not object.registerCallback then
		print("registerCallback does not exist for type", atype(object))
	end
	object:registerCallback(callback, parent_name)
end

function NameSpacer:makeNamespacedName(functionName, func)
	if functionName == "" then return functionName end
	--[[
	local parent_name = self.current_namespace_string .. "_" .. functionName
	self.parent_namespace[parent_name] = func or self.current_namespace[functionName]
	return parent_name
	]]
	local parent_name = self.current_namespace_string .. "_" .. functionName
	if self.parent_namespace[parent_name] then return parent_name end
	-- print if null and devmode or always on false, true to never print
	if not self.suppressRegistering and ((type(self.suppressRegistering) == "boolean") or GameSettings().devMode) then
		print("namespacer registering", parent_name)
	end
	if not func then
		func = function(...)
			local tar = self.current_namespace[functionName]
			if not tar then print("Field '?' is", functionName, "for namespace", self.current_namespace_string) end
			return tar(self.current_namespace, ...)
		end
	end
	self.parent_namespace[parent_name] = func
	return parent_name
end

-- TODO add functions for invokeClient, invokeServer, broadcastInvokeClient, and probably callable

---@param functionName string The function to invoke, in respect to the current namespace.
---@param ... any Any number of arguments to pass to the function.
function NameSpacer:invokeClientFunction(player, functionName, ...)
	invokeClientFunction(player, "NameSpacer_invokeFunctionHandler", self.current_namespace_string, functionName, ...)
end

---@param functionName string The function to invoke, in respect to the current namespace.
---@param ... any Any number of arguments to pass to the function.
function NameSpacer:broadcastInvokeClientFunction(functionName, ...)
	broadcastInvokeClientFunction("NameSpacer_invokeFunctionHandler", self.current_namespace_string, functionName, ...)
end

---@param functionName string The function to invoke, in respect to the current namespace.
---@param ... any number of arguments to pass to the function.
function NameSpacer:invokeServerFunction(functionName, ...)
	invokeServerFunction("NameSpacer_invokeFunctionHandler", self.current_namespace_string, functionName, ...)
end

---@param time number time in seconds before invoke
---@param functionName string The function to invoke, in respect to the current namespace.
---@param ... any number of arguments to pass to the function.
function NameSpacer:deferredCallback(time, functionName, ...)
	deferredCallback(time, "NameSpacer_invokeFunctionHandler", self.current_namespace_string, functionName, ...)
end

function NameSpacer:invokeFunction(userdata, functionName, ...)
	-- namespaced name has to be made before this is called, i.e. in the initialize TODO try and figure out a solution that avoids this
	-- one solution is to register every function in the child namespace on init, but that sounds very inefficient
	-- another solution is to just leave it up to the developer, kind of like how public variables typically work.
	return userdata:invokeFunction(self.parent_path, self:makeNamespacedName(functionName), ...)
end

local function call(...)
	local x = setmetatable({}, {__index = NameSpacer})
	x:initialize(...)
	return x
end

return call