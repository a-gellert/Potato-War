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
	-- 1. Граната
	{
		id            = "grenade",
		name          = "Граната",
		key_label     = "1",
		desc          = "Баллистическая граната с отскоками и мощным кратером",
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

	-- 2. Винтовка
	{
		id            = "rifle",
		name          = "Винтовка",
		key_label     = "2",
		desc          = "Высокоскоростная пуля для точечного урона",
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
		projectile_sprite = "circle",
		projectile_scale  = 0.3,
		projectile_tint   = {1, 1, 0.6, 1},
	},

	-- 3. Нож (melee — мгновенный удар, без снаряда)
	{
		id            = "knife",
		name          = "Нож",
		key_label     = "3",
		desc          = "Мгновенный удар ближнего боя с мощным отталкиванием",
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
		projectile_sprite = "knife",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 4. Коктейль Молотова (наносит урон + разбрасывает напалм)
	{
		id            = "molotov",
		name          = "Молотов",
		key_label     = "4",
		desc          = "Коктейль Молотова — поджигает территорию напалмом",
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
		napalm_radius    = 8,
		napalm_dps       = 10,
		projectile_sprite = "grenade",
		projectile_scale  = 0.8,
		projectile_tint   = {1.0, 0.5, 0.1, 1},
	},

	-- 5. Автомат (3 быстрых выстрела)
	{
		id            = "burst",
		name          = "Автомат",
		key_label     = "5",
		desc          = "Три быстрых выстрела подряд",
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
		projectile_scale  = 0.25,
		projectile_tint   = {1, 0.8, 0.3, 1},
	},

	-- 6. Базука (тяжёлая ракета, огромный взрыв)
	{
		id            = "bazooka",
		name          = "Базука",
		key_label     = "6",
		desc          = "Тяжёлая ракета с огромным взрывом и кратером",
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
		projectile_sprite = "grenade",
		projectile_scale  = 1.3,
		projectile_tint   = {0.5, 0.5, 0.55, 1},
	},

	-- 7. Дробовик (5 дробинок веером)
	{
		id            = "shotgun",
		name          = "Дробовик",
		key_label     = "7",
		desc          = "5 дробинок веером — смертельно вблизи",
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
		projectile_tint   = {0.9, 0.9, 0.9, 1},
	},

	-- 8. Святая граната (чудовищный взрыв)
	{
		id            = "holy_grenade",
		name          = "Св.Граната",
		key_label     = "8",
		desc          = "Святая граната — чудовищной мощности взрыв!",
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
		projectile_sprite = "grenade",
		projectile_scale  = 1.1,
		projectile_tint   = {1.0, 0.85, 0.2, 1},
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
