-- lua_modules/physics_sim.lua
-- Discrete Physics, Ballistics, and Collision Simulation for Potato War

local constants = require("lua_modules.constants")

local M = {}

-- Update a potato unit's physics
function M.update_potato(p, dt, terrain)
	if not p.is_alive then
		return
	end

	local check_radius = constants.POTATO_RADIUS

	-- Gravity and friction
	if not p.is_grounded then
		p.vel.y = math.max(-constants.MAX_FALL_SPEED, p.vel.y - constants.GRAVITY * dt)
		p.vel.x = p.vel.x * math.max(0, 1.0 - 2.0 * dt) -- air drag
	else
		-- Strong ground friction to prevent micro-sliding
		p.vel.x = p.vel.x * math.max(0, 1.0 - 16.0 * dt)
		if math.abs(p.vel.x) < 2.0 then
			p.vel.x = 0
		end
	end

	-- Integrate horizontal position
	local new_x = p.pos.x + p.vel.x * dt
	local new_y = p.pos.y

	-- Check world horizontal bounds
	if new_x < check_radius then
		new_x = check_radius
		p.vel.x = 0
	elseif new_x > constants.WORLD_WIDTH - check_radius then
		new_x = constants.WORLD_WIDTH - check_radius
		p.vel.x = 0
	end

	-- Check water level (drowning)
	if p.pos.y < constants.WATER_LEVEL or new_y < constants.WATER_LEVEL then
		p.pos.x = new_x
		p.pos.y = math.min(p.pos.y, constants.WATER_LEVEL - 5)
		p.hp = 0
		p.is_alive = false
		p.is_grounded = false
		return "drowned"
	end

	if not p.is_grounded then
		-- Airborne state
		new_y = p.pos.y + p.vel.y * dt

		local ground_y = terrain.get_smooth_ground_y(new_x, 6.0)
		local target_standing_y = ground_y + check_radius

		-- Check landing on ground
		if p.vel.y <= 0 and new_y <= (target_standing_y + 2.0) then
			new_y = target_standing_y
			p.vel.y = 0
			p.vel.x = p.vel.x * 0.4
			p.is_grounded = true
		else
			-- Check side/head collision with solid terrain while airborne
			local hit, nx, ny = terrain.check_circle_collision(new_x, new_y, check_radius)
			if hit then
				local dot = p.vel.x * nx + p.vel.y * ny
				if dot < 0 then
					p.vel.x = (p.vel.x - dot * nx) * 0.4
					p.vel.y = (p.vel.y - dot * ny) * 0.4
				end
				if ny > 0.55 and p.vel.y <= 0 then
					p.is_grounded = true
					p.vel.y = 0
					new_y = target_standing_y
				end
			end
		end
	else
		-- Grounded state
		local ground_y = terrain.get_smooth_ground_y(new_x, 6.0)
		local target_standing_y = ground_y + check_radius

		-- If potato got upward vertical impulse (e.g. explosion blast or jump), become airborne
		if p.vel.y > 5.0 then
			p.is_grounded = false
			new_y = p.pos.y + p.vel.y * dt
		else
			-- Check if ground fell away below (e.g. destroyed by blast)
			if (p.pos.y - target_standing_y) > 8.0 then
				p.is_grounded = false
				p.vel.y = -20.0
				new_y = p.pos.y + p.vel.y * dt
			else
				-- Stable ground resting / slope following:
				-- Perfectly lock vertical height to smoothed ground surface without micro-vibrations
				new_y = target_standing_y
				p.vel.y = 0
			end
		end
	end

	p.pos.x = new_x
	p.pos.y = new_y
end

-- Walk potato along terrain slope
function M.walk_potato(p, dir, dt, terrain)
	if not p.is_alive or not p.is_grounded then
		return
	end

	p.facing = dir
	local walk_dist = dir * constants.POTATO_WALK_SPEED * dt
	local target_x = p.pos.x + walk_dist

	-- Clamp bounds
	if target_x < constants.POTATO_RADIUS or target_x > constants.WORLD_WIDTH - constants.POTATO_RADIUS then
		return
	end

	local curr_gy = terrain.get_smooth_ground_y(p.pos.x, 6.0)
	local target_gy = terrain.get_smooth_ground_y(target_x, 6.0)

	-- Check slope step-up limit (cannot climb walls steeper than 12px step)
	if (target_gy - curr_gy) > 12.0 then
		p.vel.x = 0
		return
	end

	p.pos.x = target_x
	p.pos.y = target_gy + constants.POTATO_RADIUS
