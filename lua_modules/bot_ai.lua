-- lua_modules/bot_ai.lua
-- Computer Bot AI decision making and ballistic aiming for Potato War

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local physics_sim = require("lua_modules.physics_sim")

local M = {}

-- Evaluate best enemy target for the bot
local function select_target(bot, enemies)
	local best_target = nil
	local min_dist = 999999

	for _, enemy in ipairs(enemies) do
		if enemy.is_alive then
			local dx = enemy.pos.x - bot.pos.x
			local dy = enemy.pos.y - bot.pos.y
			local dist = math.sqrt(dx * dx + dy * dy)
			-- Prioritize lower HP enemies if within reasonable range
			local score = dist + enemy.hp * 0.8
			if score < min_dist then
				min_dist = score
				best_target = enemy
			end
		end
	end

	return best_target
end

-- Find optimal launch parameters for Grenade
local function solve_grenade_aim(bot_pos, target_pos, terrain)
	local dx = target_pos.x - bot_pos.x
	local dy = target_pos.y - bot_pos.y
	local dist = math.sqrt(dx * dx + dy * dy)
	local dir = dx > 0 and 1 or -1

	-- Test several launch angles between 35 and 68 degrees
	local best_angle = 45
	local best_power = 400
	local closest_error = 999999

	local grenade_def = weapons.get(weapons.TYPES.GRENADE)

	for angle_deg = 35, 70, 5 do
		local rad = math.rad(angle_deg)
		local base_v = math.sqrt(math.max(100, (dist * constants.GRAVITY) / math.sin(2 * rad)))
		base_v = math.min(grenade_def.max_power, math.max(150, base_v))

		local vx = dir * base_v * math.cos(rad)
		local vy = base_v * math.sin(rad)

		local traj = physics_sim.calculate_trajectory(bot_pos.x, bot_pos.y + 8, vx, vy, grenade_def, terrain, 20)
		if #traj > 0 then
			local end_pt = traj[#traj]
			local err_x = end_pt.x - target_pos.x
			local err_y = end_pt.y - target_pos.y
			local err = math.sqrt(err_x * err_x + err_y * err_y)
			if err < closest_error then
				closest_error = err
				best_angle = angle_deg
				best_power = base_v
			end
		end
	end

	local rad = math.rad(best_angle)
	local aim_dx = dir * math.cos(rad)
	local aim_dy = math.sin(rad)
	return aim_dx, aim_dy, best_power
end

function M.plan_movement(bot, target, enemies, terrain, difficulty)
	if not target then
		return { dir = 0, steps = 0, should_jump = false }
	end

	local dx = target.pos.x - bot.pos.x
	local dist = math.abs(dx)
	local dir = dx > 0 and 1 or -1
	local steps = 0
	local should_jump = false

	-- 1. Safety: check if near cliff/water edge
	local check_x = bot.pos.x + dir * 40
	local ground_ahead = terrain.get_ground_y(check_x)
	local ground_here = terrain.get_ground_y(bot.pos.x)
	local near_cliff = (ground_here - ground_ahead) > 30

	-- 2. Check line of sight
	local hit, hx, hy = terrain.raycast(bot.pos.x, bot.pos.y + 6, target.pos.x, target.pos.y + 6)
	local has_los = not hit or (math.abs(hx - target.pos.x) < 25 and math.abs(hy - target.pos.y) < 25)

	-- 3. Decide movement
	if near_cliff then
		-- Back away from cliff
		steps = math.random(2, 4)
		dir = -dir
	elseif dist < 48 then
		-- Close enough for melee, move in
		steps = math.random(1, 3)
	elseif not has_los and dist > 80 then
		-- No line of sight, try to reposition
		steps = math.random(3, 8)
		-- Check if going up helps (try to climb)
		local higher_ground = terrain.get_ground_y(bot.pos.x + dir * 30)
		if higher_ground > ground_here + 8 then
			should_jump = true
		end
	elseif dist > 300 then
		-- Very far, move closer
		steps = math.random(4, 10)
	elseif dist > 150 then
		-- Moderately far, small adjustment
		steps = math.random(1, 4)
	else
		-- Good position, maybe small tactical move
		if math.random() > 0.6 then
			steps = math.random(1, 3)
			-- Try to get higher ground
			local left_y = terrain.get_ground_y(bot.pos.x - 40)
			local right_y = terrain.get_ground_y(bot.pos.x + 40)
			if left_y > right_y + 5 then
				dir = -1
			elseif right_y > left_y + 5 then
				dir = 1
			end
		else
			steps = 0
		end
	end

	-- Difficulty scaling: easy bots move less
	if difficulty == "easy" then
		steps = math.floor(steps * 0.4)
	elseif difficulty == "hard" then
		steps = math.floor(steps * 1.3)
	end

	-- Random jump chance when moving (makes bot look more natural)
	if steps > 3 and math.random() > 0.65 then
		should_jump = true
	end

	return { dir = dir, steps = math.max(0, steps), should_jump = should_jump }
end

-- Plan bot turn: returns chosen weapon_id, aim_dx, aim_dy, power, delay
function M.plan_turn(bot, all_potatoes, terrain, difficulty)
	difficulty = difficulty or "normal"

	-- Collect living enemies
	local enemies = {}
	for _, p in ipairs(all_potatoes) do
		if p.team ~= bot.team and p.is_alive then
			table.insert(enemies, p)
		end
	end

	local target = select_target(bot, enemies)
	if not target then
		return nil
	end

	local dx = target.pos.x - bot.pos.x
	local dy = target.pos.y - bot.pos.y
	local dist = math.sqrt(dx * dx + dy * dy)
	local dir = dx > 0 and 1 or -1

	local chosen_weapon_id = weapons.TYPES.GRENADE
	local aim_dx, aim_dy = dir, 0.5
	local power = 400

	-- 1. Melee knife check (< 48px)
	if dist < 48 then
		chosen_weapon_id = weapons.TYPES.KNIFE
		aim_dx = dir
		aim_dy = 0.2
		power = 280
	else
		-- 2. Line of sight check for Rifle
		local hit, hx, hy = terrain.raycast(bot.pos.x, bot.pos.y + 6, target.pos.x, target.pos.y + 6)
		local clear_los = not hit or (math.abs(hx - target.pos.x) < 20 and math.abs(hy - target.pos.y) < 20)

		if clear_los and math.random() > 0.35 then
			chosen_weapon_id = weapons.TYPES.RIFLE
			local rifle_def = weapons.get(weapons.TYPES.RIFLE)
			-- Slight elevation compensation for bullet drop
			local drop_comp = 0.5 * constants.GRAVITY * rifle_def.gravity_mult * math.pow(dist / rifle_def.speed, 2)
			local eff_dy = dy + drop_comp
			local eff_len = math.sqrt(dx * dx + eff_dy * eff_dy)
			aim_dx = dx / eff_len
			aim_dy = eff_dy / eff_len
			power = rifle_def.max_power
		else
			-- 3. Ballistic Grenade lob
			chosen_weapon_id = weapons.TYPES.GRENADE
			aim_dx, aim_dy, power = solve_grenade_aim(bot.pos, target.pos, terrain)
		end
	end

	-- Apply casual error jitter based on difficulty
	local angle_jitter = 0
	local power_jitter = 1.0

	if difficulty == "easy" then
		angle_jitter = (math.random() - 0.5) * 0.22 -- ~12 degrees
		power_jitter = 1.0 + (math.random() - 0.5) * 0.25
	elseif difficulty == "normal" then
		angle_jitter = (math.random() - 0.5) * 0.10 -- ~5.7 degrees
		power_jitter = 1.0 + (math.random() - 0.5) * 0.12
	else -- "hard"
		angle_jitter = (math.random() - 0.5) * 0.04 -- ~2.3 degrees
		power_jitter = 1.0 + (math.random() - 0.5) * 0.05
	end

	-- Rotate aim vector by jitter
	local cos_j = math.cos(angle_jitter)
	local sin_j = math.sin(angle_jitter)
	local final_dx = aim_dx * cos_j - aim_dy * sin_j
	local final_dy = math.max(0.05, aim_dx * sin_j + aim_dy * cos_j)
	local final_power = power * power_jitter

	local move_plan = M.plan_movement(bot, target, enemies, terrain, difficulty)

	return {
		weapon_id = chosen_weapon_id,
		aim_dx = final_dx,
		aim_dy = final_dy,
		power = final_power,
		think_delay = 1.2 + math.random() * 0.6,
		target_id = target.id,
		movement = move_plan,
	}
end

return M
