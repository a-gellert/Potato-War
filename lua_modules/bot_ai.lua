-- lua_modules/bot_ai.lua
-- Tactical bot AI for Potato War.
-- 1. Perception: pits, line of sight, water and cliff hazards (analyze_situation)
-- 2. Positioning: scores reachable standing spots by personality, cover, range and height (plan_move)
-- 3. Attack: simulates candidate shots with the real projectile physics and scores the outcome
--    by expected damage, kills, knock-into-water and friendly fire (solve_attack)
-- 4. Human touch: aim error by difficulty that shrinks while a bot zeroes in on the same target,
--    personality quirks and short battle shouts (apply_error, plan.chat)

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local physics_sim = require("lua_modules.physics_sim")
local level_config = require("lua_modules.level_config")
local inventory_manager = require("lua_modules.inventory_manager")

local M = {}

-- Worms Personality Archetypes
M.ARCHETYPES = {
	BERSERK = "berserk",       -- Aggressive, close quarters, shotgun/knife/bazooka in face, low retreat
	SNIPER = "sniper",         -- Patient, rifle/bazooka, vantage points, high precision, long deliberation
	COWARD = "coward",         -- Defensive, grenade/mortar from deep cover, high retreat into bunkers
	CLUMSY = "clumsy",         -- Hilarious unpredictable mistakes, grenade bounces, fails
}

function M.resolve_archetype(bot)
	if bot.bot_archetype then return bot.bot_archetype end
	local c_id = bot.class_id or "recruit"
	local arch = M.ARCHETYPES.BERSERK
	if c_id == "sniper" then
		arch = M.ARCHETYPES.SNIPER
	elseif c_id == "artillery" or c_id == "artillery_2" or c_id == "rocketeer" then
		arch = M.ARCHETYPES.SNIPER
	elseif c_id == "medic" or c_id == "surgeon" or c_id == "engineer" then
		arch = M.ARCHETYPES.COWARD
	elseif c_id == "recruit" then
		arch = (math.random() > 0.45) and M.ARCHETYPES.CLUMSY or M.ARCHETYPES.COWARD
	else
		-- assault, sapper, commando
		arch = (math.random() > 0.5) and M.ARCHETYPES.BERSERK or M.ARCHETYPES.CLUMSY
	end
	bot.bot_archetype = arch
	return arch
end

-- Difficulty profiles.
-- angle_err (degrees) / power_err (share): aim error of a first shot at a new target
-- zero_in: how fast the error shrinks on repeated shots at the same target
-- wind: share of the real wind the bot accounts for (easy bots ignore it)
-- weapons: how many of the best-looking weapons get a full ballistic search
-- targets: how many enemies the search aims at
-- travel: farthest standing spot (px) the bot considers walking to
local SKILLS = {
	easy   = { angle_err = 9.0, power_err = 0.13, zero_in = 0.35, wind = 0.0, weapons = 2, targets = 1, travel = 70,  drown = false },
	normal = { angle_err = 4.5, power_err = 0.07, zero_in = 0.6,  wind = 0.7, weapons = 3, targets = 2, travel = 130, drown = true },
	hard   = { angle_err = 1.5, power_err = 0.03, zero_in = 0.9,  wind = 1.0, weapons = 5, targets = 2, travel = 170, drown = true },
	pvp    = { angle_err = 1.0, power_err = 0.02, zero_in = 1.0,  wind = 1.0, weapons = 6, targets = 3, travel = 170, drown = true },
}

function M.skill_profile(difficulty, is_pvp)
	if is_pvp then
		return SKILLS.pvp
	end
	return SKILLS[level_config.normalize_skill(difficulty or "normal")] or SKILLS.normal
end

-- Weapons the bot may consider (airstrike is planned separately)
local CANDIDATES = {
	weapons.TYPES.GRENADE, weapons.TYPES.BAZOOKA, weapons.TYPES.SHOTGUN, weapons.TYPES.RIFLE,
	weapons.TYPES.BURST, weapons.TYPES.MOLOTOV, weapons.TYPES.PEPPER, weapons.TYPES.GARLIC,
	weapons.TYPES.DRILL, weapons.TYPES.BEETLE, weapons.TYPES.HOLY_GRENADE, weapons.TYPES.DYNAMITE,
	weapons.TYPES.CLUSTER, weapons.TYPES.HOMING, weapons.TYPES.KNIFE,
}

