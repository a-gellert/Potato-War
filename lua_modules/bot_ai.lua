-- lua_modules/bot_ai.lua
-- Intelligent Tactical Bot AI Architecture for Potato War
-- Features:
-- 1. Perception & Situation Analysis (Pits/Crater detection, Direct Aim / Threat LOS evaluation, Water/Cliff safety)
-- 2. Tactical Movement Planning (Escaping jumpable pits, Standoff positioning for breaching, Seeking cover from direct aim)
-- 3. Ballistic Attack & Safety Engine (Strict self-damage avoidance, High-angle lobbing out of pits, Safe wall breaching)
-- 4. Human-like behaviors (Deliberation, dynamic obstacle climbing, aim preview)

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local physics_sim = require("lua_modules.physics_sim")

local M = {}

-- Select optimal enemy target
function M.select_target(bot, enemies)
	local best_target = nil
	local min_score = 999999

	for _, enemy in ipairs(enemies) do
		if enemy.is_alive then
			local dx = enemy.pos.x - bot.pos.x
			local dy = enemy.pos.y - bot.pos.y
			local dist = math.sqrt(dx * dx + dy * dy)
			-- Prioritize lower HP enemies if within reasonable range
			local score = dist + enemy.hp * 0.75
			if score < min_score then
				min_score = score
				best_target = enemy
			end
		end
	end

	return best_target
end

-- 1. PERCEPTION: Analyze bot's local environment, trap status, and enemy threats
function M.analyze_situation(bot, enemies, terrain)
	local sit = {
		is_pit = false,
		is_deep_pit = false,
		can_jump_left = false,
		can_jump_right = false,
		escape_dir = 0,
		left_wall_h = 0,
		right_wall_h = 0,
		dist_left = 30,
		dist_right = 30,
		is_under_direct_aim = false,
		exposed_enemy_count = 0,
		cliff_left = false,
		cliff_right = false,
		near_water = false,
	}

	local curr_x = bot.pos.x
	local curr_y = terrain.get_smooth_ground_y(curr_x, 4.0)

	-- A. Scan terrain profile left and right (up to 55px)
	local max_left_y = curr_y
	local dist_l = 20
	for d = 8, 56, 8 do
		local lx = math.max(constants.POTATO_RADIUS, curr_x - d)
		local gy = terrain.get_smooth_ground_y(lx, 4.0)
		if gy > max_left_y then
			max_left_y = gy
			dist_l = d
		end
	end

	local max_right_y = curr_y
	local dist_r = 20
	for d = 8, 56, 8 do
		local rx = math.min(constants.WORLD_WIDTH - constants.POTATO_RADIUS, curr_x + d)
		local gy = terrain.get_smooth_ground_y(rx, 4.0)
		if gy > max_right_y then
			max_right_y = gy
			dist_r = d
		end
	end

	sit.left_wall_h = max_left_y - curr_y
	sit.right_wall_h = max_right_y - curr_y
	sit.dist_left = dist_l
	sit.dist_right = dist_r

	-- Jump height of potato is ~38px (impulse 190, gravity 460)
	local JUMP_CAPABLE_H = 34.0
	sit.can_jump_left = (sit.left_wall_h <= JUMP_CAPABLE_H)
	sit.can_jump_right = (sit.right_wall_h <= JUMP_CAPABLE_H)

	-- If both sides have steep walls > 14px, bot is in a pit/crater
	if sit.left_wall_h > 14.0 and sit.right_wall_h > 14.0 then
		sit.is_pit = true
		if not sit.can_jump_left and not sit.can_jump_right then
			sit.is_deep_pit = true
			-- Direction of lower rim for breaching/escaping
			sit.escape_dir = (sit.left_wall_h <= sit.right_wall_h) and -1 or 1
		else
			sit.is_deep_pit = false
			if sit.can_jump_left and sit.can_jump_right then
				sit.escape_dir = (sit.left_wall_h <= sit.right_wall_h) and -1 or 1
			elseif sit.can_jump_left then
				sit.escape_dir = -1
			else
				sit.escape_dir = 1
			end
		end
	end

	-- B. Threat analysis: Is the bot under direct aim ("прямое наведение") from enemies?
	for _, enemy in ipairs(enemies) do
		if enemy.is_alive then
			local hit, hx, hy = terrain.raycast(enemy.pos.x, enemy.pos.y + 8, bot.pos.x, bot.pos.y + 8)
			-- If clear raycast from enemy eye to bot, enemy has direct aim!
			if not hit or (math.abs(hx - bot.pos.x) < 22 and math.abs(hy - (bot.pos.y + 8)) < 22) then
				sit.is_under_direct_aim = true
				sit.exposed_enemy_count = sit.exposed_enemy_count + 1
			end
		end
	end

	-- C. Cliff and water hazard check
	local ground_l = terrain.get_smooth_ground_y(curr_x - 35, 4.0)
	local ground_r = terrain.get_smooth_ground_y(curr_x + 35, 4.0)
	sit.cliff_left = (curr_y - ground_l) > 28.0
	sit.cliff_right = (curr_y - ground_r) > 28.0
	sit.near_water = (curr_y < constants.WATER_LEVEL + 42.0)

	return sit
