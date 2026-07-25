terrain = {
	solid_tiles = {033}
}

function terrain:tile_solid(screen_tile_pos)
	local abs_tile_pos = tile_at(screen_tile_pos)
	local contents = mget(abs_tile_pos.x, abs_tile_pos.y)
	return contains(self.solid_tiles, contents)
end
