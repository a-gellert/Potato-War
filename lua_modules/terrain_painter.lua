-- lua_modules/terrain_painter.lua
-- Hybrid-casual shading for the destructible terrain texture: chunky tinted outlines,
-- scalloped biome caps, cartoon pebbles / potatoes / crystals, biome strata and magma veins,
-- surface props (tufts, flowers, cacti, ice shards, glow bulbs) and hanging props
-- (vines, icicles, lava drips, tendrils). Crater rims are charred instead of regrowing a cap.
--
-- Pure Lua: writes RGBA bytes into any 1-based indexable stream (Defold buffer stream or table).

local M = {}

local floor, sqrt, sin, abs, min, max = math.floor, math.sqrt, math.sin, math.abs, math.min, math.max

local DEPTH_CAP = 110  -- natural depth tracked below the original surface (cells)
local EDGE_MAX = 4     -- outline + inner shading reach (cells)
local PROP_MAX = 12    -- tallest surface prop (cells)
local HANG_MAX = 12    -- longest hanging prop (cells)
local NOISE_SIZE = 256 -- tileable noise tile (cells)
local PEBBLE_CELL = 30 -- pebble jitter grid (cells)

-- Region padding a caller must repaint around a changed area so props and edges stay consistent
M.PAD_X = 6
M.PAD_Y = 14

local DIR_UP, DIR_LEFT, DIR_RIGHT, DIR_DOWN = 1, 2, 3, 4
local LEFT_LIGHT = { 1.0, 1.16, 1.07, 1.02 }
local RIGHT_SHADE = { 1.0, 0.80, 0.89, 0.96 }
local UNDER_SHADE = { 1.0, 0.58, 0.72, 0.86 }
local BURN_KEEP = { 0.0, 0.22, 0.48, 0.74 }
local STRATA = { 1.0, 0.88, 1.06, 0.94 }