end

-- Jump potato
function M.jump_potato(p, allow_midair_count)
	allow_midair_count = allow_midair_count or 1
	if p.is_grounded then
		p.air_jumps = 0
	end
	if p.is_alive and (p.is_grounded or (p.air_jumps or 0) < allow_midair_count) then
		p.air_jumps = (p.air_jumps or 0) + 1
		p.vel.y = constants.POTATO_JUMP_IMPULSE
		p.vel.x = p.facing * 40.0
		p.is_grounded = false
		return true
	end
	return false
end

-- Apply explosive blast to a potato
function M.apply_blast(p, blast_x, blast_y, blast_radius, blast_force, max_damage)
	if not p.is_alive then
		return 0
	end

	local dx = p.pos.x - blast_x
	local dy = p.pos.y - blast_y
	local dist = math.sqrt(dx * dx + dy * dy)

	-- Effective radius accounts for potato body radius so hits near feet/edges deal proper damage
	local effective_radius = blast_radius + constants.POTATO_RADIUS * 0.85

	if dist < effective_radius then
		local factor = math.max(0.15, 1.0 - (dist / effective_radius))
		local dmg = math.max(5, math.floor(max_damage * factor))

		-- Normalized impulse vector with upward lift bias
		local len = math.max(0.01, dist)
		local dir_x = dx / len
		local dir_y = (dy + 10) / (len + 10)
		local n_len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
		dir_x = dir_x / n_len
		dir_y = dir_y / n_len

		p.vel.x = p.vel.x + dir_x * blast_force * factor
		p.vel.y = p.vel.y + dir_y * blast_force * factor
		p.is_grounded = false

		p.hp = math.max(0, p.hp - dmg)
		if p.hp <= 0 then
			p.is_alive = false
		end
		return dmg
	end
	return 0
end

-- Check segment-to-circle intersection for fast moving projectiles
local function check_segment_circle(x0, y0, x1, y1, cx, cy, radius)
	local dx = x1 - x0
	local dy = y1 - y0
	local len2 = dx * dx + dy * dy
	local r2 = radius * radius

	if len2 <= 0.0001 then
		local d2 = (cx - x0) * (cx - x0) + (cy - y0) * (cy - y0)
		if d2 <= r2 then
			return true, x0, y0, math.sqrt(d2)
		end
		return false
	end

	-- Project circle center onto segment
	local t = ((cx - x0) * dx + (cy - y0) * dy) / len2
	t = math.max(0, math.min(1, t))

	local qx = x0 + t * dx
	local qy = y0 + t * dy

	local dist2 = (cx - qx) * (cx - qx) + (cy - qy) * (cy - qy)
	if dist2 <= r2 then
		local dist_from_start = math.sqrt((qx - x0) * (qx - x0) + (qy - y0) * (qy - y0))
		return true, qx, qy, dist_from_start
	end
	return false
end

