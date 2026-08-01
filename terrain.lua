terrain = {
	solid_tiles = {033,034,035,192,193,194,195,208,209,210,211},
	hourglass_background_tile = 032
}


-- get tile at screen position {x,y} (in tiles), adjusted for the camera into a position
-- suitable for indexing the map data
function abs_tile_pos(screen_tile_pos)
	local map_location = state.gameplay:cam_pos_tiles()
	return {x=screen_tile_pos.x + map_location.x,
	        y=screen_tile_pos.y + map_location.y}
end

function terrain:tile_solid(screen_tile_pos)
	local atp = abs_tile_pos(screen_tile_pos)
	local contents = mget(atp.x, atp.y)
	return contains(self.solid_tiles, contents)
end

function terrain:tile_is_background(screen_tile_pos)
	local atp = abs_tile_pos(screen_tile_pos)
	return mget(atp.x, atp.y) == self.hourglass_background_tile
end
