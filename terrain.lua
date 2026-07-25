terrain = {
	solid_tiles = {033,034,035}
}

function terrain:tile_solid(screen_tile_pos)
	local atp = abs_tile_pos(screen_tile_pos)
	local contents = mget(atp.x, atp.y)
	return contains(self.solid_tiles, contents)
end
