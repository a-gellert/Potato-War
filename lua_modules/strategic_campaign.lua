-- lua_modules/strategic_campaign.lua
-- Turn-based Strategic Campaign controller for Potato War
-- Manages player phases (Income -> Strategy/Target Selection -> Battle -> AI Counter-Attack)
-- AI counter-attack target selection on vulnerable Blue border sectors,
-- and persistence via player_profile.lua.

local territory_map = require("lua_modules.territory_map")
local player_profile = require("lua_modules.player_profile")
local constants = require("lua_modules.constants")

local M = {}

-- Campaign Phases
M.PHASE_INCOME = "income"
M.PHASE_STRATEGY = "strategy"
M.PHASE_BATTLE = "battle"
M.PHASE_COUNTERATTACK = "counterattack"
M.PHASE_VICTORY = "victory"
M.PHASE_DEFEAT = "defeat"

-- Active Battle State
M.active_battle_sector_id = nil
M.active_battle_type = "assault" -- "assault" (attacking Red sector) or "defense" (defending Blue sector)
M.phase = M.PHASE_STRATEGY
M.selected_target_id = nil

-- Callbacks
M.on_phase_changed = nil
M.on_income_collected = nil
M.on_counterattack_resolved = nil

function M.set_phase(new_phase)
	M.phase = new_phase
	if M.on_phase_changed then
		M.on_phase_changed(new_phase)
	end
end

function M.get_turn()
	return player_profile.get_campaign_turn() or 1
end

function M.get_supplies()
	return player_profile.get_points() or 0
end

function M.add_supplies(amount)
	return player_profile.add_points(amount)
end

function M.spend_supplies(amount)
	if M.get_supplies() >= amount then
		player_profile.add_points(-amount)
		return true
	end
	return false
end

-- Save / Load progress integration
function M.save_progress()
	territory_map.save_to_profile()
end

function M.load_progress()
	return territory_map.load_from_profile()
end

-- Phase 1: Collect strategic income at turn start
function M.collect_income()
	M.set_phase(M.PHASE_INCOME)
	local income = territory_map.get_income("blue")
	if income > 0 then
		M.add_supplies(income)
	end
	if M.on_income_collected then
		M.on_income_collected(income, M.get_supplies())
	end
	M.set_phase(M.PHASE_STRATEGY)
	return income
end

-- Fortify sector spending supplies
function M.fortify_sector(sector_id)
	local cost = territory_map.get_fortify_cost(sector_id)
	if M.get_supplies() < cost then
		return false, "Недостаточно припасов"
	end
	local ok, err = territory_map.fortify_sector(sector_id)
	if ok then
		M.spend_supplies(cost)
		return true, cost
	end
	return false, err
end
M.fortify = M.fortify_sector

-- Target Selection (Phase 2: Strategy)
function M.get_available_targets()
	return territory_map.get_available_targets("blue")
end

function M.select_target(sector_id)
	local s = territory_map.get_sector(sector_id)
	if not s then
		return false, "Сектор не найден"
	end

	local available = M.get_available_targets()
	local is_avail = false
	for _, target in ipairs(available) do
		if target.id == s.id then
			is_avail = true
			break
		end
	end

	if not is_avail then
		return false, "Сектор не является доступной приграничной целью"
	end

	M.selected_target_id = s.id
	M.active_battle_sector_id = s.id
	return true, s
end

