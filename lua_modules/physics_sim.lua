-- lua_modules/physics_sim.lua
-- Discrete Physics, Ballistics, Dynamic Wind, and Elemental States for Potato War
-- Includes slope movement, ceiling collision, wind drift, and status effect integration.

local constants = require("lua_modules.constants")

local M = {}

-- Helper to extract x/y components from table or vmath vector
local function get_wind_components(wind_vector)
	if not wind_vector then
		return 0, 0
	end
	local wx = wind_vector.x or 0
	local wy = wind_vector.y or 0
	return wx, wy
end

-- Update a potato unit's physics (accounting for mass, wind drift, and statuses)
function M.update_potato(p, dt, terrain, wind_vector)
	if not p.is_alive then
		return
	end

	local check_radius = constants.POTATO_RADIUS
	local mass = math.max(0.5, p.mass or 1.0)
	local is_glued = (p.statuses and p.statuses.glued and p.statuses.glued.duration > 0) or p.is_glued
	local is_concussed = (p.statuses and p.statuses.concussed and p.statuses.concussed.duration > 0) or p.is_concussed

	-- Gravity and friction
	if not p.is_grounded then
		p.vel.y = math.max(-constants.MAX_FALL_SPEED, p.vel.y - constants.GRAVITY * dt)
		local drag_rate = is_glued and 4.0 or 2.0
		p.vel.x = p.vel.x * math.max(0, 1.0 - drag_rate * dt) -- air drag

		-- Dynamic horizontal wind drift on airborne potatoes based on mass
		local wx, _ = get_wind_components(wind_vector)
		if math.abs(wx) > 0.01 then
			local wind_accel = (wx * 22.0) / mass
			p.vel.x = p.vel.x + wind_accel * dt
		end
	else
		-- Ground friction (stronger if glued)
		local ground_fric = is_glued and 28.0 or 16.0
		p.vel.x = p.vel.x * math.max(0, 1.0 - ground_fric * dt)
		if math.abs(p.vel.x) < 2.0 then
			p.vel.x = 0
		end

		-- Concussed wobble on ground
		if is_concussed and math.abs(p.vel.x) > 1.0 then
			p.vel.x = p.vel.x + (math.random() - 0.5) * 6.0
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

	-- Check water level (splash rescue or drowning)
	if p.pos.y < constants.WATER_LEVEL or new_y < constants.WATER_LEVEL then
		if p.hp > 30 then
			-- Water Splash Rescue: takes 30 water damage and bounces back up toward the map!
			p.hp = p.hp - 30
			local to_center_dir = (new_x < constants.WORLD_WIDTH * 0.5) and 1 or -1
			p.vel.y = 380.0
			p.vel.x = to_center_dir * 160.0
			p.pos.y = constants.WATER_LEVEL + 6
			p.is_grounded = false
			return "water_splash"
		else
			p.pos.x = new_x
			p.pos.y = math.min(p.pos.y, constants.WATER_LEVEL - 5)
			p.hp = 0
			p.is_alive = false
			p.is_grounded = false
			return "drowned"
		end
	end

	if not p.is_grounded then
		-- Airborne state
		new_y = p.pos.y + p.vel.y * dt

		local ground_y = terrain.get_smooth_ground_y(new_x, 6.0, p.pos.y + 6.0)
		local target_standing_y = ground_y + check_radius

		-- Check landing on ground
		if p.vel.y <= 0 and new_y <= (target_standing_y + 2.0) and p.pos.y >= (ground_y - 4.0) then
			new_y = target_standing_y
			p.vel.y = 0
			p.vel.x = p.vel.x * 0.4
			p.is_grounded = true
		else
			-- Check side/head/ceiling collision with solid terrain while airborne
			local hit, nx, ny = terrain.check_circle_collision(new_x, new_y, check_radius)
			if hit then
				local dot = p.vel.x * nx + p.vel.y * ny
				if dot < 0 then
					p.vel.x = (p.vel.x - dot * nx) * 0.4
					p.vel.y = (p.vel.y - dot * ny) * 0.4
				end
				if ny > 0.55 and p.vel.y <= 0 then
					-- Landed on terrain shelf
					p.is_grounded = true
					p.vel.y = 0
					new_y = target_standing_y
				elseif ny < -0.45 and p.vel.y > 0 then
					-- Bonked head against ceiling or bridge underside!
					p.vel.y = -math.abs(p.vel.y) * 0.5
				end
			end
		end
	else
		-- Grounded state
		local ground_y = terrain.get_smooth_ground_y(new_x, 4.0, p.pos.y + 8.0)
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
			elseif (target_standing_y - p.pos.y) > 6.0 then
				-- Hit a wall or steep rise while moving along ground: block horizontal progress
				new_x = p.pos.x
				new_y = p.pos.y
				p.vel.x = 0
			else
				-- Stable ground resting / slope following:
				new_y = target_standing_y
				p.vel.y = 0
			end
		end
	end

	p.pos.x = new_x
	p.pos.y = new_y