local PALETTES = {
	grass = {
		outline = { 36, 60, 30 }, burnt = { 54, 38, 30 }, burnt_line = { 28, 20, 18 },
		cap_th = 11, cap_hi = { 162, 238, 90 }, cap = { 104, 204, 60 }, cap_lo = { 64, 158, 50 },
		soil_top = { 184, 120, 70 }, soil_deep = { 98, 58, 40 }, body = "clods", patch = 0.84,
		stone = { 160, 154, 148 }, stone_hi = { 216, 210, 200 }, stone_lo = { 92, 86, 84 },
		pebble_rate = 0.45, pebbles = { "pebble", "pebble", "potato" },
		potato = { 224, 170, 98 }, potato_hi = { 248, 210, 142 }, potato_lo = { 134, 88, 46 },
		props = { { "tuft", 0.11 }, { "flower", 0.135 } },
		petals = { { 255, 226, 70 }, { 255, 255, 250 }, { 255, 132, 182 } }, petal_mid = { 255, 168, 40 },
		hangs = { { "vine", 0.14 } },
	},
	desert = {
		outline = { 114, 60, 34 }, burnt = { 72, 42, 30 }, burnt_line = { 40, 22, 16 },
		cap_th = 6, cap_hi = { 255, 234, 166 }, cap = { 250, 206, 120 }, cap_lo = { 228, 170, 92 },
		soil_top = { 234, 152, 88 }, soil_deep = { 166, 82, 54 }, body = "strata",
		stone = { 228, 186, 132 }, stone_hi = { 252, 226, 176 }, stone_lo = { 150, 96, 60 },
		pebble_rate = 0.4, pebbles = { "pebble" },
		props = { { "dry", 0.05 }, { "cactus", 0.058 } },
		dry = { { 168, 146, 66 }, { 200, 180, 90 }, { 238, 216, 132 } },
		cactus = { { 140, 212, 110 }, { 88, 172, 82 }, { 56, 122, 62 } },
		hangs = {},
	},
	arctic = {
		outline = { 44, 76, 132 }, burnt = { 62, 72, 94 }, burnt_line = { 30, 36, 56 },
		cap_th = 10, cap_hi = { 255, 255, 255 }, cap = { 236, 246, 255 }, cap_lo = { 190, 218, 246 },
		soil_top = { 150, 212, 248 }, soil_deep = { 64, 122, 196 }, body = "ice",
		stone = { 112, 138, 178 }, stone_hi = { 172, 198, 228 }, stone_lo = { 60, 80, 122 },
		pebble_rate = 0.5, pebbles = { "pebble", "bubble", "bubble" },
		props = { { "shard", 0.05 } },
		ice = { { 255, 255, 255 }, { 196, 236, 255 }, { 120, 190, 242 } },
		hangs = { { "icicle", 0.22 } },
	},
	volcano = {
		outline = { 26, 14, 20 }, burnt = { 30, 18, 20 }, burnt_line = { 14, 8, 10 },
		cap_th = 5, cap_hi = { 134, 106, 102 }, cap = { 94, 74, 76 }, cap_lo = { 68, 52, 58 },
		cap_fleck = { 255, 132, 40 },
		soil_top = { 80, 60, 66 }, soil_deep = { 38, 26, 34 }, body = "magma",
		stone = { 46, 38, 56 }, stone_hi = { 124, 112, 156 }, stone_lo = { 20, 14, 24 },
		pebble_rate = 0.5, pebbles = { "crystal", "pebble" },
		props = { { "spike", 0.06 } },
		spike = { { 120, 96, 96 }, { 80, 62, 66 }, { 255, 140, 50 } },
		hangs = { { "drip", 0.07 } },
		drip = { { 255, 128, 36 }, { 255, 214, 96 } },
	},
	alien = {
		outline = { 46, 18, 76 }, burnt = { 40, 20, 50 }, burnt_line = { 22, 10, 30 },
		cap_th = 8, cap_hi = { 164, 255, 214 }, cap = { 74, 234, 178 }, cap_lo = { 36, 174, 148 },
		soil_top = { 152, 80, 202 }, soil_deep = { 66, 30, 112 }, body = "clods", patch = 0.82,
		stone = { 255, 122, 222 }, stone_hi = { 255, 204, 246 }, stone_lo = { 150, 40, 132 },
		pebble_rate = 0.55, pebbles = { "crystal", "spot", "spot" },
		glow = { 124, 255, 234 }, glow_lo = { 42, 192, 184 },
		props = { { "bulb", 0.06 }, { "tuft", 0.14 } },
		bulb = { { 124, 255, 234 }, { 255, 150, 236 } },
		hangs = { { "tendril", 0.12 } },
	},
}

local pal = PALETTES.grass
local seed_off = 0
local noise_ox, noise_oy = 0, 0
local pebble_cache = {}
local noise_a, noise_b

-- Paint-call state (set at the start of M.paint, read by helpers)
local cur_stream, cur_grid, cur_carved, cur_w, cur_h
local rx0, ry0, rx1, ry1 = 0, 0, 0, 0

local function hash(x, y)
	local n = sin(x * 12.9898 + y * 78.233 + seed_off) * 43758.5453
	return n - floor(n)
end

-- Tileable 3-octave value noise, built once (seed variety comes from a lookup offset)
local function build_noise(salt)
	local S = NOISE_SIZE
	-- Wrapping lattices per octave (8, 16, 32 cells across the tile)
	local lattices = {}
	local cells = 8
	for oct = 1, 3 do
		local lat = {}
		for iy = 0, cells - 1 do
			for ix = 0, cells - 1 do
				local n = sin(ix * 127.1 + iy * 311.7 + salt * 74.7 + oct * 19.3) * 43758.5453
				lat[iy * cells + ix] = n - floor(n)
			end
		end
		lattices[oct] = { lat = lat, cells = cells }
		cells = cells * 2
	end
	local t = {}
	for y = 0, S - 1 do
		for x = 0, S - 1 do
			local v, amp, total = 0, 1, 0
			for oct = 1, 3 do
				local lt = lattices[oct]
				local n, lat = lt.cells, lt.lat
				local fx = x / S * n
				local fy = y / S * n
				local ix, iy = floor(fx), floor(fy)
				local tx, ty = fx - ix, fy - iy
				tx = tx * tx * (3 - 2 * tx)
				ty = ty * ty * (3 - 2 * ty)
				local ix1, iy1 = (ix + 1) % n, (iy + 1) % n
				local a = lat[iy * n + ix]
				local b = lat[iy * n + ix1]
				local c = lat[iy1 * n + ix]
				local d = lat[iy1 * n + ix1]
				local ab = a + (b - a) * tx
				local cd = c + (d - c) * tx
				v = v + (ab + (cd - ab) * ty) * amp
				total = total + amp
				amp = amp * 0.5
			end
			t[y * S + x + 1] = v / total
		end
	end
	return t
