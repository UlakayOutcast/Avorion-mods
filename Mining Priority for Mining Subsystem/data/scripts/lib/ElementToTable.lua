include("UIDragList")
include("UISortList")
include("UIGraph")
include("UIInvSelection")

Element_New_Meta = {
	__index = function(self, ind)
		return self.element[ind] or rawget(self, ind)
	end,
	__newindex = function(self, ind, val) -- TODO add the x so this works again removing the function removes the dumb errors
		local _, ret = pcall(function(this, ind, val)
			this.element[ind] = val
			return this.element[ind]
		end, self, ind, val)
		if not ret then
			print('The following error is not causing any issues, ignore it.')
			rawset(self, ind, val)
		end
	end
}

local UIElements = { -- TODO make these functions interface with namespacer
	createDragList = function(self, namespace, window)
		return UIDragList(namespace, window, self)
	end,
	createSortList = function(self, namespace, rect, inventory, is_turrets)
		return UISortList(namespace, self, rect, inventory, is_turrets)
	end,
	createGraph = function(self, rect)
		return UIGraph(self, rect)
	end,
	createInvSelection = function(self, rect, namespace)
		return UIInvSelection(self.element, rect, namespace)
	end
}
--[[
local namespacerfunctions = {
	createCheckBox = function(self, rect, caption, onCheckedFunction)
		local node = type(rect) == 'table' and rect.rect and rect
		if node then rect = node.rect end -- translate gravyui nodes to rect easily
		onCheckedFunction = self.namespacer:makeNamespacedName(onCheckedFunction)
		local elem = ElementToTable(self.element:createCheckBox(rect, caption, onCheckedFunction), self.namespacer)
		table.insert(self.children, elem)
		rawset(elem, 'parent', self)
		rawset(elem, 'node', node)
		--rawset(elem, 'element_type', self) probably not needed because you can avoriontype the element
		return elem
	end,
	createComboBox = function(self, rect, onSelectedFunction)
	end,
	createCraftPortrait = function(self, rect, _function) end,
	createRoundButton = function(self, rect, icon, _function) end,
	createSlider = function(self, rect, min, max, steps, caption, onValueChangedFunction) end,
	createTextBox = function(self, rect, onTextChangedFunction) end,
	createValueComboBox = function(self, rect, onSelectedFunction) end
}]]

--which parameter is the one that needs to be namespaced
local namespacerfunctions = {
	createButton = 3,
	createCheckBox = 3,
	createComboBox = 2,
	createCraftPortrait = 2,
	createRoundButton = 2,
	createSlider = 6,
	createTextBox = 2,
	createValueComboBox = 2
}

--- @param element UIElement @Any UI element to be converted to a table
function ElementToTable(element, namespacer)
	local x = {element = element, children = {}, d = {}, namespacer = namespacer}
	for k, v in pairs(getmetatable(element)) do
		if string.find(k, 'create') then
			x[k] = function(self, ...)
				local args = {...}
				local node = type(args[1]) == 'table' and args[1].rect and args[1]
				if node then args[1] = node.rect end -- translate gravyui nodes to rect easily
				local namespaced_arg = namespacerfunctions[k]
				local namespacer = rawget(self, "namespacer")
				if namespaced_arg and namespacer then
					args[namespaced_arg] = namespacer:makeNamespacedName(args[namespaced_arg])
				end
				local elem = ElementToTable(v(self.element, unpack(args)), namespacer)
				table.insert(self.children, elem)
				rawset(elem, 'parent', self)
				rawset(elem, 'node', node)
				--rawset(elem, 'element_type', self) probably not needed because you can avoriontype the element
				return elem
			end
		elseif not string.find(k, 'index') then
			x[k] = function(self, ...)
				return v(self.element, ...)
			end
		end
	end
	for k, v in pairs(UIElements) do
		x[k] = v
	end
	setmetatable(x, Element_New_Meta) -- TODO uncomment this
	return x
end

--[[function ElementToTable(element)
	local x = {element = element, children = {}}
	local old_meta = getmetatable(element)
	local new_meta = {}
	for k, v in pairs(old_meta) do
		if string.find(k, 'create') then
			new_meta[k] = function(self, ...)
				local elem = ElementToTable(v(self.element, ...))
				table.insert(self.children, elem)
				elem.parent = self
				return elem
			end
		else
			new_meta[k] = function(self, ...)
				return v(self.element, ...)
			end
		end
	end
	new_meta.__index = function(self, ind)
		local suc, ret = pcall(old_meta.__index, self.element, ind)
		if not suc then
			ret = rawget(self, ind)
		end
		return ret
	end
	new_meta.__newindex = function(self, ind, val)
		local suc, ret = pcall(old_meta.__newindex, self.element, ind, val)
		if not suc then
			ret = rawset(self, ind, val)
		end
		return ret
	end
	setmetatable(x, new_meta)
	return x
end]]