-- Update projectile physics and collisions
function M.update_projectile(proj, dt, terrain, potatoes)
	if not proj.is_active then
		return "inactive"
	end

	proj.fuse_timer = proj.fuse_timer - dt

	-- Fuse timeout check (e.g. Grenade or Holy Grenade)
	if proj.fuse_timer <= 0 then
		return "explode", proj.pos.x, proj.pos.y
	end

	-- If projectile is resting on ground
	if proj.is_resting then
		-- Check collision with potatoes while resting
		for _, p in ipairs(potatoes) do
			if p.is_alive and (proj.owner_id == nil or p.id ~= proj.owner_id or proj.fuse_timer < proj.weapon.fuse_time - 0.2) then
				local pdx = proj.pos.x - p.pos.x
				local pdy = proj.pos.y - p.pos.y
				if pdx * pdx + pdy * pdy < (constants.POTATO_RADIUS + 4) * (constants.POTATO_RADIUS + 4) then
					return "explode", proj.pos.x, proj.pos.y, p
				end
			end
		end

		local gy = terrain.get_smooth_ground_y(proj.pos.x, 3.0)
		local ground_target_y = gy + 4.0
		-- If ground beneath was destroyed, resume falling
		if (proj.pos.y - ground_target_y) > 6.0 then
			proj.is_resting = false
			proj.vel.y = -20.0
		else
			proj.pos.y = ground_target_y
			proj.vel.x = 0
			proj.vel.y = 0
			return "resting", proj.pos.x, proj.pos.y
		end
	end

	-- Gravity
	local grav = constants.GRAVITY * (proj.weapon.gravity_mult or 1.0)
	proj.vel.y = proj.vel.y - grav * dt

	-- Step path
	local x0 = proj.pos.x
	local y0 = proj.pos.y
	local next_x = x0 + proj.vel.x * dt
	local next_y = y0 + proj.vel.y * dt

	-- Water check
	if next_y < constants.WATER_LEVEL then
		return "water", next_x, constants.WATER_LEVEL
	end

	-- 1. Check continuous segment collision with all living potatoes (anti-tunneling)
	local hit_potato = nil
	local closest_potato_dist = 999999
	local potato_hx, potato_hy = 0, 0

	for _, p in ipairs(potatoes) do
		if p.is_alive and (proj.owner_id == nil or p.id ~= proj.owner_id or proj.fuse_timer < proj.weapon.fuse_time - 0.1) then
			local hit_p, px, py, p_dist = check_segment_circle(x0, y0, next_x, next_y, p.pos.x, p.pos.y, constants.POTATO_RADIUS + 3)
			if hit_p and p_dist < closest_potato_dist then
				closest_potato_dist = p_dist
				hit_potato = p
				potato_hx = px
				potato_hy = py
			end
		end
	end

	-- 2. Check collision with terrain along step path
	local terrain_hit, thx, thy, nx, ny = terrain.raycast(x0, y0, next_x, next_y)
	local terrain_dist = terrain_hit and math.sqrt((thx - x0) * (thx - x0) + (thy - y0) * (thy - y0)) or 999999

	-- If potato was hit before terrain:
	if hit_potato and closest_potato_dist <= terrain_dist then
		return "explode", potato_hx, potato_hy, hit_potato
	end

	-- Otherwise, if terrain was hit:
	if terrain_hit then
		if proj.weapon.bounciness and proj.weapon.bounciness > 0.1 then
			-- Bounce (Grenade / Holy Grenade)
			local dot = proj.vel.x * nx + proj.vel.y * ny
			if dot < 0 then
				proj.vel.x = (proj.vel.x - (1.0 + proj.weapon.bounciness) * dot * nx) * proj.weapon.friction
				proj.vel.y = (proj.vel.y - (1.0 + proj.weapon.bounciness) * dot * ny) * proj.weapon.friction
			end

			proj.pos.x = thx + nx * 1.0
			proj.pos.y = thy + ny * 1.0
			proj.bounces = (proj.bounces or 0) + 1

			local speed = math.sqrt(proj.vel.x * proj.vel.x + proj.vel.y * proj.vel.y)
			-- Rest condition: low speed and landing on upward-facing ground
			if (speed < 35.0 and ny > 0.35) or (speed < 15.0) then
				proj.is_resting = true
				proj.vel.x = 0
				proj.vel.y = 0
				local gy = terrain.get_smooth_ground_y(proj.pos.x, 3.0)
				proj.pos.y = gy + 4.0
			end
			return "bounce", thx, thy
		else
			-- Explode on impact (Rifle / Rocket / Burst / Shotgun / Molotov)
			return "explode", thx, thy
		end
	end

	proj.pos.x = next_x
	proj.pos.y = next_y
	return "flying", next_x, next_y
end

