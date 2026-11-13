-- lua_modules/debris_fx.lua
-- Biome-aware burst of flying debris (clods, sand, ice shards, rock + embers, alien goo).
-- Spawns main/entities/debris objects through a factory URL.

local M = {}

local function rgb(r, g, b) return vmath.vector4(r / 255, g / 255, b / 255, 1.0) end

-- Note on sizes:
-- dirt_particle and spark are 8x8 px base art.
-- vfx_leaf, vfx_ember, vfx_snow, vfx_spore are 64x64 px base art.
-- Potato body is 40 px in world height.
-- All debris particles are scaled to be crisp, small and natural (2 to 12 px max).

local PALETTES = {
	grass = {
		chunk = { rgb(172, 112, 65), rgb(138, 88, 54), rgb(98, 58, 40), rgb(78, 165, 48) },
		accent = { rgb(95, 195, 52), rgb(148, 224, 76), rgb(235, 210, 75) },
		accent_anim = "vfx_leaf", accent_chance = 0.25, accent_scale = 0.11, glow = 1.0,
	},
	desert = {
		chunk = { rgb(228, 144, 84), rgb(245, 198, 114), rgb(160, 78, 50), rgb(215, 155, 86) },
		accent = { rgb(250, 226, 154), rgb(240, 195, 110), rgb(205, 120, 65) },
		accent_anim = "dirt_particle", accent_chance = 0.30, accent_scale = 0.45, glow = 1.0,
	},
	arctic = {
		chunk = { rgb(228, 242, 255), rgb(178, 210, 242), rgb(140, 202, 244), rgb(110, 178, 235) },
		accent = { rgb(255, 255, 255), rgb(190, 232, 255), rgb(120, 200, 250) },
		accent_anim = "vfx_snow", accent_chance = 0.26, accent_scale = 0.10, glow = 1.25, accent_grav = 0.75,
	},
	volcano = {
		chunk = { rgb(68, 48, 54), rgb(44, 32, 38), rgb(28, 20, 26), rgb(96, 72, 78) },
		accent = { rgb(255, 135, 35), rgb(255, 205, 85), rgb(255, 75, 20), rgb(255, 170, 45) },
		accent_anim = "vfx_ember", accent_chance = 0.28, accent_scale = 0.11, glow = 1.6, accent_grav = 0.65,
	},
	alien = {
		chunk = { rgb(148, 72, 195), rgb(92, 44, 142), rgb(60, 26, 105), rgb(68, 225, 170) },
		accent = { rgb(118, 248, 226), rgb(248, 142, 228), rgb(60, 230, 180) },
		accent_anim = "vfx_spore", accent_chance = 0.28, accent_scale = 0.10, glow = 1.4, accent_grav = 0.6,
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
	-- Crisp, proportional particle count (10-22 max)
	local count = math.max(12, math.min(30, math.floor(10 + radius * 0.55)))
	local power = 110 + radius * 2.8

	for i = 1, count do
		local is_accent = (math.random() < pal.accent_chance)
		local is_micro = (not is_accent and math.random() < 0.50)
		local is_heavy = (not is_accent and not is_micro and math.random() < 0.20)

		-- Radial fan: upward burst with wide lateral spread
		local angle = math.rad(is_accent and (math.random() * 180) or (20 + math.random() * 140))
		local speed = power * (is_micro and (0.65 + math.random() * 0.7) or (0.35 + math.random() * 0.70))
		if is_heavy then
			speed = speed * 0.70
		end

		local tint, size, anim, grav, life, bounce

		if is_accent then
			tint = vmath.vector4(pick(pal.accent))
			local g = pal.glow or 1.0
			tint.x, tint.y, tint.z = tint.x * g, tint.y * g, tint.z * g
			anim = (math.random() < 0.30 and "spark") or pal.accent_anim
			if anim == "spark" then
				size = 0.40 + math.random() * 0.30 -- 3.2 to 5.6 px
			else
				-- 64x64 textures (leaves, snow, embers, spores) scaled down to 6-8 world px
				size = (pal.accent_scale or 0.11) * (0.85 + math.random() * 0.30)
			end
			grav = pal.accent_grav or 0.85
			life = 0.65 + math.random() * 0.60
			bounce = 0.30 + math.random() * 0.20
		elseif is_micro then
			-- Fine dirt crumbs / gravel particles (8x8 art -> 2.0 to 3.6 world px)
			tint = vmath.vector4(pick(pal.chunk))
			local v = 0.80 + math.random() * 0.35
			tint.x, tint.y, tint.z = tint.x * v, tint.y * v, tint.z * v
			anim = "dirt_particle"
			size = 0.25 + math.random() * 0.20
			grav = 1.15
			life = 0.50 + math.random() * 0.45
			bounce = 0.15 + math.random() * 0.15
		elseif is_heavy then
			-- Small stone chunk (8x8 art -> 5.2 to 7.2 world px)
			tint = vmath.vector4(pick(pal.chunk))
			local v = 0.75 + math.random() * 0.25
			tint.x, tint.y, tint.z = tint.x * v, tint.y * v, tint.z * v
			anim = "dirt_particle"
			size = 0.65 + math.random() * 0.25
			grav = 1.2
			life = 0.80 + math.random() * 0.50
			bounce = 0.30 + math.random() * 0.20
		else
			-- Standard medium chunk (8x8 art -> 3.2 to 5.0 world px)
			tint = vmath.vector4(pick(pal.chunk))
			local v = 0.85 + math.random() * 0.30
			tint.x, tint.y, tint.z = tint.x * v, tint.y * v, tint.z * v
			anim = "dirt_particle"
			size = 0.40 + math.random() * 0.22
			grav = 1.05
			life = 0.65 + math.random() * 0.50
			bounce = 0.25 + math.random() * 0.20
		end

		pcall(factory.create, factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.5, y + 2, 0.49), nil, {
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed,
			spin = (math.random() - 0.5) * 800,
			life = life,
			grav = grav,
			bounce = bounce,
			size = size,
			anim = hash(anim),
			tint = tint,
		})
	end
end

-- Subtle crumb spray for terrain modification (5-8 tiny crumbs)
function M.crumbs(factory_url, x, y, radius, biome)
	local pal = PALETTES[biome] or PALETTES.grass
	local count = math.min(7, math.max(3, math.floor(radius * 0.2)))
	for _ = 1, count do
		local angle = math.rad(30 + math.random() * 120)
		local speed = 60 + math.random() * 70
		local tint = vmath.vector4(pick(pal.chunk))
		pcall(factory.create, factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.4, y + 1, 0.48), nil, {
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed,
			spin = (math.random() - 0.5) * 600,
			life = 0.45 + math.random() * 0.35,
			grav = 1.2,
			bounce = 0.2,
			size = 0.24 + math.random() * 0.16, -- 2 to 3.2 px
			anim = hash("dirt_particle"),
			tint = tint,
		})
	end
