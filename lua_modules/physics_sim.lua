-- lua_modules/physics_sim.lua
-- Discrete Physics, Ballistics, Dynamic Wind, and Elemental States for Potato War
-- Includes slope movement, ceiling collision, wind drift, and status effect integration.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")

local M = {}

-- Every launch speed is the raw aim power times this boost (player drag, bot solver, previews)
M.LAUNCH_BOOST = 1.30

-- Longest physics step: a falling potato moves ~5px per step, well under its radius,
-- so thin bridges and islands can't be skipped between two frames
M.POTATO_STEP = 1 / 120
M.PROJECTILE_STEP = 1 / 60
local MAX_SUBSTEPS = 8

-- Shot preview and bot simulation share one step so they trace the same arc
M.SIM_DT = 1 / 60

-- Helper to extract x/y components from table or vmath vector
local function get_wind_components(wind_vector)
	if not wind_vector then
		return 0, 0
	end
	local wx = wind_vector.x or 0
	local wy = wind_vector.y or 0
	return wx, wy
end

-- Exact step under constant acceleration: the arc is the same at any frame rate
local function integrate(x, y, vx, vy, ax, ay, dt)
	local nx = x + (vx + 0.5 * ax * dt) * dt
	local ny = y + (vy + 0.5 * ay * dt) * dt
	return nx, ny, vx + ax * dt, vy + ay * dt
end

-- Constant acceleration of a shell of this weapon in this wind
local function shell_accel(weapon, wind_vector)
	local wx, wy = get_wind_components(wind_vector)
	local wind_sens = weapon.wind_sensitivity or 1.0
	return wx * wind_sens, wy * wind_sens - constants.GRAVITY * (weapon.gravity_mult or 1.0)
end

-- Frame-rate independent damping factor for a per-second rate
local function damp(rate, dt)
	return math.exp(-rate * dt)
end

