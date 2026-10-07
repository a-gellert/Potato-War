-- lua_modules/weapons.lua
-- Centralized weapon definitions, elemental statuses, and arena pickups for Potato War
-- All weapon stats and elemental interactions are data-driven from this module.

local M = {}

M.TYPES = {
	GRENADE      = "grenade",
	RIFLE        = "rifle",
	KNIFE        = "knife",
	MOLOTOV      = "molotov",
	BURST        = "burst",
	BAZOOKA      = "bazooka",
	SHOTGUN      = "shotgun",
	HOLY_GRENADE = "holy_grenade",
	BEETLE       = "beetle",
	DRILL        = "drill",
	PEPPER       = "pepper",
	GARLIC       = "garlic",
	AIR_BOMB     = "air_bomb",
}

-- Elemental & Tactical Status States
M.STATUS_TYPES = {
	BURNING   = "burning",   -- Fire DoT, ignites terrain, flammable
	POISONED  = "poisoned",  -- Acid/Toxin DoT, weakens attack power (-20%)
	GLUED     = "glued",     -- Sticky mash/syrup: -60% movement speed, disables/halves jumping
	CONCUSSED = "concussed", -- Stunned/dazed: aim wobble, power penalty, shortens turn timer
}

-- Elemental Combination Reactions
M.COMBOS = {
	sticky_inferno = {
		id = "sticky_inferno",
		req = { glued = true, burning = true },
		name = "Липкий ад",
		name_en = "Sticky Inferno",
		bonus_damage = 25,
		duration_bonus = 2,
		desc = "Липкая картофельная масса вспыхивает ярким пламенем, нанося мгновенный урон и продлевая горение!",
	},
	toxic_burst = {
		id = "toxic_burst",
		req = { poisoned = true, burning = true },
		name = "Токсичный взрыв",
		name_en = "Toxic Burst",
		bonus_damage = 20,
		aoe_radius = 28,
		desc = "Ядовитые пары перца взрываются при контакте с огнем!",
	},
	paralyzed = {
		id = "paralyzed",
		req = { glued = true, concussed = true },
		name = "Паралич",
		name_en = "Paralyzed",
		bonus_damage = 10,
		immobilize = true,
		desc = "Оглушенный боец полностью застревает в картофельном пюре!",
	},
	neurotoxin = {
		id = "neurotoxin",
		req = { poisoned = true, concussed = true },
		name = "Нейротоксин",
		name_en = "Neurotoxin",
		bonus_damage = 15,
		damage_reduction = 0.40,
		desc = "Яд парализует нервную систему: снижение урона на 40% и усиленный DoT!",
	},
}

-- Evaluate elemental combination between existing active statuses and an incoming status
function M.eval_combo(current_statuses, new_status_type)
	if not current_statuses or not new_status_type then
		return nil
	end

	local has_status = function(st)
		return (current_statuses[st] and current_statuses[st].duration > 0) or (new_status_type == st)
	end

	if has_status("glued") and has_status("burning") then
		return M.COMBOS.sticky_inferno
	elseif has_status("poisoned") and has_status("burning") then
		return M.COMBOS.toxic_burst
	elseif has_status("glued") and has_status("concussed") then
		return M.COMBOS.paralyzed
	elseif has_status("poisoned") and has_status("concussed") then
		return M.COMBOS.neurotoxin
	end

	return nil
end

M.CATEGORY_CLASS_BASE  = "class_base"
M.CATEGORY_ARENA_PICKUP = "arena_pickup"