-- Build match configuration from sector attributes
function M.build_battle_config(s, battle_type)
	battle_type = battle_type or ((s.owner == "red") and "assault" or "defense")
	local def = s.defense_level or 1
	local enemy_hp = 70
	local enemy_count = math.min(4, math.max(2, s.garrison or 2))
	local enemy_skill = "easy"

	if def == 1 then
		enemy_hp = 70
		enemy_skill = "easy"
	elseif def == 2 then
		enemy_hp = 85
		enemy_skill = "normal"
	else
		enemy_hp = (s.id == 18) and 125 or 100
		enemy_skill = "hard"
	end

	return {
		mode = constants.MODE_CAMPAIGN,
		sector_id = s.id,
		sector_name_ru = s.name_ru,
		sector_name_en = s.name_en,
		region = s.region,
		battle_type = battle_type,
		biome = s.biome,
		terrain_type = s.terrain_preset,
		terrain_preset = s.terrain_preset,
		potato_count = enemy_count,
		enemy_count = (battle_type == "assault") and enemy_count or 2,
		red_count = (battle_type == "assault") and enemy_count or 2,
		player_count = (battle_type == "defense") and enemy_count or 1,
		blue_count = (battle_type == "defense") and enemy_count or 1,
		enemy_hp = enemy_hp,
		opponent_type = "bot",
		enemy_skill = enemy_skill,
		bot_difficulty = enemy_skill,
		defense_level = def,
		income_reward = s.income,
	}
end

-- Phase 3: Prepare and launch battle for sector
function M.prepare_battle(sector_id)
	sector_id = sector_id or M.selected_target_id
	local s = sector_id and territory_map.get_sector(sector_id)
	if not s then return nil end

	M.active_battle_sector_id = sector_id
	if s.owner == "red" then
		M.active_battle_type = "assault"
	else
		M.active_battle_type = "defense"
	end

	local battle_config = M.build_battle_config(s, M.active_battle_type)
	M.set_phase(M.PHASE_BATTLE)
	return battle_config
end

function M.launch_battle(sector_id)
	if sector_id then
		local ok, err = M.select_target(sector_id)
		if not ok then
			return false, err
		end
	end
	local cfg = M.prepare_battle(M.active_battle_sector_id)
	if not cfg then
		return false, "Не удалось сформировать бой"
	end
	return true, cfg
end

-- AI Counter-attack algorithm:
-- Evaluates vulnerable Blue border sectors using multi-factor heuristic:
-- 1. Defense level (defense 1 is extremely vulnerable, defense 3 is heavily fortified)
-- 2. Red threat pressure (number of bordering Red sectors)
-- 3. Economic value (higher income makes it an attractive prize)
-- 4. Isolation (fewer Blue neighbors)
function M.find_ai_counterattack_target()
	local vulnerable = territory_map.get_border_sectors("blue")
	if #vulnerable == 0 then
		return nil
	end

	local scored_candidates = {}
	for _, sec in ipairs(vulnerable) do
		local def = sec.defense_level or 1
		local defense_score = (4 - def) * 100

		local red_neighbors = {}
		local blue_neighbors_count = 0
		for _, nid in ipairs(sec.neighbors or {}) do
			local n_sec = territory_map.get_sector(nid)
			if n_sec then
				if n_sec.owner == "red" then
					table.insert(red_neighbors, n_sec)
				else
					blue_neighbors_count = blue_neighbors_count + 1
				end
			end
		end

		local threat_score = #red_neighbors * 30
		local income_score = math.floor((sec.income or 30) * 0.5)
		local isolation_score = math.max(0, 4 - blue_neighbors_count) * 20
		local total_vulnerability = defense_score + threat_score + income_score + isolation_score

		-- Select strongest Red staging sector
		table.sort(red_neighbors, function(a, b)
			if (a.defense_level or 1) ~= (b.defense_level or 1) then
				return (a.defense_level or 1) > (b.defense_level or 1)
			else
				return (a.income or 0) > (b.income or 0)
			end
		end)

		table.insert(scored_candidates, {
			sector = sec,
			staging_sector = red_neighbors[1],
			vulnerability = total_vulnerability,
			defense_level = def,
			red_pressure = #red_neighbors,
			income = sec.income or 30,
		})
	end

	table.sort(scored_candidates, function(a, b)
		return a.vulnerability > b.vulnerability
	end)

	local best = scored_candidates[1]
	return {
		target_sector = best.sector,
		staging_sector = best.staging_sector,
		vulnerability_score = best.vulnerability,
		all_candidates = scored_candidates,
	}