-- Update a potato unit's physics (accounting for mass, wind drift, and statuses)
function M.update_potato(p, dt, terrain, wind_vector)
	if not p.is_alive and not p.is_dying then
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
		p.vel.x = p.vel.x * damp(drag_rate, dt) -- air drag
		-- Wind only affects projectiles; potatoes are immune to wind drift
	else
		-- Ground friction (stronger if glued)
		local ground_fric = is_glued and 28.0 or 16.0
		p.vel.x = p.vel.x * damp(ground_fric, dt)
		if math.abs(p.vel.x) < 2.0 then
			p.vel.x = 0
		end

		-- Concussed wobble on ground
		if is_concussed and math.abs(p.vel.x) > 1.0 then
			p.vel.x = p.vel.x + (math.random() - 0.5) * 360.0 * dt
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

	-- Check water level: Instant death into water / deep fryer!
	if p.pos.y <= (constants.WATER_LEVEL + 4.0) or new_y <= (constants.WATER_LEVEL + 4.0) then
		if game_state and game_state.mode == constants.MODE_TUTORIAL then
			-- Fail-safe tutorial rescue: teleport back to safe edge without penalty
			p.pos.x = 380.0
			p.pos.y = terrain.get_smooth_ground_y(380.0, 4.0) + 20.0
			p.vel.x = 0
			p.vel.y = 0
			p.is_grounded = true
			return "tutorial_rescue"
		else
			-- Worms instant death upon falling into the water!
			p.pos.x = new_x
			p.pos.y = math.min(p.pos.y, constants.WATER_LEVEL - 5)
			p.hp = 0
			p.is_alive = false
			p.is_dying = false
			p.is_grounded = false
			return "drowned"
		end
	end

	if not p.is_grounded then
		-- Airborne state
		new_y = p.pos.y + p.vel.y * dt

		local ground_y = terrain.get_smooth_ground_y(new_x, 4.0, p.pos.y + 6.0)
		local target_standing_y = ground_y + check_radius

		-- Check if potato is trapped in a narrow pit/crevice (solid walls on both sides)
		-- Probe at body width and also slightly above to catch wider pits
		local probe_dx = check_radius * 1.5
		local wall_left = terrain.is_solid(new_x - probe_dx, new_y) or terrain.is_solid(new_x - probe_dx, new_y + check_radius)
		local wall_right = terrain.is_solid(new_x + probe_dx, new_y) or terrain.is_solid(new_x + probe_dx, new_y + check_radius)
		local in_tight_pit = wall_left and wall_right
		-- Also detect if center is embedded inside solid terrain (clipped through wall)
		local in_wall = terrain.is_solid(new_x, new_y)

		if in_tight_pit or in_wall then
			-- In a narrow pit or embedded: cancel horizontal jitter, allow vertical settling only
			p.vel.x = 0
		end

		-- Check landing on ground (only if ground is actually above water!)
		if ground_y > constants.WATER_LEVEL and p.vel.y <= 0 and new_y <= (target_standing_y + 3.0) then
			local impact_speed = math.abs(p.vel.y)
			if impact_speed > 90.0 and not in_tight_pit and not in_wall then
				-- High fall elastic rebound on open ground
				p.vel.y = impact_speed * 0.35
				p.vel.x = p.vel.x * 0.5
				new_y = target_standing_y + 2.0
				p.is_grounded = false
				p.pos.x = new_x
				p.pos.y = new_y
				return "bounce", impact_speed
			else
				new_y = target_standing_y
				p.vel.y = 0
				p.vel.x = in_tight_pit and 0 or (p.vel.x * 0.3)
				p.is_grounded = true
				p.pos.x = new_x
				p.pos.y = new_y
				return "land", impact_speed
			end
		else
			-- Check side/head/ceiling collision with solid terrain while airborne
			local hit, nx, ny = terrain.check_circle_collision(new_x, new_y, check_radius)
			if hit then
				-- In a narrow pit, embedded in wall, or against steep walls with low lateral speed: damp horizontal motion completely
				if in_tight_pit or in_wall or (math.abs(nx) > 0.45 and (math.abs(p.vel.x) < 40.0 or ny > 0.35)) then
					p.vel.x = 0
					-- If embedded in solid terrain and moving upward, prevent phasing through ceiling
					if in_wall and p.vel.y > 0 then
						p.vel.y = 0
					end
					-- Check if bottom of circle is resting on or near ground inside the pit, or wedged between walls
					if ground_y > constants.WATER_LEVEL and p.vel.y <= 0 then
						p.is_grounded = true
						p.vel.y = 0
						-- If wedged in a narrow pit where it cannot reach the pit floor, rest at wedged height
						if in_tight_pit and new_y > target_standing_y then
							new_y = math.max(target_standing_y, math.min(new_y, p.pos.y))
						else
							new_y = target_standing_y
						end
						p.pos.x = new_x
						p.pos.y = new_y
						return "land", math.abs(p.vel.y)
					end
				else
					local dot = p.vel.x * nx + p.vel.y * ny
					if dot < 0 then
						local impact_speed = math.abs(dot)
						if impact_speed > 45.0 then
							local restitution = 0.30
							p.vel.x = (p.vel.x - (1.0 + restitution) * dot * nx) * 0.65
							p.vel.y = (p.vel.y - (1.0 + restitution) * dot * ny) * 0.65
							new_x = new_x + nx * 1.0
							new_y = new_y + ny * 1.0
							-- In pits: clamp upward velocity to prevent phasing through walls
							if wall_left and wall_right then
								p.vel.x = 0
								if p.vel.y > 0 then
									p.vel.y = math.min(p.vel.y, 60.0)
								end
								new_y = math.min(new_y, p.pos.y + 2.0)
							end
							if impact_speed > 60.0 then
								p.pos.x = new_x
								p.pos.y = new_y
								return "bounce", impact_speed
							end
						else
							-- Low speed contact with wall: damp smoothly, no bouncing
							p.vel.x = p.vel.x * 0.15
							p.vel.y = p.vel.y * 0.85
							new_x = new_x + nx * 0.4
						end
					end
					if ny > 0.55 and p.vel.y <= 0 and math.abs(p.vel.y) <= 80.0 and ground_y > constants.WATER_LEVEL then
						-- Landed on terrain shelf
						p.is_grounded = true
						p.vel.y = 0
						p.vel.x = 0
						new_y = target_standing_y
						p.pos.x = new_x
						p.pos.y = new_y
						return "land", math.abs(p.vel.y)
					elseif ny < -0.45 and p.vel.y > 0 then
						-- Bonked head against ceiling or bridge underside!
						p.vel.y = -math.abs(p.vel.y) * 0.4
					end
				end
			end
		end
	else
		-- Grounded state
		local ground_y = terrain.get_smooth_ground_y(new_x, 4.0, p.pos.y + 8.0)
		local target_standing_y = ground_y + check_radius

		if ground_y <= constants.WATER_LEVEL then
			-- Ground fell away into water! Potato slips into water
			p.is_grounded = false
			p.vel.y = -50.0
			new_y = p.pos.y + p.vel.y * dt
		elseif p.vel.y > 5.0 then
			p.is_grounded = false
			new_y = p.pos.y + p.vel.y * dt
		else
			-- Check if potato is trapped in narrow pit or resting on solid walls
			local probe_dx = check_radius * 1.5
			local wall_left = terrain.is_solid(new_x - probe_dx, p.pos.y) or terrain.is_solid(new_x - probe_dx, p.pos.y + check_radius)
			local wall_right = terrain.is_solid(new_x + probe_dx, p.pos.y) or terrain.is_solid(new_x + probe_dx, p.pos.y + check_radius)
			local in_tight_pit = wall_left and wall_right
			local is_supported = in_tight_pit or terrain.check_circle_collision(new_x, p.pos.y, check_radius)

			-- Check if ground fell away below (e.g. destroyed by blast)
			if (p.pos.y - target_standing_y) > 8.0 and not is_supported then
				p.is_grounded = false
				p.vel.y = -20.0
				new_y = p.pos.y + p.vel.y * dt
			elseif (target_standing_y - p.pos.y) > 6.0 and not in_tight_pit then
				-- Hit a wall or steep rise while moving along ground: block horizontal progress
				new_x = p.pos.x
				new_y = p.pos.y
				p.vel.x = 0
			else
				-- Stable ground resting / slope following:
				if p.is_walking then
					-- Preserve active hop y while walking
					new_y = p.pos.y
					p.is_walking = false -- will be set back to true on next walk_potato call if still walking
				else
					p.walk_step_time = 0
					if in_tight_pit and (p.pos.y - target_standing_y) > 4.0 then
						-- Wedged in pit above floor: preserve wedged resting height
						new_y = p.pos.y
					else
						new_y = target_standing_y
					end
				end
				p.vel.y = 0
			end
		end
	end

	p.pos.x = new_x
	p.pos.y = new_y
