-- lua_modules/classes.lua
-- Potato Archetypes and Class Tree for Potato War
-- Provides base stats (HP, mass, speed), arsenal configurations, and class active skills.

local M = {}

M.DEFAULT_CLASS_ID = "recruit"

M.CLASSES = {
	-- 0. Базовый класс (новобранец) - начальный класс для всех картошек
	recruit = {
		id = "recruit",
		name = "Новобранец",
		name_en = "Recruit",
		branch = "base",
		tier = 0,
		parent_class = nil,
		desc = "Базовый универсальный боец. Надежен, неприхотлив и готов ко всему.",
		stats = {
			base_hp = 100,
			max_hp = 100,
			mass = 1.0,
			walk_speed_mult = 1.0,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 2,
			knife = 3,
		},
		active_skill = {
			id = "sprint",
			name = "Марш-бросок",
			name_en = "Sprint Dash",
			desc = "+40% скорости и импульса прыжка на текущий ход",
			cooldown_turns = 2,
			icon = "hand",
			effect_type = "mobility",
		},
	},

	-- Ветвь 1: ШТУРМОВИК
	assault = {
		id = "assault",
		name = "Штурмовик",
		name_en = "Assault",
		branch = "assault",
		tier = 1,
		parent_class = "recruit",
		desc = "Мастер ближнего и среднего боя с автоматическим картофельным оружием.",
		stats = {
			base_hp = 110,
			max_hp = 110,
			mass = 1.05,
			walk_speed_mult = 1.05,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			burst = 4,
			shotgun = 3,
			knife = 2,
		},
		active_skill = {
			id = "rapid_fire",
			name = "Шквал огня",
			name_en = "Rapid Fire",
			desc = "Мгновенно пополняет боезапас автомата на 2 очереди",
			cooldown_turns = 3,
			icon = "rifle",
			effect_type = "offensive",
		},
	},

	assault_2 = {
		id = "assault_2",
		name = "Штурмовик II",
		name_en = "Assault II",
		branch = "assault",
		tier = 2,
		parent_class = "assault",
		desc = "Закаленный ветеран штурма: бронированный клубень с увеличенным арсеналом.",
		stats = {
			base_hp = 130,
			max_hp = 130,
			mass = 1.15,
			walk_speed_mult = 1.08,
			jump_mult = 1.05,
		},
		base_arsenal = {
			grenade = -1,
			burst = 6,
			shotgun = 5,
			knife = 4,
			molotov = 2,
		},
		active_skill = {
			id = "tactical_breach",
			name = "Тактический прорыв",
			name_en = "Tactical Breach",
			desc = "Временный щит от взрывов (-50% урона на 1 ход) и рывок вперед",
			cooldown_turns = 3,
			icon = "crosshair",
			effect_type = "buff",
		},
	},

	sniper = {
		id = "sniper",
		name = "Снайпер",
		name_en = "Sniper",
		branch = "assault",
		tier = 2,
		parent_class = "assault",
		desc = "Точный стрелок со шпажкой-снайпером. Легкий клубень для дальних дистанций.",
		stats = {
			base_hp = 90,
			max_hp = 90,
			mass = 0.85,
			walk_speed_mult = 1.0,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			rifle = 5,
			knife = 3,
		},
		active_skill = {
			id = "eagle_eye",
			name = "Орлиный глаз",
			name_en = "Eagle Eye",
			desc = "Игнорирует воздействие ветра и увеличивает урон выстрела на 30%",
			cooldown_turns = 2,
			icon = "skewer_dart",
			effect_type = "buff",
		},
	},

	-- Ветвь 2: САПЕР
	sapper = {
		id = "sapper",
		name = "Сапер",
		name_en = "Sapper",
		branch = "sapper",
		tier = 1,
		parent_class = "recruit",
		desc = "Специалист по пробитию грунта, бурению укреплений и созданию укрытий.",
		stats = {
			base_hp = 120,
			max_hp = 120,
			mass = 1.25,
			walk_speed_mult = 0.95,
			jump_mult = 0.95,
		},
		base_arsenal = {
			grenade = -1,
			drill = 4,
			garlic = 2,
			shotgun = 2,
		},
		active_skill = {
			id = "trench_dig",
			name = "Окоп",
			name_en = "Trench Fortify",
			desc = "Быстро углубляется в грунт и снижает входящий урон на 35%",
			cooldown_turns = 3,
			icon = "drill_missile",
			effect_type = "buff",
		},
	},

	sapper_2 = {
		id = "sapper_2",
		name = "Сапер II",
		name_en = "Sapper II",
		branch = "sapper",
		tier = 2,
		parent_class = "sapper",
		desc = "Мастер подрывных работ и тяжелого бурения. Высокая масса и устойчивость.",
		stats = {
			base_hp = 140,
			max_hp = 140,
			mass = 1.35,
			walk_speed_mult = 0.95,
			jump_mult = 0.95,
		},
		base_arsenal = {
			grenade = -1,
			drill = 6,
			garlic = 4,
			beetle = 2,
			bazooka = 2,
		},
		active_skill = {
			id = "cluster_trap",
			name = "Минная ловушка",
			name_en = "Mine Trap",
			desc = "Устанавливает взрывчатку с таймером в точке стояния",
			cooldown_turns = 3,
			icon = "tnt_barrel",
			effect_type = "offensive",
		},
	},

	commando = {
		id = "commando",
		name = "Командо",
		name_en = "Commando",
		branch = "sapper",
		tier = 2,
		parent_class = "sapper",
		desc = "Диверсант и специалист по скрытным операциям. Высокая подвижность и нож.",
		stats = {
			base_hp = 105,
			max_hp = 105,
			mass = 0.90,
			walk_speed_mult = 1.20,
			jump_mult = 1.15,
		},
		base_arsenal = {
			grenade = -1,
			knife = 6,
			burst = 4,
			molotov = 3,
			garlic = 2,
		},
		active_skill = {
			id = "smoke_screen",
			name = "Дымовая завеса",
			name_en = "Smoke Screen",
			desc = "Рассеивает дым, снимает негативные статусы и совершает акробатический прыжок",
			cooldown_turns = 2,
			icon = "smoke",
			effect_type = "cleanse",
		},
	},

	-- Ветвь 3: АРТИЛЛЕРИСТ
	artillery = {
		id = "artillery",
		name = "Артиллерист",
		name_en = "Artillery",
		branch = "artillery",
		tier = 1,
		parent_class = "recruit",
		desc = "Специалист по навесной стрельбе и тяжелым взрывам из толкушки-базуки.",
		stats = {
			base_hp = 110,
			max_hp = 110,
			mass = 1.30,
			walk_speed_mult = 0.90,
			jump_mult = 0.90,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 4,
			garlic = 2,
		},
		active_skill = {
			id = "siege_stance",
			name = "Осадный режим",
			name_en = "Siege Stance",
			desc = "+35% к силе выстрела и радиусу взрыва следующего снаряда",
			cooldown_turns = 3,
			icon = "masher_bazooka",
			effect_type = "buff",
		},
	},

	artillery_2 = {
		id = "artillery_2",
		name = "Артиллерист II",
		name_en = "Artillery II",
		branch = "artillery",
		tier = 2,
		parent_class = "artillery",
		desc = "Тяжелая осадная батарея: колоссальная разрушительная сила и воронки.",
		stats = {
			base_hp = 125,
			max_hp = 125,
			mass = 1.40,
			walk_speed_mult = 0.85,
			jump_mult = 0.85,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 6,
			air_bomb = 2,
			holy_grenade = 1,
		},
		active_skill = {
			id = "carpet_salvo",
			name = "Артналет",
			name_en = "Artillery Salvo",
			desc = "Запрашивает сброс авиабомбы в точку прицела",
			cooldown_turns = 4,
			icon = "air_bomb",
			effect_type = "offensive",
		},
	},

	rocketeer = {
		id = "rocketeer",
		name = "Ракетчик",
		name_en = "Rocketeer",
		branch = "artillery",
		tier = 2,
		parent_class = "artillery",
		desc = "Мобильный стрелок реактивными снарядами, преодолевающий любые высоты.",
		stats = {
			base_hp = 95,
			max_hp = 95,
			mass = 0.80,
			walk_speed_mult = 1.10,
			jump_mult = 1.25,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 5,
			drill = 3,
			burst = 2,
		},
		active_skill = {
			id = "rocket_jump",
			name = "Ракетный прыжок",
			name_en = "Rocket Jump",
			desc = "Высокий реактивный прыжок через горы и стены без урона для себя",
			cooldown_turns = 2,
			icon = "spark",
			effect_type = "mobility",
		},
	},

	-- Ветвь 4: МЕДИК
	medic = {
		id = "medic",
		name = "Медик",
		name_en = "Medic",
		branch = "medic",
		tier = 1,
		parent_class = "recruit",
		desc = "Полевой санитар: лечит союзников, очищает дебаффы и травит врагов перцем.",
		stats = {
			base_hp = 105,
			max_hp = 105,
			mass = 1.0,
			walk_speed_mult = 1.05,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			pepper = 4,
			molotov = 2,
			shotgun = 2,
		},
		active_skill = {
			id = "first_aid",
			name = "Полевая аптечка",
			name_en = "Field Aid",
			desc = "Исцеляет +35 HP бойцу и очищает эффекты горения и яда",
			cooldown_turns = 2,
			icon = "circle",
			effect_type = "heal",
		},
	},

	surgeon = {
		id = "surgeon",
		name = "Хирург",
		name_en = "Surgeon",
		branch = "medic",
		tier = 2,
		parent_class = "medic",
		desc = "Главврач картофельного госпиталя: мощное лечение, святая реанимация и биогель.",
		stats = {
			base_hp = 120,
			max_hp = 120,
			mass = 1.05,
			walk_speed_mult = 1.05,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			pepper = 6,
			holy_grenade = 1,
			knife = 4,
			molotov = 3,
		},
		active_skill = {
			id = "biogel_surge",
			name = "Биогель / Реанимация",
			name_en = "Biogel Surge",
			desc = "Исцеляет +50 HP, полностью снимает все негативные статусы и активирует регенерацию",
			cooldown_turns = 3,
			icon = "holy_spud",
			effect_type = "heal",
		},
	},

	-- Ветвь 5: ТАНК
	tank = {
		id = "tank",
		name = "Танк",
		name_en = "Tank",
		branch = "tank",
		tier = 1,
		parent_class = "recruit",
		desc = "Тяжелобронированный рыцарь-клубень со щитом и боевым топором. Несгибаемая стойкость.",
		stats = {
			base_hp = 150,
			max_hp = 150,
			mass = 1.60,
			walk_speed_mult = 0.85,
			jump_mult = 0.80,
		},
		base_arsenal = {
			grenade = -1,
			knife = 5,
			shotgun = 3,
			bazooka = 2,
		},
		active_skill = {
			id = "iron_bastion",
			name = "Стальной бастион",
			name_en = "Iron Bastion",
			desc = "Поднимает щит: -50% получаемого урона на 1 ход и полная устойчивость к отбрасыванию",
			cooldown_turns = 3,
			icon = "knife",
			effect_type = "buff",
		},
	},
}

