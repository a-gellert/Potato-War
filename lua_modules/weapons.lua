-- lua_modules/weapons.lua
-- Weapon definitions and statistics for Potato War

local M = {}

M.TYPES = {
	GRENADE = "grenade",
	RIFLE = "rifle",
	KNIFE = "knife",
}

M.LIST = {
	{
		id = M.TYPES.GRENADE,
		name = "Граната",
		desc = "Баллистическая граната с отскоками и мощным кратером",
		icon = "grenade",
		blast_radius = 36,
		max_damage = 50,
		blast_force = 320,
		fuse_time = 3.0,
		bounciness = 0.55,
		friction = 0.82,
		gravity_mult = 1.0,
		max_power = 600,
		power_scale = 3.2,
		projectile_sprite = "grenade",
	},
	{
		id = M.TYPES.RIFLE,
		name = "Винтовка",
		desc = "Высокоскоростная пуля для точечного урона на расстоянии",
		icon = "rifle",
		blast_radius = 14,
		max_damage = 45,
		blast_force = 220,
		fuse_time = 5.0,
		bounciness = 0.0,
		friction = 1.0,
		gravity_mult = 0.12,
		max_power = 950,
		speed = 950,
		power_scale = 4.8,
		projectile_sprite = "circle",
	},
	{
		id = M.TYPES.KNIFE,
		name = "Нож",
		desc = "Холодное оружие ближнего боя с мощным отталкиванием",
		icon = "knife",
		blast_radius = 14,
		max_damage = 60,
		blast_force = 450,
		fuse_time = 0.35,
		bounciness = 0.0,
		friction = 1.0,
		gravity_mult = 0.0,
		max_power = 320,
		power_scale = 1.8,
		melee_range = 42,
		projectile_sprite = "knife",
	},
}

M.BY_ID = {}
for i, weapon in ipairs(M.LIST) do
	M.BY_ID[weapon.id] = weapon
end

function M.get(id)
	return M.BY_ID[id] or M.LIST[1]
end

return M