M.LIST = {
	-- 1. Горячая Картошка (Граната) — Базовое оружие (Новобранец / универсал)
	{
		id               = "grenade",
		name             = "Горячая Картошка",
		key_label        = "1",
		icon             = "grenade",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = -1, -- Unlimited!
		desc             = "Прыгучий горячий клубень с тикающим фитилем и мощным кратером",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.55,
		friction         = 0.82,
		fuse_time        = 3.0,
		wind_sensitivity = 0.85, -- Standard wind drift
		blast_radius     = 36,
		max_damage       = 30,
		blast_force      = 180,
		max_power        = 600,
		power_scale      = 3.2,
		projectile_sprite = "grenade",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 2. Шампур-Снайпер (Винтовка) — Базовое оружие (Снайпер)
	{
		id               = "rifle",
		name             = "Шампур-Снайпер",
		key_label        = "2",
		icon             = "skewer_rifle",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 3,
		desc             = "Заостренная бамбуковая шпажка — точечное пробитие насквозь",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.12,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		speed            = 950,
		wind_sensitivity = 0.28, -- Heavy, minimal wind drift!
		blast_radius     = 14,
		max_damage       = 45,
		blast_force      = 150,
		max_power        = 950,
		power_scale      = 4.8,
		projectile_sprite = "skewer_dart",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 3. Боевой Топор (Нож / Ближний бой) — Базовое оружие в стиле референса
	{
		id               = "knife",
		name             = "Боевой Топор",
		key_label        = "3",
		icon             = "knife",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 4,
		desc             = "Сокрушительный рубящий удар боевым топором в упор!",
		fire_mode        = "melee",
		on_hit           = "explode",
		melee_range      = 42,
		blast_radius     = 30,
		max_damage       = 60,
		blast_force      = 220,
		gravity_mult     = 0.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 0.0,
		wind_sensitivity = 0.0, -- Melee immune to wind
		max_power        = 1,
		power_scale      = 1.0,
		projectile_sprite = "knife",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 4. Фритюрное масло (Молотов) — Оружие на арене (Стихия Огня: Burning)
	{
		id               = "molotov",
		name             = "Фритюрное масло",
		key_label        = "4",
		icon             = "oil_bottle",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "common",
		default_ammo     = 2,
		desc             = "Кипящее масло: заливает все фритюром и поджигает врагов (Горение)",
		fire_mode        = "single",
		on_hit           = "napalm",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 0.90,
		blast_radius     = 18,
		max_damage       = 20,
		blast_force      = 100,
		max_power        = 550,
		power_scale      = 3.0,
		napalm_count     = 6,
		napalm_spread    = 40,
		napalm_burn_time = 2.5,
		napalm_radius    = 10,
		napalm_dps       = 10,
		status_effect    = {
			type     = M.STATUS_TYPES.BURNING,
			duration = 3,
			power    = 14,
		},
		projectile_sprite = "oil_bottle",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 5. Фри-автомат (Автомат) — Базовое оружие (Штурмовик)
	{
		id               = "burst",
		name             = "Фри-автомат",
		key_label        = "5",
		icon             = "rifle",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 3,
		desc             = "Три быстрых выстрела хрустящей картошкой фри подряд",
		fire_mode        = "multi_shot",
		on_hit           = "explode",
		shot_count       = 3,
		shot_delay       = 0.12,
		shot_spread      = 0.06,
		gravity_mult     = 0.15,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 4.0,
		speed            = 900,
		wind_sensitivity = 0.40,
		blast_radius     = 12,
		max_damage       = 30,
		blast_force      = 120,
		max_power        = 900,
		power_scale      = 4.5,
		projectile_sprite = "fry_bullet",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 6. Пюре-Базука (Базука) — Базовое оружие (Артиллерист / Ракетчик: Glued)
	{
		id               = "bazooka",
		name             = "Пюре-Базука",
		key_label        = "6",
		icon             = "masher_bazooka",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 2,
		desc             = "Ракетница-толкушка: облепляет цель густым пюре и замедляет (Клей)",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.4,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 6.0,
		wind_sensitivity = 0.50,
		blast_radius     = 48,
		max_damage       = 65,
		blast_force      = 220,
		max_power        = 700,
		power_scale      = 3.5,
		status_effect    = {
			type     = M.STATUS_TYPES.GLUED,
			duration = 2,
			power    = 1,
		},
		projectile_sprite = "masher_rocket",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 7. Кухонная Тёрка (Дробовик) — Базовое оружие (Штурмовик / Сапер)
	{
		id               = "shotgun",
		name             = "Кухонная Тёрка",
		key_label        = "7",
		icon             = "grater",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 3,
		desc             = "Веер острых картофельных чипсов — смертельно вблизи, сносится ветром!",
		fire_mode        = "spread",
		on_hit           = "explode",
		shot_count       = 5,
		spread_angle     = 0.35,
		gravity_mult     = 0.3,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 3.0,
		speed            = 750,
		wind_sensitivity = 1.35, -- Light chips get easily pushed by wind!
		blast_radius     = 10,
		max_damage       = 22,
		blast_force      = 180,
		max_power        = 750,
		power_scale      = 4.0,
		projectile_sprite = "potato_chip",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 8. Золотой Клубень (Святая граната) — Оружие на арене (Легендарное)
	{
		id               = "holy_grenade",
		name             = "Золотой Клубень",
		key_label        = "8",
		icon             = "holy_spud",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "legendary",
		default_ammo     = 1,
		desc             = "Священная золотая картофелина — колоссальный божественный бабах!",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.6,
		friction         = 0.78,
		fuse_time        = 4.0,
		wind_sensitivity = 0.70,
		blast_radius     = 55,
		max_damage       = 80,
		blast_force      = 250,
		max_power        = 580,
		power_scale      = 3.0,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 2,
			power    = 1,
		},
		projectile_sprite = "holy_spud",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 9. Колорадский Десант (Банка с жуками) — Оружие на арене (Редкое)
	{
		id               = "beetle",
		name             = "Колорадский Десант",
		key_label        = "9",
		icon             = "beetle_crate",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
		default_ammo     = 2,
		desc             = "Банка с жуками: раскалывается и выпускает 3 жуков-диверсантов!",
		fire_mode        = "single",
		on_hit           = "beetles",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 0.75,
		blast_radius     = 20,
		max_damage       = 24,
		blast_force      = 160,
		max_power        = 620,
		power_scale      = 3.2,
		beetle_count     = 3,
		projectile_sprite = "beetle_crate",
		projectile_scale  = 0.9,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 10. Грядковый Бур (Пробитие террейна) — Базовое оружие (Сапер)
	{
		id               = "drill",
		name             = "Грядковый Бур",
		key_label        = "10",
		icon             = "drill_missile",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 2,
		desc             = "Пружинный бур: просверливает грунт и взрывается в бункере врага!",
		fire_mode        = "single",
		on_hit           = "drill",
		gravity_mult     = 0.22,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		speed            = 850,
		wind_sensitivity = 0.25, -- Heavy drill, cut through wind
		blast_radius     = 42,
		max_damage       = 60,
		blast_force      = 200,
		max_power        = 850,
		power_scale      = 4.2,
		drill_dist       = 65,
		projectile_sprite = "drill_missile",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 11. Перцемолка «Острый Чили» — Оружие на арене / Базовое (Медик: Poisoned)
	{
		id               = "pepper",
		name             = "Перцемолка «Чили»",
		key_label        = "11",
		icon             = "pepper_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "common",
		default_ammo     = 2,
		desc             = "Жгучий помол кайенского перца: ядовитое облако отравляет бойцов (Яд)",
		fire_mode        = "single",
		on_hit           = "pepper",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 1.20, -- Spice cloud catches wind
		blast_radius     = 22,
		max_damage       = 20,
		blast_force      = 120,
		max_power        = 560,
		power_scale      = 3.0,
		pepper_count     = 6,
		pepper_spread    = 42,
		pepper_burn_time = 3.0,
		pepper_radius    = 11,
		pepper_dps       = 12,
		status_effect    = {
			type     = M.STATUS_TYPES.POISONED,
			duration = 3,
			power    = 10,
		},
		projectile_sprite = "pepper_bomb",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 12. Чесночный Динамит — Оружие на арене (Concussed)
	{
		id               = "garlic",
		name             = "Чесночный Динамит",
		key_label        = "12",
		icon             = "garlic_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
		default_ammo     = 2,
		desc             = "Связка ядреного чеснока: колоссальная ударная волна и оглушение (Контузия)",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.85,
		bounciness       = 0.35,
		friction         = 0.85,
		fuse_time        = 3.2,
		wind_sensitivity = 0.80,
		blast_radius     = 55,
		crater_radius    = 14,
		max_damage       = 25,
		blast_force      = 320,
		max_power        = 620,
		power_scale      = 3.2,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 2,
			power    = 1,
		},
		projectile_sprite = "garlic_bomb",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- Специальный миньон жука (порождается Колорадским Десантом)
	{
		id               = "beetle_minion",
		name             = "Колорадский Жук",
		key_label        = "",
		icon             = "beetle_minion",
		category         = M.CATEGORY_ARENA_PICKUP,
		default_ammo     = 0,
		desc             = "Жук-диверсант, грызет клубни и взрывается!",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.4,
		friction         = 0.75,
		fuse_time        = 2.0,
		wind_sensitivity = 0.60,
		blast_radius     = 20,
		max_damage       = 24,
		blast_force      = 180,
		max_power        = 300,
		power_scale      = 2.0,
		projectile_sprite = "beetle_minion",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- Снаряд с дирижабля / Артналет (Оружие на арене)
	{
		id               = "air_bomb",
		name             = "Авиабомба",
		key_label        = "",
		icon             = "air_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
		default_ammo     = 0,
		desc             = "Снаряд с дирижабля: умеренный урон 30 HP и воронка",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.4,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 6.0,
		wind_sensitivity = 0.40,
		blast_radius     = 28,
		max_damage       = 30,
		blast_force      = 200,
		max_power        = 700,
		power_scale      = 3.5,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 1,
			power    = 1,
		},
		projectile_sprite = "air_bomb",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},
}

-- Build fast lookup by id
M.BY_ID = {}
for i, weapon in ipairs(M.LIST) do
	M.BY_ID[weapon.id] = weapon
	weapon.index = i
end

function M.get(id)
	return M.BY_ID[id] or M.LIST[1]
end

function M.get_by_index(idx)
	return M.LIST[idx] or M.LIST[1]
end

function M.count()
	return #M.LIST
end

-- Category queries
function M.is_class_base(id)
	local w = M.get(id)
	return w and (w.category == M.CATEGORY_CLASS_BASE)
end

function M.is_arena_pickup(id)
	local w = M.get(id)
	return w and (w.category == M.CATEGORY_ARENA_PICKUP)
end

function M.get_base_weapons()
	local res = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_CLASS_BASE then
			table.insert(res, w)
		end
	end
	return res
end

function M.get_arena_pickups()
	local res = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_ARENA_PICKUP and w.id ~= "beetle_minion" then
			table.insert(res, w)
		end
	end
	return res
end

function M.get_random_arena_pickup(rarity)
	local pool = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_ARENA_PICKUP and w.id ~= "beetle_minion" then
			if not rarity or w.pickup_rarity == rarity then
				table.insert(pool, w)
			end
		end
	end
	if #pool == 0 then
		return M.get("molotov")
	end
	return pool[math.random(1, #pool)]
end

return M
