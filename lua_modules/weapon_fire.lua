-- lua_modules/weapon_fire.lua
-- Weapon firing, projectile bookkeeping and burst queue for main.script.
-- Functions take the main.script instance (self); factory URLs resolve against it.

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local physics_sim = require("lua_modules.physics_sim")
local terrain_grid = require("lua_modules.terrain_grid")
local inventory_manager = require("lua_modules.inventory_manager")
local progression = require("lua_modules.progression")
local game_state = require("lua_modules.game_state")
local camera_controller = require("lua_modules.camera_controller")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local PLANE_ALTITUDE = 0.92 -- plane altitude as a share of the world height

-- Bots fire most weapons freely; these heavy ones they really have to carry and use up
local BOT_LIMITED = { airstrike = true, homing = true, dynamite = true, cluster = true, holy_grenade = true }

local function spawn_projectile(self, x, y, vx, vy, weapon_id, owner_id, target_id)
	local url = factory.create("#projectile_factory", vmath.vector3(x, y, 0.2), nil, {
		vel_x = vx,
		vel_y = vy,
		weapon_type = hash(weapon_id),
		owner_id = owner_id or 0,
		target_id = target_id or 0,
	})
	table.insert(self.active_projectiles, url)
	return url
end

local function find_potato(id)
	for _, p in ipairs(game_state.potatoes) do
		if p.id == id then
			return p
		end
	end
	return nil
end

-- Enemy closest to where the shot would land: the homing missile locks on it
local function homing_target(shooter, x, y, vx, vy, weapon)
	local ix, iy = physics_sim.simulate_shot(x, y, vx, vy, weapon, terrain_grid, {}, shooter.id, game_state.wind_vector)
	local best, best_d = nil, math.huge
	for _, p in ipairs(game_state.potatoes) do
		if p.is_alive and p.team ~= shooter.team then
			local d = (p.pos.x - ix) ^ 2 + (p.pos.y - iy) ^ 2
			if d < best_d then
				best, best_d = p, d
			end
		end
	end
	return best
end

-- Airstrike: a plane crosses the map towards the marked spot and drops a row of bombs there
local function call_airstrike(self, weapon, shooter, target_x)
	local from_x = shooter and shooter.pos.x or target_x
	local dir = (target_x >= from_x) and 1 or -1
	local start_x = (dir > 0) and -180 or (constants.WORLD_WIDTH + 180)
	local url = factory.create("#plane_factory", vmath.vector3(start_x, constants.WORLD_HEIGHT * PLANE_ALTITUDE, 0.45), nil, {
		target_x = target_x,
		dir = dir,
		owner_id = shooter and shooter.id or 0,
		bombs = weapon.bombs or 5,
		spacing = weapon.bomb_spacing or 34,
	})
	-- The plane counts as a live projectile until it has left the map
	table.insert(self.active_projectiles, url)
end

local function fire_melee(weapon)
	local potato = game_state.active_potato
	if not potato then
		return
	end
	local facing = potato.facing or 1
	local hit_x = potato.pos.x + facing * 20
	local hit_y = potato.pos.y + 4
	local level = progression.battle_weapon_level(weapon.id, potato.team, game_state.battle)
	local max_damage = math.floor(weapon.max_damage * progression.level_bonus(level).damage + 0.5)

	-- Visual slash effect
	msg.post(".", "spawn_explosion", { x = hit_x, y = hit_y, radius = 12 })
	camera_controller.shake(8, 0.15)

	-- Apply damage to potatoes in melee range
	for _, p in ipairs(game_state.potatoes) do
		if p.is_alive and p.id ~= potato.id then
			local dx = p.pos.x - hit_x
			local dy = p.pos.y - hit_y
			local dist = math.sqrt(dx * dx + dy * dy)
			if dist < (weapon.melee_range or 42) then
				local dmg = physics_sim.apply_blast(p, hit_x, hit_y, weapon.blast_radius, weapon.blast_force, max_damage)
				if dmg == 0 then
					dmg = max_damage
					p.hp = math.max(0, p.hp - dmg)
					if p.hp <= 0 then p.is_alive = false end
					p.vel.x = p.vel.x + facing * (weapon.blast_force or 400) * 0.7
					p.vel.y = p.vel.y + (weapon.blast_force or 400) * 0.5
					p.is_grounded = false
				end
				if dmg > 0 and potato.stats and p.team ~= potato.team then
					potato.stats.damage = potato.stats.damage + dmg
					if p.hp <= 0 then
						potato.stats.kills = potato.stats.kills + 1
					end
				end
				if dmg > 0 and p.url then
					msg.post(p.url, "apply_damage", { damage = dmg })
					msg.post("/gui_hud#gui", "show_damage", { x = p.pos.x, y = p.pos.y, amount = dmg })
					msg.post(".", "potato_damaged", { x = p.pos.x, y = p.pos.y, damage = dmg, potato_id = p.id })
				end
			end
		end
	end
