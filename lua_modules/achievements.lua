-- lua_modules/achievements.lua
-- Micro-achievements and challenge badges for Potato War

local constants = require("lua_modules.constants")
local i18n = require("lua_modules.i18n")

local M = {}

M.DEFINITIONS = {
	one_shot = {
		id = "one_shot",
		icon = "🎯",
		title_ru = "СНАЙПЕР!",
		title_en = "ONE SHOT!",
		desc_ru = "Уничтожил врага за один выстрел!",
		desc_en = "Killed enemy in one shot!",
		points = 50,
	},
	water_kill = {
		id = "water_kill",
		icon = "🌊",
		title_ru = "В ВОДУ!",
		title_en = "WATER KILL!",
		desc_ru = "Сбросил вражескую картошку в воду!",
		desc_en = "Sent enemy potato to watery grave!",
		points = 50,
	},
	long_shot = {
		id = "long_shot",
		icon = "🏹",
		title_ru = "ДАЛЬНИЙ ПРИЦЕЛ!",
		title_en = "LONG SHOT!",
		desc_ru = "Попадание с огромной дистанции!",
		desc_en = "Direct hit from across the map!",
		points = 40,
	},
	flawless = {
		id = "flawless",
		icon = "🛡️",
		title_ru = "БЕЗ УРОНА!",
		title_en = "FLAWLESS!",
		desc_ru = "Победа без единой царапины!",
		desc_en = "Won without taking any damage!",
		points = 100,
	},
	clutch = {
		id = "clutch",
		icon = "❤️",
		title_ru = "НА ГРАНИ!",
		title_en = "CLUTCH!",
		desc_ru = "Победа с критическим здоровьем!",
		desc_en = "Won with critical health remaining!",
		points = 100,
	},
	double_kill = {
		id = "double_kill",
		icon = "💥",
		title_ru = "ДВОЙНОЙ УДАР!",
		title_en = "DOUBLE KILL!",
		desc_ru = "2 врага уничтожены одним выстрелом!",
		desc_en = "2 enemies killed in a single shot!",
		points = 120,
	},
}

M.match_state = {
	player_damage_taken = 0,
	kills_this_turn = 0,
	unlocked_ids = {},
	unlocked_list = {},
}

function M.reset_match()
	M.match_state.player_damage_taken = 0
	M.match_state.kills_this_turn = 0
	M.match_state.unlocked_ids = {}
	M.match_state.unlocked_list = {}
end

function M.on_turn_start(active_team)
	M.match_state.kills_this_turn = 0
end

local function trigger_achievement(achieve_id)
	if M.match_state.unlocked_ids[achieve_id] then
		return nil
	end

	local def = M.DEFINITIONS[achieve_id]
	if not def then return nil end

	M.match_state.unlocked_ids[achieve_id] = true
	local entry = {
		id = def.id,
		icon = def.icon,
		title = (i18n.current_lang == "ru") and def.title_ru or def.title_en,
		desc = (i18n.current_lang == "ru") and def.desc_ru or def.desc_en,
		points = def.points,
	}
	table.insert(M.match_state.unlocked_list, entry)
	return entry
end

function M.on_player_hit_enemy(dist, was_full_hp, damage, is_kill)
	local triggered = {}

	-- 1. Long Shot (> 420 px distance)
	if dist and dist > 420 then
		local a = trigger_achievement("long_shot")
		if a then table.insert(triggered, a) end
	end

	-- 2. One Shot (killed from 100% full HP in single blast)
	if is_kill and was_full_hp then
		local a = trigger_achievement("one_shot")
		if a then table.insert(triggered, a) end
	end

	-- 3. Double Kill (2 kills in same turn)
	if is_kill then
		M.match_state.kills_this_turn = M.match_state.kills_this_turn + 1
		if M.match_state.kills_this_turn >= 2 then
			local a = trigger_achievement("double_kill")
			if a then table.insert(triggered, a) end
		end
	end

	return triggered
end

function M.on_drown(potato, active_team)
	if potato and potato.team == constants.TEAM_RED and active_team == constants.TEAM_BLUE then
		local a = trigger_achievement("water_kill")
		return a
	end
	return nil
end

function M.on_player_damaged(damage)
	if damage and damage > 0 then
		M.match_state.player_damage_taken = M.match_state.player_damage_taken + damage
	end
end

function M.evaluate_match_end(winner_team, player_hp)
	local end_triggered = {}

	if winner_team == constants.TEAM_BLUE then
		-- Flawless: zero damage taken
		if M.match_state.player_damage_taken == 0 then
			local a = trigger_achievement("flawless")
			if a then table.insert(end_triggered, a) end
		end

		-- Clutch: won with <= 20 HP
		if player_hp and player_hp > 0 and player_hp <= 20 then
			local a = trigger_achievement("clutch")
			if a then table.insert(end_triggered, a) end
		end
	end

	local total_bonus = 0
	for _, a in ipairs(M.match_state.unlocked_list) do
		total_bonus = total_bonus + (a.points or 0)
	end

	return M.match_state.unlocked_list, total_bonus
end

return M