end

-- update_potato in short substeps. Returns the terminal event ("drowned", "tutorial_rescue")
-- as soon as it happens, otherwise the hardest "land"/"bounce" of the frame and its speed.
function M.step_potato(p, dt, terrain, wind_vector)
	local steps = math.min(MAX_SUBSTEPS, math.max(1, math.ceil(dt / M.POTATO_STEP)))
	local sub = math.min(dt, MAX_SUBSTEPS * M.POTATO_STEP) / steps
	-- A walking hop lasts the whole frame, not just the first substep
	local walking = p.is_walking
	local event, impact = nil, 0
	for _ = 1, steps do
		p.is_walking = walking
		local res, speed = M.update_potato(p, sub, terrain, wind_vector)
		if res == "drowned" or res == "tutorial_rescue" then
			return res
		end
		if (res == "land" or res == "bounce") and (speed or 0) >= impact then
			event, impact = res, speed or 0
		end
		if not p.is_alive and not p.is_dying then
			break
		end
	end
	p.is_walking = false
	return event, impact
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

	-- 5. Walking off a cliff / ledge (steep drop) or into water
	if (curr_gy - target_gy) > 8.0 or target_gy <= constants.WATER_LEVEL then
		p.pos.x = target_x
		p.is_grounded = false
		p.vel.x = dir * base_speed * 0.75
		p.vel.y = -10.0
		return
	end

	-- 6. Apply smooth position update with walking micro-hops
	p.walk_step_time = (p.walk_step_time or 0) + dt * 18.0
	local hop_y = math.abs(math.sin(p.walk_step_time)) * 2.0
	p.pos.x = target_x
	p.pos.y = target_gy + radius + hop_y
	p.is_walking = true
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
		p.vel.x = p.facing * (70.0 * (is_glued and 0.5 or 1.0))
		p.is_grounded = false
		return true
	end
	return false
