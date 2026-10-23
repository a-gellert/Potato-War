-- lua_modules/match_spawner.lua
-- Spawning and clearing of match entities (potatoes, crates, barrels) for main.script.
-- Functions take the main.script instance (self); factory URLs resolve against it.

local constants = require("lua_modules.constants")
local terrain_grid = require("lua_modules.terrain_grid")
local game_state = require("lua_modules.game_state")
local player_profile = require("lua_modules.player_profile")
local level_config = require("lua_modules.level_config")
local i18n = require("lua_modules.i18n")
local classes = require("lua_modules.classes")
local inventory_manager = require("lua_modules.inventory_manager")
local tutorial = require("lua_modules.tutorial")

local M = {}

local ENEMY_HAT_POOL = { "hat_viking", "hat_beret", "hat_bandana", "hat_tophat", "hat_crown" }

function M.is_mobile_platform()
	local s_info = sys.get_sys_info()
	local name = s_info.system_name or ""
	if name == "Android" or name == "iPhone OS" then
		return true
	end
	-- Check for HTML5 touch device detection (Poki Mobile Web)
	if html5 and html5.run then
		local has_touch = html5.run("('ontouchstart' in window || navigator.maxTouchPoints > 0) ? '1' : '0'")
		if has_touch == "1" then
			return true
		end
	end
	return false
end

-- If x falls into a water gap/chasm, search left/right for the nearest solid ground.
-- Returns the adjusted x and its ground height.
function M.find_dry_x(x, from_wy, opts)
	opts = opts or {}
	local min_x = opts.min_x or (constants.POTATO_RADIUS + 20)
	local max_x = opts.max_x or (constants.WORLD_WIDTH - constants.POTATO_RADIUS - 20)
	local margin = opts.margin or 20
	local step = opts.step or 15
	local max_offset = opts.max_offset or 220

	local gy = terrain_grid.get_smooth_ground_y(x, 6.0, from_wy)
	if gy >= constants.WATER_LEVEL + margin then
		return x, gy
	end
	for offset = step, max_offset, step do
		local test_l = math.max(min_x, x - offset)
		local test_r = math.min(max_x, x + offset)
		local gy_l = terrain_grid.get_smooth_ground_y(test_l, 6.0, from_wy)
		local gy_r = terrain_grid.get_smooth_ground_y(test_r, 6.0, from_wy)
		if gy_l > constants.WATER_LEVEL + margin then
			return test_l, gy_l
		elseif gy_r > constants.WATER_LEVEL + margin then
			return test_r, gy_r
		end
	end
	return x, gy
end

local function pick_blue_hat(match_cfg, is_tutorial)
	local hat = match_cfg and match_cfg.hat_blue
	if not hat then
		local s_id = match_cfg and match_cfg.skin_blue
		if s_id and player_profile.SKINS_BY_ID[s_id] then
			hat = player_profile.SKINS_BY_ID[s_id].hat
		end
	end
	if not hat or hat == "" or hat == "none" then
		if is_tutorial then
			return "none"
		end
		local skin = player_profile.get_equipped_skin()
		hat = skin and skin.hat or "hat_cap"
	end
	return hat
end