end

-- Walk potato along terrain slope (accounts for glued, concussed, and class speed multipliers)
function M.walk_potato(p, dir, dt, terrain)
	if not p.is_alive then
		return
	end

	p.facing = dir

	-- Status modifiers
	local is_glued = (p.statuses and p.statuses.glued and p.statuses.glued.duration > 0) or p.is_glued
	local is_concussed = (p.statuses and p.statuses.concussed and p.statuses.concussed.duration > 0) or p.is_concussed
	local speed_mult = p.walk_speed_mult or 1.0

	if is_glued then
		speed_mult = speed_mult * 0.40 -- Cut speed by 60%
	end
	if is_concussed then
		speed_mult = speed_mult * 0.80 -- Cut speed by 20%
	end

	local base_speed = constants.POTATO_WALK_SPEED * speed_mult

	if not p.is_grounded then
		-- Air control while jumping
		p.vel.x = dir * base_speed * 0.85
		return
	end

	local radius = constants.POTATO_RADIUS
	local MAX_CLIMB_SLOPE = 1.05 -- ~46 degrees (standard Worms max walkable slope)
	local MAX_STEP_UP = 3.5      -- small voxel step-up limit (curbs, jagged pixels)

	-- 1. Wall collision check at body level
	local front_check_x = p.pos.x + dir * (radius * 0.75)
	if terrain.is_solid(front_check_x, p.pos.y) or terrain.is_solid(front_check_x, p.pos.y + 4.0) then
		p.vel.x = 0
		return
	end

	-- 2. Measure ground height under current position and ahead
	local curr_gy = terrain.get_smooth_ground_y(p.pos.x, 4.0, p.pos.y + 8.0)
	local look_ahead = 6.0
	local ahead_x = p.pos.x + dir * look_ahead
	local ahead_gy = terrain.get_smooth_ground_y(ahead_x, 4.0, p.pos.y + 8.0)
	local ahead_diff = ahead_gy - curr_gy

	if ahead_diff > MAX_STEP_UP then
		local slope = ahead_diff / look_ahead
		if slope > MAX_CLIMB_SLOPE then
			p.vel.x = 0
			return
		end
	end

	-- 3. Calculate movement speed along surface
	local slope_angle = math.atan2(math.max(0, ahead_diff), look_ahead)
	local slope_speed_mult = math.max(0.75, 1.0 - 0.25 * math.sin(slope_angle))
	local move_speed = base_speed * slope_speed_mult

	local ds = move_speed * dt
	local step_x = dir * ds * math.cos(slope_angle)
	local target_x = p.pos.x + step_x

	-- Clamp bounds
	if target_x < radius or target_x > constants.WORLD_WIDTH - radius then
		p.vel.x = 0
		return
	end

	-- 4. Check immediate step-up at target_x
	local target_gy = terrain.get_smooth_ground_y(target_x, 4.0, p.pos.y + 8.0)
	local step_diff = target_gy - curr_gy

	if step_diff > MAX_STEP_UP then
		local local_slope = step_diff / math.max(0.01, math.abs(step_x))
		if local_slope > MAX_CLIMB_SLOPE then
			p.vel.x = 0
			return
		end
	end

	-- 5. Walking off a cliff / ledge (steep drop)
	if (curr_gy - target_gy) > 8.0 then
		p.pos.x = target_x
		p.is_grounded = false
		p.vel.x = dir * base_speed * 0.75
		p.vel.y = -10.0
		return
	end

	-- 6. Apply smooth position update
	p.pos.x = target_x
	p.pos.y = target_gy + radius