end

-- Handles the "fire_weapon" message
function M.fire(self, message)
	local weapon = weapons.get(message.weapon_id or "grenade")
	sound_manager.play(weapon.sfx or "throw", { vary = 0.06 })
	local shooter = message.owner_id and find_potato(message.owner_id)

	-- Weapon recoil animation on firing potato
	if message.owner_id then
		for _, p in ipairs(game_state.potatoes) do
			if p.id == message.owner_id and p.url then
				msg.post(p.url, "on_recoil")
				if p.team == constants.TEAM_BLUE then
					game_state.consume_ammo(message.weapon_id or "grenade")
				elseif BOT_LIMITED[weapon.id] then
					inventory_manager.consume_ammo(p.id, weapon.id)
				end
				break
			end
		end
	end

	if weapon.fire_mode == "melee" then
		-- Instant melee damage — no projectile
		fire_melee(weapon)

	elseif weapon.fire_mode == "airstrike" then
		call_airstrike(self, weapon, shooter, message.target_x or (shooter and shooter.pos.x) or constants.WORLD_WIDTH * 0.5)

	elseif weapon.fire_mode == "spread" then
		-- Spread: multiple projectiles simultaneously in a fan
		local count = weapon.shot_count or 5
		local total_spread = weapon.spread_angle or 0.35
		local base_angle = math.atan2(message.vel_y, message.vel_x)
		local speed = math.sqrt(message.vel_x * message.vel_x + message.vel_y * message.vel_y)
		for i = 1, count do
			local frac = (i - 1) / math.max(1, count - 1) -- 0..1
			local angle = base_angle + (frac - 0.5) * total_spread
			spawn_projectile(self, message.origin_x, message.origin_y, math.cos(angle) * speed, math.sin(angle) * speed, weapon.id, message.owner_id)
		end

	elseif weapon.fire_mode == "multi_shot" then
		-- Multi-shot burst: fire first shot immediately, queue the rest
		spawn_projectile(self, message.origin_x, message.origin_y, message.vel_x, message.vel_y, weapon.id, message.owner_id)
		local remaining = (weapon.shot_count or 3) - 1
		if remaining > 0 then
			table.insert(self.burst_queue, {
				weapon_id = weapon.id,
				origin_x = message.origin_x,
				origin_y = message.origin_y,
				vel_x = message.vel_x,
				vel_y = message.vel_y,
				owner_id = message.owner_id or 0,
				shots_left = remaining,
				delay_timer = weapon.shot_delay or 0.12,
			})
		end

	else
		-- Single projectile (default: grenade, rifle, molotov, bazooka, holy_grenade, homing)
		local target = weapon.homing and shooter and homing_target(shooter, message.origin_x, message.origin_y, message.vel_x, message.vel_y, weapon)
		spawn_projectile(self, message.origin_x, message.origin_y, message.vel_x, message.vel_y, weapon.id, message.owner_id, target and target.id)
	end

	game_state.on_action_fired()
