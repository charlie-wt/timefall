player = {
	-- params ----------------
	run_speed = 3,
	jump_height = 30,
	gravity = 0.8,
	acceleration_frames = 4,
	start_pos = {x=64, y=8},
	sprites = {
		fallback=001
	},

	-- state -----------------
	pos = {x=0,y=0},
	vel = {x=0,y=0},
	grounded = false,
	was_grounded = grounded,
	accelerated_for_frames = 0,
	collision_x = 0,
	collision_y = 0,
}

function player:init()
	self.pos = shallow_copy(self.start_pos)
	self.vel = {x=0, y=0}
	self.accelerated_for_frames = 0
end

-- get the list of tiles ({x,y}) that the player will occupy next frame, if
-- their velocity is `vl` (defaults to `vel`)
function player:tiles(vl)
	local vl = vl or self.vel
	local future_pos = {
		x=self.pos.x+vl.x,
		y=self.pos.y+vl.y
	}

	local future_tiles = {
		lft=flr(future_pos.x/8),
		rgt=ceil(future_pos.x/8),
		top=flr(future_pos.y/8),
		btm=ceil(future_pos.y/8)
	}

	local tiles = {}
	for j=future_tiles.top, future_tiles.btm do
		for i=future_tiles.lft, future_tiles.rgt do
			add(tiles, {x=i,y=j})
		end
	end

	return tiles
end

function player:jump_speed()
	return sqrt(2 * self.gravity * self.jump_height)
end

function player:input()
	-- x
	if btn(0) then
		self.accelerated_for_frames -= 2
	elseif btn(1) then
		self.accelerated_for_frames += 2
	end

	if self.accelerated_for_frames > 0 then
		self.accelerated_for_frames -= 1
	elseif self.accelerated_for_frames < 0 then
		self.accelerated_for_frames += 1
	end
	self.accelerated_for_frames = min(self.acceleration_frames, self.accelerated_for_frames)
	self.accelerated_for_frames = max(-self.acceleration_frames, self.accelerated_for_frames)
	local w = self.accelerated_for_frames / self.acceleration_frames
	self.vel.x = self.run_speed * w

	-- y
	if btn(2) and self.grounded then
		self.vel.y = -self:jump_speed()
	end
end

function player:apply_gravity()
	self.vel.y += self.gravity
end

-- get the amount by which the player is colliding in the x dimension.
-- +ve means collider on *left*
function player:get_collision_x()
	local vl = {x=self.vel.x, y=0}
	local future_pos = {
		x=self.pos.x+vl.x,
		y=self.pos.y+vl.y
	}

	for tile in all(self:tiles(vl)) do
		if (not tile_is_solid(tile)) goto cont

		local lft = tile.x*8
		local rgt = (tile.x+1)*8

		sand:try_shunt(tile, self.vel.x)
		if self.vel.x > 0 then
			return lft - (future_pos.x+8)
		else
			return rgt - future_pos.x
		end
		::cont::
	end
	return 0
end

-- get the amount by which the player is colliding in the y dimension.
-- +ve means collider *above*
-- only counts fully solid tiles, ie. not top-solid.
function player:get_collision_y()
	local vl = {x=0, y=self.vel.y}
	local future_pos = {x=self.pos.x, y=self.pos.y+vl.y}

	for tile in all(self:tiles(vl)) do
		if (not tile_is_solid(tile)) goto cont

		local top = tile.y*8
		local btm = (tile.y+1)*8

		if self.vel.y > 0 then
			return top - (future_pos.y+8)
		else
			-- if sand:tile_is_sand(tile) then
			-- 	self:die()
			-- end
			return btm - future_pos.y
		end
		::cont::
	end
	return 0
end

function player:move()
	self.collision_y = self:get_collision_y()
	self.pos.y += self.vel.y + self.collision_y

	self.collision_x = self:get_collision_x()
	self.pos.x += self.vel.x + self.collision_x

	was_grounded = self.grounded
	self.grounded = self.collision_y < 0

	if self.collision_x != 0 then
		self.vel.x = 0
		self.accelerated_for_frames = 0
	end
	if (self.collision_y != 0) self.vel.y = 0
end

function player:update()
	self:input()
	self:apply_gravity()
	self:move()
end

function player:dbg_txt()
	local res = {}

	local dx = "➡️ "
	if (self.collision_x > 0) dx = "⬅️ "
	add(res, dx..abs(self.collision_x))
	local dy = "⬇️ "
	if (self.collision_y > 0) dy = "⬆️ "
	add(res, dy..abs(self.collision_y))
	add(res, "pos:\t"..self.pos.x.."\t\t"..self.pos.y)
	add(res, "vel:\t"..self.vel.x.."\t\t"..self.vel.y)
	if (self.grounded) add(res, "grounded")

	return res
end

function player:draw()
	-- TODO #finish
	local current_sprite = self.sprites.fallback
	spr(current_sprite, self.pos.x, self.pos.y)
end