end

-- Jump potato (glued status heavily dampens or blocks jumps)
function M.jump_potato(p, allow_midair_count)
	allow_midair_count = allow_midair_count or 1
	if p.is_grounded then
		p.air_jumps = 0
	end

	local is_glued = (p.statuses and p.statuses.glued and p.statuses.glued.duration > 0) or p.is_glued
	local jump_mult = (p.jump_mult or 1.0) * (is_glued and 0.40 or 1.0)

	if p.is_alive and (p.is_grounded or (p.air_jumps or 0) < allow_midair_count) then
		p.air_jumps = (p.air_jumps or 0) + 1
		p.vel.y = constants.POTATO_JUMP_IMPULSE * jump_mult
		p.vel.x = p.facing * (40.0 * (is_glued and 0.5 or 1.0))
		p.is_grounded = false
		return true
	end
	return false
end

-- Apply explosive blast to a potato (mass dampens knockback)
function M.apply_blast(p, blast_x, blast_y, blast_radius, blast_force, max_damage)
	if not p.is_alive then
		return 0
	end

	local dx = p.pos.x - blast_x
	local dy = p.pos.y - blast_y
	local dist = math.sqrt(dx * dx + dy * dy)

	local effective_radius = blast_radius + constants.POTATO_RADIUS * 0.85

	if dist < effective_radius then
		local factor = math.max(0.15, 1.0 - (dist / effective_radius))
		local dmg = math.max(5, math.floor(max_damage * factor))

		local len = math.max(0.01, dist)
		local dir_x = dx / len
		local dir_y = (dy + 10) / (len + 10)
		local n_len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
		dir_x = dir_x / n_len
		dir_y = dir_y / n_len

		local mass = math.max(0.5, p.mass or 1.0)
		local eff_force = (blast_force * factor) / mass

		p.vel.x = p.vel.x + dir_x * eff_force
		p.vel.y = p.vel.y + dir_y * eff_force
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

