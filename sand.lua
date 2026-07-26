sand = {
	total_pieces = 50,

	-- spawning & falling timing
	-- (note: spawn timings will be locked to the start of a fall period)
	initial_spawn_t = 5,
	spawn_interval_range_t = {3,5},
	spawn_positions = {
		{x=7,y=0},
		{x=8,y=0},
	},
	fall_period_seconds = 0.5,

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
	pieces_spawned = nil,
	pieces_dropped = nil
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
	self.pieces_dropped = 0
end

-- screen pos tile
function sand:tile_is_sand(tile)
	if tile.x < 0 or tile.x > 15 or
	   tile.y < 0 or tile.y > 15 then
		return false
	end
	return self.data[tile.y + 1][tile.x + 1]
end

-- screen pos tile
function sand:set_tile_is_sand(tile, value)
	if tile.x < 0 or tile.x > 15 or
	   tile.y < 0 or tile.y > 15 then
		return
	end
	self.data[tile.y + 1][tile.x + 1] = value
end

-- NOTE: assumes data is initialised but empty (all `false`)
function sand:predistribute(num_pieces)
	while num_pieces > 0 do
		local candidate_tile = {x=flr(rnd(16)), y=flr(rnd(14))+2}
		if terrain:tile_is_background(candidate_tile) and (not tile_is_solid(candidate_tile)) then
			self:set_tile_is_sand(candidate_tile, true)
			num_pieces -= 1
		end
	end

	-- TODO #finish: fall until fallen?
end

function sand:flip()
	if self.data == nil then
		-- bit of a hack to not have to worry back out in `scenes.gameplay` whether we
		-- need to `sand:init` or `sand:flip`, depending on whether this is the first
		-- iteration
		self:init()
		return
	end

	local to_predistribute = self.total_pieces - self.pieces_spawned

	self:init()

	self:predistribute(to_predistribute)
	self.pieces_spawned = to_predistribute
end

function sand:spawn()
	if self:pieces_remaining() == 0 then return end

	local until_next = rnd(self.spawn_interval_range_t[2] - self.spawn_interval_range_t[1]) + self.spawn_interval_range_t[1]
	self.t_next_spawn = time() + until_next

	self:set_tile_is_sand(rnd(self.spawn_positions), true)

	self.pieces_spawned += 1
	self.pieces_dropped += 1
end

function above(tile)
	return {x=tile.x, y=tile.y - 1}
end

function below(tile)
	return {x=tile.x, y=tile.y + 1}
end

function sand:fall()
	local new_data = init_data()

	function set_new_data(tile, value)
		new_data[tile.y + 1][tile.x + 1] = value
	end

	for y=0,15 do
		for x=0,15 do
			local tile = {x=x, y=y}
			if self:tile_is_sand(tile) then
				set_new_data(tile, true)
				if y < 15 and not tile_is_solid(below(tile)) then
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

	if now - self.t_last_fall > self.fall_period_seconds then
		self.t_last_fall = now
		self:fall()

		-- note: putting this check in the fall tick check means we'll always spawn at
		-- the start of a fall tick, so you won't see weird behaviour where a block
		-- spawns then immediately falls
		if now > self.t_next_spawn then
			self:spawn()
		end
	end

	if self:tile_is_sand(tiles(player.pos)) then
		player:die()
	end
end

-- dir: +ve for right, -ve for left
function sand:try_shunt(tile, dir)
	if not self:tile_is_sand(tile) then
		return
	end

	if self:tile_is_sand(above(tile)) then
		return
	end

	local x_inc = 1
	if dir < 0 then
		x_inc = -1
	end
	local destination = {x=tile.x + x_inc, y=tile.y}

	if not tile_is_solid(destination) then
		self:set_tile_is_sand(tile, false)
		self:set_tile_is_sand(destination, true)
	end
end

function sand:draw_pieces_remaining(x, y)
	local colour = self.pieces_remaining_default_colour
	for val in all(self.pieces_remaining_threshold_colours) do
		local threshold,col = unpack(val)
		if self:pieces_remaining() <= threshold then
			colour = col
		end
	end
	print(tostr(self:pieces_remaining()), x, y, colour)
end

function sand:draw_sand()
	for y=0,15 do
		for x=0,15 do
			local tile = {x=x, y=y}
			if self:tile_is_sand(tile) then
				local sprite = self.sprites.settled
				if y < 16 and not tile_is_solid(below(tile)) then
					sprite = self.sprites.falling
				end
				local pos = pixels(tile)
				spr(sprite, pos.x, pos.y)
			end
		end
	end
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
