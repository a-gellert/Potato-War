-- lua_modules/tutorial.lua
-- Training level flow: move -> jump -> aim & shoot -> keep shooting until the target is destroyed.
-- Pure logic (no GUI); main.script feeds events, the HUD reads hints.

local constants = require("lua_modules.constants")

local M = {}

M.PLAYER_X = 300
M.TARGET_X = 640
M.TARGET_HP = 100
M.MOVE_DISTANCE = 40 -- px the player must walk to complete step 1
M.RULE_TIP_DELAY = 3.5 -- seconds into a turn before the rule tip replaces the shot feedback

local COLOR_GREEN = vmath.vector4(0.3, 0.95, 0.5, 1.0)
local COLOR_GOLD = vmath.vector4(0.95, 0.85, 0.2, 1.0)
local COLOR_CYAN = vmath.vector4(0.2, 0.85, 1.0, 1.0)
local COLOR_ORANGE = vmath.vector4(1.0, 0.55, 0.2, 1.0)
local COLOR_WHITE = vmath.vector4(0.92, 0.94, 1.0, 1.0)

local TEXTS = {
	ru = {
		move = "Шаг 1/4: Подойди к врагу — [A/D] или стрелки на экране",
		jump = "Шаг 2/4: Прыгни — [Пробел / W] или кнопка прыжка",
		aim_direct = "Шаг 3/4: Зажми ЛКМ и тяни к врагу — пунктир покажет полёт. Отпусти — выстрел!",
		aim_sling = "Шаг 3/4: Оттяни назад от врага, как рогатку, и отпусти — выстрел!",
		hit = "Попал! У врага осталось %d HP. Шаг 4/4: добей его!",
		short = "Недолёт! Тяни дальше — выстрел будет сильнее",
		long = "Перелёт! Тяни ближе — выстрел будет слабее",
		rules = {
			"Шаг 4/4: стреляй, пока не уничтожишь врага. В бою за ход — один выстрел, потом стреляет враг",
			"В бою время хода ограничено — таймер в круге сверху. Синий круг — твой ход, красный — ход врага",
			"Оружие меняется кнопками внизу или клавишами 1–5. Полный арсенал — [Q]",
			"Ветер сносит снаряды — следи за стрелкой справа вверху",
			"Вода внизу — мгновенная гибель. Не стой у края обрыва!",
		},
	},
	en = {
		move = "Step 1/4: Walk towards the enemy — [A/D] or on-screen arrows",
		jump = "Step 2/4: Jump — [Space / W] or the jump button",
		aim_direct = "Step 3/4: Hold the mouse and drag towards the enemy — the dots show the flight. Release to fire!",
		aim_sling = "Step 3/4: Pull back away from the enemy like a slingshot and release to fire!",
		hit = "Hit! The enemy has %d HP left. Step 4/4: finish it off!",
		short = "Too short! Drag further for more power",
		long = "Too far! Drag less for a softer shot",
		rules = {
			"Step 4/4: keep firing until the enemy is destroyed. In battle you get one shot per turn, then the enemy fires",
			"In battle each turn is timed — see the top circle. Blue circle: your turn, red: the enemy's",
			"Switch weapons with the bottom buttons or keys 1–5. Full arsenal — [Q]",
			"Wind pushes projectiles — watch the arrow in the top right",
			"The water below is instant death. Don't stand at the cliff edge!",
		},
	},
		pt = {
			move = "Passo 1/4: Ande até o inimigo — [A/D] ou as setas na tela",
			jump = "Passo 2/4: Pule — [Espaço / W] ou o botão de pulo",
			aim_direct = "Passo 3/4: Segure o mouse e arraste em direção ao inimigo — os pontos mostram a trajetória. Solte para atirar!",
			aim_sling = "Passo 3/4: Puxe para trás, longe do inimigo, como um estilingue, e solte para atirar!",
			hit = "Acertou! O inimigo ainda tem %d HP. Passo 4/4: acabe com ele!",
			short = "Curto demais! Arraste mais para ter mais força",
			long = "Longe demais! Arraste menos para um tiro mais fraco",
			rules = {
				"Passo 4/4: continue atirando até destruir o inimigo. Na batalha você dá um tiro por turno, depois o inimigo atira",
				"Na batalha cada turno tem tempo limitado — veja o círculo no alto. Círculo azul: sua vez, vermelho: a do inimigo",
				"Troque de arma com os botões de baixo ou com as teclas 1–5. Arsenal completo — [Q]",
				"O vento desvia os projéteis — fique de olho na seta no canto superior direito",
				"A água lá embaixo é morte instantânea. Não fique na beira do penhasco!",
			},
		},
		fr = {
			move = "Étape 1/4 : Avance vers l'ennemi — [A/D] ou les flèches à l'écran",
			jump = "Étape 2/4 : Saute — [Espace / W] ou le bouton de saut",
			aim_direct = "Étape 3/4 : Maintiens la souris et tire vers l'ennemi — les points montrent la trajectoire. Relâche pour tirer !",
			aim_sling = "Étape 3/4 : Tire en arrière, loin de l'ennemi, comme un lance-pierre, puis relâche pour tirer !",
			hit = "Touché ! Il reste %d PV à l'ennemi. Étape 4/4 : achève-le !",
			short = "Trop court ! Tire plus loin pour plus de puissance",
			long = "Trop loin ! Tire moins pour un tir plus doux",
			rules = {
				"Étape 4/4 : tire jusqu'à détruire l'ennemi. En combat, tu as un tir par tour, puis l'ennemi tire",
				"En combat, chaque tour est chronométré — regarde le cercle en haut. Cercle bleu : ton tour, rouge : celui de l'ennemi",
				"Change d'arme avec les boutons du bas ou les touches 1–5. Arsenal complet — [Q]",
				"Le vent dévie les projectiles — surveille la flèche en haut à droite",
				"L'eau en bas, c'est la mort instantanée. Ne reste pas au bord de la falaise !",
			},
		},
		es = {
			move = "Paso 1/4: Camina hacia el enemigo — [A/D] o las flechas en pantalla",
			jump = "Paso 2/4: Salta — [Espacio / W] o el botón de salto",
			aim_direct = "Paso 3/4: Mantén el ratón y arrastra hacia el enemigo — los puntos muestran el vuelo. ¡Suelta para disparar!",
			aim_sling = "Paso 3/4: Tira hacia atrás, lejos del enemigo, como un tirachinas, ¡y suelta para disparar!",
			hit = "¡Impacto! Al enemigo le quedan %d HP. Paso 4/4: ¡acaba con él!",
			short = "¡Muy corto! Arrastra más para tener más fuerza",
			long = "¡Te pasaste! Arrastra menos para un disparo más suave",
			rules = {
				"Paso 4/4: sigue disparando hasta destruir al enemigo. En combate tienes un disparo por turno, luego dispara el enemigo",
				"En combate cada turno tiene tiempo límite — mira el círculo de arriba. Círculo azul: tu turno, rojo: el del enemigo",
				"Cambia de arma con los botones de abajo o las teclas 1–5. Arsenal completo — [Q]",
				"El viento desvía los proyectiles — vigila la flecha de arriba a la derecha",
				"El agua de abajo es muerte instantánea. ¡No te quedes al borde del precipicio!",
			},
		},
		tr = {
			move = "Adım 1/4: Düşmana doğru yürü — [A/D] veya ekrandaki oklar",
			jump = "Adım 2/4: Zıpla — [Boşluk / W] veya zıplama düğmesi",
			aim_direct = "Adım 3/4: Fareyi basılı tut ve düşmana doğru çek — noktalar uçuş yolunu gösterir. Bırak, ateş et!",
			aim_sling = "Adım 3/4: Sapan gibi düşmandan uzağa doğru geri çek ve bırakarak ateş et!",
			hit = "İsabet! Düşmanın %d HP'si kaldı. Adım 4/4: işini bitir!",
			short = "Çok kısa! Daha güçlü atış için biraz daha çek",
			long = "Çok uzun! Daha yumuşak atış için daha az çek",
			rules = {
				"Adım 4/4: düşmanı yok edene kadar ateş et. Savaşta turda bir atış hakkın var, sonra düşman ateş eder",
				"Savaşta her tur süreli — üstteki daireye bak. Mavi daire: senin sıran, kırmızı: düşmanın sırası",
				"Silahı alttaki düğmelerle veya 1–5 tuşlarıyla değiştir. Tüm cephanelik — [Q]",
				"Rüzgar mermileri sürükler — sağ üstteki oka dikkat et",
				"Aşağıdaki su anında ölüm demek. Uçurumun kenarında durma!",
			},
		},
}