end

-- Fires queued burst shots with a slight random spread
function M.update_bursts(self, dt)
	local bq = self.burst_queue[1]
	if not bq then
		return
	end
	bq.delay_timer = bq.delay_timer - dt
	if bq.delay_timer > 0 then
		return
	end

	local weapon = weapons.get(bq.weapon_id)
	local spread = weapon.shot_spread or 0.06
	local angle = math.atan2(bq.vel_y, bq.vel_x) + (math.random() - 0.5) * spread
	local speed = math.sqrt(bq.vel_x * bq.vel_x + bq.vel_y * bq.vel_y)
	spawn_projectile(self, bq.origin_x, bq.origin_y, math.cos(angle) * speed, math.sin(angle) * speed, bq.weapon_id, bq.owner_id)

	bq.shots_left = bq.shots_left - 1
	if bq.shots_left <= 0 then
		table.remove(self.burst_queue, 1)
	else
		bq.delay_timer = weapon.shot_delay or 0.12
	end
end

-- Drops finished projectiles; potatoes near a live projectile panic/flinch
function M.track_projectiles(self)
	local alive = {}
	for _, proj_url in ipairs(self.active_projectiles) do
		local ok, ppos = pcall(go.get_position, proj_url)
		if ok and ppos then
			table.insert(alive, proj_url)
			for _, p in ipairs(game_state.potatoes) do
				if p.is_alive and p.url then
					local dx = p.pos.x - ppos.x
					local dy = p.pos.y - ppos.y
					if (dx * dx + dy * dy) < 2304 then -- < 48 px
						msg.post(p.url, "alert_aimed")
					end
				end
			end
		end
	end
	self.active_projectiles = alive
end

function M.spawn_napalm(self, message)
	sound_manager.play(message.is_pepper and "pop" or "sizzle", { vary = 0.1 })
	local count = message.count or 6
	local spread = message.spread or 40
	for _ = 1, count do
		local ox = (math.random() - 0.5) * spread * 2
		local oy = (math.random() - 0.5) * spread * 0.5 + 10
		local pos = vmath.vector3(message.x + ox, message.y + oy, 0.4)
		local np = factory.create("#napalm_factory", pos, nil, {
			burn_time = message.burn_time or 2.5,
			radius = message.radius or 8,
			dps = message.dps or 10,
			is_pepper = (message.is_pepper == true),
		})
		table.insert(self.active_projectiles, np) -- track for settling
	end
end

function M.spawn_beetles(self, message)
	local count = message.count or 3
	local vx_offsets = { -110, 0, 110 }
	for i = 1, count do
		local base_vx = vx_offsets[i] or ((math.random() - 0.5) * 200)
		local svx = base_vx + (math.random() - 0.5) * 35
		local svy = 150 + (math.random() * 50)
		spawn_projectile(self, message.x, message.y + 6, svx, svy, "beetle_minion", message.owner_id)
	end
end

-- Cluster bomb burst: bomblets fan out upwards
function M.spawn_cluster(self, message)
	local count = message.count or 5
	for i = 1, count do
		local vx = (i - (count + 1) / 2) * 70 + (math.random() - 0.5) * 40
		local vy = 240 + math.random() * 140
		spawn_projectile(self, message.x, message.y + 6, vx, vy, message.weapon_id or "bomblet", message.owner_id)
	end
end

-- One bomb of the airstrike row
function M.drop_airstrike_bomb(self, message)
	spawn_projectile(self, message.x, message.y, message.vx or 0, -30, "airstrike_bomb", message.owner_id)
	sound_manager.play("whistle", { vary = 0.1 })
end

function M.drop_air_bomb(self, message)
	spawn_projectile(self, message.x, message.y, (math.random() - 0.5) * 40, -340, "air_bomb", 999)
	sound_manager.play("whistle", { vary = 0.1 })
end

return M