end

-- Damage and knockback a blast would deal to a potato at (px, py); 0 when out of reach.
-- Pure function: bots use it to weigh shots, apply_blast to resolve real ones.
function M.estimate_blast(px, py, mass, blast_x, blast_y, blast_radius, blast_force, max_damage)
	local dx = px - blast_x
	local dy = py - blast_y
	local dist = math.sqrt(dx * dx + dy * dy)
	local effective_radius = blast_radius + constants.POTATO_RADIUS * 0.85
	if dist >= effective_radius then
		return 0, 0, 0
	end

	local factor = math.max(0.15, 1.0 - (dist / effective_radius))
	local dmg = math.max(5, math.floor(max_damage * factor))

	local len = math.max(0.01, dist)
	local dir_x = dx / len
	local dir_y = (dy + 10) / (len + 10)
	local n_len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
	local eff_force = (blast_force * factor) / math.max(0.5, mass or 1.0)
	return dmg, dir_x / n_len * eff_force, dir_y / n_len * eff_force
end

-- Apply explosive blast to a potato (mass dampens knockback)
function M.apply_blast(p, blast_x, blast_y, blast_radius, blast_force, max_damage)
	if not p.is_alive and not p.is_dying then
		return 0
	end

	local dmg, kx, ky = M.estimate_blast(p.pos.x, p.pos.y, p.mass, blast_x, blast_y, blast_radius, blast_force, max_damage)
	if dmg == 0 then
		return 0
	end

	p.vel.x = p.vel.x + kx
	p.vel.y = p.vel.y + ky
	p.is_grounded = false

	p.hp = math.max(0, p.hp - dmg)
	if p.hp <= 0 then
		p.is_alive = false
		p.is_dying = true
	end
	return dmg
end

-- Rough flight of a knocked-back potato: true when it would end up in the water.
-- Mirrors update_potato's gravity and air drag, ignores bounces.
function M.knockback_drowns(px, py, vx, vy, terrain)
	local dt = 1 / 30
	local x, y = px, py
	for _ = 1, 75 do
		vy = math.max(-constants.MAX_FALL_SPEED, vy - constants.GRAVITY * dt)
		vx = vx * damp(2.0, dt)
		x = x + vx * dt
		y = y + vy * dt
		local r = constants.POTATO_RADIUS
		if x < r or x > constants.WORLD_WIDTH - r then
			-- The world edge stops the potato; it then drops straight down
			x = math.max(r, math.min(constants.WORLD_WIDTH - r, x))
			vx = 0
		end
		if y <= constants.WATER_LEVEL + 4 then
			return true
		end
		if vy < 0 and terrain.is_solid(x, y - constants.POTATO_RADIUS) then
			return false
		end
	end
	return false
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

-- Velocity after a bouncy shell hits a surface with normal (nx, ny)
local function bounce_velocity(weapon, vx, vy, nx, ny)
	local dot = vx * nx + vy * ny
	if dot < 0 then
		local k = 1.0 + weapon.bounciness
		local f = weapon.friction or 0.8
		return (vx - k * dot * nx) * f, (vy - k * dot * ny) * f
	end
	return vx, vy
end

-- A bounced shell this slow lies down on the ground
local function comes_to_rest(vx, vy, ny)
	local speed = math.sqrt(vx * vx + vy * vy)
	return (speed < 35.0 and ny > 0.35) or (speed < 15.0)
end

local HIT_PAD = 3 -- shells hit a potato this many px outside its body

