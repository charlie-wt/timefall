player = {
	-- params ----------------
	run_speed = 3,
	max_jump_height = 30,
	gravity = 0.8,
	acceleration_frames = 4,
	min_jump_hold_time = 0.1,
	start_pos = {x=64, y=8},
	sprites = {
		fallback=001,
		standing_right=002,
		running_right={003,004},
		jumping_right=005,
		falling_right=006,
	},
	running_frames_cycle_time_seconds = 0.25,
	collision_size_pixels = 7.5,

	-- state -----------------
	pos = {x=0,y=0},
	vel = {x=0,y=0},
	grounded = false,
	was_grounded = grounded,
	accelerated_for_frames = 0,
	last_facing = nil,
	t_started_running = nil,
	t_started_jumping = nil,

	--- (just for dbg)
	collision_x = 0,
	collision_y = 0,
	pre_collision_vel = {x=0,y=0}
}

function player:init()
	self.pos = shallow_copy(self.start_pos)
	self.vel = {x=0, y=0}
	self.accelerated_for_frames = 0
	self.last_facing = "right"
	self.t_started_running = nil
	self.t_started_jumping = nil
end

function player:centre()
	return {x=self.pos.x, y=self.pos.y - (self.collision_size_pixels/2 - 1)}
end

function player:bounds(vl)
	local p = self.pos
	if vl ~= nil then p = {x=p.x+vl.x, y=p.y+vl.y} end
	return {
		lft=p.x - self.collision_size_pixels/2,
		rgt=p.x + self.collision_size_pixels/2 - 1,
		top=p.y - (self.collision_size_pixels - 1),
		btm=p.y
	}
end

-- --- rect is {lft, rgt, top, btm}
-- function player:colliding_with(rect)
-- 	local b = self:bounds()
-- 	if b.lft >= rect.lft and
-- 	   b.rgt <= rect.rgt and
-- 	   b.top >= rect.top and
-- 	   b.btm <= rect.btm then
-- 	   return true  -- player contained in rect
-- 	end
-- 	if b.lft <= rect.rgt and
-- 	   b.rgt >= rect.lft and
-- 	   b.top <= rect.btm and
-- 	   b.btm >= rect.top then
-- 	   return true  -- player intersecting with rect
-- 	end
-- 	return false
-- end

-- get the list of tiles ({x,y}) that the player will occupy next frame, if
-- their velocity is `vl` (defaults to `vel`)
function player:tiles(vl)
	local vl = vl or self.vel
	local future_pos = {
		x=self.pos.x+vl.x,
		y=self.pos.y+vl.y
	}

	local future_tiles = tiles(player:bounds(vl))

	local tiles = {}
	for j=future_tiles.top, future_tiles.btm do
		for i=future_tiles.lft, future_tiles.rgt do
			add(tiles, {x=i,y=j})
		end
	end

	return tiles
end

function player:max_jump_speed()
	return sqrt(2 * self.gravity * self.max_jump_height)
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
	local now = time()
	if self.grounded then
		if btn(2) then
			-- jump
			self.vel.y = -self:max_jump_speed()
			sfx(003)
			self.t_started_jumping = now
		else
			self.t_started_jumping = nil
		end
	end

	if (not btn(2)) and
	   (self.t_started_jumping ~= nil and now - self.t_started_jumping > self.min_jump_hold_time) then
		self.vel.y = max(0, self.vel.y)
		self.t_started_jumping = nil
	end
end

function player:apply_gravity()
	self.vel.y += self.gravity
end

-- get the amount by which the player is colliding in the x dimension.
-- +ve means collider on *left*
function player:get_collision_x()
	local vl = {x=self.vel.x, y=0}
	local future_bounds = player:bounds(vl)

	for tile in all(self:tiles(vl)) do
		if (not tile_is_solid(tile)) goto contx

		local lft = pixels(tile.x) - 0.1
		local rgt = pixels(tile.x + 1) + 0.1

		sand:try_shunt(tile, self.vel.x)
		if self.vel.x > 0 then
			return lft - future_bounds.rgt
		else
			return rgt - future_bounds.lft
		end
		::contx::
	end
	return 0
end

-- get the amount by which the player is colliding in the y dimension.
-- +ve means collider *above*
-- only counts fully solid tiles, ie. not top-solid.
function player:get_collision_y()
	local vl = {x=0, y=self.vel.y}
	local future_bounds = player:bounds(vl)

	for tile in all(self:tiles(vl)) do
		if (not tile_is_solid(tile)) goto conty

		local top = pixels(tile.y) - 0.1
		local btm = pixels(tile.y + 1) + 0.1

		if self.vel.y > 0 then
			return top - future_bounds.btm
		else
			return btm - future_bounds.top
		end
		::conty::
	end
	return 0
end

function player:move()
	self.pre_collision_vel = self.vel

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

	if self.vel.x > 0 then
		self.last_facing = "right"
	elseif self.vel.x < 0 then
		self.last_facing = "left"
	end
end

function player:draw()
	local current_sprite = self.sprites.fallback

	if self.grounded then
		if self.vel.x == 0 then
			self.t_started_running = nil
			current_sprite = self.sprites.standing_right
		else
			local now = time()
			if self.t_started_running == nil then
				self.t_started_running = now
			end

			current_sprite = sprite.cycling(
				self.sprites.running_right,
				self.running_frames_cycle_time_seconds,
				now - self.t_started_running
			)
		end
	else
		if self.vel.y < 0 then
			current_sprite = self.sprites.jumping_right
		elseif self.vel.y > 0 then
			current_sprite = self.sprites.falling_right
		else
			current_sprite = self.sprites.standing_right
		end
	end

	local should_flip = false
	if self.last_facing == "left" then
		should_flip = true
	end

	spr(current_sprite, self.pos.x - 4, ceil(self.pos.y) - 8, 1, 1, should_flip, false)
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
