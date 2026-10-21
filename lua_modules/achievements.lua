-- lua_modules/achievements.lua
-- Micro-achievements and challenge badges for Potato War

local constants = require("lua_modules.constants")
local i18n = require("lua_modules.i18n")

local M = {}

M.DEFINITIONS = {
	one_shot = {
		id = "one_shot",
		icon = "🎯",
		title = { ru = "СНАЙПЕР!", en = "ONE SHOT!", tr = "KESKİN NİŞANCI!", es = "¡UN DISPARO!", pt = "UM TIRO!", fr = "UN COUP !" },
		desc = { ru = "Уничтожил врага за один выстрел!", en = "Killed enemy in one shot!", tr = "Düşmanı tek atışta vurdu!", es = "¡Eliminó al enemigo de un tiro!", pt = "Eliminou o inimigo com um tiro!", fr = "Ennemi éliminé en un coup !" },
		points = 50,
	},
	water_kill = {
		id = "water_kill",
		icon = "🌊",
		title = { ru = "В ВОДУ!", en = "WATER KILL!", tr = "SUYA!", es = "¡AL AGUA!", pt = "NA ÁGUA!", fr = "À L'EAU !" },
		desc = { ru = "Сбросил вражескую картошку в воду!", en = "Sent enemy potato to watery grave!", tr = "Düşman patatesi suya attı!", es = "¡Tiró la papa enemiga al agua!", pt = "Jogou a batata inimiga na água!", fr = "Patate ennemie jetée à l'eau !" },
		points = 50,
	},
	long_shot = {
		id = "long_shot",
		icon = "🏹",
		title = { ru = "ДАЛЬНИЙ ПРИЦЕЛ!", en = "LONG SHOT!", tr = "UZAK ATIŞ!", es = "¡TIRO LARGO!", pt = "TIRO LONGO!", fr = "TIR DE LOIN !" },
		desc = { ru = "Попадание с огромной дистанции!", en = "Direct hit from across the map!", tr = "Çok uzak mesafeden isabet!", es = "¡Impacto desde larga distancia!", pt = "Acerto de longa distância!", fr = "Tir réussi à longue distance !" },
		points = 40,
	},
	flawless = {
		id = "flawless",
		icon = "🛡️",
		title = { ru = "БЕЗ УРОНА!", en = "FLAWLESS!", tr = "KUSURSUZ!", es = "¡IMPECABLE!", pt = "PERFEITO!", fr = "SANS FAUTE !" },
		desc = { ru = "Победа без единой царапины!", en = "Won without taking any damage!", tr = "Hiç hasar almadan zafer!", es = "¡Victoria sin sufrir daño!", pt = "Vitória sem sofrer dano!", fr = "Victoire sans subir de dégâts !" },
		points = 100,
	},
	clutch = {
		id = "clutch",
		icon = "❤️",
		title = { ru = "НА ГРАНИ!", en = "CLUTCH!", tr = "SON ANDA!", es = "¡AL LÍMITE!", pt = "NO LIMITE!", fr = "JUSTE À TEMPS !" },
		desc = { ru = "Победа с критическим здоровьем!", en = "Won with critical health remaining!", tr = "Kritik canla kazanılan zafer!", es = "¡Victoria con salud crítica!", pt = "Vitória com vida crítica!", fr = "Victoire avec santé critique !" },
		points = 100,
	},
	double_kill = {
		id = "double_kill",
		icon = "💥",
		title = { ru = "ДВОЙНОЙ УДАР!", en = "DOUBLE KILL!", tr = "ÇİFTE VURUŞ!", es = "¡DOBLE IMPACTO!", pt = "GOLPE DUPLO!", fr = "DOUBLE ÉLIMINATION !" },
		desc = { ru = "2 врага уничтожены одним выстрелом!", en = "2 enemies killed in a single shot!", tr = "Tek atışta 2 düşman yok edildi!", es = "¡2 enemigos eliminados de un tiro!", pt = "2 inimigos eliminados com um tiro!", fr = "2 ennemis éliminés en un tir !" },
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
	local lang = i18n.current_lang or "en"
	local title_str = (def.title and (def.title[lang] or def.title.en)) or def.title_en or achieve_id
	local desc_str = (def.desc and (def.desc[lang] or def.desc.en)) or def.desc_en or ""
	local entry = {
		id = def.id,
		icon = def.icon,
		title = title_str,
		desc = desc_str,
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