-- Update projectile physics, collisions, and dynamic wind
function M.update_projectile(proj, dt, terrain, potatoes, wind_vector)
	if not proj.is_active then
		return "inactive"
	end

	proj.fuse_timer = proj.fuse_timer - dt

	-- Fuse timeout check
	if proj.fuse_timer <= 0 then
		return "explode", proj.pos.x, proj.pos.y
	end

	-- If projectile is resting on ground
	if proj.is_resting then
		for _, p in ipairs(potatoes) do
			if p.is_alive and (proj.owner_id == nil or p.id ~= proj.owner_id or proj.fuse_timer < proj.weapon.fuse_time - 0.2) then
				local pdx = proj.pos.x - p.pos.x
				local pdy = proj.pos.y - p.pos.y
				if pdx * pdx + pdy * pdy < (constants.POTATO_RADIUS + 4) * (constants.POTATO_RADIUS + 4) then
					return "explode", proj.pos.x, proj.pos.y, p
				end
			end
		end

		local gy = terrain.get_smooth_ground_y(proj.pos.x, 3.0, proj.pos.y + 6.0)
		local ground_target_y = gy + 4.0
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

	-- Dynamic Wind force application
	local wind_sens = proj.weapon.wind_sensitivity or 1.0
	local wx, wy = get_wind_components(wind_vector or proj.wind_vector)
	proj.vel.x = proj.vel.x + wx * wind_sens * dt
	proj.vel.y = proj.vel.y + wy * wind_sens * dt

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

	-- 1. Check continuous segment collision with living potatoes
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

	if hit_potato and closest_potato_dist <= terrain_dist then
		return "explode", potato_hx, potato_hy, hit_potato
	end

	if terrain_hit then
		if proj.weapon.on_hit == "drill" and not proj.is_drilling then
			proj.is_drilling = true
			local drill_dist = proj.weapon.drill_dist or 65
			local speed = math.sqrt(proj.vel.x * proj.vel.x + proj.vel.y * proj.vel.y)
			if speed > 0.01 then
				local dir_x = proj.vel.x / speed
				local dir_y = proj.vel.y / speed
				local final_x = thx + dir_x * drill_dist
				local final_y = thy + dir_y * drill_dist
				if terrain and terrain.carve_circle then
					terrain.carve_circle(thx + dir_x * 15, thy + dir_y * 15, 10)
					terrain.carve_circle(thx + dir_x * 35, thy + dir_y * 35, 11)
					terrain.carve_circle(thx + dir_x * 55, thy + dir_y * 55, 12)
				end
				proj.pos.x = final_x
				proj.pos.y = final_y
				return "explode", final_x, final_y
			end
			return "explode", thx, thy
		elseif proj.weapon.bounciness and proj.weapon.bounciness > 0.1 then
			local dot = proj.vel.x * nx + proj.vel.y * ny
			if dot < 0 then
				proj.vel.x = (proj.vel.x - (1.0 + proj.weapon.bounciness) * dot * nx) * proj.weapon.friction
				proj.vel.y = (proj.vel.y - (1.0 + proj.weapon.bounciness) * dot * ny) * proj.weapon.friction
			end

			proj.pos.x = thx + nx * 1.0
			proj.pos.y = thy + ny * 1.0
			proj.bounces = (proj.bounces or 0) + 1

			local speed = math.sqrt(proj.vel.x * proj.vel.x + proj.vel.y * proj.vel.y)
			if (speed < 35.0 and ny > 0.35) or (speed < 15.0) then
				proj.is_resting = true
				proj.vel.x = 0
				proj.vel.y = 0
				local gy = terrain.get_smooth_ground_y(proj.pos.x, 3.0, proj.pos.y + 6.0)
				proj.pos.y = gy + 4.0
			end
			return "bounce", thx, thy
		else
			return "explode", thx, thy
		end
	end

	proj.pos.x = next_x
	proj.pos.y = next_y
	return "flying", next_x, next_y
end

-- Calculate ballistic trajectory points with dynamic wind support
function M.calculate_trajectory(start_x, start_y, vel_x, vel_y, weapon, terrain, max_points, wind_vector)
	max_points = max_points or 18
	local points = {}
	local curr_x = start_x
	local curr_y = start_y
	local vx = vel_x
	local vy = vel_y
	local dt = 0.045
	local grav = constants.GRAVITY * (weapon.gravity_mult or 1.0)
	local wind_sens = weapon.wind_sensitivity or 1.0
	local wx, wy = get_wind_components(wind_vector)

	for i = 1, max_points do
		vx = vx + wx * wind_sens * dt
		vy = vy - grav * dt + wy * wind_sens * dt

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

-- Full simulated shot trajectory with wind prediction for Bot AI
function M.simulate_shot(start_x, start_y, vel_x, vel_y, weapon, terrain, potatoes, owner_id, wind_vector)
	potatoes = potatoes or {}
	local curr_x = start_x
	local curr_y = start_y
	local vx = vel_x
	local vy = vel_y
	local dt = 0.035
	local grav = constants.GRAVITY * (weapon.gravity_mult or 1.0)
	local wind_sens = weapon.wind_sensitivity or 1.0
	local wx, wy = get_wind_components(wind_vector)
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
			local gy = terrain.get_smooth_ground_y(curr_x, 3.0, curr_y + 6.0)
			curr_y = gy + 4.0
		else
			vx = vx + wx * wind_sens * dt
			vy = vy - grav * dt + wy * wind_sens * dt

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