end

-- Selects a vulnerable frontline Blue sector and marks it under attack
function M.trigger_ai_counter_attack()
	local plan = M.find_ai_counterattack_target()
	if not plan then return nil end

	local target = plan.target_sector
	territory_map.set_under_attack(target.id, true)
	return target
end

-- Executes AI Counter-attack (auto-resolve simulation or marks for battle)
function M.execute_ai_counterattack(auto_resolve)
	if auto_resolve == nil then auto_resolve = true end

	local plan = M.find_ai_counterattack_target()
	if not plan then
		M.advance_turn()
		return { target = nil, defended = true, reason = "No border target available" }
	end

	local target = plan.target_sector
	local staging = plan.staging_sector

	if not auto_resolve then
		territory_map.set_under_attack(target.id, true)
		local defense_cfg = M.build_battle_config(target, "defense")
		M.active_battle_sector_id = target.id
		M.active_battle_type = "defense"
		M.set_phase(M.PHASE_BATTLE)
		return {
			target = target,
			staging = staging,
			battle_config = defense_cfg,
			requires_player_match = true,
		}
	end

	-- Auto-resolve simulation based on Blue sector defense_level
	local def = target.defense_level or 1
	local base_hold_chance = 35 + (def - 1) * 27.5
	if staging and staging.defense_level == 3 then
		base_hold_chance = base_hold_chance - 10
	elseif staging and staging.defense_level == 1 then
		base_hold_chance = base_hold_chance + 10
	end
	base_hold_chance = math.max(15, math.min(95, base_hold_chance))

	local roll = math.random(1, 100)
	local defended = (roll <= base_hold_chance)
	local defense_degraded = false

	local stats = player_profile.get_campaign_stats()
	if defended then
		stats.counterattacks_repelled = (stats.counterattacks_repelled or 0) + 1
		territory_map.set_under_attack(target.id, false)
		if def > 1 and roll > (base_hold_chance * 0.75) then
			target.defense_level = target.defense_level - 1
			defense_degraded = true
		end
	else
		territory_map.capture_sector(target.id, "red")
		stats.sectors_lost = (stats.sectors_lost or 0) + 1
	end
	player_profile.set_campaign_stats(stats)

	local result = {
		target_id = target.id,
		target_name_ru = target.name_ru,
		target_name_en = target.name_en,
		staging_id = staging and staging.id,
		defended = defended,
		captured = not defended,
		defense_level = target.defense_level,
		defense_degraded = defense_degraded,
		roll = roll,
		hold_chance = base_hold_chance,
	}

	if M.on_counterattack_resolved then
		M.on_counterattack_resolved(result)
	end

	if territory_map.is_defeat("blue") then
		M.set_phase(M.PHASE_DEFEAT)
		return result
	end

	M.advance_turn()
	return result
end