end

-- Select biome palette and reseed decorations. Call before a full repaint.
function M.reset(biome, seed)
	pal = PALETTES[biome] or PALETTES.grass
	seed = seed or 0
	seed_off = (seed % 997) * 0.731
	noise_ox = seed % NOISE_SIZE
	noise_oy = floor(seed / NOISE_SIZE) % NOISE_SIZE
	pebble_cache = {}
	if not noise_a then
		noise_a = build_noise(1)
		noise_b = build_noise(2)
	end
end

-- Rounded "drips" hanging from the bottom of the cap
local function cap_thickness(gx)
	local p = 12
	local cell = floor(gx / p)
	local t = (gx - cell * p) / p * 2 - 1
	local bump = sqrt(max(0, 1 - t * t))
	return pal.cap_th + floor(bump * (2 + hash(cell, 7.7) * 3) + 0.5)
end

---------------------------------------------------------
-- Embedded pebbles / potatoes / crystals / bubbles / glow spots
---------------------------------------------------------

local function get_pebble(cx, cy)
	local key = cy * 1000 + cx
	local p = pebble_cache[key]
	if p == nil then
		p = false
		if hash(cx * 1.7 + 3.1, cy * 2.3 + 1.9) < pal.pebble_rate then
			local h2 = hash(cx + 11.3, cy + 5.7)
			local h3 = hash(cx + 23.9, cy + 17.1)
			local kinds = pal.pebbles
			local kind = kinds[floor(hash(cx + 7.3, cy + 29.3) * #kinds) + 1]
			local rx = 4 + floor(h2 * 5)
			local ry = max(3, floor(rx * (0.6 + h3 * 0.3) + 0.5))
			if kind == "spot" or kind == "bubble" then
				rx = 2 + floor(h2 * 2)
				ry = rx
			elseif kind == "crystal" then
				ry = rx + 2
			end
			local mx, my = rx + 3, ry + 3
			p = {
				x = cx * PEBBLE_CELL + mx + floor(h3 * (PEBBLE_CELL - 2 * mx)),
				y = cy * PEBBLE_CELL + my + floor(h2 * (PEBBLE_CELL - 2 * my)),
				rx = rx, ry = ry, kind = kind,
			}
		end
		pebble_cache[key] = p
	end
	return p
end

local function shade_pebble(p, gx, gy, r, g, b)
	local dx, dy = gx - p.x, gy - p.y
	local rx, ry, kind = p.rx, p.ry, p.kind
	local P = pal

	if kind == "crystal" then
		local q = abs(dx) / rx + abs(dy) / ry
		if q > 1 then return r, g, b end
		local c
		if q > 1 - 1.5 / rx then
			c = P.stone_lo
		elseif dx < 0 then
			c = (dy > 0 and dx > -rx * 0.5) and P.stone_hi or P.stone
		else
			c = P.stone
			return c[1] * 0.82, c[2] * 0.82, c[3] * 0.82
		end
		return c[1], c[2], c[3]
	end

	local nx, ny = dx / rx, dy / ry
	local q = nx * nx + ny * ny

	if kind == "spot" then
		if q > 2.6 then return r, g, b end
		local gc = P.glow
		if q > 1 then
			local k = 0.38 * (2.6 - q) / 1.6
			return r + (gc[1] - r) * k, g + (gc[2] - g) * k, b + (gc[3] - b) * k
		end
		if q < 0.3 then return 235, 255, 250 end
		return gc[1], gc[2], gc[3]
	end

	if q > 1 then return r, g, b end
	local ix, iy = dx / max(1, rx - 1), dy / max(1, ry - 1)
	local rim = (ix * ix + iy * iy) > 1

	if kind == "bubble" then
		if rim then return 236, 250, 255 end
		if dx == -1 and dy == 1 then return 255, 255, 255 end
		return r + (255 - r) * 0.3, g + (255 - g) * 0.3, b + (255 - b) * 0.3
	end

	local base, hi, lo = P.stone, P.stone_hi, P.stone_lo
	if kind == "potato" then
		base, hi, lo = P.potato, P.potato_hi, P.potato_lo
	end
	if rim then return lo[1], lo[2], lo[3] end
	if kind == "potato" and ((dx == -1 and dy == 0) or (dx == 2 and dy == -1) or (dx == 1 and dy == 1 and rx > 4)) then
		return lo[1], lo[2], lo[3]
	end
	if nx < -0.1 and ny > 0.1 and q < 0.55 then return hi[1], hi[2], hi[3] end
	if nx - ny > 0.75 then return base[1] * 0.84, base[2] * 0.84, base[3] * 0.84 end
	return base[1], base[2], base[3]
end

---------------------------------------------------------
-- Solid cell shading
---------------------------------------------------------

local function shade_solid(gx, gy, idx, nd, run, cap_th)
	local P = pal
	local grid, carved, w = cur_grid, cur_carved, cur_w

	-- Nearest air: straight up comes from the column run, then left / right / down
	local e, dir, air_idx = 99, 0, nil
	if run < EDGE_MAX then
		e = run + 1
		dir = DIR_UP
		air_idx = idx + e * w
	end
	for d = 1, min(e - 1, EDGE_MAX) do
		if gx - d >= 0 and grid[idx - d] ~= 1 then
			e, dir, air_idx = d, DIR_LEFT, idx - d
			break
		end
		if gx + d < w and grid[idx + d] ~= 1 then
			e, dir, air_idx = d, DIR_RIGHT, idx + d
			break
		end
		if gy - d >= 0 and grid[idx - d * w] ~= 1 then
			e, dir, air_idx = d, DIR_DOWN, idx - d * w
			break
		end
	end

	local burnt_edge = air_idx ~= nil and carved[air_idx] == true
	if e == 1 then
		local c = burnt_edge and P.burnt_line or P.outline
		return c[1], c[2], c[3]
	end

	local r, g, b
	if nd < cap_th then
		-- Biome cap: highlight band, body, darker drip bottoms
		local c
		if nd <= 2 then
			c = P.cap_hi
		elseif nd >= cap_th - 2 then
			c = P.cap_lo
		else
			c = P.cap
		end
		r, g, b = c[1], c[2], c[3]
		if P.cap_fleck and nd > 2 and hash(gx, gy) < 0.06 then
			c = P.cap_fleck
			r, g, b = c[1], c[2], c[3]
		end
	else
		-- Darker with altitude loss (seam-free), plus a soft lit band under the surface
		local t = (cur_h * 0.72 - gy) / (cur_h * 0.62)
		if t < 0 then t = 0 elseif t > 1 then t = 1 end
		local st, sd = P.soil_top, P.soil_deep
		r = st[1] + (sd[1] - st[1]) * t
		g = st[2] + (sd[2] - st[2]) * t
		b = st[3] + (sd[3] - st[3]) * t
		local below = nd - P.cap_th
		if below < 16 then
			local m = 1 + 0.12 * (1 - below / 16)
			r, g, b = r * m, g * m, b * m
		end

		local ni = ((gy + noise_oy) % NOISE_SIZE) * NOISE_SIZE + ((gx + noise_ox) % NOISE_SIZE) + 1
		local n1, n2 = noise_a[ni], noise_b[ni]
		local body = P.body

		if body == "strata" then
			local ly = gy + (n2 - 0.5) * 40 + sin(gx * 0.021) * 7
			local band = floor(ly / 8)
			local m = STRATA[(band % 4) + 1]
			if ly - band * 8 < 1 then m = m * 0.82 end
			r, g, b = r * m, g * m, b * m
		else
			local m = 1
			if n1 > 0.6 then
				m = P.patch or 0.84
			elseif n1 > 0.585 then
				m = (P.patch or 0.84) * 0.9
			end
			r, g, b = r * m, g * m, b * m
		end

		if body == "magma" and nd > cap_th + 3 and n1 > 0.47 then
			local v = abs(n2 - 0.5)
			if v < 0.006 then
				r, g, b = 255, 222, 104
			elseif v < 0.014 then
				r, g, b = 255, 130, 38
			elseif v < 0.028 then
				r, g, b = r + (200 - r) * 0.4, g + (62 - g) * 0.4, b + (22 - b) * 0.4
			end
		elseif body == "ice" then
			local s = (gx + gy) % 44
			if (s < 3 or s == 5) and n2 > 0.47 then
				r, g, b = r + (255 - r) * 0.32, g + (255 - g) * 0.32, b + (255 - b) * 0.32
			end
		end

		if nd < cap_th + 2 then
			r, g, b = r * 0.7, g * 0.7, b * 0.7 -- Drop shadow under the cap
		elseif nd >= cap_th + 3 then
			local p = get_pebble(floor(gx / PEBBLE_CELL), floor(gy / PEBBLE_CELL))
			if p then
				r, g, b = shade_pebble(p, gx, gy, r, g, b)
			end
		end
	end

	if e <= EDGE_MAX then
		if burnt_edge then
			local k = BURN_KEEP[e]
			local bc = P.burnt
			r = bc[1] + (r - bc[1]) * k
			g = bc[2] + (g - bc[2]) * k
			b = bc[3] + (b - bc[3]) * k
		elseif dir == DIR_DOWN then
			local m = UNDER_SHADE[e]
			r, g, b = r * m, g * m, b * m
		elseif dir == DIR_RIGHT then
			local m = RIGHT_SHADE[e]
			r, g, b = r * m, g * m, b * m
		elseif dir == DIR_LEFT then
			local m = LEFT_LIGHT[e]
			r, g, b = r * m, g * m, b * m
		end
	end
	return r, g, b
end

---------------------------------------------------------
-- Prop stamping (only into air pixels inside the repaint region)
---------------------------------------------------------

local function put(gx, gy, c, k)
	if gx < rx0 or gx > rx1 or gy < ry0 or gy > ry1 then return end
	local cell = gy * cur_w + gx + 1
	if cur_grid[cell] == 1 then return end
	local i = (cell - 1) * 4 + 1
	if cur_stream[i + 3] ~= 0 then return end
	k = k or 1
	cur_stream[i] = floor(c[1] * k)
	cur_stream[i + 1] = floor(c[2] * k)
	cur_stream[i + 2] = floor(c[3] * k)
	cur_stream[i + 3] = 255
end

-- Ground height for a prop column near base row (follows slopes down a few cells)
local function prop_base(bx, gy)
	if bx < 0 or bx >= cur_w then return gy end
	local b = gy
	while b > gy - 3 and b >= 0 and cur_grid[b * cur_w + bx + 1] ~= 1 do
		b = b - 1
	end
	return b
end

local function stamp_tuft(gx, gy, hgt, lo, mid, hi)
	for dx = -2, 2 do
		local bh = hgt - abs(dx) - ((dx % 2 ~= 0) and 1 or 0)
		if bh > 0 then
			local bx = gx + dx
			local top = gy + bh
			for y = prop_base(bx, gy) + 1, top do
				put(bx, y, (y == top) and hi or ((y <= gy + 1) and lo or mid))
			end
		end
	end
end

local function stamp_flower(gx, gy, h1)
	local P = pal
	local petal = P.petals[floor(h1 * #P.petals) + 1]
	for y = gy + 1, gy + 5 do
		put(gx, y, P.cap_lo)
	end
	put(gx + 1, gy + 3, P.cap)
	local cy = gy + 7
	for dy = -2, 2 do
		for dx = -2, 2 do
			local d = dx * dx + dy * dy
			if d == 0 then
				put(gx + dx, cy + dy, P.petal_mid)
			elseif d <= 5 then
				put(gx + dx, cy + dy, petal, (d == 5) and 0.84 or 1)
			end
		end
	end
end

local function stamp_cactus(gx, gy, h1)
	local c = pal.cactus
	local hgt = 8 + floor(h1 * 4)
	for dx = -1, 1 do
		local col = (dx < 0) and c[1] or ((dx > 0) and c[3] or c[2])
		local top = (dx == 0) and hgt + 1 or hgt
		for y = prop_base(gx + dx, gy) + 1, gy + top do
			put(gx + dx, y, col)
		end
	end
	-- Right arm
	local ay = gy + floor(hgt * 0.45)
	put(gx + 2, ay, c[2])
	for y = ay, ay + 3 do
		put(gx + 3, y, c[3])
	end
	-- Left arm
	local ly = gy + floor(hgt * 0.3)
	put(gx - 2, ly, c[2])
	for y = ly, ly + 3 do
		put(gx - 3, y, c[1])
	end
end

local function stamp_spike(gx, gy, hgt, cols)
	for dx = -1, 1 do
		local sh = hgt - abs(dx) * 3
		if sh > 0 then
			local col = (dx < 0) and cols[1] or ((dx > 0) and cols[3] or cols[2])
			for y = prop_base(gx + dx, gy) + 1, gy + sh do
				put(gx + dx, y, col)
			end
		end
	end
end

local function stamp_bulb(gx, gy, h1)
	local P = pal
	local hgt = 3 + floor(h1 * 4)
	local glow = P.bulb[(h1 > 0.5) and 2 or 1]
	for y = gy + 1, gy + hgt do
		put(gx, y, P.cap_lo)
	end
	local cy = gy + hgt + 2
	for dy = -1, 1 do
		for dx = -1, 1 do
			if dx == 0 or dy == 0 then
				put(gx + dx, cy + dy, glow, (dx == 0 and dy == 0) and 1 or 0.86)
			end
		end
	end
	put(gx - 1, cy + 1, glow, 1.0)
end

local function stamp_surface(gx, gy)
	local P = pal
	local hc = hash(gx * 0.917, 3.31)
	local kind
	for i = 1, #P.props do
		if hc < P.props[i][2] then
			kind = P.props[i][1]
			break
		end
	end
	if not kind then return end
	local h1 = hash(gx * 1.37, 5.91)

	if kind == "tuft" then
		stamp_tuft(gx, gy, 4 + floor(h1 * 4), P.cap_lo, P.cap, P.cap_hi)
	elseif kind == "dry" then
		stamp_tuft(gx, gy, 4 + floor(h1 * 4), P.dry[1], P.dry[2], P.dry[3])
	elseif kind == "flower" then
		stamp_flower(gx, gy, h1)
	elseif kind == "cactus" then
		stamp_cactus(gx, gy, h1)
	elseif kind == "shard" then
		stamp_spike(gx, gy, 4 + floor(h1 * 5), P.ice)
	elseif kind == "spike" then
		local s = P.spike
		stamp_spike(gx, gy, 3 + floor(h1 * 4), { s[1], s[2], s[2] })
		put(gx, gy + 3 + floor(h1 * 4) + 1, s[3])
	elseif kind == "bulb" then
		stamp_bulb(gx, gy, h1)
	end
end

local function stamp_hang(gx, gy)
	local P = pal
	local hc = hash(gx * 0.713, 9.17)
	local kind
	for i = 1, #P.hangs do
		if hc < P.hangs[i][2] then
			kind = P.hangs[i][1]
			break
		end
	end
	if not kind then return end
	local h1 = hash(gx * 1.91, 4.37)

	if kind == "vine" then
		local len = 4 + floor(h1 * 8)
		for k = 0, len - 1 do
			put(gx, gy - k, (k == len - 1) and P.cap or P.cap_lo)
			if k % 3 == 1 then
				put(gx + ((k % 2 == 0) and 1 or -1), gy - k, P.cap)
			end
		end
	elseif kind == "icicle" then
		local len = 4 + floor(h1 * 8)
		local ic = P.ice
		for dx = -1, 1 do
			local l = len - abs(dx) * (floor(len / 2) + 1)
			local col = (dx < 0) and ic[1] or ((dx > 0) and ic[3] or ic[2])
			for k = 0, l - 1 do
				put(gx + dx, gy - k, col)
			end
		end
	elseif kind == "drip" then
		local len = 1 + floor(h1 * 3)
		local dc = P.drip
		for k = 0, len - 1 do
			put(gx, gy - k, dc[1])
		end
		put(gx, gy - len, dc[2])
	elseif kind == "tendril" then
		local len = 4 + floor(h1 * 6)
		local phase = h1 * 6.28
		local x = gx
		for k = 0, len - 1 do
			x = gx + floor(sin(k * 0.7 + phase) * 1.2 + 0.5)
			put(x, gy - k, P.cap_lo)
		end
		put(x, gy - len, P.glow)
		put(x + 1, gy - len, P.glow, 0.85)
		put(x, gy - len - 1, P.glow, 0.85)
	end
end

---------------------------------------------------------
-- Public: repaint a rectangular grid region (inclusive cell bounds)
---------------------------------------------------------

function M.paint(stream, grid, carved, w, h, x0, y0, x1, y1)
	if not noise_a then
		M.reset("grass", 0)
	end
	x0, y0 = max(0, x0), max(0, y0)
	x1, y1 = min(w - 1, x1), min(h - 1, y1)
	if x0 > x1 or y0 > y1 then return end

	carved = carved or {}
	cur_stream, cur_grid, cur_carved, cur_w, cur_h = stream, grid, carved, w, h
	rx0, ry0, rx1, ry1 = x0, y0, x1, y1

	local surf_x, surf_y, n_surf = {}, {}, 0
	local hang_x, hang_y, n_hang = {}, {}, 0
	local sx0, sx1 = max(0, x0 - M.PAD_X), min(w - 1, x1 + M.PAD_X)
	local scan_top = min(h - 1, y1 + DEPTH_CAP)
	local scan_bot = max(0, y0 - PROP_MAX)

	for gx = sx0, sx1 do
		local write_col = gx >= x0 and gx <= x1
		local cap_th = cap_thickness(gx)
		local nd = DEPTH_CAP -- depth below the original (pre-crater) surface
		local run = 99       -- live solid cells above (0 = air directly above)
		local prev_live, prev_orig = true, true

		for gy = scan_top, scan_bot, -1 do
			local idx = gy * w + gx + 1
			local live = grid[idx] == 1
			local cv = carved[idx] == true
			local orig = live or cv

			if orig then
				if prev_orig then
					if nd < DEPTH_CAP then nd = nd + 1 end
				else
					nd = 0
				end
			end

			if live then
				if prev_live then
					if run < 99 then run = run + 1 end
				else
					run = 0
					if gy + 1 <= y1 and not carved[idx + w] then
						n_surf = n_surf + 1
						surf_x[n_surf], surf_y[n_surf] = gx, gy
					end
				end
			elseif prev_live and gy < h - 1 and not cv and gy >= y0 then
				n_hang = n_hang + 1
				hang_x[n_hang], hang_y[n_hang] = gx, gy
			end

			if write_col and gy <= y1 and gy >= y0 then
				local si = (idx - 1) * 4 + 1
				if live then
					local r, g, b = shade_solid(gx, gy, idx, nd, run, cap_th)
					stream[si] = r > 255 and 255 or (r < 0 and 0 or floor(r))
					stream[si + 1] = g > 255 and 255 or (g < 0 and 0 or floor(g))
					stream[si + 2] = b > 255 and 255 or (b < 0 and 0 or floor(b))
					stream[si + 3] = 255
				else
					stream[si] = 0
					stream[si + 1] = 0
					stream[si + 2] = 0
					stream[si + 3] = 0
				end
			end

			prev_live, prev_orig = live, orig
		end
	end

	for i = 1, n_surf do
		stamp_surface(surf_x[i], surf_y[i])
	end
	for i = 1, n_hang do
		stamp_hang(hang_x[i], hang_y[i])
	end
end

return M
