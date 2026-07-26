local rspr_clear_col=0
-- sx: source spritesheet x (pixels)
-- sy: source spritesheet y (pixels)
-- x: spritesheet buffer space x
-- y: spritesheet buffer space y
-- a: angle in [0,1]
-- w: width in tiles (which should equal height)
function rspr(sx,sy,x,y,a,w)
	local ca, sa = cos(a), sin(a)
	local srcx, srcy, addr, pixel_pair
	local ddx0, ddy0=ca, sa
	local mask = shl(0xfff8,(w-1))
	w *= 4
	ca *= w - 0.5
	sa *= w - 0.5
	local dx0, dy0 = sa-ca+w, -ca-sa+w
	w = 2 * w - 1
	for ix=0,w do
		srcx, srcy = dx0, dy0
		for iy=0,w do
			if band(bor(srcx, srcy), mask)==0 then
				local c = sget(sx + srcx, sy + srcy)
				sset(x + ix, y + iy, c)
			else
				sset(x + ix, y + iy, rspr_clear_col)
			end
			srcx -= ddy0
			srcy += ddx0
		end
		dx0 += ddx0
		dy0 += ddy0
	end
end

local rotation_sprite_buffer = {x=64, y=64}
local full_sprite_w_tiles = 8
local effective_sprite_w_tiles = 4

function draw_hourglass_top()
	local sprite_loc = {x=00, y=24}

	local angle = time() / 3
	local scale = 1.5--2 + sin(time() / 3)

	local orbit_offset = {
		x = sin(angle),
		y = -cos(angle)
	}

	local screen_pos = {
		x = -(full_sprite_w_tiles * scale) * 4 + effective_sprite_w_tiles * scale * orbit_offset.x * 8,
		y = -(full_sprite_w_tiles * scale) * 4 + effective_sprite_w_tiles * scale * orbit_offset.y * 8
	}

	-- rotate sprite (using another sprite location as buffer)
	rspr(sprite_loc.x,sprite_loc.y,
	     rotation_sprite_buffer.x,rotation_sprite_buffer.y,
	     -angle, full_sprite_w_tiles)

	-- display sprite (inc. scaling)
	-- spritesheet_{x,y}, sprite_{w,h}_pixels, screen_pos_{x,y}, screen_{w,h}_tiles, flip_{x,y}
	sspr(rotation_sprite_buffer.x, rotation_sprite_buffer.y,
	     full_sprite_w_tiles * 8, full_sprite_w_tiles * 8,
	     screen_pos.x, screen_pos.y,
	     full_sprite_w_tiles * 8 * scale, full_sprite_w_tiles * 8 * scale)
end

function draw_hourglass_bottom()
	local sprite_loc = {x=64, y=00}

	local angle = (time() / 3)
	local scale = 1.5--2 + sin(time() / 3)

	local screen_pos = {
		x = -(full_sprite_w_tiles * scale) * 4,
		y = -(full_sprite_w_tiles * scale) * 4
	}

	-- rotate sprite (using another sprite location as buffer)
	rspr(sprite_loc.x,sprite_loc.y,
	     rotation_sprite_buffer.x,rotation_sprite_buffer.y,
	     -angle, full_sprite_w_tiles)

	-- display sprite (inc. scaling)
	-- spritesheet_{x,y}, sprite_{w,h}_pixels, screen_pos_{x,y}, screen_{w,h}_tiles, flip_{x,y}
	sspr(rotation_sprite_buffer.x, rotation_sprite_buffer.y,
	     full_sprite_w_tiles * 8, full_sprite_w_tiles * 8,
	     screen_pos.x, screen_pos.y,
	     full_sprite_w_tiles * 8 * scale, full_sprite_w_tiles * 8 * scale)
end
