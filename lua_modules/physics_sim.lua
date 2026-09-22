-- lua_modules/physics_sim.lua
-- Discrete Physics, Ballistics, and Collision Simulation for Potato War

local constants = require("lua_modules.constants")

local M = {}

-- Update a potato unit's physics
function M.update_potato(p, dt, terrain)
	if not p.is_alive then
		return
	end

	-- Gravity
	if not p.is_grounded then
		p.vel.y = math.max(-constants.MAX_FALL_SPEED, p.vel.y - constants.GRAVITY * dt)
	else
		-- Ground friction
		p.vel.x = p.vel.x * math.max(0, 1.0 - 12.0 * dt)
		if math.abs(p.vel.x) < 2.0 then
			p.vel.x = 0
		end
	end

	-- Integrate position
	local new_x = p.pos.x + p.vel.x * dt
	local new_y = p.pos.y + p.vel.y * dt

	-- Check world horizontal bounds
	if new_x < constants.POTATO_RADIUS then
		new_x = constants.POTATO_RADIUS
		p.vel.x = 0
	elseif new_x > constants.WORLD_WIDTH - constants.POTATO_RADIUS then
		new_x = constants.WORLD_WIDTH - constants.POTATO_RADIUS
		p.vel.x = 0
	end

	-- Check water level (drowning)
	if new_y < constants.WATER_LEVEL then
		p.pos.x = new_x
		p.pos.y = new_y
		p.hp = 0
		p.is_alive = false
		p.is_grounded = false
		return "drowned"
	end

	-- Terrain collision resolution
	local check_radius = constants.POTATO_RADIUS
	local feet_y = new_y - 2
	local hit, nx, ny = terrain.check_circle_collision(new_x, feet_y + 4, check_radius)

	if hit then
		-- Push out along normal
		new_x = new_x + nx * 2.0
		new_y = new_y + ny * 2.0

		-- Velocity response
		local dot = p.vel.x * nx + p.vel.y * ny
		if dot < 0 then
			p.vel.x = p.vel.x - dot * nx
			p.vel.y = p.vel.y - dot * ny
		end

		if ny > 0.45 then
			p.is_grounded = true
			if p.vel.y < 0 then
				p.vel.y = 0
			end
		end
	else
		-- Test 2px below feet for grounded state
		local ground_hit = terrain.is_solid(new_x, new_y - check_radius - 2)
		if ground_hit and p.vel.y <= 1.0 then
			p.is_grounded = true
			p.vel.y = 0
		else
			p.is_grounded = false
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

	-- Slope step-up check (up to 6px)
	local feet_y = p.pos.y - constants.POTATO_RADIUS
	local stepped = false
	for step = 0, 7 do
		local test_y = feet_y + step
		if not terrain.is_solid(target_x, test_y + 4) then
			p.pos.x = target_x
			-- Stick to ground slope
			local gy = terrain.get_ground_y(target_x)
			if gy > constants.WATER_LEVEL and math.abs(gy + constants.POTATO_RADIUS - p.pos.y) < 10 then
				p.pos.y = gy + constants.POTATO_RADIUS
			else
				p.pos.y = test_y + constants.POTATO_RADIUS
			end
			stepped = true
			break
		end
	end

	if not stepped then
		p.vel.x = 0
	end
end

-- Jump potato
function M.jump_potato(p)
	if p.is_alive and p.is_grounded then
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
	local dy = (p.pos.y + 4) - blast_y
	local dist = math.sqrt(dx * dx + dy * dy)

	if dist < blast_radius then
		local factor = 1.0 - (dist / blast_radius)
		local dmg = math.max(5, math.floor(max_damage * factor))

		-- Normalized impulse vector with upward lift bias
		local len = math.max(0.01, dist)
		local dir_x = dx / len
		local dir_y = (dy + 12) / (len + 12)
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

-- Update projectile physics and collisions
function M.update_projectile(proj, dt, terrain, potatoes)
	if not proj.is_active then
		return "inactive"
	end

	proj.fuse_timer = proj.fuse_timer - dt

	-- Fuse timeout check (e.g. Grenade or Knife)
	if proj.fuse_timer <= 0 then
		return "explode", proj.pos.x, proj.pos.y
	end

	-- Gravity
	local grav = constants.GRAVITY * (proj.weapon.gravity_mult or 1.0)
	proj.vel.y = proj.vel.y - grav * dt

	-- Step path
	local next_x = proj.pos.x + proj.vel.x * dt
	local next_y = proj.pos.y + proj.vel.y * dt

	-- Water check
	if next_y < constants.WATER_LEVEL then
		return "water", next_x, constants.WATER_LEVEL
	end

	-- Check collision with potatoes
	for _, p in ipairs(potatoes) do
		if p.is_alive and (proj.owner_id == nil or p.id ~= proj.owner_id or proj.fuse_timer < proj.weapon.fuse_time - 0.2) then
			local pdx = next_x - p.pos.x
			local pdy = next_y - p.pos.y
			if pdx * pdx + pdy * pdy < (constants.POTATO_RADIUS + 6) * (constants.POTATO_RADIUS + 6) then
				return "explode", next_x, next_y, p
			end
		end
	end

	-- Check collision with terrain
	local hit, hx, hy, nx, ny = terrain.raycast(proj.pos.x, proj.pos.y, next_x, next_y)
	if hit then
		if proj.weapon.bounciness and proj.weapon.bounciness > 0.1 then
			-- Bounce (Grenade)
			local dot = proj.vel.x * nx + proj.vel.y * ny
			proj.vel.x = (proj.vel.x - (1.0 + proj.weapon.bounciness) * dot * nx) * proj.weapon.friction
			proj.vel.y = (proj.vel.y - (1.0 + proj.weapon.bounciness) * dot * ny) * proj.weapon.friction
			proj.pos.x = hx + nx * 2
			proj.pos.y = hy + ny * 2
			proj.bounces = (proj.bounces or 0) + 1

			-- Slow to rest check
			if math.abs(proj.vel.x) < 15 and math.abs(proj.vel.y) < 15 then
				proj.vel.x = 0
				proj.vel.y = 0
			end
			return "bounce", hx, hy
		else
			-- Explode on impact (Rifle / Rocket)
			return "explode", hx, hy
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

		if terrain.is_solid(nx, ny) then
			table.insert(points, { x = nx, y = ny })
			break
		end

		table.insert(points, { x = nx, y = ny })
		curr_x = nx
		curr_y = ny
	end

	return points
end

return M