end

-- 2. TACTICAL MOVEMENT: Escaping pits, safe standoff for breaching, or seeking cover from direct aim
function M.plan_movement(bot, target, enemies, terrain, difficulty, situation)
	if not target then
		return { dir = 0, steps = 0, should_jump = false, intent = "idle" }
	end

	situation = situation or M.analyze_situation(bot, enemies, terrain)

	local dx = target.pos.x - bot.pos.x
	local dir_to_target = dx > 0 and 1 or -1
	local dist_to_target = math.abs(dx)

	-- 1. SITUATION: Trapped in a jumpable pit
	if situation.is_pit and not situation.is_deep_pit then
		local esc_dir = situation.escape_dir
		local rim_dist = (esc_dir == -1) and situation.dist_left or situation.dist_right
		local steps = math.max(3, math.min(9, math.ceil(rim_dist / 6.0)))
		return {
			dir = esc_dir,
			steps = steps,
			should_jump = true,
			intent = "escape_pit",
		}
	end

	-- 2. SITUATION: Trapped in a DEEP pit (cannot jump out directly)
	-- To safely breach the wall, back away from the target wall to gain standoff distance!
	if situation.is_deep_pit then
		local breach_wall_dir = dir_to_target -- breach wall facing the enemy
		local dist_to_breach_wall = (breach_wall_dir == 1) and situation.dist_right or situation.dist_left
		local dist_to_opposite = (breach_wall_dir == 1) and situation.dist_left or situation.dist_right

		-- If too close to the wall we need to blast, back away towards opposite wall!
		if dist_to_breach_wall < 42.0 and dist_to_opposite > 15.0 then
			local back_steps = math.max(2, math.min(6, math.floor(dist_to_opposite / 7.0)))
			return {
				dir = -breach_wall_dir, -- back up
				steps = back_steps,
				should_jump = false,
				intent = "standoff_breach",
			}
		else
			-- Already have reasonable standoff distance
			return {
				dir = 0,
				steps = 0,
				should_jump = false,
				intent = "hold_breach_standoff",
			}
		end
	end

	-- 3. SITUATION: On open ground and under DIRECT AIM ("уход от прямого наведения")
	-- Search candidate positions along terrain to find cover (break line of sight from enemies)
	if situation.is_under_direct_aim and difficulty ~= "easy" then
		local best_cand_x = nil
		local best_score = -999999

		local test_offsets = { -80, -60, -45, -30, -18, 18, 30, 45, 60, 80 }
		for _, offset in ipairs(test_offsets) do
			local cand_x = bot.pos.x + offset
			if cand_x > 35 and cand_x < constants.WORLD_WIDTH - 35 then
				local cand_gy = terrain.get_smooth_ground_y(cand_x, 5.0)
				-- Skip water hazard
				if cand_gy > constants.WATER_LEVEL + 32.0 then
					-- Check path steepness from bot to candidate
					local step_diff = cand_gy - bot.pos.y
					if math.abs(step_diff) < 45.0 then
						local score = 0

						-- Cover check: raycast from each alive enemy
						local in_cover_count = 0
						for _, enemy in ipairs(enemies) do
							if enemy.is_alive then
								local hit, hx, hy = terrain.raycast(enemy.pos.x, enemy.pos.y + 8, cand_x, cand_gy + 8)
								if hit and (math.abs(hx - cand_x) > 25 or math.abs(hy - (cand_gy + 8)) > 25) then
									in_cover_count = in_cover_count + 1
								end
							end
						end

						if in_cover_count > 0 then
							score = score + in_cover_count * 120 -- massive cover bonus!
						else
							score = score - 60 -- still in open view
						end

						-- Height bonus: higher ground provides better tactical angle
						score = score + math.min(25, (cand_gy - bot.pos.y) * 0.8)

						-- Cliff / steep drop penalty
						local ground_ahead = terrain.get_smooth_ground_y(cand_x + (offset > 0 and 25 or -25), 4.0)
						if (cand_gy - ground_ahead) > 28.0 then
							score = score - 150
						end

						-- Moderate distance preference to target
						local cand_dist = math.abs(cand_x - target.pos.x)
						if cand_dist >= 90 and cand_dist <= 260 then
							score = score + 30
						end

						if score > best_score then
							best_score = score
							best_cand_x = cand_x
						end
					end
				end
			end
		end

		if best_cand_x and best_score > 40 then
			local move_dx = best_cand_x - bot.pos.x
			local move_dir = move_dx > 0 and 1 or -1
			local steps = math.max(2, math.min(10, math.ceil(math.abs(move_dx) / 7.5)))
			return {
				dir = move_dir,
				steps = steps,
				should_jump = (math.abs(move_dx) > 35),
				intent = "seek_cover",
			}
		end
	end

	-- 4. GENERAL TACTICAL POSITIONING
	local steps = 0
	local should_jump = false
	local dir = dir_to_target

	-- Avoid cliffs
	if dir == -1 and situation.cliff_left then
		dir = 1
		steps = math.random(2, 4)
	elseif dir == 1 and situation.cliff_right then
		dir = -1
		steps = math.random(2, 4)
	elseif dist_to_target < 45 then
		-- In knife / shotgun sweet spot
		steps = math.random(1, 2)
	elseif dist_to_target > 320 then
		-- Far away, advance forward
		steps = math.random(4, 9)
		if math.random() > 0.6 then should_jump = true end
	elseif dist_to_target > 160 then
		steps = math.random(2, 5)
	else
		-- Good medium distance, small tactical adjustment to higher ground
		if math.random() > 0.5 then
			steps = math.random(1, 3)
			local left_y = terrain.get_smooth_ground_y(bot.pos.x - 30, 4.0)
			local right_y = terrain.get_smooth_ground_y(bot.pos.x + 30, 4.0)
			if left_y > right_y + 6 then
				dir = -1
			elseif right_y > left_y + 6 then
				dir = 1
			end
		else
			steps = 0
		end
	end

	if difficulty == "easy" then
		steps = math.floor(steps * 0.5)
	elseif difficulty == "hard" then
		steps = math.floor(steps * 1.2)
	end

	return {
		dir = dir,
		steps = math.max(0, steps),
		should_jump = should_jump,
		intent = "reposition",
	}