end

-- Lingering smoke rising from the crater plus slow burning embers
function M.smoke_column(factory_url, x, y, radius)
	local puffs = math.min(6, 2 + math.floor(radius / 16))
	for i = 1, puffs do
		local shade = 0.22 + math.random() * 0.16
		pcall(factory.create, factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.5, y + radius * 0.15, 0.46), nil, {
			vx = (math.random() - 0.5) * 18,
			vy = 16 + math.random() * 20,
			life = 1.6 + math.random() * 1.0,
			grav = -0.02,
			drag = 0.6,
			size = 0.30 + math.random() * 0.15, -- 7 to 11 px
			grow = 2.4,
			fade_start = 0.25,
			spin = (math.random() - 0.5) * 45,
			anim = hash("smoke"),
			tint = vmath.vector4(shade, shade * 0.95, shade * 0.9, 0.40 - i * 0.03),
		})
	end
	-- Glowing burning sparks floating upward in the smoke
	for _ = 1, math.min(3, 1 + math.floor(radius / 16)) do
		pcall(factory.create, factory_url, vmath.vector3(x + (math.random() - 0.5) * radius * 0.4, y + 3, 0.5), nil, {
			vx = (math.random() - 0.5) * 40,
			vy = 28 + math.random() * 40,
			life = 0.6 + math.random() * 0.4,
			grav = -0.05,
			drag = 1.0,
			size = 0.25 + math.random() * 0.18, -- 2.0 to 3.5 px
			grow = 0.3,
			fade_start = 0.35,
			anim = hash("spark"),
			tint = vmath.vector4(2.0, 1.1 + math.random() * 0.3, 0.3, 1.0),
		})
	end
end

return M