-- Can a projectile collide with potato p?
-- The owner/shooter cannot be hit by their own projectile right after launch.
-- They can only be hit if the projectile has bounced off terrain/walls (ricochet),
-- or has been in the air for a long time (> 1.2s, high sky arc falling back down).
local function can_hit_potato(owner_id, bounces, age, p)
	if not p.is_alive then
		return false
	end
	if owner_id and owner_id ~= 0 and p.id == owner_id then
		bounces = bounces or 0
		age = age or 0
		if bounces > 0 and age > 0.8 then
			return true
		end
		if age > 1.2 then
			return true
		end
		return false
	end
	return true
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

	-- If projectile is resting on ground:
	-- The owner is immune to resting proximity detonation (fused bombs only detonate on fuse_timer <= 0 for the thrower).
	if proj.is_resting then
		for _, p in ipairs(potatoes) do
			if p.is_alive and (proj.owner_id == nil or proj.owner_id == 0 or p.id ~= proj.owner_id) then
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

	proj.age = (proj.age or 0) + dt
	local x0 = proj.pos.x
	local y0 = proj.pos.y
	local next_x, next_y
	local homing = proj.weapon.homing
	if homing and proj.target and proj.target.is_alive and proj.age >= homing.delay then
		-- Homing missile: turns towards its target at a limited rate, ignoring wind and gravity
		local want = math.atan2(proj.target.pos.y - proj.pos.y, proj.target.pos.x - proj.pos.x)
		local cur = math.atan2(proj.vel.y, proj.vel.x)
		local diff = (want - cur + math.pi) % (2 * math.pi) - math.pi
		local turn = math.max(-homing.turn * dt, math.min(homing.turn * dt, diff))
		local speed = math.sqrt(proj.vel.x * proj.vel.x + proj.vel.y * proj.vel.y)
		speed = speed + (homing.speed - speed) * math.min(1, 2 * dt)
		cur = cur + turn
		proj.vel.x = math.cos(cur) * speed
		proj.vel.y = math.sin(cur) * speed
		next_x = x0 + proj.vel.x * dt
		next_y = y0 + proj.vel.y * dt
	else
		-- Gravity and wind are constant: exact arc, same as the preview and the bot simulation
		local ax, ay = shell_accel(proj.weapon, wind_vector or proj.wind_vector)
		local vx, vy
		next_x, next_y, vx, vy = integrate(x0, y0, proj.vel.x, proj.vel.y, ax, ay, dt)
		proj.vel.x = vx
		proj.vel.y = vy
	end

	-- Water check
	if next_y < constants.WATER_LEVEL then
		return "water", next_x, constants.WATER_LEVEL
	end

	-- 1. Check continuous segment collision with living potatoes
	local hit_potato = nil
	local closest_potato_dist = 999999
	local potato_hx, potato_hy = 0, 0

	for _, p in ipairs(potatoes) do
		if can_hit_potato(proj.owner_id, proj.bounces, proj.age, p) then
			local hit_radius = constants.POTATO_RADIUS + HIT_PAD
			if p.is_target or (p.team == constants.TEAM_RED and game_state and game_state.mode == constants.MODE_TUTORIAL) then
				hit_radius = constants.POTATO_RADIUS + 18 -- Fail-safe: generous hitbox for tutorial target
			end
			local hit_p, px, py, p_dist = check_segment_circle(x0, y0, next_x, next_y, p.pos.x, p.pos.y, hit_radius)
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
			local vx, vy = bounce_velocity(proj.weapon, proj.vel.x, proj.vel.y, nx, ny)
			proj.vel.x = vx
			proj.vel.y = vy

			proj.pos.x = thx + nx * 1.0
			proj.pos.y = thy + ny * 1.0
			proj.bounces = (proj.bounces or 0) + 1

			if comes_to_rest(vx, vy, ny) then
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
	local ax, ay = shell_accel(weapon, wind_vector)

	for i = 1, max_points do
		local nx, ny
		nx, ny, vx, vy = integrate(curr_x, curr_y, vx, vy, ax, ay, dt)

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