end

-- 3. BALLISTICS & SAFE ATTACK: Solves weapon, angle, and power with 100% self-damage protection
function M.solve_safe_attack(bot, target, all_potatoes, terrain, situation, difficulty)
	local dx = target.pos.x - bot.pos.x
	local dy = target.pos.y - (bot.pos.y + 8)
	local dist = math.sqrt(dx * dx + dy * dy)
	local dir_to_target = dx > 0 and 1 or -1

	local hit, hx, hy = terrain.raycast(bot.pos.x, bot.pos.y + 8, target.pos.x, target.pos.y + 8)
	local clear_los = not hit or (math.abs(hx - target.pos.x) < 22 and math.abs(hy - target.pos.y) < 22)

	-- Helper: simulate candidate shot and score it
	local function eval_shot(weapon, aim_dx, aim_dy, power)
		local vx = aim_dx * power
		local vy = aim_dy * power
		local impact_x, impact_y, hit_type, hit_potato, path = physics_sim.simulate_shot(
			bot.pos.x, bot.pos.y + 8, vx, vy, weapon, terrain, all_potatoes, bot.id
		)

		-- Distance from impact to bot
		local dist_to_bot = math.sqrt(math.pow(impact_x - bot.pos.x, 2) + math.pow(impact_y - (bot.pos.y + 8), 2))
		local blast_radius = weapon.blast_radius or 30

		-- STRICT SAFETY RULE: NEVER DAMAGE ONESELF OR SHOOT POINT-BLANK INTO DIRT!
		if dist_to_bot < (blast_radius * 1.15 + 6.0) then
			return -999999, impact_x, impact_y, path -- REJECTED
		end

		-- Friendly fire check
		for _, p in ipairs(all_potatoes) do
			if p.is_alive and p.team == bot.team and p.id ~= bot.id then
				local dist_to_ally = math.sqrt(math.pow(impact_x - p.pos.x, 2) + math.pow(impact_y - p.pos.y, 2))
				if dist_to_ally < blast_radius * 1.1 then
					return -500000, impact_x, impact_y, path -- Heavily penalize friendly fire
				end
			end
		end

		-- Distance from impact to enemy target
		local dist_to_target = math.sqrt(math.pow(impact_x - target.pos.x, 2) + math.pow(impact_y - target.pos.y, 2))
		local score = 1000 - dist_to_target

		if dist_to_target < blast_radius then
			score = score + 500 * (1.0 - (dist_to_target / blast_radius))
		end

		if hit_potato and hit_potato.team ~= bot.team then
			score = score + 1000 -- Direct enemy hit!
		end

		return score, impact_x, impact_y, path
	end

	-- A. SITUATION: TRAPPED IN A DEEP PIT
	if situation.is_deep_pit then
		-- Option 1: Try High-Angle Lobbing (Mortar: 68° to 84°) out of the pit to reach target
		local lob_weapon = weapons.get(weapons.TYPES.GRENADE)
		local best_lob_score = -999999
		local best_lob_dx, best_lob_dy, best_lob_pow = dir_to_target, 0.8, 400

		for angle_deg = 65, 84, 3 do
			local rad = math.rad(angle_deg)
			for p_mult = 0.55, 1.0, 0.15 do
				local pow = lob_weapon.max_power * p_mult
				local aim_x = dir_to_target * math.cos(rad)
				local aim_y = math.sin(rad)
				local score, ix, iy, path = eval_shot(lob_weapon, aim_x, aim_y, pow)

				-- Verify the trajectory clears the pit rims (all points within pit width must be above terrain)
				local cleared_pit = true
				if #path > 2 then
					for _, pt in ipairs(path) do
						local p_dist_x = math.abs(pt.x - bot.pos.x)
						if p_dist_x < 55.0 then
							local gy = terrain.get_ground_y(pt.x)
							if pt.y < gy + 6.0 and pt ~= path[#path] then
								cleared_pit = false
								break
							end
						end
					end
				end

				if cleared_pit and score > best_lob_score then
					best_lob_score = score
					best_lob_dx = aim_x
					best_lob_dy = aim_y
					best_lob_pow = pow
				end
			end
		end

		-- If a safe high-angle lob successfully reaches near target, use it!
		if best_lob_score > 400 then
			return {
				weapon_id = lob_weapon.id,
				aim_dx = best_lob_dx,
				aim_dy = best_lob_dy,
				power = best_lob_pow,
				is_breaching = false,
			}
		end

		-- Option 2: SAFE WALL BREACHING ("пробивать стену на безопасном расстоянии")
		-- Target the upper rim of the obstructing wall with an explosive weapon to blast an exit!
		local breach_weapon = weapons.get(weapons.TYPES.BAZOOKA)
		local rim_dist = (dir_to_target == 1) and situation.dist_right or situation.dist_left
		local rim_h = (dir_to_target == 1) and situation.right_wall_h or situation.left_wall_h
		local wall_target_x = bot.pos.x + dir_to_target * (rim_dist + 4.0)
		local wall_target_y = bot.pos.y + rim_h - 6.0 -- target near upper lip

		local to_wall_x = wall_target_x - bot.pos.x
		local to_wall_y = wall_target_y - (bot.pos.y + 8)
		local wall_dist = math.sqrt(to_wall_x * to_wall_x + to_wall_y * to_wall_y)

		-- SAFE STANDOFF CHECK:
		local safe_standoff = breach_weapon.blast_radius * 1.15 + 10.0
		if wall_dist >= safe_standoff then
			-- Aim at the upper rim of the wall to blow it away
			local aim_x = to_wall_x / wall_dist
			local aim_y = to_wall_y / wall_dist
			local breach_pow = math.max(220, math.min(480, wall_dist * 5.0))

			local score, ix, iy = eval_shot(breach_weapon, aim_x, aim_y, breach_pow)
			if score > -900000 then
				return {
					weapon_id = breach_weapon.id,
					aim_dx = aim_x,
					aim_dy = aim_y,
					power = breach_pow,
					is_breaching = true,
				}
			end
		end

		-- If standoff is still too close for Bazooka, use Grenade with high angle lob
		local gren_weapon = weapons.get(weapons.TYPES.GRENADE)
		local safe_rad = math.rad(78)
		local safe_pow = 380
		return {
			weapon_id = gren_weapon.id,
			aim_dx = dir_to_target * math.cos(safe_rad),
			aim_dy = math.sin(safe_rad),
			power = safe_pow,
			is_breaching = false,
		}
	end

	-- B. SITUATION: MELEE RANGE (< 44px)
	if dist < 44.0 then
		if math.random() > 0.35 then
			return {
				weapon_id = weapons.TYPES.KNIFE,
				aim_dx = dir_to_target,
				aim_dy = 0.05,
				power = 1,
				is_breaching = false,
			}
		else
			local sg = weapons.get(weapons.TYPES.SHOTGUN)
			return {
				weapon_id = sg.id,
				aim_dx = dir_to_target * 0.95,
				aim_dy = 0.25,
				power = sg.max_power * 0.7,
				is_breaching = false,
			}
		end
	end

	-- C. SITUATION: DIRECT LINE OF SIGHT (LOS CLEAR)
	if clear_los then
		-- Close-medium range: Shotgun or Assault Rifle (Burst)
		if dist < 140.0 then
			local roll = math.random()
			if roll < 0.50 then
				local sg = weapons.get(weapons.TYPES.SHOTGUN)
				local len = math.sqrt(dx * dx + dy * dy)
				return {
					weapon_id = sg.id,
					aim_dx = dx / len,
					aim_dy = dy / len + 0.06,
					power = sg.max_power * 0.75,
					is_breaching = false,
				}
			else
				local burst = weapons.get(weapons.TYPES.BURST)
				local drop = 0.5 * constants.GRAVITY * burst.gravity_mult * math.pow(dist / (burst.speed or 900), 2)
				local eff_dy = dy + drop
				local len = math.sqrt(dx * dx + eff_dy * eff_dy)
				return {
					weapon_id = burst.id,
					aim_dx = dx / len,
					aim_dy = eff_dy / len,
					power = burst.max_power,
					is_breaching = false,
				}
			end
		elseif dist < 420.0 then
			-- Medium to long range direct fire: Sniper Rifle or Burst
			local roll = math.random()
			if roll < 0.55 then
				local rifle = weapons.get(weapons.TYPES.RIFLE)
				local drop = 0.5 * constants.GRAVITY * rifle.gravity_mult * math.pow(dist / rifle.speed, 2)
				local eff_dy = dy + drop
				local len = math.sqrt(dx * dx + eff_dy * eff_dy)
				return {
					weapon_id = rifle.id,
					aim_dx = dx / len,
					aim_dy = eff_dy / len,
					power = rifle.max_power,
					is_breaching = false,
				}
			else
				local burst = weapons.get(weapons.TYPES.BURST)
				local drop = 0.5 * constants.GRAVITY * burst.gravity_mult * math.pow(dist / (burst.speed or 900), 2)
				local eff_dy = dy + drop
				local len = math.sqrt(dx * dx + eff_dy * eff_dy)
				return {
					weapon_id = burst.id,
					aim_dx = dx / len,
					aim_dy = eff_dy / len,
					power = burst.max_power,
					is_breaching = false,
				}
			end
		end
	end

	-- D. SITUATION: NO LOS OR INDIRECT PARABOLIC LOB
	local candidate_weapons = {
		weapons.get(weapons.TYPES.GRENADE),
		weapons.get(weapons.TYPES.BAZOOKA),
	}
	if dist > 180.0 then
		table.insert(candidate_weapons, weapons.get(weapons.TYPES.HOLY_GRENADE))
	end
	if dist < 260.0 then
		table.insert(candidate_weapons, weapons.get(weapons.TYPES.MOLOTOV))
	end

	local chosen_weapon = candidate_weapons[math.random(1, #candidate_weapons)]
	local best_score = -999999
	local best_aim_dx = dir_to_target
	local best_aim_dy = 0.6
	local best_power = 400

	-- Ballistic search over launch angles and powers
	for angle_deg = 32, 74, 4 do
		local rad = math.rad(angle_deg)
		local grav = constants.GRAVITY * (chosen_weapon.gravity_mult or 1.0)
		local sin2 = math.max(0.1, math.sin(2 * rad))
		local ideal_v = math.sqrt(math.max(100, (dist * grav) / sin2))

		for _, p_mult in ipairs({ 0.85, 1.0, 1.15 }) do
			local test_v = math.min(chosen_weapon.max_power, math.max(140, ideal_v * p_mult))
			local aim_x = dir_to_target * math.cos(rad)
			local aim_y = math.sin(rad)

			local score, ix, iy = eval_shot(chosen_weapon, aim_x, aim_y, test_v)
			if score > best_score then
				best_score = score
				best_aim_dx = aim_x
				best_aim_dy = aim_y
				best_power = test_v
			end
		end
	end

	-- Fallback if no clean score found
	if best_score < -900000 then
		local rad = math.rad(60)
		best_aim_dx = dir_to_target * math.cos(rad)
		best_aim_dy = math.sin(rad)
		best_power = 420
	end

	return {
		weapon_id = chosen_weapon.id,
		aim_dx = best_aim_dx,
		aim_dy = best_aim_dy,
		power = best_power,
		is_breaching = false,
	}
end

-- 4. MASTER BOT TURN PLANNER: Coordinates perception, movement, and combat
function M.plan_turn(bot, all_potatoes, terrain, difficulty)
	difficulty = difficulty or "normal"

	-- Collect alive enemies
	local enemies = {}
	for _, p in ipairs(all_potatoes) do
		if p.team ~= bot.team and p.is_alive then
			table.insert(enemies, p)
		end
	end

	local target = M.select_target(bot, enemies)
	if not target then
		return nil
	end

	-- 1. Perception
	local situation = M.analyze_situation(bot, enemies, terrain)

	-- 2. Movement
	local move_plan = M.plan_movement(bot, target, enemies, terrain, difficulty, situation)

	-- 3. Attack
	local attack_plan = M.solve_safe_attack(bot, target, all_potatoes, terrain, situation, difficulty)

	-- 4. Difficulty jitter on attack (only applies to aim, strictly prevents self-damage)
	local angle_jitter = 0
	local power_jitter = 1.0

	if difficulty == "easy" then
		angle_jitter = (math.random() - 0.5) * 0.16 -- ~9 degrees
		power_jitter = 1.0 + (math.random() - 0.5) * 0.18
	elseif difficulty == "normal" then
		angle_jitter = (math.random() - 0.5) * 0.06 -- ~3.4 degrees
		power_jitter = 1.0 + (math.random() - 0.5) * 0.08
	else -- "hard"
		angle_jitter = (math.random() - 0.5) * 0.02 -- ~1.1 degrees
		power_jitter = 1.0 + (math.random() - 0.5) * 0.03
	end

	local cos_j = math.cos(angle_jitter)
	local sin_j = math.sin(angle_jitter)
	local final_dx = attack_plan.aim_dx * cos_j - attack_plan.aim_dy * sin_j
	local final_dy = math.max(0.06, attack_plan.aim_dx * sin_j + attack_plan.aim_dy * cos_j)
	local final_power = attack_plan.power * power_jitter

	-- Deliberation delay (human-like pause)
	local think_delay = 1.1 + math.random() * 0.5
	if difficulty == "easy" then
		think_delay = 1.4 + math.random() * 0.6
	elseif difficulty == "hard" then
		think_delay = 0.9 + math.random() * 0.4
	end

	return {
		weapon_id = attack_plan.weapon_id,
		aim_dx = final_dx,
		aim_dy = final_dy,
		power = final_power,
		think_delay = think_delay,
		target_id = target.id,
		movement = move_plan,
		situation = situation,
		tactical_intent = move_plan.intent,
		is_breaching = attack_plan.is_breaching,
	}
end

return M
