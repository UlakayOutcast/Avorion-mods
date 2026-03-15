package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
Node = include("node")

-- namespace Graph
Graph = {}

function Graph:createLegend(rect)
	if rect.__avoriontype == "Rect" then
		self.label_node = Node(rect.size)
	else
		self.label_node = rect
	end
	self.legend_container = self._parent:createContainer(rect.rect)
	self.label_root = Node(self.label_node.rect.size)
	self.label_frame = self.legend_container:createScrollFrame(self.label_root)
	self.label_lister = UIVerticalLister(self.label_root:pad(0,0,20,0).rect, 10, 5)
	self.labels = {}
	self.labels_by_name = {}
end

function Graph:initialize()
	---@type UIContainer
	self.container = self._parent:createContainer(self._rect.rect)
	self.root_node = Node(self._rect.rect.size)
	self.line_node, self.slider_node = self.root_node:rows({1, 20}, 10)

	self.slider = self.container:createSlider(self.slider_node, 100, 0, 10, "History", "")
	self.slider.value = self.slider.max

	self.line_container = self.container:createContainer(self.line_node)
	self.line_frame = self.container:createFrame(self.line_node)
end

function Graph:sortLabels()
	if #self.labels < 2 then return end
	local to_sort = {}
	for k, v in pairs(self.data_points) do
		table.insert(to_sort, v)
	end
	if not self.sorting_disabled and #to_sort > 1 then
		table.sort(to_sort, function(a, b)
			if not a.values[1] then return false end
			if not b.values[1] then return true end
			return a.values[1].value > b.values[1].value
		end)
	end
	for k, v in pairs(to_sort) do
		local label = self.labels[k]
		if not label then return end
		label.label.element.caption = v.name
		label.label.element.tooltip = v.name
		label.box.element.color = v.color
		local first = v.values[1]
		if first then
			label.box.element.tooltip = v.name .. ": " .. first.value .. "\nDate/Time: " .. os.date("%c", first.time)
		end
	end
end

function Graph:createLabel(name)
	if self.labels_by_name[name] then self:sortLabels() return end
	self.labels_by_name[name] = true

	local node = Node(self.label_lister:nextRect(20))
	local left, right = node:cols({20,1}, 10)
	local box = self.label_frame:createRect(left.rect, self.data_points[name].color)
	---@type Label
	local label_e = self.label_frame:createLabel(right.rect, name, 14)
	label_e.element.shortenText = true
	label_e.element.tooltip = name
	label_e:setLeftAligned()
	table.insert(self.labels, {nodes = {root = node, left = left, right = right}, label = label_e, box = box})
	self:sortLabels()
end

function Graph:createEntry(name, color)
	if self.data_points[name] then
		local color = color or self.data_points[name].color
		self.data_points[name].color = color
		if self.label_lister then
			self:createLabel(name, color)
		end
	else
		if not color then color = ColorHSV(math.random()*360, 1, 1) end
		self.data_points[name] = {name = name, color = color, values = {}}
		if self.label_lister then
			self:createLabel(name, color)
		end
	end
end

function Graph:getLine(data_point, k, v)
	local height = self.line_node.rect.height
	local width = self.line_node.rect.width

	local num = self.slider.value == 0 and self.highest_entries or self.slider.value
	local x = -k/num + 1/num + 1
	local y = 1-v/self.highest_good
	-- TODO maybe update the highest_good based on the visible entries and the lowest so you can actually see some variance in the graph

	--print("num", self.highest_entries, "high", self.highest_good)
	--print("x", x, "y", y)

	local prev = vec2(0, height)
	local next = data_point.values[k + 1]
	if next then
		k = k + 1
		v = next.value
		local x = -k/num + 1/num + 1
		local y = 1-v/self.highest_good
		prev = vec2(width*x, y*height)
	end
	local cur = vec2(width*x, y*height)
	return prev, cur
end

function Graph:redraw()
	self.line_container:clear()
	local size = vec2(self.dot_size or 3)
	local slider_val = self.slider.value
	for k, data_point in pairs(self.data_points) do

		for k, v in pairs(data_point.values) do
			if not (slider_val ~= 0 and k > slider_val) then
				local prev, cur = self:getLine(data_point, k, v.value)
				local line = self.line_container:createLine(prev, cur)
				line.element.color = data_point.color
				local box = self.line_container:createRect(Rect(cur-size, cur+size), data_point.color)
				box.element.tooltip = data_point.name .. ": " .. v.value .. "\nDate/Time: " .. os.date("%c", v.time)
				--self.line_container:createLabel(cur, k, 14)
			end
		end
	end
end

function Graph:limitData(key)
	if tablelength(self.data_points[key]) > 200 then -- limit size
		table.remove(self.data_points[key])
	end
end

function Graph:addData(key, value)
	local this = {value=value, time = os.time()}
	table.insert(self.data_points[key].values, 1, this)

	self.highest_good = self.highest_good or 0
	self.highest_entries = self.highest_entries or 0

	local len = #self.data_points[key].values
	if len > self.highest_entries then
		self.highest_entries = len
	end

	if value > self.highest_good then
		self.highest_good = value
	end

	if self.data_points[key].label then
		self.data_points[key].label.box.tooltip = key .. ": " .. this.value .. "\nDate/Time: " .. os.date("%c", this.time)
	end

	self:limitData(key)

	self:redraw()
end

function Graph:clearValues()
	for k, v in pairs(self.data_points) do
		self.data_points[k].values = {}
	end
end

function Graph:secure() -- TODO make another library file to export all the heavy lifting of this out of the end file
	local data = {points = {}}
	for k, v in pairs(self.data_points) do
		data.points[k] = {name = v.name, color = {h = v.color.hue, s = v.color.saturation, v = v.color.value}, values = v.values}
	end
	data.slider = self.slider.value
	data.highest_entries = self.highest_entries
	data.highest_good = self.highest_good
	return data
end

function Graph:restore(data)
	--if true then return end
	for k, v in pairs(data.points) do
		v.color = ColorHSV(v.color.h, v.color.s, v.color.v)
		self.data_points[k] = v
	end
	self.data_points = data.points
	self.slider.value = data.slider
	self.highest_entries = data.highest_entries
	self.highest_good = data.highest_good
end

function UIGraph(parent, rect, namespace) -- namespace for registering functions with callable?
	if rect.__avoriontype == "Rect" then rect = Node(rect) end
	local x = {_parent = parent, _rect = rect, _namespace = namespace, data_points = {}}
	setmetatable(x, {__index = Graph})
	x:initialize()
	return x
end

return Graph