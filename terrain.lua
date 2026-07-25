terrain = {
	solid_tiles = {033,034,035},
	hourglass_background_tile = 032
}

function terrain:tile_solid(screen_tile_pos)
	local atp = abs_tile_pos(screen_tile_pos)
	local contents = mget(atp.x, atp.y)
	return contains(self.solid_tiles, contents)
end

function terrain:tile_is_background(screen_tile_pos)
	local atp = abs_tile_pos(screen_tile_pos)
	return mget(atp.x, atp.y) == self.hourglass_background_tile
end
