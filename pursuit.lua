pursuit = {
	-- config
	movement_speed_pixels_per_second = {  -- !!! {num_flips, speed}; must be ascending !!!
		{1, 2},
		{10, 5}
	},
	start_pos = {x=64, y=-8},
	seconds_before_spawning = 30,
	catch_radius_pixels = 3,

	sprites = {020,021},
	sprite_cycle_period_seconds = 0.7,
	spawn_sound = 006
}

function pursuit:flips_needed_to_spawn()
	return self.movement_speed_pixels_per_second[1][1]
end

function pursuit:spawn()
	sfx(self.spawn_sound)
	return {
		-- state
		pos = shallow_copy(pursuit.start_pos),
		facing = "right",
		t_spawned = time(),
		t_last_update = time(),

		-- methods
		speed = function(self)
			local s = state.times_flipped
			local lerp_from = nil
			local lerp_to = nil
			for candidate in all(pursuit.movement_speed_pixels_per_second) do
				if candidate[1] > s then
					lerp_to = candidate
					break
				else
					lerp_from = candidate
				end
			end

			if lerp_from == nil then
				return nil
			end
			if lerp_to == nil then
				return pursuit.movement_speed_pixels_per_second[#pursuit.movement_speed_pixels_per_second][2]
			end

			if lerp_from == lerp_to then
				return lerp_to[2]
			end

			local progress = max(0, min(1, (s - lerp_from[1]) / (lerp_to[1] - lerp_from[1])))
			local res = progress * (lerp_to[2] - lerp_from[2]) + lerp_from[2]
			return res
		end,

		update = function(self)
			local now = time()
			local spd = self:speed() * (now - self.t_last_update)
			self.t_last_update = now

			local pc = player:centre()
			local dx = pc.x - (self.pos.x + 4)
			local dy = pc.y - (self.pos.y + 4)

			if sqrt(dx * dx + dy * dy) < pursuit.catch_radius_pixels then
				lose("you were caught by the demon!")
			end

			local angle = atan2(dx, dy)
			local vx = spd * cos(angle)
			local vy = spd * sin(angle)

			if vx > 0 then
				self.facing = "right"
			elseif vx < 0 then
				self.facing = "left"
			end

			self.pos.x += vx
			self.pos.y += vy
		end,

		draw = function(self)
			spr(sprite.cycling(pursuit.sprites, pursuit.sprite_cycle_period_seconds, time() - self.t_spawned),
				self.pos.x, self.pos.y, 1, 1, self.facing == "left", false)
		end
	}
end