-- Resolve tactical battle results
function M.resolve_battle(winner_team, points_earned)
	local sector_id = M.active_battle_sector_id
	local s = sector_id and territory_map.get_sector(sector_id)
	local stats = player_profile.get_campaign_stats()

	local is_victory = (winner_team == constants.TEAM_BLUE) or (winner_team == true) or (winner_team == "blue")
	local outcome = {
		sector_id = sector_id,
		sector_name_ru = s and s.name_ru or "Сектор",
		sector_name_en = s and s.name_en or "Sector",
		is_victory = is_victory,
		battle_type = M.active_battle_type,
		points_earned = points_earned or 0,
	}
	M.last_battle_outcome = outcome

	if is_victory then
		stats.battles_won = (stats.battles_won or 0) + 1
		if M.active_battle_type == "assault" then
			territory_map.capture_sector(sector_id, "blue")
			stats.sectors_conquered = (stats.sectors_conquered or 0) + 1
			outcome.message_ru = "СЕКТОР ОСВОБОЖДЕН! Флаг Синих поднят!"
			outcome.message_en = "SECTOR LIBERATED! Blue flag is raised!"
		else
			-- Defended successfully
			territory_map.set_under_attack(sector_id, false)
			stats.counterattacks_repelled = (stats.counterattacks_repelled or 0) + 1
			outcome.message_ru = "АТАКА ОТБИТА! Оборона рубежа удержана!"
			outcome.message_en = "ATTACK REPELLED! Sector defense held!"
		end

		if territory_map.is_victory("blue") then
			M.set_phase(M.PHASE_VICTORY)
			outcome.campaign_won = true
			player_profile.set_campaign_stats(stats)
			return outcome
		end
	else
		stats.battles_lost = (stats.battles_lost or 0) + 1
		if M.active_battle_type == "defense" then
			-- Enemy captures or degrades defense
			local lvl = s and s.defense_level or 1
			if lvl > 1 then
				s.defense_level = lvl - 1
				territory_map.set_under_attack(sector_id, false)
				outcome.message_ru = "ОБОРОНА ОСЛАБЛЕНА! Уровень защиты снижен."
				outcome.message_en = "DEFENSE WEAKENED! Fortification degraded."
			else
				territory_map.capture_sector(sector_id, "red")
				stats.sectors_lost = (stats.sectors_lost or 0) + 1
				outcome.message_ru = "СЕКТОР ПОТЕРЯН! Враг захватил территорию!"
				outcome.message_en = "SECTOR LOST! Enemy seized the territory!"
			end
		else
			outcome.message_ru = "ШТУРМ ПРОВАЛЕН! Войска отступили на базу."
			outcome.message_en = "ASSAULT FAILED! Forces retreated to base."
		end

		if territory_map.is_defeat("blue") then
			M.set_phase(M.PHASE_DEFEAT)
			outcome.campaign_lost = true
			player_profile.set_campaign_stats(stats)
			return outcome
		end
	end

	player_profile.set_campaign_stats(stats)
	player_profile.set_campaign_turn(M.get_turn() + 1)
	M.set_phase(M.PHASE_COUNTERATTACK)

	-- Check for enemy counter-attack on next turn
	local counter_target = nil
	if is_victory and math.random() < 0.45 then
		counter_target = M.trigger_ai_counter_attack()
	end
	outcome.counter_target = counter_target

	M.active_battle_sector_id = nil
	M.selected_target_id = nil
	return outcome
end

-- Advance to next turn (advances turn counter, collects income)
function M.advance_turn()
	player_profile.set_campaign_turn(M.get_turn() + 1)
	M.selected_target_id = nil
	M.active_battle_sector_id = nil
	M.collect_income()
	return M.get_turn()
end

-- Campaign Initialization
function M.init(force_reset)
	if force_reset then
		M.start_new_campaign()
	else
		M.load_progress()
	end

	if territory_map.is_victory("blue") then
		M.set_phase(M.PHASE_VICTORY)
	elseif territory_map.is_defeat("blue") then
		M.set_phase(M.PHASE_DEFEAT)
	else
		M.collect_income()
	end
	return M
end

function M.start_new_campaign()
	territory_map.reset_map()
	player_profile.set_campaign_turn(1)
	player_profile.set_campaign_stats({
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	})
	M.active_battle_sector_id = nil
	M.selected_target_id = nil
	M.active_battle_type = "assault"
	M.collect_income()
end

function M.reset_campaign()
	return M.start_new_campaign()
end

-- Get comprehensive campaign summary for UI
function M.get_campaign_summary(lang)
	local stats = territory_map.get_stats()
	local targets = territory_map.get_available_targets("blue")
	return {
		turn = M.get_turn(),
		phase = M.phase,
		supplies = M.get_supplies(),
		income = territory_map.get_income("blue"),
		stats = stats,
		available_targets = targets,
		active_battle_sector_id = M.active_battle_sector_id,
		active_battle_type = M.active_battle_type,
	}
end

return M
