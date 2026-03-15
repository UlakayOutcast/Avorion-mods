-- namespace DataManager
DataManager = {}

if onServer() then

local self = DataManager
self.data = {}

function DataManager.secure()
	--print("secure")
	return self.data
end

function DataManager.receiveData(id, data_in)
	--print("receive data", id)
	self.data[id] = data_in
	--print(self.data[1].bg_path)
end
--[[
function DataManager.updateServer()
	print(type(self.data[1]))
end
--]]
function DataManager.sendData(id)
	if not self.data[id] then
		self.data[id] = {}
		--print("no data", id)
	end
	return self.data[id]
end

function DataManager.restore(data_in)
	self.data = data_in or {}
	--print("restore", self.data[1].bg_path)
end

end
