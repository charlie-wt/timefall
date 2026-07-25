width_map = {
	6, 6, 6, 6, 6,
	5, 5,
	4, 4,
	3,
	2, 2,
}

platforms = {
	heights = {3, 6, 9, 11},
	sprite = 036,

	data = nil,

}

function make_platform(height)
	assert(height < #width_map)
	local available_width = width_map[height]

	local width = flr(rnd(available_width - 1) + 1)

	local dist = flr(rnd(available_width - width))

	return {
		height = height,
		side = rnd({"left", "right"}),
		dist_from_centre = dist,
		width = width
	}
end

function platforms:init()
	self.data = {}

	for h in all(self.heights) do
		add(self.data, make_platform(h))
	end
end

function platforms:tiles()
	assert(self.data ~= nil)

	local res = {}

	for plt in all(self.data) do
		local y_tile = 15 - plt.height
		local x_inc = 1
		local centre_x_tile = 8

		if plt.side == "left" then
			x_inc = -1
			centre_x_tile = 7
		end

		for i=1,plt.width do
			add(res, {x=centre_x_tile + (plt.dist_from_centre * x_inc) + (x_inc * i),
			          y=y_tile})
		end
	end

	return res
end

function platforms:tile_is_solid(tile)
	-- TODO #test: is this gonna compare by reference?
	-- return contains(self:tiles(), tile)
	for tl in all(self:tiles()) do
		if tl.x == tile.x and tl.y == tile.y then
			return true
		end
	end
	return false
end

function platforms:draw()
	for tl in all(self:tiles()) do
		local pos = pixels(tl)
		spr(self.sprite, pos.x, pos.y)
	end
end
