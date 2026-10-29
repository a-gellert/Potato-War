-- lua_modules/debris_fx.lua
-- Biome-aware burst of flying debris (clods, sand, ice shards, rock + embers, alien goo).
-- Spawns main/entities/debris objects through a factory URL.

local M = {}

local function rgb(r, g, b) return vmath.vector4(r / 255, g / 255, b / 255, 1.0) end

-- chunk: tints of the main lumps (dirt_particle sprite)
-- accent: tints of the small flying bits, drawn with accent_anim; glow > 1 makes them shine
local PALETTES = {
	grass = {
		chunk = { rgb(184, 120, 70), rgb(138, 88, 54), rgb(98, 58, 40), rgb(104, 204, 60) },
		accent = { rgb(104, 204, 60), rgb(162, 238, 90) }, accent_anim = "dirt_particle", accent_chance = 0.25,
	},
	desert = {
		chunk = { rgb(234, 152, 88), rgb(250, 206, 120), rgb(166, 82, 54), rgb(228, 170, 92) },
		accent = { rgb(255, 234, 166), rgb(250, 206, 120) }, accent_anim = "dirt_particle", accent_chance = 0.4,
	},
	arctic = {
		chunk = { rgb(236, 246, 255), rgb(190, 218, 246), rgb(150, 212, 248), rgb(120, 190, 242) },
		accent = { rgb(255, 255, 255), rgb(196, 236, 255) }, accent_anim = "star", accent_chance = 0.3,
		accent_scale = 0.45, glow = 1.2,
	},
	volcano = {
		chunk = { rgb(94, 74, 76), rgb(68, 52, 58), rgb(46, 38, 56), rgb(134, 106, 102) },
		accent = { rgb(255, 140, 50), rgb(255, 214, 96), rgb(255, 100, 30) }, accent_anim = "spark",
		accent_chance = 0.45, accent_scale = 1.3, glow = 1.8, accent_grav = 0.6,
	},
	alien = {
		chunk = { rgb(152, 80, 202), rgb(98, 50, 150), rgb(66, 30, 112), rgb(74, 234, 178) },
		accent = { rgb(124, 255, 234), rgb(255, 150, 236) }, accent_anim = "spore",
		accent_chance = 0.4, accent_scale = 1.4, glow = 1.5, accent_grav = 0.5,
	},
}

local function pick(list)
	return list[math.random(#list)]
end

-- Dust-puff tint for the explosion's own sprites (a random soil color of the biome).
function M.dust_color(biome)
	local pal = PALETTES[biome] or PALETTES.grass
	return pick(pal.chunk)
end

-- factory_url: e.g. "#debris_factory". Positions are world coordinates.
function M.burst(factory_url, x, y, radius, biome)
	local pal = PALETTES[biome] or PALETTES.grass
	local count = math.max(10, math.min(34, math.floor(8 + radius * 0.55)))
	local power = 110 + radius * 3.2

	for _ = 1, count do
		local is_accent = math.random() < pal.accent_chance
		-- Mostly upward fan, a few low sideways throws
		local angle = math.rad(is_accent and (math.random() * 180) or (25 + math.random() * 130))
		local speed = power * (0.45 + math.random() * 0.85)
		local tint, size, anim, grav

		if is_accent then
			tint = vmath.vector4(pick(pal.accent))
			local g = pal.glow or 1.0
			tint.x, tint.y, tint.z = tint.x * g, tint.y * g, tint.z * g
			anim = pal.accent_anim
			size = (pal.accent_scale or 1.0) * (0.8 + math.random() * 0.9)
			grav = pal.accent_grav or 0.9
		else
			tint = vmath.vector4(pick(pal.chunk))
			-- Slight brightness variation so clods don't look stamped
			local v = 0.85 + math.random() * 0.3
			tint.x, tint.y, tint.z = tint.x * v, tint.y * v, tint.z * v
			anim = "dirt_particle"
			size = 1.1 + math.random() * 1.5 + radius * 0.012
			grav = 1.0
		end

		factory.create(factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.6, y + 2, 0.49), nil, {
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed,
			spin = (math.random() - 0.5) * 900,
			life = 0.9 + math.random() * 0.9,
			grav = grav,
			bounce = 0.25 + math.random() * 0.25,
			size = size,
			anim = hash(anim),
			tint = tint,
		})
	end
end

-- Lingering smoke rising from the crater plus a few slow embers; bigger blasts smoke longer
function M.smoke_column(factory_url, x, y, radius)
	local puffs = math.min(7, 2 + math.floor(radius / 14))
	for i = 1, puffs do
		local shade = 0.22 + math.random() * 0.16
		factory.create(factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.7, y + radius * 0.2, 0.46), nil, {
			vx = (math.random() - 0.5) * 24,
			vy = 22 + math.random() * 26,
			life = 1.3 + math.random() * 0.9 + radius * 0.008,
			grav = -0.02,
			drag = 0.6,
			size = 0.5 + radius * 0.012 + math.random() * 0.3,
			grow = 2.6,
			fade_start = 0.25,
			spin = (math.random() - 0.5) * 60,
			anim = hash("smoke"),
			tint = vmath.vector4(shade, shade * 0.95, shade * 0.9, 0.55 - i * 0.03),
		})
	end
	for _ = 1, math.min(6, math.floor(radius / 10)) do
		factory.create(factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.5, y + 4, 0.5), nil, {
			vx = (math.random() - 0.5) * 70,
			vy = 40 + math.random() * 60,
			life = 0.9 + math.random() * 0.7,
			grav = -0.08,
			drag = 1.2,
			size = 0.25 + math.random() * 0.2,
			grow = 0.4,
			fade_start = 0.4,
			anim = hash("spark"),
			tint = vmath.vector4(2.0, 0.9 + math.random() * 0.4, 0.3, 1.0),
		})
	end
end

return M
