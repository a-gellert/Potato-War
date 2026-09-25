-- lua_modules/weapons.lua
-- Centralized weapon definitions for Potato War
-- All weapon stats are data-driven from this module.
--
-- fire_mode:  "single" | "melee" | "multi_shot" | "spread"
-- on_hit:     "explode" | "napalm"

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
}

M.LIST = {
	-- 1. Горячая Картошка (Граната)
	{
		id            = "grenade",
		name          = "Горячая Картошка",
		key_label     = "1",
		icon          = "grenade",
		default_ammo  = -1, -- Unlimited!
		desc          = "Прыгучий горячий клубень с тикающим фитилем и мощным кратером",
		fire_mode     = "single",
		on_hit        = "explode",
		-- projectile physics
		gravity_mult  = 1.0,
		bounciness    = 0.55,
		friction      = 0.82,
		fuse_time     = 3.0,
		-- damage
		blast_radius  = 36,
		max_damage    = 50,
		blast_force   = 320,
		-- firing
		max_power     = 600,
		power_scale   = 3.2,
		-- visual
		projectile_sprite = "grenade",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 2. Шампур-Снайпер (Винтовка)
	{
		id            = "rifle",
		name          = "Шампур-Снайпер",
		key_label     = "2",
		icon          = "skewer_rifle",
		default_ammo  = 3,
		desc          = "Заостренная бамбуковая шпажка — точечное пробитие насквозь",
		fire_mode     = "single",
		on_hit        = "explode",
		gravity_mult  = 0.12,
		bounciness    = 0.0,
		friction      = 1.0,
		fuse_time     = 5.0,
		speed         = 950,
		blast_radius  = 14,
		max_damage    = 45,
		blast_force   = 220,
		max_power     = 950,
		power_scale   = 4.8,
		projectile_sprite = "skewer_rifle",
		projectile_scale  = 0.85,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 3. Картофелечистка (Нож)
	{
		id            = "knife",
		name          = "Картофелечистка",
		key_label     = "3",
		icon          = "peeler",
		default_ammo  = 4,
		desc          = "Срезает кожуру в упор с диким кулинарным отталкиванием!",
		fire_mode     = "melee",
		on_hit        = "explode",
		melee_range   = 42,
		blast_radius  = 30,
		max_damage    = 60,
		blast_force   = 450,
		-- not used for projectile, but needed by bot_ai / physics_sim compatibility
		gravity_mult  = 0.0,
		bounciness    = 0.0,
		friction      = 1.0,
		fuse_time     = 0.0,
		max_power     = 1,
		power_scale   = 1.0,
		projectile_sprite = "peeler",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 4. Фритюрное масло (Молотов)
	{
		id            = "molotov",
		name          = "Фритюрное масло",
		key_label     = "4",
		icon          = "oil_bottle",
		default_ammo  = 2,
		desc          = "Бутылка с кипящим маслом — заливает все шипящим фритюром",
		fire_mode     = "single",
		on_hit        = "napalm",
		gravity_mult  = 1.0,
		bounciness    = 0.0,
		friction      = 1.0,
		fuse_time     = 5.0,
		blast_radius  = 18,
		max_damage    = 20,
		blast_force   = 100,
		max_power     = 550,
		power_scale   = 3.0,
		-- napalm properties
		napalm_count     = 6,
		napalm_spread    = 40,
		napalm_burn_time = 2.5,
		napalm_radius    = 10,
		napalm_dps       = 10,
		projectile_sprite = "oil_bottle",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 5. Фри-автомат (Автомат)
	{
		id            = "burst",
		name          = "Фри-автомат",
		key_label     = "5",
		icon          = "rifle",
		default_ammo  = 3,
		desc          = "Три быстрых выстрела хрустящей картошкой фри подряд",
		fire_mode     = "multi_shot",
		on_hit        = "explode",
		shot_count    = 3,
		shot_delay    = 0.12,
		shot_spread   = 0.06,
		gravity_mult  = 0.15,
		bounciness    = 0.0,
		friction      = 1.0,
		fuse_time     = 4.0,
		speed         = 900,
		blast_radius  = 12,
		max_damage    = 30,
		blast_force   = 150,
		max_power     = 900,
		power_scale   = 4.5,
		projectile_sprite = "circle",
		projectile_scale  = 0.28,
		projectile_tint   = {1, 0.85, 0.2, 1},
	},

	-- 6. Пюре-Базука (Базука)
	{
		id            = "bazooka",
		name          = "Пюре-Базука",
		key_label     = "6",
		icon          = "masher_bazooka",
		default_ammo  = 2,
		desc          = "Ракетница-толкушка: превращает зону удара и врагов в пюре!",
		fire_mode     = "single",
		on_hit        = "explode",
		gravity_mult  = 0.4,
		bounciness    = 0.0,
		friction      = 1.0,
		fuse_time     = 6.0,
		blast_radius  = 48,
		max_damage    = 65,
		blast_force   = 400,
		max_power     = 700,
		power_scale   = 3.5,
		projectile_sprite = "masher_bazooka",
		projectile_scale  = 1.1,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 7. Кухонная Тёрка (Дробовик)
	{
		id            = "shotgun",
		name          = "Кухонная Тёрка",
		key_label     = "7",
		icon          = "grater",
		default_ammo  = 3,
		desc          = "Веер острых картофельных чипсов — смертельно вблизи!",
		fire_mode     = "spread",
		on_hit        = "explode",
		shot_count    = 5,
		spread_angle  = 0.35,
		gravity_mult  = 0.3,
		bounciness    = 0.0,
		friction      = 1.0,
		fuse_time     = 3.0,
		speed         = 750,
		blast_radius  = 10,
		max_damage    = 22,
		blast_force   = 180,
		max_power     = 750,
		power_scale   = 4.0,
		projectile_sprite = "circle",
		projectile_scale  = 0.2,
		projectile_tint   = {0.95, 0.9, 0.7, 1},
	},

	-- 8. Золотой Клубень (Святая граната)
	{
		id            = "holy_grenade",
		name          = "Золотой Клубень",
		key_label     = "8",
		icon          = "holy_spud",
		default_ammo  = 1,
		desc          = "Священная золотая картофелина — божественный бабах!",
		fire_mode     = "single",
		on_hit        = "explode",
		gravity_mult  = 1.0,
		bounciness    = 0.6,
		friction      = 0.78,
		fuse_time     = 4.0,
		blast_radius  = 55,
		max_damage    = 80,
		blast_force   = 500,
		max_power     = 580,
		power_scale   = 3.0,
		projectile_sprite = "holy_spud",
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

return M