-- Personality taste: multiplies the value of a shot made with the weapon
local ARCH_AFFINITY = {
	berserk = { knife = 1.35, shotgun = 1.25, bazooka = 1.15, burst = 1.1, dynamite = 1.1 },
	sniper  = { rifle = 1.35, bazooka = 1.15, homing = 1.15, burst = 1.1 },
	coward  = { grenade = 1.2, cluster = 1.2, beetle = 1.2, drill = 1.15, molotov = 1.1, knife = 0.6, shotgun = 0.8 },
	clumsy  = { grenade = 1.2, holy_grenade = 1.3, molotov = 1.2, dynamite = 1.25 },
}

local CLASS_AFFINITY = {
	sniper = { rifle = 1.25 },
	artillery = { bazooka = 1.2 }, artillery_2 = { bazooka = 1.2 }, rocketeer = { bazooka = 1.2, homing = 1.2 },
	sapper = { drill = 1.25, garlic = 1.2 }, sapper_2 = { drill = 1.25, garlic = 1.2 },
	commando = { knife = 1.2, burst = 1.2, molotov = 1.15 },
	medic = { pepper = 1.2, molotov = 1.15 }, surgeon = { pepper = 1.2, molotov = 1.15 },
	assault = { burst = 1.2, shotgun = 1.2 }, assault_2 = { burst = 1.2, shotgun = 1.2 },
}

-- Rare weapons are kept for shots that are clearly better than a plain grenade
local RARITY_COST = { common = 2, rare = 5, epic = 9, legendary = 14 }

-- Weapon each bot fired last (weak keys: a new match starts clean). Repeating it is worth a bit
-- less, so bots vary their arsenal instead of spamming the single strongest gun.
local last_weapon = setmetatable({}, { __mode = "k" })
local REPEAT_FACTOR = 0.8
local MOOD_SPREAD = 0.2 -- per-turn random liking of each weapon, +-10%

-- Preferred distance to the target by personality (px)
local RANGE_BAND = {
	berserk = { 50, 170 },
	sniper  = { 260, 600 },
	coward  = { 220, 480 },
	clumsy  = { 90, 360 },
}

local EYE = 8 -- shots leave and lines of sight start this high above a potato's center

local function can_use(bot, w_id)
	if not (bot and bot.id and inventory_manager.inventories[bot.id]) then
		return true
	end
	return inventory_manager.has_weapon(bot.id, w_id)
end

local function dist2(ax, ay, bx, by)
	return (ax - bx) * (ax - bx) + (ay - by) * (ay - by)
end