-- Fast lookup / query helpers
function M.get(class_id)
	return M.CLASSES[class_id] or M.CLASSES[M.DEFAULT_CLASS_ID]
end

function M.get_default()
	return M.CLASSES[M.DEFAULT_CLASS_ID]
end

function M.list()
	local result = {}
	for _, c in pairs(M.CLASSES) do
		table.insert(result, c)
	end
	table.sort(result, function(a, b)
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		return a.id < b.id
	end)
	return result
end

function M.get_by_branch(branch)
	local result = {}
	for _, c in pairs(M.CLASSES) do
		if c.branch == branch then
			table.insert(result, c)
		end
	end
	return result
end

function M.get_promotions(class_id)
	local result = {}
	for _, c in pairs(M.CLASSES) do
		if c.parent_class == class_id then
			table.insert(result, c)
		end
	end
	return result
end

-- Extensible registration API: allows registering new custom archetypes at runtime
function M.register(class_def)
	if not class_def or not class_def.id then
		return false
	end
	class_def.stats = class_def.stats or { base_hp = 100, max_hp = 100, mass = 1.0, walk_speed_mult = 1.0, jump_mult = 1.0 }
	class_def.base_arsenal = class_def.base_arsenal or { grenade = -1 }
	M.CLASSES[class_def.id] = class_def
	return true
end

return M