local function pick_red_hat(match_cfg, potato_id, is_tutorial)
	local red_idx = potato_id - (match_cfg and (match_cfg.blue_count or match_cfg.player_count) or 2)
	red_idx = math.max(1, red_idx)
	local hat = match_cfg and match_cfg.red_hats and match_cfg.red_hats[red_idx]
	if not hat then
		local s_id = match_cfg and match_cfg.skin_red
		if s_id and player_profile.SKINS_BY_ID[s_id] and player_profile.SKINS_BY_ID[s_id].hat ~= "none" then
			hat = player_profile.SKINS_BY_ID[s_id].hat
		end
	end
	if not hat or hat == "none" then
		if is_tutorial then
			return "none"
		end
		-- Red enemy team: wear distinct hats from the player
		local equipped = player_profile.get_equipped_skin()
		local my_hat = (match_cfg and match_cfg.hat_blue) or (equipped and equipped.hat)
		local filtered = {}
		for _, h in ipairs(ENEMY_HAT_POOL) do
			if h ~= my_hat then table.insert(filtered, h) end
		end
		hat = (#filtered > 0) and filtered[((red_idx - 1) % #filtered) + 1] or "hat_viking"
	end
	return hat
end

function M.spawn_potato(self, x, team, potato_id, initial_hp, max_hp, from_wy, class_id, unit_level, ammo_overrides)
	local gy
	x, gy = M.find_dry_x(x, from_wy)

	local spawn_y = math.max(constants.WATER_LEVEL + 30, gy + constants.POTATO_RADIUS)
	constants.log(">>> SPAWNING POTATO:", potato_id, "team:", team, "x:", x, "y:", spawn_y, "hp:", initial_hp, "class:", class_id, "lvl:", unit_level)

	-- Resolve class archetype and initialize its inventory
	class_id = class_id or "recruit"
	local c_def = classes.get(class_id)
	inventory_manager.register_potato(potato_id, c_def.id, ammo_overrides)

	local initial_facing = (team == constants.TEAM_BLUE) and 1 or -1
	local potato_hp = initial_hp or c_def.stats.base_hp or 100
	local potato_max_hp = max_hp or c_def.stats.max_hp or potato_hp
	local pos = vmath.vector3(x, spawn_y, 0.1)

	local url = factory.create("#potato_factory", pos, nil, {
		team = team,
		potato_id = potato_id,
		hp = potato_hp,
		max_hp = potato_max_hp,
		facing = initial_facing
	})

	local c_name = i18n.field(c_def, "name")
	if c_name == "" then c_name = "Recruit" end

	local record = {
		id = potato_id,
		team = team,
		class_id = c_def.id,
		class_name = c_name,
		unit_level = unit_level or 1,
		mass = c_def.stats.mass or 1.0,
		walk_speed_mult = c_def.stats.walk_speed_mult or 1.0,
		jump_mult = c_def.stats.jump_mult or 1.0,
		statuses = {},
		pos = vmath.vector3(x, spawn_y, 0.1),
		vel = vmath.vector3(0, 0, 0),
		hp = potato_hp,
		max_hp = potato_max_hp,
		radius = constants.POTATO_RADIUS,
		facing = initial_facing,
		is_alive = true,
		is_grounded = false,
		url = url
	}

	msg.post(url, "set_facing", { facing = initial_facing })
	msg.post(url, "set_class", { class_id = c_def.id })
	msg.post(url, "set_weapon", { weapon_id = "grenade" })

	-- Apply hat from lobby match configuration or player profile
	local match_cfg = game_state.match_config
	local is_tutorial = (game_state.mode == constants.MODE_TUTORIAL)
	local hat
	if team == constants.TEAM_BLUE then
		hat = pick_blue_hat(match_cfg, is_tutorial)
	else
		hat = pick_red_hat(match_cfg, potato_id, is_tutorial)
	end
	msg.post(url, "set_hat", { hat = hat })

	table.insert(self.spawned_potatoes, record)
	table.insert(game_state.potatoes, record)
	return record
end

function M.clear(self)
	for _, p in ipairs(self.spawned_potatoes) do
		pcall(go.delete, p.url)
	end
	self.spawned_potatoes = {}
	game_state.potatoes = {}
	self.active_projectiles = {}

	for _, b in ipairs(self.spawned_barrels or {}) do
		pcall(go.delete, b.url)
	end
	self.spawned_barrels = {}

	if self.airship_url then
		pcall(go.delete, self.airship_url)
		self.airship_url = nil
	end
	self.airship_timer = 55.0

	for _, c in ipairs(self.spawned_crates or {}) do
		pcall(go.delete, c.url)
	end
	self.spawned_crates = {}
	self.crate_timer = 60.0
end

-- Training ground: flat field, the target stands on the same line in front of the player
function M.spawn_tutorial(self)
	local player = M.spawn_potato(self, tutorial.PLAYER_X, constants.TEAM_BLUE, 1, 100, 100, nil, "recruit", 1, { bazooka = 99 })
	local target = M.spawn_potato(self, tutorial.TARGET_X, constants.TEAM_RED, 2, tutorial.TARGET_HP, tutorial.TARGET_HP, nil, "recruit", 1)
	target.is_target = true
	tutorial.start()
	tutorial.spawn_x = player.pos.x
end

-- Shuffled, well-separated spawn slots across the map, nudged off water
local function make_spawn_slots(total, from_wy)
	local slots = {}
	local slot_w = (1720 - 200) / math.max(1, total)
	local order = {}
	for i = 1, total do
		table.insert(order, i)
	end
	for i = #order, 2, -1 do
		local j = math.random(1, i)
		order[i], order[j] = order[j], order[i]
	end

	for i = 1, total do
		local x_cand = 200 + (order[i] - 0.5) * slot_w + (math.random() - 0.5) * (slot_w * 0.55)
		x_cand = math.max(160, math.min(1760, x_cand))
		x_cand = M.find_dry_x(x_cand, from_wy, { min_x = 160, max_x = 1760, margin = 25, step = 20, max_offset = 180 })
		table.insert(slots, x_cand)
	end
	return slots
end

-- Regular battle: both squads, defensive crate and TNT barrels.
-- ctx: { config, lobby_config, is_campaign, is_defense, active_level, terrain_preset }
function M.spawn_battle(self, ctx)
	local config = ctx.config
	local lobby_config = ctx.lobby_config
	local is_campaign = ctx.is_campaign
	local active_level = ctx.active_level

	-- Determine squad counts for both teams
	local player_squad = is_campaign and player_profile.get_squad() or nil
	local blue_count = (lobby_config and (lobby_config.blue_count or lobby_config.potato_count))
		or (config and (config.player_count or config.blue_count))
		or (player_squad and #player_squad) or 1
	local red_count = (lobby_config and (lobby_config.red_count or lobby_config.potato_count))
		or (config and (config.enemy_count or config.red_count))
		or level_config.get_enemy_count(active_level) or 1

	local player_max_hp = constants.PLAYER_HP
	local player_hp = is_campaign and player_profile.get_campaign_hp() or player_max_hp
	local from_wy = (ctx.terrain_preset == "cavern") and (constants.WORLD_HEIGHT * 0.55)
		or ((ctx.terrain_preset == "floating_islands") and (constants.WORLD_HEIGHT * 0.85))
		or nil

	local spawn_slots = make_spawn_slots(blue_count + red_count, from_wy)

	for i = 1, blue_count do
		local x = spawn_slots[i] or (220 + i * 160)
		local c_id = (lobby_config and lobby_config.blue_classes and lobby_config.blue_classes[i])
			or (config and config.blue_classes and config.blue_classes[i])
			or (is_campaign and (player_squad and player_squad[i] and player_squad[i].class_id or "recruit"))
			or classes.get_random_specialized_class()
		local u_lvl = is_campaign and (player_squad and player_squad[i] and player_squad[i].level or 1) or math.random(1, 2)
		local cur_hp = is_campaign and player_hp or nil
		local cur_max = is_campaign and player_max_hp or nil
		M.spawn_potato(self, x, constants.TEAM_BLUE, i, cur_hp, cur_max, from_wy, c_id, u_lvl)
	end

	for i = 1, red_count do
		local x = spawn_slots[blue_count + i] or (1600 - i * 160)
		local enemy_class = (lobby_config and lobby_config.red_classes and lobby_config.red_classes[i])
			or (config and config.red_classes and config.red_classes[i])
			or (is_campaign and ((config.enemy_classes and config.enemy_classes[i]) or level_config.get_enemy_class(active_level, i)))
			or classes.get_random_specialized_class()
		local enemy_lvl = is_campaign and ((config.enemy_levels and config.enemy_levels[i]) or level_config.get_enemy_level(active_level, i)) or math.random(1, 2)
		local enemy_hp = is_campaign and level_config.get_enemy_hp(active_level, i) or nil
		M.spawn_potato(self, x, constants.TEAM_RED, blue_count + i, enemy_hp, enemy_hp, from_wy, enemy_class, enemy_lvl)
	end

	-- Defensive Fortifications: crate on the defensive rampart
	if ctx.is_defense then
		local parapet_x = 350
		local p_gy = terrain_grid.get_smooth_ground_y(parapet_x, 4.0, from_wy)
		if p_gy > constants.WATER_LEVEL + 20 then
			local crate_pos = vmath.vector3(parapet_x, p_gy + 16, 0.15)
			local c_url = factory.create("#crate_factory", crate_pos, nil, { weapon_id = hash("grenade"), ammo_count = 2 })
			table.insert(self.spawned_crates, { id = c_url, url = c_url, x = parapet_x, y = crate_pos.y })
		end
	end

	-- TNT Barrels in the neutral center (1-2)
	local barrel_count = (math.random() < 0.75) and 2 or 1
	for b = 1, barrel_count do
		local bx = 960 + (b - 1.5) * 140 + math.random(-40, 40)
		local bgy = terrain_grid.get_smooth_ground_y(bx, 4.0, from_wy)
		if bgy > constants.WATER_LEVEL + 25 then
			local bpos = vmath.vector3(bx, bgy + 17, 0.15)
			local b_url = factory.create("#barrel_factory", bpos)
			table.insert(self.spawned_barrels, { id = b_url, url = b_url, x = bx, y = bpos.y })
		end
	end
end

-- Rewarded revive: recreate the fallen blue potato with half HP on dry ground
function M.revive_potato(self, pot, hp)
	if pot.url then
		pcall(go.delete, pot.url)
	end

	local from_wy = (self.current_terrain_preset == "cavern") and (constants.WORLD_HEIGHT * 0.55) or nil
	local rx = math.max(constants.POTATO_RADIUS + 20, math.min(constants.WORLD_WIDTH - constants.POTATO_RADIUS - 20, pot.pos.x))
	local gy
	rx, gy = M.find_dry_x(rx, from_wy, { step = 12, max_offset = 120 })

	local spawn_y = math.max(constants.WATER_LEVEL + 30, gy + constants.POTATO_RADIUS)
	pot.pos = vmath.vector3(rx, spawn_y, 0.1)
	pot.vel = vmath.vector3(0, 0, 0)
	pot.hp = hp
	pot.is_alive = true
	pot.is_grounded = false

	local new_url = factory.create("#potato_factory", pot.pos, nil, {
		team = constants.TEAM_BLUE,
		potato_id = pot.id,
		hp = hp,
		max_hp = pot.max_hp or 100,
		facing = 1
	})
	pot.url = new_url
	msg.post(new_url, "set_facing", { facing = 1 })
	msg.post(new_url, "set_weapon", { weapon_id = game_state.selected_weapon_id or "grenade" })

	local skin = player_profile.get_equipped_skin()
	if skin then
		msg.post(new_url, "set_skin", { tint = skin.tint, hat = skin.hat, skin_id = skin.id })
	end
	return new_url
end

return M
