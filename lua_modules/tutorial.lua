-- lua_modules/tutorial.lua
-- Training level flow: move -> jump -> aim & shoot -> keep shooting until the target is destroyed.
-- Pure logic (no GUI); main.script feeds events, the HUD reads hints.

local constants = require("lua_modules.constants")

local M = {}

M.PLAYER_X = 300
M.TARGET_X = 640
M.TARGET_HP = 60
M.MOVE_DISTANCE = 40 -- px the player must walk to complete step 1
M.RULE_TIP_DELAY = 3.5 -- seconds into a turn before the rule tip replaces the shot feedback

local COLOR_GREEN = vmath.vector4(0.3, 0.95, 0.5, 1.0)
local COLOR_GOLD = vmath.vector4(0.95, 0.85, 0.2, 1.0)
local COLOR_CYAN = vmath.vector4(0.2, 0.85, 1.0, 1.0)
local COLOR_ORANGE = vmath.vector4(1.0, 0.55, 0.2, 1.0)
local COLOR_WHITE = vmath.vector4(0.92, 0.94, 1.0, 1.0)

local TEXTS = {
	ru = {
		aim_title = "АТАКА",
		aim_direct = "Зажми и тяни!",
		aim_sling = "Оттяни назад!",
		move_title = "ДВИЖЕНИЕ",
		move_text = "Иди к врагу",
		jump_title = "ПРЫЖОК",
		jump_text = "Перепрыгни препятствие",
		finish_title = "БОЙ",
		finish_text = "Уничтожь врага!",
		hit = "Попал! Осталось %d HP",
		short = "Недолёт! Тяни сильнее",
		long = "Перелёт! Тяни слабее",
		rules = {
			"Один выстрел за ход — затем ходит враг",
			"Следи за таймером своего хода",
			"Оружие меняется внизу экрана [1-5]",
			"Ветер сносит снаряды — следи за стрелкой",
			"Вода внизу — мгновенная гибель",
		},
	},
	en = {
		aim_title = "ATTACK",
		aim_direct = "Hold & drag!",
		aim_sling = "Pull back!",
		move_title = "MOVE",
		move_text = "Walk to the enemy",
		jump_title = "JUMP",
		jump_text = "Jump over obstacle",
		finish_title = "BATTLE",
		finish_text = "Destroy the enemy!",
		hit = "Hit! %d HP left",
		short = "Too short! Drag further",
		long = "Too far! Drag less",
		rules = {
			"One shot per turn, then enemy fires",
			"Watch your turn timer at the top",
			"Switch weapons at the bottom [1-5]",
			"Wind pushes projectiles — watch the arrow",
			"Water below is instant death",
		},
	},
	pt = {
		aim_title = "ATAQUE",
		aim_direct = "Segure e arraste!",
		aim_sling = "Puxe para trás!",
		move_title = "MOVER",
		move_text = "Vá até o inimigo",
		jump_title = "PULAR",
		jump_text = "Pule o obstáculo",
		finish_title = "BATALHA",
		finish_text = "Destrua o inimigo!",
		hit = "Acertou! Restam %d HP",
		short = "Curto! Arraste mais",
		long = "Longe! Arraste menos",
		rules = {
			"Um tiro por turno, depois o inimigo atira",
			"Fique atento ao tempo do seu turno",
			"Troque de arma embaixo [1-5]",
			"O vento desvia os projéteis",
			"A água embaixo é morte certa",
		},
	},
	fr = {
		aim_title = "ATTAQUE",
		aim_direct = "Glisse pour viser !",
		aim_sling = "Tire en arrière !",
		move_title = "BOUGER",
		move_text = "Avance vers l'ennemi",
		jump_title = "SAUTER",
		jump_text = "Saute l'obstacle",
		finish_title = "COMBAT",
		finish_text = "Détruis l'ennemi !",
		hit = "Touché ! Reste %d PV",
		short = "Trop court ! Tire plus fort",
		long = "Trop loin ! Tire moins fort",
		rules = {
			"Un tir par tour, puis l'ennemi tire",
			"Surveille le chronomètre de tour",
			"Change d'arme en bas [1-5]",
			"Le vent dévie les tirs — surveille la flèche",
			"L'eau en bas est mortelle",
		},
	},
	es = {
		aim_title = "ATAQUE",
		aim_direct = "¡Mantén y arrastra!",
		aim_sling = "¡Tira hacia atrás!",
		move_title = "MOVER",
		move_text = "Acércate al enemigo",
		jump_title = "SALTAR",
		jump_text = "Salta el obstáculo",
		finish_title = "BATALLA",
		finish_text = "¡Destruye al enemigo!",
		hit = "¡Impacto! Quedan %d HP",
		short = "¡Muy corto! Arrastra más",
		long = "¡Te pasaste! Arrastra menos",
		rules = {
			"Un disparo por turno, luego el enemigo",
			"Vigila el tiempo de tu turno",
			"Cambia de arma abajo [1-5]",
			"El viento desvía los disparos",
			"El agua abajo es muerte instantánea",
		},
	},
	tr = {
		aim_title = "SALDIRI",
		aim_direct = "Basılı tut ve çek!",
		aim_sling = "Geriye çek!",
		move_title = "HAREKET",
		move_text = "Düşmana yaklaş",
		jump_title = "ZIPLA",
		jump_text = "Engeli aş",
		finish_title = "SAVAŞ",
		finish_text = "Düşmanı yok et!",
		hit = "İsabet! %d HP kaldı",
		short = "Kısa kaldı! Daha çok çek",
		long = "Çok uzağa gitti! Daha az çek",
		rules = {
			"Her turda bir atış, sonra düşman atar",
			"Yukarıdaki tur süresine dikkat et",
			"Alttan silahı değiştir [1-5]",
			"Rüzgar mermiyi saptırır",
			"Aşağıdaki su anında yok eder",
		},
	},
}