local function enemies_of(bot, potatoes)
	local list = {}
	for _, p in ipairs(potatoes) do
		if p.is_alive and p.team ~= bot.team then
			list[#list + 1] = p
		end
	end
	return list
end

-- Clear line from one eye point to another (a hit right at the end counts as clear)
local function has_los(terrain, x0, y0, x1, y1)
	local hit, hx, hy = terrain.raycast(x0, y0, x1, y1)
	return not hit or (math.abs(hx - x1) < 22 and math.abs(hy - y1) < 22)
end

-- Select optimal enemy target using Utility Scoring:
-- finishing off wounded targets, enemies by the water, personality range preference
function M.rank_targets(bot, enemies, terrain)
	local arch = M.resolve_archetype(bot)
	local ranked = {}
	for _, enemy in ipairs(enemies) do
		local dx = enemy.pos.x - bot.pos.x
		local dy = enemy.pos.y - bot.pos.y
		local dist = math.sqrt(dx * dx + dy * dy)
		local enemy_gy = terrain and terrain.get_smooth_ground_y(enemy.pos.x, 4.0) or enemy.pos.y

		local kill_urgency = (enemy.hp <= 45) and 180 or (100 - enemy.hp * 0.4)
		local dist_penalty = dist * 0.35

		local drown_bonus = 0
		if enemy_gy < constants.WATER_LEVEL + 40.0 then
			drown_bonus = 320
		elseif enemy_gy < constants.WATER_LEVEL + 70.0 then
			drown_bonus = 140
		end

		local arch_bias = 0
		if arch == M.ARCHETYPES.BERSERK then
			dist_penalty = dist * 0.6
			if dist < 120 then arch_bias = 220 end
		elseif arch == M.ARCHETYPES.SNIPER then
			if dist > 180 then arch_bias = 160 end
		elseif arch == M.ARCHETYPES.COWARD then
			if dist < 90 then dist_penalty = 200 end
		elseif arch == M.ARCHETYPES.CLUMSY then
			arch_bias = (math.random() - 0.5) * 80
		end

		-- Grudge: the potato that hurt this bot last gets extra attention
		if bot.last_attacker_id and bot.last_attacker_id == enemy.id then
			arch_bias = arch_bias + 90
		end

		ranked[#ranked + 1] = { p = enemy, utility = kill_urgency + drown_bonus + arch_bias - dist_penalty }
	end
	table.sort(ranked, function(a, b) return a.utility > b.utility end)
	local list = {}
	for i, r in ipairs(ranked) do
		list[i] = r.p
	end
	return list
end

function M.select_target(bot, enemies, terrain)
	return M.rank_targets(bot, enemies, terrain)[1]
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
	local curr_y = terrain.get_smooth_ground_y(curr_x, 4.0, bot.pos.y + 12.0)

	-- A. Scan terrain profile left and right (up to 55px)
	local max_left_y = curr_y
	local dist_l = 20
	for d = 8, 56, 8 do
		local lx = math.max(constants.POTATO_RADIUS, curr_x - d)
		local gy = terrain.get_smooth_ground_y(lx, 4.0, bot.pos.y + 16.0)
		if gy > max_left_y then
			max_left_y = gy
			dist_l = d
		end
	end

	local max_right_y = curr_y
	local dist_r = 20
	for d = 8, 56, 8 do
		local rx = math.min(constants.WORLD_WIDTH - constants.POTATO_RADIUS, curr_x + d)
		local gy = terrain.get_smooth_ground_y(rx, 4.0, bot.pos.y + 16.0)
		if gy > max_right_y then
			max_right_y = gy
			dist_r = d
		end
	end

	sit.left_wall_h = max_left_y - curr_y
	sit.right_wall_h = max_right_y - curr_y
	sit.dist_left = dist_l
	sit.dist_right = dist_r

	-- Jump height of potato with impulse 295, gravity 460 is ~94px
	local JUMP_CAPABLE_H = 65.0
	sit.can_jump_left = (sit.left_wall_h <= JUMP_CAPABLE_H)
	sit.can_jump_right = (sit.right_wall_h <= JUMP_CAPABLE_H)

	-- If both sides have steep walls > 14px, bot is in a pit/crater
	if sit.left_wall_h > 14.0 and sit.right_wall_h > 14.0 then
		sit.is_pit = true
		if not sit.can_jump_left and not sit.can_jump_right then
			sit.is_deep_pit = true
			sit.escape_dir = (sit.left_wall_h <= sit.right_wall_h) and -1 or 1
		else
			if sit.can_jump_left and sit.can_jump_right then
				sit.escape_dir = (sit.left_wall_h <= sit.right_wall_h) and -1 or 1
			elseif sit.can_jump_left then
				sit.escape_dir = -1
			else
				sit.escape_dir = 1
			end
		end
	end

	-- B. Threat analysis: which enemies have a direct line of fire on the bot
	for _, enemy in ipairs(enemies) do
		if enemy.is_alive and has_los(terrain, enemy.pos.x, enemy.pos.y + EYE, bot.pos.x, bot.pos.y + EYE) then
			sit.is_under_direct_aim = true
			sit.exposed_enemy_count = sit.exposed_enemy_count + 1
		end
	end

	-- C. Cliff and water hazard check
	local ground_l = terrain.get_smooth_ground_y(curr_x - 35, 4.0, bot.pos.y + 12.0)
	local ground_r = terrain.get_smooth_ground_y(curr_x + 35, 4.0, bot.pos.y + 12.0)
	sit.cliff_left = (curr_y - ground_l) > 28.0
	sit.cliff_right = (curr_y - ground_r) > 28.0
	sit.near_water = (curr_y < constants.WATER_LEVEL + 42.0)

	return sit
end

------------------------------------------------------------------------------------------
-- 2. POSITIONING
------------------------------------------------------------------------------------------

local WALK_SAMPLE = 6     -- px between ground samples along a path
local MAX_JUMP_RISE = 55  -- a rise the potato can still hop onto
local SAFE_ABOVE_WATER = 14

-- Ground heights walking from x0 in direction dir for up to `range` px.
-- Stops before water, sheer drops and walls too high to jump. Returns reachable spots.
local function reachable_spots(terrain, x0, y0, dir, range)
	local spots = {}
	local prev_y = terrain.get_smooth_ground_y(x0, 4.0, y0 + 8)
	local walked = 0
	local x = x0
	local r = constants.POTATO_RADIUS
	while walked < range do
		x = x + dir * WALK_SAMPLE
		walked = walked + WALK_SAMPLE
		if x < r + 4 or x > constants.WORLD_WIDTH - r - 4 then
			break
		end
		local gy = terrain.get_smooth_ground_y(x, 4.0, prev_y + MAX_JUMP_RISE + 8)
		if gy - prev_y > MAX_JUMP_RISE then
			break -- wall
		end
		if gy < constants.WATER_LEVEL + SAFE_ABOVE_WATER or prev_y - gy > 90 then
			break -- water or a deep fall ahead
		end
		spots[#spots + 1] = { x = x, y = gy, needs_jump = (gy - prev_y) > 10 }
		prev_y = gy
	end
	return spots
end

-- Decides where the bot walks before shooting.
-- Returns { target_x, intent, target_id, chat }
function M.plan_move(bot, all_potatoes, terrain, difficulty, is_pvp)
	local skill = M.skill_profile(difficulty, is_pvp)
	local arch = M.resolve_archetype(bot)
	local enemies = enemies_of(bot, all_potatoes)
	local ranked = M.rank_targets(bot, enemies, terrain)
	local target = ranked[1]
	if not target then
		return nil
	end

	local sit = M.analyze_situation(bot, enemies, terrain)
	local band = RANGE_BAND[arch] or RANGE_BAND.clumsy
	local cur_gy = terrain.get_smooth_ground_y(bot.pos.x, 4.0, bot.pos.y + 8)

	local candidates = { { x = bot.pos.x, y = cur_gy } }
	for _, dir in ipairs({ -1, 1 }) do
		local spots = reachable_spots(terrain, bot.pos.x, bot.pos.y, dir, skill.travel)
		-- Every third sample is enough to compare spots
		for i = 3, #spots, 3 do
			candidates[#candidates + 1] = spots[i]
		end
	end

	local best, best_score = candidates[1], -math.huge
	for _, c in ipairs(candidates) do
		local score = 0
		local eye_y = c.y + constants.POTATO_RADIUS + EYE

		-- Cover from enemies that are not the target, line of fire on the target
		local exposed = 0
		for _, e in ipairs(enemies) do
			if has_los(terrain, e.pos.x, e.pos.y + EYE, c.x, eye_y) then
				exposed = exposed + 1
			end
		end
		local cover_w = (arch == M.ARCHETYPES.COWARD) and 55 or ((arch == M.ARCHETYPES.BERSERK) and 12 or 30)
		score = score - exposed * cover_w
		if has_los(terrain, c.x, eye_y, target.pos.x, target.pos.y + EYE) then
			score = score + ((arch == M.ARCHETYPES.SNIPER) and 70 or 35)
		end

		-- Personality range
		local d = math.abs(c.x - target.pos.x)
		if d >= band[1] and d <= band[2] then
			score = score + 45
		else
			score = score - 0.18 * ((d < band[1]) and (band[1] - d) or (d - band[2]))
		end

		-- High ground, hazards, effort
		score = score + math.max(-30, math.min(30, (c.y - cur_gy) * 0.5))
		if c.y < constants.WATER_LEVEL + 40 then
			score = score - 60
		end
		local edge_l = terrain.get_smooth_ground_y(c.x - 28, 4.0, c.y + 20)
		local edge_r = terrain.get_smooth_ground_y(c.x + 28, 4.0, c.y + 20)
		if (c.y - edge_l) > 30 or (c.y - edge_r) > 30 then
			score = score - 35
		end
		score = score - math.abs(c.x - bot.pos.x) * 0.08
		if c.x == bot.pos.x then
			score = score + 8
		end
		-- Do not stand right next to an enemy unless that is the plan
		for _, e in ipairs(enemies) do
			if math.abs(e.pos.x - c.x) < 45 and arch ~= M.ARCHETYPES.BERSERK then
				score = score - 40
			end
		end
		if arch == M.ARCHETYPES.CLUMSY then
			score = score + (math.random() - 0.5) * 50
		end

		if score > best_score then
			best, best_score = c, score
		end
	end

	-- Out of a jumpable pit first: the open field is worth more than any spot in a hole
	local intent = "reposition"
	local chat = nil
	if math.abs(best.x - bot.pos.x) < 6 then
		intent = "hold"
	elseif sit.is_pit and not sit.is_deep_pit then
		intent = "escape_pit"
	elseif sit.is_under_direct_aim and arch ~= M.ARCHETYPES.BERSERK then
		intent = "seek_cover"
		chat = "cover"
	elseif arch == M.ARCHETYPES.BERSERK and math.abs(best.x - target.pos.x) < math.abs(bot.pos.x - target.pos.x) then
		intent = "charge"
		chat = "charge"
	end

	return {
		target_x = best.x,
		intent = intent,
		target_id = target.id,
		chat = chat,
		situation = sit,
	}
end

------------------------------------------------------------------------------------------
-- 3. ATTACK
------------------------------------------------------------------------------------------

-- Worth of a blast at (x, y) for the bot's side; positive is good for the bot.
-- direct: potato hit point-blank (takes the full damage), dir_x: shell flight direction.
local function blast_value(ctx, weapon, x, y, direct, dir_x)
	local bot = ctx.bot
	local value, kills, drowns = 0, 0, 0
	for _, p in ipairs(ctx.potatoes) do
		if p.is_alive then
			local dmg, kx, ky
			if p == direct then
				local force = weapon.blast_force or 150
				dmg, kx, ky = weapon.max_damage, (dir_x or 0) * force * 0.5, force * 0.4
			else
				dmg, kx, ky = physics_sim.estimate_blast(p.pos.x, p.pos.y, p.mass, x, y,
					weapon.blast_radius, weapon.blast_force, weapon.max_damage)
			end
			if dmg > 0 then
				local lethal = dmg >= p.hp
				local drown = not lethal and ctx.skill.drown
					and physics_sim.knockback_drowns(p.pos.x, p.pos.y, kx, ky, ctx.terrain)
				local worth = math.min(dmg, p.hp) + (lethal and 45 or 0) + (drown and (p.hp + 45) or 0)
				if p.team ~= bot.team then
					if not lethal and not drown then
						-- Status effects and elemental combos on survivors
						local st = weapon.status_effect
						if st then
							worth = worth + 8
							local combo = weapons.eval_combo(p.statuses, st.type)
							if combo then
								worth = worth + (combo.bonus_damage or 0) * 1.5
							end
						end
					end
					value = value + worth
					if lethal then kills = kills + 1 end
					if drown then drowns = drowns + 1 end
				elseif p == bot then
					value = value - worth * 2.5
				else
					value = value - worth * 1.6
				end
			end
		end
	end
	return value, kills, drowns
end

-- Bonus for effects that outlive the blast: fire patches, bomblets, beetles
local function lingering_value(ctx, weapon, x, y)
	local bonus = 0
	for _, e in ipairs(ctx.enemies) do
		local d2 = dist2(e.pos.x, e.pos.y, x, y)
		if weapon.on_hit == "napalm" and d2 < 45 * 45 then
			bonus = bonus + math.min(e.hp, (weapon.napalm_dps or 10) * (weapon.napalm_burn_time or 2.5) * 0.5)
		elseif weapon.on_hit == "pepper" and d2 < 50 * 50 then
			bonus = bonus + math.min(e.hp, (weapon.pepper_dps or 12) * (weapon.pepper_burn_time or 3.0) * 0.5)
		elseif weapon.cluster and d2 < 90 * 90 then
			bonus = bonus + 18
		elseif weapon.on_hit == "beetles" and d2 < 110 * 110 then
			bonus = bonus + 20
		end
	end
	return bonus
end

-- Extra pellets / burst rounds land near the first one
local function volley_mult(weapon, dist)
	if weapon.fire_mode == "spread" then
		return 1 + ((weapon.shot_count or 5) - 1) * math.max(0.15, math.min(1, 1 - dist / 260))
	elseif weapon.fire_mode == "multi_shot" then
		return 1 + ((weapon.shot_count or 3) - 1) * 0.75
	end
	return 1
end

local function weapon_taste(bot, w_id)
	local arch = ARCH_AFFINITY[M.resolve_archetype(bot)] or {}
	local cls = CLASS_AFFINITY[bot.class_id or ""] or {}
	return (arch[w_id] or 1) * (cls[w_id] or 1)
end

-- Simulates one shot and scores it into ctx.best (and ctx.closest, the safe fallback)
local function try_shot(ctx, weapon, vx, vy, target)
	local ox, oy = ctx.ox, ctx.oy
	local ix, iy, kind, hit_p, _, t = physics_sim.simulate_shot(ox, oy, vx, vy, weapon, ctx.terrain,
		ctx.potatoes, ctx.bot.id, ctx.sim_wind)
	ctx.tick()

	local value, kills, drowns = -5, 0, 0
	if kind ~= "water" and kind ~= "timeout" then
		value, kills, drowns = blast_value(ctx, weapon, ix, iy, hit_p, (vx >= 0) and 1 or -1)
		if value > -50 then
			value = value + lingering_value(ctx, weapon, ix, iy)
		end
		if weapon.homing then
			-- The missile locks on the enemy nearest to this impact and usually flies into it
			local near, near_d = nil, 160 * 160
			for _, e in ipairs(ctx.enemies) do
				local d = dist2(e.pos.x, e.pos.y, ix, iy)
				if d < near_d then near, near_d = e, d end
			end
			if near then
				local hv = blast_value(ctx, weapon, near.pos.x, near.pos.y, near, (near.pos.x >= ox) and 1 or -1)
				value = math.max(value, hv * 0.75)
			end
		end
	end

	if value > 0 then
		value = value * volley_mult(weapon, math.sqrt(dist2(ox, oy, target.pos.x, target.pos.y)))
			* weapon_taste(ctx.bot, weapon.id) * ctx.mood(weapon.id)
	end
	value = value - (RARITY_COST[weapon.rarity] or 4) * ((weapon.id == weapons.TYPES.GRENADE) and 0 or 1)
		- (t or 0) * 1.5 -- quick shots keep the game moving

	if value > ctx.best.value then
		ctx.best = { value = value, weapon_id = weapon.id, vx = vx, vy = vy, target_id = target.id,
			kills = kills, drowns = drowns }
	end

	-- Nothing reachable: still prefer a safe shell that lands as close to the target as possible
	local safe = (dist2(ix, iy, ox, oy) > (weapon.blast_radius * 1.2 + constants.POTATO_RADIUS) ^ 2)
	if safe and kind ~= "water" then
		local d = dist2(ix, iy, target.pos.x, target.pos.y)
		if d < ctx.closest.d then
			ctx.closest = { d = d, weapon_id = weapon.id, vx = vx, vy = vy, target_id = target.id }
		end
	end
	return ix, iy
end

-- Launch speed that lands a shell at (dx, dy) when thrown at angle theta (no wind)
local function ballistic_speed(dx, dy, theta, g)
	local c = math.cos(theta)
	local denom = 2 * c * c * (math.abs(dx) * math.tan(theta) - dy)
	if denom <= 0 then
		return nil
	end
	return math.sqrt(g * dx * dx / denom)
end

local ARC_ANGLES = { 12, 20, 28, 36, 44, 52, 60, 68, 76, 84 }

local function search_weapon(ctx, weapon, target)
	local ox, oy = ctx.ox, ctx.oy
	local tx, ty = target.pos.x, target.pos.y
	local dx, dy = tx - ox, ty - oy
	local dir = (dx >= 0) and 1 or -1
	local max_speed = weapon.max_power * physics_sim.LAUNCH_BOOST

	if weapon.fire_mode == "melee" then
		local reach = (weapon.melee_range or 42)
		local hx, hy = ox + dir * 20, oy - EYE + 4
		if dist2(hx, hy, tx, ty) < reach * reach then
			local value = blast_value(ctx, weapon, hx, hy, target, dir) * weapon_taste(ctx.bot, weapon.id) - 2
			if value > ctx.best.value then
				ctx.best = { value = value, weapon_id = weapon.id, vx = dir, vy = 0.05, target_id = target.id, melee = true }
			end
		end
		return
	end

	if weapon.fixed_power then
		-- Guns: sweep a fan around the straight line to the target
		local base = math.atan2(dy, dx)
		for k = -6, 6 do
			local a = base + math.rad(k * 1.5)
			try_shot(ctx, weapon, math.cos(a) * max_speed, math.sin(a) * max_speed, target)
		end
		return
	end

	local g = constants.GRAVITY * (weapon.gravity_mult or 1.0)
	for _, deg in ipairs(ARC_ANGLES) do
		local theta = math.rad(deg)
		local v = ballistic_speed(dx, dy, theta, g)
		if v and v <= max_speed * 1.05 then
			v = math.min(v, max_speed)
			local cx, sy = dir * math.cos(theta), math.sin(theta)
			-- Two probes, then one secant step on the landing x to correct for wind and terrain
			local x1 = try_shot(ctx, weapon, cx * v, sy * v, target)
			local v2 = math.min(max_speed, v * 1.05)
			if v2 > v then
				local x2 = try_shot(ctx, weapon, cx * v2, sy * v2, target)
				if math.abs(x2 - x1) > 0.5 then
					local vc = v + (v2 - v) * (tx - x1) / (x2 - x1)
					vc = math.max(60, math.min(max_speed, vc))
					if math.abs(vc - v) > 1 and math.abs(vc - v2) > 1 then
						try_shot(ctx, weapon, cx * vc, sy * vc, target)
					end
				end
			end
		end
	end
end

-- Rough appeal of a weapon before the expensive search, so only the promising ones are simulated
local function weapon_prescore(bot, weapon, dist, los)
	local s = weapon.max_damage + weapon.blast_radius * 0.5
	if weapon.fire_mode == "melee" then
		return (dist <= (weapon.melee_range or 42) + 6) and 200 or -1
	end
	if weapon.fixed_power or weapon.fire_mode == "spread" or weapon.fire_mode == "multi_shot" then
		if not los then return s * 0.2 end
		if weapon.fire_mode == "spread" then
			s = s * ((dist < 140) and 2.2 or 0.4)
		end
	end
	if weapon.id == weapons.TYPES.DYNAMITE and dist > 260 then
		s = s * 0.3 -- short throw
	end
	if weapon.id == weapons.TYPES.DRILL and not los then
		s = s * 1.3 -- digs through cover
	end
	s = s * weapon_taste(bot, weapon.id) - (RARITY_COST[weapon.rarity] or 4)
	return s
end

-- Finds the best shot from the bot's current position.
-- tick: called after every simulated shot (lets the caller spread the work over frames).
-- Returns { weapon_id, vx, vy, target_id, value, chat } or an airstrike plan with target_x.
function M.solve_attack(bot, all_potatoes, terrain, difficulty, is_pvp, wind_vector, tick)
	local skill = M.skill_profile(difficulty, is_pvp)
	local enemies = enemies_of(bot, all_potatoes)
	local targets = M.rank_targets(bot, enemies, terrain)
	if #targets == 0 then
		return nil
	end

	local wind = wind_vector or { x = 0, y = 0 }
	local ctx = {
		bot = bot,
		potatoes = all_potatoes,
		enemies = enemies,
		terrain = terrain,
		skill = skill,
		ox = bot.pos.x,
		oy = bot.pos.y + EYE,
		-- What the bot believes the wind is
		sim_wind = { x = (wind.x or 0) * skill.wind, y = (wind.y or 0) * skill.wind },
		tick = tick or function() end,
		best = { value = -math.huge },
		closest = { d = math.huge },
	}
	local moods = {}
	ctx.mood = function(w_id)
		if not moods[w_id] then
			moods[w_id] = (1 - MOOD_SPREAD * 0.5 + math.random() * MOOD_SPREAD)
				* ((last_weapon[bot] == w_id and w_id ~= weapons.TYPES.GRENADE) and REPEAT_FACTOR or 1)
		end
		return moods[w_id]
	end

	-- Shortlist weapons by quick appeal against the main target
	local main = targets[1]
	local main_dist = math.sqrt(dist2(ctx.ox, ctx.oy, main.pos.x, main.pos.y))
	local main_los = has_los(terrain, ctx.ox, ctx.oy, main.pos.x, main.pos.y + EYE)
	local pool = {}
	for _, w_id in ipairs(CANDIDATES) do
		if can_use(bot, w_id) then
			local w = weapons.get(w_id)
			local s = weapon_prescore(bot, w, main_dist, main_los)
			if s > 0 then
				pool[#pool + 1] = { w = w, s = s }
			end
		end
	end
	table.sort(pool, function(a, b) return a.s > b.s end)

	local grenade_in = false
	for i = 1, math.min(#pool, skill.weapons) do
		grenade_in = grenade_in or pool[i].w.id == weapons.TYPES.GRENADE
		for t = 1, math.min(#targets, skill.targets) do
			search_weapon(ctx, pool[i].w, targets[t])
		end
	end
	-- The unlimited grenade is always worth a look as a baseline
	if not grenade_in then
		search_weapon(ctx, weapons.get(weapons.TYPES.GRENADE), main)
	end

	local best = ctx.best
	local plan
	if best.value > 0 then
		plan = best
	elseif ctx.closest.weapon_id then
		plan = { weapon_id = ctx.closest.weapon_id, vx = ctx.closest.vx, vy = ctx.closest.vy,
			target_id = ctx.closest.target_id, value = 0 }
	else
		-- Blind lob towards the main target
		local dir = (main.pos.x >= bot.pos.x) and 1 or -1
		local v = weapons.get(weapons.TYPES.GRENADE).max_power * 0.7
		plan = { weapon_id = weapons.TYPES.GRENADE, vx = dir * v * 0.64, vy = v * 0.77, target_id = main.id, value = 0 }
	end

	-- A called-in airstrike beats a weak shell
	local strike = M.plan_airstrike(bot, main, all_potatoes, skill.angle_err * 7)
	if strike and (plan.value < 30 or math.random() < 0.3) then
		strike.target_id = main.id
		strike.value = 30
		strike.chat = "airstrike"
		return strike
	end

	if (plan.kills or 0) > 0 then
		plan.chat = "kill"
	elseif (plan.drowns or 0) > 0 then
		plan.chat = "drown"
	end
	last_weapon[bot] = plan.weapon_id
	return plan
end

-- Airstrike when the bot carries one and no ally stands under the bomb row.
-- aim_error: random spread of the marked spot (px)
function M.plan_airstrike(bot, target, all_potatoes, aim_error)
	if not (bot.id and inventory_manager.inventories[bot.id] and inventory_manager.has_weapon(bot.id, weapons.TYPES.AIRSTRIKE)) then
		return nil
	end
	local w = weapons.get(weapons.TYPES.AIRSTRIKE)
	local half_row = (w.bombs or 5) * (w.bomb_spacing or 34) * 0.5 + (w.blast_radius or 26)
	for _, p in ipairs(all_potatoes) do
		if p.is_alive and p.team == bot.team and math.abs(p.pos.x - target.pos.x) < half_row then
			return nil
		end
	end
	local dir = (target.pos.x >= bot.pos.x) and 1 or -1
	return {
		weapon_id = w.id,
		vx = dir * 0.6,
		vy = 0.8,
		target_x = target.pos.x + (math.random() * 2 - 1) * (aim_error or 0),
	}
end

------------------------------------------------------------------------------------------
-- 4. HUMAN TOUCH
------------------------------------------------------------------------------------------

-- Shots so far at the current target, per bot (weak keys: a new match starts clean)
local zeroing = setmetatable({}, { __mode = "k" })

-- Adds the bot's aim error. The first shot at a new target is the roughest; every further shot
-- at the same target is closer ("zeroing in"), like a human correcting after a miss.
function M.apply_error(bot, plan, difficulty, is_pvp)
	if plan.target_x or plan.melee then
		return plan
	end
	local skill = M.skill_profile(difficulty, is_pvp)
	local arch = M.resolve_archetype(bot)

	local mem = zeroing[bot]
	if not mem or mem.target_id ~= plan.target_id then
		mem = { target_id = plan.target_id, shots = 0 }
		zeroing[bot] = mem
	end
	local k = 1 / (1 + skill.zero_in * mem.shots)
	if mem.shots >= 1 and not plan.chat and math.random() < 0.5 then
		plan.chat = "zeroing"
	end
	mem.shots = mem.shots + 1

	local angle_err = skill.angle_err * k
	local power_err = skill.power_err * k
	if arch == M.ARCHETYPES.SNIPER then
		angle_err, power_err = angle_err * 0.5, power_err * 0.5
	elseif arch == M.ARCHETYPES.CLUMSY then
		angle_err, power_err = angle_err * 1.6, power_err * 1.6
	end

	-- Sum of two uniforms: a cheap bell curve in [-1, 1]
	local n1 = math.random() + math.random() - 1.0
	local n2 = math.random() + math.random() - 1.0
	local w = weapons.get(plan.weapon_id)
	if w.fixed_power then
		power_err = 0 -- guns always fire at full power
	end
	local a = math.atan2(plan.vy, plan.vx) + math.rad(angle_err) * n1
	local speed = math.sqrt(plan.vx * plan.vx + plan.vy * plan.vy) * (1 + power_err * n2)
	speed = math.min(speed, w.max_power * physics_sim.LAUNCH_BOOST)
	plan.vx = math.cos(a) * speed
	plan.vy = math.sin(a) * speed
	return plan
end

-- Short battle shouts, shown above the bot
M.CHAT = {
	kill = { ru = "Тебе конец!", en = "You're done!", pt = "Você já era!", fr = "C'est fini pour toi !", es = "¡Estás acabado!", tr = "İşin bitti!" },
	drown = { ru = "Иди поплавай!", en = "Go for a swim!", pt = "Vai nadar!", fr = "Va nager !", es = "¡A nadar!", tr = "Yüzmeye git!" },
	zeroing = { ru = "Теперь точно...", en = "This time for sure...", pt = "Agora vai...", fr = "Cette fois, c'est la bonne...", es = "Esta vez sí...", tr = "Bu sefer kesin..." },
	cover = { ru = "В укрытие!", en = "Taking cover!", pt = "Proteção!", fr = "À couvert !", es = "¡A cubierto!", tr = "Siper al!" },
	charge = { ru = "В атаку!", en = "Charge!", pt = "Ao ataque!", fr = "À l'attaque !", es = "¡Al ataque!", tr = "Saldırı!" },
	airstrike = { ru = "Авиаудар!", en = "Air support!", pt = "Apoio aéreo!", fr = "Soutien aérien !", es = "¡Apoyo aéreo!", tr = "Hava desteği!" },
}

return M