-- Full simulated shot for the bot AI and the homing lock-on. Follows update_projectile's rules:
-- same arc, hit radius, owner grace time, bounces, resting and drilling.
-- Returns impact_x, impact_y, hit_type ("potato" | "terrain" | "water" | "fuse" | "timeout"),
-- hit_potato, path (only when want_path) and the flight time in seconds.
function M.simulate_shot(start_x, start_y, vel_x, vel_y, weapon, terrain, potatoes, owner_id, wind_vector, want_path)
	potatoes = potatoes or {}
	local curr_x = start_x
	local curr_y = start_y
	local vx = vel_x
	local vy = vel_y
	local dt = M.SIM_DT
	local ax, ay = shell_accel(weapon, wind_vector)
	local fuse_time = weapon.fuse_time or 3.0
	local fuse_timer = fuse_time
	local max_steps = math.ceil(math.min(4.5, fuse_time + 0.1) / dt)
	local bouncy = (weapon.bounciness or 0) > 0.1
	local bounces = 0
	local is_resting = false
	local path = want_path and { { x = curr_x, y = curr_y } } or nil
	local t = 0

	local function mark(x, y)
		if path then
			path[#path + 1] = { x = x, y = y }
		end
	end

	for _ = 1, max_steps do
		fuse_timer = fuse_timer - dt
		t = t + dt
		if fuse_timer <= 0 then
			return curr_x, curr_y, "fuse", nil, path, t
		end

		if is_resting then
			for _, p in ipairs(potatoes) do
				if can_hit_potato(owner_id, bounces, t, p) then
					local pdx = curr_x - p.pos.x
					local pdy = curr_y - p.pos.y
					local r = constants.POTATO_RADIUS + 4
					if pdx * pdx + pdy * pdy < r * r then
						return curr_x, curr_y, "potato", p, path, t
					end
				end
			end
		else
			local next_x, next_y
			next_x, next_y, vx, vy = integrate(curr_x, curr_y, vx, vy, ax, ay, dt)

			if next_y < constants.WATER_LEVEL then
				mark(next_x, constants.WATER_LEVEL)
				return next_x, constants.WATER_LEVEL, "water", nil, path, t
			end

			local hit_p, closest, phx, phy = nil, math.huge, 0, 0
			for _, p in ipairs(potatoes) do
				if can_hit_potato(owner_id, bounces, t, p) then
					local hit, qx, qy, d = check_segment_circle(curr_x, curr_y, next_x, next_y, p.pos.x, p.pos.y, constants.POTATO_RADIUS + HIT_PAD)
					if hit and d < closest then
						hit_p, closest, phx, phy = p, d, qx, qy
					end
				end
			end

			local hit, hx, hy, nx, ny = terrain.raycast(curr_x, curr_y, next_x, next_y)
			local terrain_dist = hit and math.sqrt((hx - curr_x) ^ 2 + (hy - curr_y) ^ 2) or math.huge
			if hit_p and closest <= terrain_dist then
				mark(phx, phy)
				return phx, phy, "potato", hit_p, path, t
			end

			if hit then
				mark(hx, hy)
				if weapon.on_hit == "drill" then
					local speed = math.max(0.01, math.sqrt(vx * vx + vy * vy))
					local dist = weapon.drill_dist or 65
					return hx + vx / speed * dist, hy + vy / speed * dist, "terrain", nil, path, t
				elseif bouncy and bounces < 6 then
					vx, vy = bounce_velocity(weapon, vx, vy, nx, ny)
					curr_x = hx + nx * 1.0
					curr_y = hy + ny * 1.0
					bounces = bounces + 1
					if comes_to_rest(vx, vy, ny) then
						is_resting = true
						vx, vy = 0, 0
						curr_y = terrain.get_smooth_ground_y(curr_x, 3.0, curr_y + 6.0) + 4.0
					end
				else
					return hx, hy, "terrain", nil, path, t
				end
			else
				curr_x = next_x
				curr_y = next_y
				mark(curr_x, curr_y)
			end
		end
	end

	return curr_x, curr_y, "timeout", nil, path, t
end

return M
