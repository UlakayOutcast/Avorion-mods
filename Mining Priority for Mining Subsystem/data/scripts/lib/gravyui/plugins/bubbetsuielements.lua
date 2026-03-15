function GravyUINode:centeredrect(height, width, offset)
	-- printlog("GravyUINode:centeredrect")
	--node.rect.center
	width = width or self.rect.width
	height = height or self.rect.height

	-- define both for square
	-- define just height to use parents width
	-- define just width to use parents height

	local center = self.rect.center

	local size = vec2(width, height)

	offset = offset or vec2()
	local rect = Rect(center - size*0.5 + offset, center + size*0.5 + offset)
	return self:child(rect)
end

function GravyUINode:invert()
	return self:child(Rect(self.rect.upper, self.rect.lower))
end

function GravyUINode:dirdist(dist, dir) -- Compatibility, default gravyui has this built in
	return self:radial(dir, dist)
end