-- Calculate ballistic trajectory points for Angry Birds slingshot guide
function M.calculate_trajectory(start_x, start_y, vel_x, vel_y, weapon, terrain, max_points)
	max_points = max_points or 18
	local points = {}
	local curr_x = start_x
	local curr_y = start_y
	local vx = vel_x
	local vy = vel_y
	local dt = 0.045
	local grav = constants.GRAVITY * (weapon.gravity_mult or 1.0)

	for i = 1, max_points do
		vy = vy - grav * dt
		local nx = curr_x + vx * dt
		local ny = curr_y + vy * dt

		if ny < constants.WATER_LEVEL or nx < 0 or nx > constants.WORLD_WIDTH then
			table.insert(points, { x = nx, y = math.max(constants.WATER_LEVEL, ny) })
			break
		end

		local hit, hx, hy = terrain.raycast(curr_x, curr_y, nx, ny)
		if hit then
			table.insert(points, { x = hx, y = hy })
			break
		end

		table.insert(points, { x = nx, y = ny })
		curr_x = nx
		curr_y = ny
	end

	return points
end

-- Full simulated shot trajectory and impact point prediction for Bot AI
function M.simulate_shot(start_x, start_y, vel_x, vel_y, weapon, terrain, potatoes, owner_id)
	potatoes = potatoes or {}
	local curr_x = start_x
	local curr_y = start_y
	local vx = vel_x
	local vy = vel_y
	local dt = 0.035
	local grav = constants.GRAVITY * (weapon.gravity_mult or 1.0)
	local fuse_timer = weapon.fuse_time or 3.0
	local max_steps = math.ceil(math.min(3.5, fuse_timer + 0.5) / dt)
	local bounciness = weapon.bounciness or 0
	local friction = weapon.friction or 0.8
	local bounces = 0
	local is_resting = false
	local path = { { x = curr_x, y = curr_y } }

	for step = 1, max_steps do
		fuse_timer = fuse_timer - dt
		if fuse_timer <= 0 then
			return curr_x, curr_y, "fuse", nil, path
		end

		-- Check potato hit
		for _, p in ipairs(potatoes) do
			if p.is_alive and (owner_id == nil or p.id ~= owner_id or fuse_timer < (weapon.fuse_time or 3.0) - 0.2) then
				local pdx = curr_x - p.pos.x
				local pdy = curr_y - p.pos.y
				if pdx * pdx + pdy * pdy < (constants.POTATO_RADIUS + 6) * (constants.POTATO_RADIUS + 6) then
					return curr_x, curr_y, "potato", p, path
				end
			end
		end

		if is_resting then
			local gy = terrain.get_smooth_ground_y(curr_x, 3.0)
			curr_y = gy + 4.0
			-- continue resting until fuse expires
		else
			vy = vy - grav * dt
			local next_x = curr_x + vx * dt
			local next_y = curr_y + vy * dt

			if next_y < constants.WATER_LEVEL then
				table.insert(path, { x = next_x, y = constants.WATER_LEVEL })
				return next_x, constants.WATER_LEVEL, "water", nil, path
			end

			local hit, hx, hy, nx, ny = terrain.raycast(curr_x, curr_y, next_x, next_y)
			if hit then
				table.insert(path, { x = hx, y = hy })
				if bounciness > 0.1 and bounces < 4 then
					local dot = vx * nx + vy * ny
					if dot < 0 then
						vx = (vx - (1.0 + bounciness) * dot * nx) * friction
						vy = (vy - (1.0 + bounciness) * dot * ny) * friction
					end
					curr_x = hx + nx * 1.5
					curr_y = hy + ny * 1.5
					bounces = bounces + 1

					local speed = math.sqrt(vx * vx + vy * vy)
					if (speed < 35.0 and ny > 0.35) or (speed < 15.0) then
						is_resting = true
						vx = 0
						vy = 0
					end
				else
					return hx, hy, "terrain", nil, path
				end
			else
				curr_x = next_x
				curr_y = next_y
				table.insert(path, { x = curr_x, y = curr_y })
			end
		end
	end

	return curr_x, curr_y, "timeout", nil, path
end

return M