function M.reset()
	M.active = false
	M.stage = "move"
	M.spawn_x = M.PLAYER_X
	M.shots = 0
	M.hits = 0
	M.awaiting_impact = false
	M.last_result = nil -- "hit" | "short" | "long"
	M.turn_elapsed = 0
end

M.reset()

function M.start()
	M.reset()
	M.active = true
end

function M.is_active()
	return M.active and M.stage ~= nil
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

	if M.stage == "move" then
		local player = find_team(constants.TEAM_BLUE)
		if player and math.abs(player.pos.x - M.spawn_x) >= M.MOVE_DISTANCE then
			M.stage = "jump"
		end
	end
end

function M.on_jump()
	if M.active and M.stage == "jump" then
		M.stage = "aim"
	end
end

function M.on_shot()
	if not M.active then
		return
	end
	-- Shooting early is fine: skip the remaining steps
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
	return M.active and M.stage == "aim"
end

-- Returns hint text and color for the current step
function M.get_hint(is_ru, is_slingshot)
	-- first arg (is_ru) is kept for backward compatibility and ignored
	local t = TEXTS[require("lua_modules.i18n").current_lang] or TEXTS.en

	if M.stage == "move" then
		return t.move, COLOR_GREEN
	elseif M.stage == "jump" then
		return t.jump, COLOR_GOLD
	elseif M.stage == "aim" then
		return is_slingshot and t.aim_sling or t.aim_direct, COLOR_CYAN
	end

	-- "finish": shot feedback first, then a rule tip
	if M.turn_elapsed < M.RULE_TIP_DELAY and M.last_result then
		if M.last_result == "hit" then
			local target = find_team(constants.TEAM_RED)
			local hp = target and math.max(0, target.hp) or 0
			return string.format(t.hit, hp), COLOR_GREEN
		end
		return t[M.last_result], COLOR_ORANGE
	end
	local idx = ((math.max(1, M.shots) - 1) % #t.rules) + 1
	return t.rules[idx], COLOR_WHITE
end

return M
