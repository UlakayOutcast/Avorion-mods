function pairsByValues(t)
	local a = {}
	for k, v in pairs(t) do table.insert(a, {ind = k, val = v}) end
	table.sort(a, function(a, b) return a.val > b.val end)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i].ind, a[i].val
		end
	end
	return iter
end

function table.find(self, value, func)
	if not func then
		func = function(k, v, val)
			return v == val
		end
	end
	for k, v in pairs(self) do
		if func(k, v, value) then
			return k, v
		end
	end
end

function sort_on_values(t,...)
	local a = {...}
	table.sort(t, function (u,v)
		for i = 1, #a do
			if u.v[a[i]] and v.v[a[i]] then
				if u.v[a[i]] > v.v[a[i]] then return false end
				if u.v[a[i]] < v.v[a[i]] then return true end
			end
		end
		return false
	end)
end

function pairsByKeysWithStringKeys(t, ...)
	local a = {}
	for n, v in pairs(t) do table.insert(a, {k = n, v = v}) end
	--table.sort(a, sortfunc)
	sort_on_values(a, ...)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i].k, a[i].v
		end
	end
	return iter
end
