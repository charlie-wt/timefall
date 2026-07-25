sand = {
	total_pieces = 50,

	-- spawning
	-- TODO #enhancement: might it be better if these are expressed as fall tick counts,
	-- so that we can *never* spawn *immediately* before falling?
	initial_spawn_t = 5,
	spawn_interval_range_t = {3,5},
	spawn_positions = {
		{x=7,y=0},
		{x=8,y=0},
	},
	fall_period_seconds = 1,

	-- drawing
	sprites = {
		settled = 034,
		falling = 035
	},

	pieces_remaining_default_colour = 7,
	pieces_remaining_threshold_colours = {  -- !!! {thresh,col}; must be descending !!!
		{25, 10},
		{12, 9},
		{5, 8}
	},

	-- state
	data = nil,
	t_next_spawn = nil,
	t_last_fall = nil,
	pieces_spawned = nil
}

function sand:pieces_remaining()
	assert(self.pieces_spawned ~= nil)
	return max(self.total_pieces - self.pieces_spawned, 0)
end

function init_data()
	local res = {}

	local row = {}
	for i=1,16 do
		add(row, false)
	end

	for i=1,16 do
		add(res, shallow_copy(row))
	end

	return res
end

function sand:init()
	self.data = init_data()
	local now = time()
	self.t_next_spawn = now + self.initial_spawn_t
	self.t_last_fall = now
	self.pieces_spawned = 0
end

function sand:print_data()
	printh("data {")
	if self.data == nil then
		printh("nil")
	else
		for row in all(self.data) do
			printh(list_str(row))
		end
	end
	printh("}")
end

function sand:spawn()
	if self:pieces_remaining() == 0 then return end

	local until_next = rnd(self.spawn_interval_range_t[2] - self.spawn_interval_range_t[1]) + self.spawn_interval_range_t[1]
	self.t_next_spawn = time() + until_next

	local spawn_pos = rnd(self.spawn_positions)
	printh("getting spawn pos "..table_str(spawn_pos))
	self:set_tile_is_sand(spawn_pos, true)

	self.pieces_spawned += 1
end

function below(tile)
	return {x=tile.x, y=tile.y + 1}
end

function sand:fall()
	self.t_last_fall = time()

	local new_data = init_data()

	function set_new_data(tile, value)
		new_data[tile.y + 1][tile.x + 1] = value
	end

	for y=0,15 do
		for x=0,15 do
			local tile = {x=x, y=y}
			if self:tile_is_sand(tile) then
				set_new_data(tile, true)
				if y < 15 and not self:tile_is_solid(below(tile)) then
					set_new_data(tile, false)
					set_new_data(below(tile), true)
				end
			end
		end
	end

	self.data = new_data
end

function sand:update()
	assert(self.data ~= nil)

	local now = time()

	if now > self.t_next_spawn then
		self:spawn()
	end

	if now - self.t_last_fall > self.fall_period_seconds then
		self:fall()
	end
end

-- screen pos tile
function sand:tile_is_sand(tile)
	return self.data[tile.y + 1][tile.x + 1]
end

function sand:set_tile_is_sand(tile, value)
	self.data[tile.y + 1][tile.x + 1] = value
end

-- screen pos tile
function sand:tile_is_solid(tile)
	if terrain:tile_solid(tile) then
		return true
	end

	return self:tile_is_sand(tile)
end

function sand:draw_pieces_remaining()
	local colour = self.pieces_remaining_default_colour
	for val in all(self.pieces_remaining_threshold_colours) do
		local threshold,col = unpack(val)
		if self:pieces_remaining() <= threshold then
			colour = col
		end
	end
	print(tostr(self:pieces_remaining()), 8, 8, colour)
end

function sand:draw_sand()
	for y=0,15 do
		for x=0,15 do
			local tile = {x=x, y=y}
			if self:tile_is_sand(tile) then
				local sprite = self.sprites.settled
				if y < 16 and not self:tile_is_solid(below(tile)) then
					sprite = self.sprites.falling
				end
				local pos = pixels(tile)
				printh("drawing tile pos "..table_str(tile).." -> pixel pos "..table_str(pos))
				spr(sprite, pos.x, pos.y)
			end
		end
	end
end