function M.reset()
	M.active = false
	M.tutorial_level = 1
	M.stage = "aim"
	M.spawn_x = M.PLAYER_X
	M.shots = 0
	M.hits = 0
	M.awaiting_impact = false
	M.last_result = nil -- "hit" | "short" | "long"
	M.turn_elapsed = 0
end

M.reset()

function M.start(level)
	M.reset()
	level = level or 1
	if level == 2 and require("lua_modules.player_profile").is_tutorial_completed() then
		return
	end
	M.active = true
	M.tutorial_level = level
	if M.tutorial_level == 1 then
		M.stage = "aim"
	elseif M.tutorial_level == 2 then
		M.stage = "move"
	end
end

function M.is_active()
	if M.tutorial_level == 2 and require("lua_modules.player_profile").is_tutorial_completed() then
		return false
	end
	return M.active and M.stage ~= nil and M.stage ~= "done"
end

local function find_team(team)
	for _, p in ipairs(M.potatoes or {}) do
		if p.team == team then
			return p
		end
	end
	return nil
end

-- Called every frame by main.script with the live potato list
function M.update(dt, potatoes)
	if not M.active then
		return
	end
	M.potatoes = potatoes
	M.turn_elapsed = M.turn_elapsed + dt

	if M.tutorial_level == 2 and M.stage == "move" then
		local player = find_team(constants.TEAM_BLUE)
		if player and math.abs(player.pos.x - (M.spawn_x or player.pos.x)) >= M.MOVE_DISTANCE then
			M.stage = "jump"
		end
	end
end

function M.on_jump()
	if M.active and M.stage == "jump" then
		if M.tutorial_level == 2 then
			M.stage = "done"
			M.active = false
		else
			M.stage = "aim"
		end
	end
end

function M.on_shot()
	if not M.active then
		return
	end
	if M.tutorial_level == 2 then
		M.stage = "done"
		M.active = false
		return
	end
	-- In Level 1:
	M.stage = "finish"
	M.shots = M.shots + 1
	M.awaiting_impact = true
	M.last_result = nil
end

function M.on_impact(x)
	if not (M.active and M.awaiting_impact) then
		return
	end
	M.awaiting_impact = false
	if M.last_result == "hit" then
		return
	end
	local player = find_team(constants.TEAM_BLUE)
	local target = find_team(constants.TEAM_RED)
	if not (player and target) then
		return
	end
	local dir = (target.pos.x >= player.pos.x) and 1 or -1
	M.last_result = ((x - target.pos.x) * dir < 0) and "short" or "long"
end

function M.on_enemy_hit()
	if M.active then
		M.hits = M.hits + 1
		M.last_result = "hit"
	end
end

function M.on_turn_start()
	M.turn_elapsed = 0
	M.awaiting_impact = false
end

function M.wants_hand()
	return M.active and M.tutorial_level == 1 and (M.stage == "aim" or (M.hits == 0 and not M.awaiting_impact and M.turn_elapsed > 1.2))
end

-- Returns structured step info: stage, title, text, color, active keys
function M.get_step_info(is_slingshot)
	local lang = require("lua_modules.i18n").current_lang or "ru"
	local t = TEXTS[lang] or TEXTS.en

	if M.stage == "move" then
		return {
			stage = "move",
			title = t.move_title,
			text = t.move_text,
			color = COLOR_GREEN,
			keys = { a = true, d = true },
		}
	elseif M.stage == "jump" then
		return {
			stage = "jump",
			title = t.jump_title,
			text = t.jump_text,
			color = COLOR_GOLD,
			keys = { w = true, space = true },
		}
	elseif M.stage == "aim" then
		return {
			stage = "aim",
			title = t.aim_title,
			text = is_slingshot and t.aim_sling or t.aim_direct,
			color = COLOR_CYAN,
			keys = {},
		}
	end

	-- "finish": shot feedback first, then a rule tip
	local title = t.finish_title
	local text = t.finish_text
	local color = COLOR_WHITE
	if M.turn_elapsed < M.RULE_TIP_DELAY and M.last_result then
		if M.last_result == "hit" then
			local target = find_team(constants.TEAM_RED)
			local hp = target and math.max(0, target.hp) or 0
			text = string.format(t.hit, hp)
			color = COLOR_GREEN
		else
			text = t[M.last_result] or t.finish_text
			color = COLOR_ORANGE
		end
	else
		local idx = ((math.max(1, M.shots) - 1) % #t.rules) + 1
		text = t.rules[idx]
	end
	return {
		stage = "finish",
		title = title,
		text = text,
		color = color,
		keys = {},
	}
end

-- Returns hint text and color for the current step (backwards compatibility)
function M.get_hint(is_ru, is_slingshot)
	local info = M.get_step_info(is_slingshot)
	return info.title .. ": " .. info.text, info.color
end

return M
