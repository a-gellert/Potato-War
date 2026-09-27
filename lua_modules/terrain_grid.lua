-- lua_modules/terrain_grid.lua
-- Optimized 2D Destructible Hybrid Terrain System for Potato War (Worms-style)

local constants = require("lua_modules.constants")

local M = {}

M.width = constants.TERRAIN_WIDTH
M.height = constants.TERRAIN_HEIGHT
M.scale = constants.TERRAIN_SCALE -- 2.0 world units per cell
M.grid = {} -- 1D flat array: gy * width + gx + 1 -> 1 (solid) or 0 (air)

-- Initialize or clear the grid
function M.init(w, h, scale)
	M.width = w or constants.TERRAIN_WIDTH
	M.height = h or constants.TERRAIN_HEIGHT
	M.scale = scale or constants.TERRAIN_SCALE
	local total = M.width * M.height
	M.grid = {}
	for i = 1, total do
		M.grid[i] = 0
	end
end

-- Convert world coordinates to grid coordinates
function M.world_to_grid(wx, wy)
	local gx = math.floor(wx / M.scale)
	local gy = math.floor(wy / M.scale)
	return gx, gy
end

-- Convert grid coordinates to world coordinates (center of cell)
function M.grid_to_world(gx, gy)
	local wx = (gx + 0.5) * M.scale
	local wy = (gy + 0.5) * M.scale
	return wx, wy
end

-- Check if world point is solid ground
function M.is_solid(wx, wy)
	local gx = math.floor(wx / M.scale)
	local gy = math.floor(wy / M.scale)
	if gx < 0 or gx >= M.width then
		return false
	end
	if gy < 0 or gy >= M.height then
		return false
	end
	return M.grid[gy * M.width + gx + 1] == 1
end

-- Check if a circular area around world point intersects terrain
function M.check_circle_collision(cx, cy, radius)
	local r2 = radius * radius
	local min_x = cx - radius
	local max_x = cx + radius
	local min_y = cy - radius
	local max_y = cy + radius
	
	local step = M.scale
	local colliding = false
	local pen_x, pen_y = 0, 0
	local count = 0
	
	for py = min_y, max_y, step do
		for px = min_x, max_x, step do
			local dx = px - cx
			local dy = py - cy
			if dx * dx + dy * dy <= r2 then
				if M.is_solid(px, py) then
					colliding = true
					pen_x = pen_x - dx
					pen_y = pen_y - dy
					count = count + 1
				end
			end
		end
	end
	
	if colliding and count > 0 then
		local len = math.sqrt(pen_x * pen_x + pen_y * pen_y)
		if len > 0.0001 then
			return true, pen_x / len, pen_y / len
		else
			return true, 0, 1
		end
	end
	return false, 0, 0
end

-- Sample surface normal at given world point
function M.sample_normal(wx, wy)
	local offset = M.scale * 2
	local left = M.is_solid(wx - offset, wy) and 1 or 0
	local right = M.is_solid(wx + offset, wy) and 1 or 0
	local down = M.is_solid(wx, wy - offset) and 1 or 0
	local up = M.is_solid(wx, wy + offset) and 1 or 0
	
	local nx = left - right
	local ny = down - up
	local len = math.sqrt(nx * nx + ny * ny)
	if len > 0.001 then
		return nx / len, ny / len
	end
	return 0, 1 -- Default up vector
end

-- Raycast from (x0, y0) to (x1, y1) in world coordinates
function M.raycast(x0, y0, x1, y1)
	local dx = x1 - x0
	local dy = y1 - y0
	local dist = math.sqrt(dx * dx + dy * dy)
	if dist <= 0 then
		return false
	end
	
	local steps = math.ceil(dist / (M.scale * 0.5))
	local step_x = dx / steps
	local step_y = dy / steps
	
	local curr_x = x0
	local curr_y = y0
	
	for i = 1, steps do
		curr_x = curr_x + step_x
		curr_y = curr_y + step_y
		if M.is_solid(curr_x, curr_y) then
			local nx, ny = M.sample_normal(curr_x, curr_y)
			return true, curr_x, curr_y, nx, ny
		end
	end
	return false, x1, y1, 0, 1
end

-- Carve a circular crater into the terrain
-- Returns affected bounding box in grid coordinates: min_gx, min_gy, max_gx, max_gy
function M.carve_circle(world_cx, world_cy, world_radius)
	local gcx = math.floor(world_cx / M.scale)
	local gcy = math.floor(world_cy / M.scale)
	local gr = math.ceil(world_radius / M.scale)
	
	local min_gx = math.max(0, gcx - gr)
	local max_gx = math.min(M.width - 1, gcx + gr)
	local min_gy = math.max(0, gcy - gr)
	local max_gy = math.min(M.height - 1, gcy + gr)
	
	local gr2 = gr * gr
	local cleared = 0
	
	for gy = min_gy, max_gy do
		local dy = gy - gcy
		local dy2 = dy * dy
		local row_offset = gy * M.width
		for gx = min_gx, max_gx do
			local dx = gx - gcx
			if dx * dx + dy2 <= gr2 then
				local idx = row_offset + gx + 1
				if M.grid[idx] == 1 then
					M.grid[idx] = 0
					cleared = cleared + 1
				end
			end
		end
	end
	
	return min_gx, min_gy, max_gx, max_gy, cleared
end

-- Find ground Y position at given world X, optionally scanning downwards from a specific world Y
function M.get_ground_y(wx, from_wy)
	local gx = math.floor(wx / M.scale)
	if gx < 0 or gx >= M.width then
		return constants.WATER_LEVEL
	end
	
	local start_gy = M.height - 1
	if from_wy then
		start_gy = math.min(M.height - 1, math.max(0, math.floor(from_wy / M.scale)))
	end

	-- If the query height is already inside solid rock, the actual ground surface is ABOVE this point.
	-- Scanning upward finds the true top of the rock column, preventing walking into walls or elevator loops.
	if from_wy and M.grid[start_gy * M.width + gx + 1] == 1 then
		for gy = start_gy + 1, M.height - 1 do
			if M.grid[gy * M.width + gx + 1] == 0 then
				return gy * M.scale
			end
		end
		return M.height * M.scale
	end
	
	for gy = start_gy, 0, -1 do
		if M.grid[gy * M.width + gx + 1] == 1 then
			return (gy + 1) * M.scale
		end
	end
	return constants.WATER_LEVEL
end

-- Find smoothed ground Y position around given world X (filters out sawtooth/pixel jaggedness)
function M.get_smooth_ground_y(wx, radius, from_wy)
	radius = radius or 4.0
	local samples = 5
	local step = (radius * 2) / (samples - 1)
	local total_y = 0
	local weight_sum = 0

	for i = 0, samples - 1 do
		local sample_x = (wx - radius) + i * step
		local gy = M.get_ground_y(sample_x, from_wy)
		local w = (i == 2) and 4 or ((i == 1 or i == 3) and 2 or 1)
		total_y = total_y + gy * w
		weight_sum = weight_sum + w
	end

	return total_y / weight_sum
end

-- Simple hash-based value noise (Lua 5.1 compatible, no bitwise ops)
local function hash_val(x)
    x = math.floor(x)
    local h = math.sin(x * 127.1 + x * 311.7) * 43758.5453
    return h - math.floor(h)
end

local function hash_val2d(x, y)
    local n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
    return n - math.floor(n)
end

local function value_noise(x, seed)
    local ix = math.floor(x)
    local fx = x - ix
    fx = fx * fx * (3.0 - 2.0 * fx) -- smoothstep
    local a = hash_val(ix + seed * 7919)
    local b = hash_val(ix + 1 + seed * 7919)
    return a + (b - a) * fx
end

local function value_noise2d(x, y, seed)
    local ix = math.floor(x)
    local iy = math.floor(y)
    local fx = x - ix
    local fy = y - iy
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)

    local s = seed * 37
    local a = hash_val2d(ix + s, iy + s)
    local b = hash_val2d(ix + 1 + s, iy + s)
    local c = hash_val2d(ix + s, iy + 1 + s)
    local d = hash_val2d(ix + 1 + s, iy + 1 + s)

    local ab = a + (b - a) * fx
    local cd = c + (d - c) * fx
    return ab + (cd - ab) * fy
end

local function fractal_noise(x, octaves, seed)
    local val = 0
    local amp = 1.0
    local freq = 1.0
    local max_amp = 0
    for i = 1, octaves do
        val = val + value_noise(x * freq, seed + i * 131) * amp
        max_amp = max_amp + amp
        amp = amp * 0.5
        freq = freq * 2.0
    end
    return val / max_amp
end

local function fractal_noise2d(x, y, octaves, seed)
    local val = 0
    local amp = 1.0
    local freq = 1.0
    local max_amp = 0
    for i = 1, octaves do
        val = val + value_noise2d(x * freq, y * freq, seed + i * 97) * amp
        max_amp = max_amp + amp
        amp = amp * 0.5
        freq = freq * 2.0
    end
    return val / max_amp
end

-- Ridged noise: creates sharp peaks and ridges
local function ridged_noise(x, octaves, seed)
    local val = 0
    local amp = 1.0
    local freq = 1.0
    local max_amp = 0
    for i = 1, octaves do
        local n = value_noise(x * freq, seed + i * 131)
        n = 1.0 - math.abs(n * 2.0 - 1.0) -- fold to create ridges
        n = n * n -- sharpen
        val = val + n * amp
        max_amp = max_amp + amp
        amp = amp * 0.45
        freq = freq * 2.2
    end
    return val / max_amp
end

---- Coordinate Displacement & Domain Warping
local function warp_coord_1d(x, seed, strength, freq)
    freq = freq or 3.0
    strength = strength or 0.08
    local d1 = (value_noise(x * freq, seed + 101) - 0.5) * 2.0
    local d2 = (value_noise(x * (freq * 2.3), seed + 203) - 0.5) * 2.0
    return x + d1 * strength + d2 * (strength * 0.35)
end

local function warp_coord_2d(nx, ny, seed, sx, sy)
    sx = sx or 0.08
    sy = sy or 0.06
    local dx1 = (value_noise2d(nx * 3.0, ny * 3.0, seed + 11) - 0.5) * 2.0
    local dy1 = (value_noise2d(nx * 3.0, ny * 3.0, seed + 47) - 0.5) * 2.0
    local dx2 = (value_noise2d(nx * 7.0 + dx1, ny * 7.0, seed + 89) - 0.5) * 2.0
    local dy2 = (value_noise2d(nx * 7.0, ny * 7.0 + dy1, seed + 131) - 0.5) * 2.0
    return nx + dx1 * sx + dx2 * (sx * 0.35),
           ny + dy1 * sy + dy2 * (sy * 0.35)
end

-- Geological stepped terrace curve (sharp ledges & shelves)
local function stepped_terrace(val, step_size)
    step_size = step_size or 12
    local s = val / step_size
    local base = math.floor(s)
    local frac = s - base
    local smoothed = frac * frac * (3.0 - 2.0 * frac)
    smoothed = smoothed * smoothed * (3.0 - 2.0 * smoothed)
    return (base + smoothed) * step_size
end

---------------------------------------------------------
-- Shape Primitives & Operators for 2D Worms-like Map Construction
---------------------------------------------------------

-- Add organic blob (island / plateau / rock clump)
local function add_blob(gcx, gcy, grx, gry, seed, roughness)
	roughness = roughness or 0.22
	local min_gx = math.max(0, math.floor(gcx - grx * 1.3))
	local max_gx = math.min(M.width - 1, math.ceil(gcx + grx * 1.3))
	local min_gy = math.max(0, math.floor(gcy - gry * 1.3))
	local max_gy = math.min(M.height - 1, math.ceil(gcy + gry * 1.3))

	for gy = min_gy, max_gy do
		local dy = (gy - gcy) / gry
		local row = gy * M.width
		for gx = min_gx, max_gx do
			local dx = (gx - gcx) / grx
			local angle = math.atan2(dy, dx)
			local dist = math.sqrt(dx * dx + dy * dy)
			local deform = 1.0 + roughness * math.sin(angle * 4.0 + seed * 0.1) 
			                   + (roughness * 0.6) * math.cos(angle * 7.0 + seed * 0.3)
			if dist <= deform then
				M.grid[row + gx + 1] = 1
			end
		end
	end
end

-- Procedural Worm Excavator: carves organic winding tunnels through mountains
local function carve_worm_tunnel(start_gx, start_gy, steps, init_angle, radius, curve_rate, seed)
	local cx = start_gx
	local cy = start_gy
	local angle = init_angle
	local r = radius

	for i = 1, steps do
		local n = value_noise(i * 0.25, seed) * 2.0 - 1.0
		angle = angle + n * curve_rate
		cx = cx + math.cos(angle) * (r * 0.55)
		cy = cy + math.sin(angle) * (r * 0.55)

		-- Dynamic tunnel radius variation
		local cur_r = r * (0.8 + 0.4 * value_noise(i * 0.4, seed + 50))
		local min_gx = math.max(2, math.floor(cx - cur_r))
		local max_gx = math.min(M.width - 3, math.ceil(cx + cur_r))
		local min_gy = math.max(16, math.floor(cy - cur_r)) -- keep water bed protected
		local max_gy = math.min(M.height - 2, math.ceil(cy + cur_r))
		local r2 = cur_r * cur_r

		for gy = min_gy, max_gy do
			local dy2 = (gy - cy) * (gy - cy)
			local row = gy * M.width
			for gx = min_gx, max_gx do
				local dx = gx - cx
				if dx * dx + dy2 <= r2 then
					M.grid[row + gx + 1] = 0
				end
			end
		end
	end
end

-- Add Arch / Bridge structure across a chasm
local function add_arch(gcx, gcy, span_gx, arch_height_gy, thickness_gy, seed)
	local min_gx = math.max(0, math.floor(gcx - span_gx))
	local max_gx = math.min(M.width - 1, math.ceil(gcx + span_gx))
	
	for gx = min_gx, max_gx do
		local nx = (gx - gcx) / span_gx
		if math.abs(nx) <= 1.0 then
			local arch_norm = math.cos(nx * 1.57079)
			local base_arch_y = gcy + arch_norm * arch_height_gy
			local top_arch_y = base_arch_y + thickness_gy * (0.85 + 0.3 * math.abs(nx))
			
			local rough_top = (value_noise(gx * 0.15, seed) - 0.5) * 3.0
			local rough_bot = (value_noise(gx * 0.18, seed + 22) - 0.5) * 4.0

			local min_y = math.max(0, math.floor(base_arch_y + rough_bot))
			local max_y = math.min(M.height - 1, math.floor(top_arch_y + rough_top))
			for gy = min_y, max_y do
				M.grid[gy * M.width + gx + 1] = 1
			end
		end
	end
end

---------------------------------------------------------
-- Terrain Preset Generators (Domain-warped & noise-rich)
---------------------------------------------------------

function M.generate(preset_type, campaign_level)
	preset_type = preset_type or "hills"
	local w = M.width
	local h = M.height
	local total = w * h
	M.grid = {}
	for i = 1, total do
		M.grid[i] = 0
	end

	local seed = math.random(1, 99999)
	local is_early_level = (campaign_level == nil) or (campaign_level <= 5)
	local max_allowed_gy = is_early_level and math.floor(h * 0.44) or math.floor(h * 0.54)

	if preset_type == "flat" then
		-- Gentle training arena with domain-warped dunes and sniper berms
		local base_h = h * 0.25
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.06, 2.5)
			local gentle = fractal_noise(wx * 4.0, 3, seed) * (h * 0.05)
			local mound1 = math.exp(-((wx - 0.35) * 6) ^ 2) * (h * 0.04)
			local mound2 = math.exp(-((wx - 0.65) * 6) ^ 2) * (h * 0.04)
			local micro = (value_noise(gx * 0.15, seed + 8) - 0.5) * 3
			local height_val = math.floor(math.max(16, math.min(max_allowed_gy, base_h + gentle + mound1 + mound2 + micro)))
			for gy = 0, height_val do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "floating_islands" then
		-- Arena 2 (Arctic): Floating icebergs hanging in mid-air with icicles, overhangs, and open air beneath
		-- 1. Submerged icy seabed
		for gx = 0, w - 1 do
			local nx = gx / w
			local seabed = math.floor(8 + fractal_noise(nx * 8.0, 2, seed) * 4)
			for gy = 0, seabed do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Helper for domain-warped floating iceberg slab
		local function add_island(gcx, gcy, span_x, thickness, iseed)
			local min_gx = math.max(2, math.floor(gcx - span_x * 1.2))
			local max_gx = math.min(w - 3, math.ceil(gcx + span_x * 1.2))
			for gx = min_gx, max_gx do
				local nx = (gx - gcx) / span_x
				if math.abs(nx) <= 1.0 then
					local env = math.cos(nx * 1.57079)
					local top_rough = (fractal_noise(gx * 0.08, 2, iseed) - 0.5) * 6
					local bot_icicles = ridged_noise(gx * 0.14, 3, iseed + 19) * 16
					local top_y = gcy + env * 14 + top_rough
					local bot_y = gcy - env * thickness - bot_icicles * env
					local min_y = math.max(16, math.floor(bot_y))
					local max_y = math.min(math.floor(h * 0.50), math.floor(top_y))
					for gy = min_y, max_y do
						M.grid[gy * w + gx + 1] = 1
					end
				end
			end
		end

		-- Three majestic floating islands: Left, Center, Right
		add_island(w * 0.22, h * 0.32, w * 0.15, h * 0.14, seed)
		add_island(w * 0.50, h * 0.38, w * 0.13, h * 0.13, seed + 40)
		add_island(w * 0.78, h * 0.32, w * 0.15, h * 0.14, seed + 80)

		-- Small intermediate ice floes / stepping shards
		add_island(w * 0.36, h * 0.25, w * 0.04, h * 0.06, seed + 120)
		add_island(w * 0.64, h * 0.25, w * 0.04, h * 0.06, seed + 160)

	elseif preset_type == "canyon_bridge" or preset_type == "canyon" then
		-- Arena 3 (Desert): Grand Canyon with domain-warped stepped terraces, hoodoos, and a massive rock arch bridge
		local canyon_left = math.floor(w * 0.30)
		local canyon_right = math.floor(w * 0.70)
		local mesa_top = math.floor(h * 0.40)
		local floor_h = 16

		-- Left & Right mesas with stepped geological terraces
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.08, 3.5)
			local max_gy = floor_h

			if gx <= canyon_left then
				local drop = math.min(1.0, math.max(0.0, (canyon_left - gx) / 14.0))
				local terraced_drop = stepped_terrace(drop * (mesa_top - floor_h), 12)
				local strata_noise = (fractal_noise(wx * 8.0, 2, seed) - 0.5) * 5
				max_gy = math.floor(floor_h + terraced_drop + strata_noise)
			elseif gx >= canyon_right then
				local drop = math.min(1.0, math.max(0.0, (gx - canyon_right) / 14.0))
				local terraced_drop = stepped_terrace(drop * (mesa_top - floor_h), 12)
				local strata_noise = (fractal_noise(wx * 8.0, 2, seed + 50) - 0.5) * 5
				max_gy = math.floor(floor_h + terraced_drop + strata_noise)
			else
				-- Canyon floor with desert dunes and sandstone hoodoos (rock needles)
				local hoodoo1 = math.exp(-((nx - 0.44) * 35) ^ 2) * (h * 0.10)
				local hoodoo2 = math.exp(-((nx - 0.56) * 35) ^ 2) * (h * 0.10)
				local dune = fractal_noise(nx * 10.0, 2, seed) * 6
				max_gy = math.floor(floor_h + dune + hoodoo1 + hoodoo2)
			end

			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Grand Sandstone Arch Bridge across the abyss
		local b_start = math.floor(w * 0.26)
		local b_end = math.floor(w * 0.74)
		local b_span = (b_end - b_start) * 0.5
		local b_center = (b_start + b_end) * 0.5
		local b_deck_y = math.floor(h * 0.35)

		for gx = b_start, b_end do
			local nx = (gx - b_center) / b_span
			if math.abs(nx) <= 1.0 then
				local wnx, _ = warp_coord_2d(nx, 0.5, seed + 88, 0.08, 0.05)
				local arch_norm = math.cos(math.max(-1.0, math.min(1.0, wnx)) * 1.57079)
				local arch_bot = math.floor(h * 0.19 + arch_norm * (h * 0.11))
				local deck_top = math.floor(b_deck_y + (fractal_noise(gx * 0.12, 2, seed) - 0.5) * 4)
				for gy = arch_bot, deck_top do
					M.grid[gy * w + gx + 1] = 1
				end
			end
		end

		-- Central bridge support pillar anchoring into the canyon floor
		local p_center = math.floor(w * 0.50)
		for gx = p_center - 6, p_center + 6 do
			for gy = floor_h, math.floor(h * 0.28) do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "cavern" then
		-- Arena 4 (Volcano): Underground volcanic caldera with rugged basalt floor, stalactites, and wide central chimney
		-- 1. Floor with cooled magma ramps and basalt battle platforms
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.09, 3.2)
			local m1 = math.exp(-((wx - 0.25) * 5.5) ^ 2) * (h * 0.12)
			local m2 = math.exp(-((wx - 0.75) * 5.5) ^ 2) * (h * 0.12)
			local center_platform = math.exp(-((wx - 0.50) * 12) ^ 2) * (h * 0.07)
			local rough = fractal_noise(nx * 10.0, 3, seed) * (h * 0.06)
			local floor_y = math.floor(h * 0.17 + m1 + m2 + center_platform + rough)
			for gy = 0, floor_y do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- 2. Hanging Stalactite Ceiling with central volcano chimney opening (nx = 0.40 .. 0.60)
		for gx = 0, w - 1 do
			local nx = gx / w
			if nx < 0.40 or nx > 0.60 then
				local wx = warp_coord_1d(nx, seed + 33, 0.08, 4.0)
				local stalactite = ridged_noise(wx * 18.0, 3, seed + 44) * (h * 0.18)
				local undulation = math.sin(wx * 6.28 * 2.0 + seed) * (h * 0.05)
				local ceil_bot = math.max(math.floor(h * 0.50), math.floor(h * 0.74 - stalactite + undulation))
				for gy = ceil_bot, h - 1 do
					M.grid[gy * w + gx + 1] = 1
				end
			end
		end

		-- 3. Suspended basalt monolith hanging in the skylight gap
		local m_start = math.floor(w * 0.46)
		local m_end = math.floor(w * 0.54)
		for gx = m_start, m_end do
			local nx = (gx - w * 0.50) / (w * 0.04)
			local env = math.cos(nx * 1.57079)
			local min_y = math.floor(h * 0.40 - env * 6)
			local max_y = math.floor(h * 0.44 + env * 4)
			for gy = min_y, max_y do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "swiss_cheese" then
		-- Arena 5 (Alien): High organic terrain block riddled with winding worm tunnels and bio-bubbles
		local block_top = math.floor(h * 0.46)
		for gx = 0, w - 1 do
			local nx = gx / w
			local wave = math.sin(nx * 6.28 * 2.0 + seed) * (h * 0.05)
			local rough = (fractal_noise(nx * 6.0, 2, seed) - 0.5) * 6
			local max_gy = math.floor(block_top + wave + rough)
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- 3 winding procedural worm tunnels through the alien rock
		carve_worm_tunnel(w * 0.15, h * 0.32, 28, 0.2, 14, 0.45, seed + 10)
		carve_worm_tunnel(w * 0.50, h * 0.22, 32, -0.1, 15, 0.50, seed + 20)
		carve_worm_tunnel(w * 0.85, h * 0.32, 28, 3.0, 14, 0.45, seed + 30)

		-- 12 organic bio-bubbles with domain-warped deformations
		local bubbles = {
			{ 0.18, 0.22, 16 }, { 0.32, 0.32, 18 }, { 0.48, 0.18, 18 },
			{ 0.65, 0.32, 18 }, { 0.82, 0.22, 16 }, { 0.25, 0.38, 14 },
			{ 0.75, 0.38, 14 }, { 0.50, 0.34, 15 }, { 0.38, 0.16, 14 },
			{ 0.60, 0.16, 14 }, { 0.10, 0.30, 14 }, { 0.90, 0.30, 14 }
		}
		for _, b in ipairs(bubbles) do
			local cx = math.floor(w * b[1] + (value_noise(b[1] * 10, seed) - 0.5) * 16)
			local cy = math.floor(h * b[2] + (value_noise(b[2] * 10, seed + 30) - 0.5) * 10)
			local r = b[3]
			local min_gx = math.max(2, math.floor(cx - r * 1.2))
			local max_gx = math.min(w - 3, math.ceil(cx + r * 1.2))
			local min_gy = math.max(16, math.floor(cy - r * 1.2))
			local max_gy = math.min(h - 2, math.ceil(cy + r * 1.2))
			for gy = min_gy, max_gy do
				local dy = (gy - cy) * 1.1
				local row = gy * w
				for gx = min_gx, max_gx do
					local dx = gx - cx
					local angle = math.atan2(dy, dx)
					local dist = math.sqrt(dx * dx + dy * dy)
					local deform = r * (1.0 + 0.22 * math.sin(angle * 3.0 + seed) + 0.15 * math.cos(angle * 5.0 + seed * 0.7))
					if dist <= deform then
						M.grid[row + gx + 1] = 0
					end
				end
			end
		end

	elseif preset_type == "islands" then
		-- 3 Distinct scenic islands separated by ocean straits with sea stack needles & coastal shelves
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.09, 3.5)
			local i1 = math.exp(-((wx - 0.20) * 7.0) ^ 2) * (h * 0.26)
			local i2 = math.exp(-((wx - 0.50) * 8.0) ^ 2) * (h * 0.28)
			local i3 = math.exp(-((wx - 0.80) * 7.0) ^ 2) * (h * 0.26)
			local peak = math.max(i1, math.max(i2, i3))

			local height_val = 8 -- submerged seabed
			if peak > 2.0 then
				local cliff_warp = (fractal_noise(wx * 8.0, 2, seed) - 0.5) * 6
				local shelf = stepped_terrace(peak, 14)
				height_val = 8 + shelf + cliff_warp
			end

			-- Central sea stack needle rock
			local needle = math.exp(-((nx - 0.35) * 40) ^ 2) * (h * 0.16)
			height_val = math.max(height_val, 8 + needle)

			local max_gy = math.floor(math.max(4, math.min(max_allowed_gy, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "bunkers" then
		-- Fortified concrete bunkers with stepped ramparts, embrasure slits, and shell craters
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.05, 3.0)
			local height_val = 16

			if nx >= 0.12 and nx <= 0.38 then
				local dist_edge = math.min(nx - 0.12, 0.38 - nx)
				local wall = math.min(1.0, dist_edge / 0.025)
				local rampart = stepped_terrace(wall * (h * 0.18), 10)
				height_val = h * 0.20 + rampart + (fractal_noise(wx * 10, 2, seed) - 0.5) * 3
			elseif nx >= 0.62 and nx <= 0.88 then
				local dist_edge = math.min(nx - 0.62, 0.88 - nx)
				local wall = math.min(1.0, dist_edge / 0.025)
				local rampart = stepped_terrace(wall * (h * 0.18), 10)
				height_val = h * 0.20 + rampart + (fractal_noise(wx * 10, 2, seed + 20) - 0.5) * 3
			elseif nx > 0.38 and nx < 0.62 then
				-- No-man's land trench with bomb craters
				local crater1 = math.exp(-((nx - 0.45) * 22) ^ 2) * (h * 0.07)
				local crater2 = math.exp(-((nx - 0.55) * 22) ^ 2) * (h * 0.07)
				local trench_floor = h * 0.18
				height_val = math.max(16, trench_floor - crater1 - crater2 + (fractal_noise(wx * 8, 2, seed) - 0.5) * 3)
			else
				height_val = h * 0.20 + fractal_noise(wx * 4, 2, seed) * 4
			end

			local max_gy = math.floor(math.max(16, math.min(math.floor(h * 0.42), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Pillbox embrasure slits through the bunkers
		local embrasures = {
			{ math.floor(w * 0.25), math.floor(h * 0.28), 18, 4 },
			{ math.floor(w * 0.75), math.floor(h * 0.28), 18, 4 }
		}
		for _, emb in ipairs(embrasures) do
			local ecx, ecy, erw, erh = emb[1], emb[2], emb[3], emb[4]
			for gy = ecy - erh, ecy + erh do
				local row = gy * w
				for gx = ecx - erw, ecx + erw do
					M.grid[row + gx + 1] = 0
				end
			end
		end

	else -- "hills" (Arena 1: Rolling meadow hills with domain warping, terraces, and overhang rock ledge)
		local base_h = h * 0.22
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.08, 3.2)

			local gentle_roll = math.sin(wx * 6.28 * 1.1 + seed * 0.05) * (h * 0.06)
			local wave = math.cos(wx * 6.28 * 2.2 + seed * 0.1) * (h * 0.035)
			local h1 = math.exp(-((wx - 0.28) * 5.5) ^ 2) * (h * 0.09)
			local h2 = math.exp(-((wx - 0.72) * 5.5) ^ 2) * (h * 0.09)
			local micro_noise = (fractal_noise(nx * 12.0, 3, seed + 15) - 0.5) * (h * 0.025)

			local height_val = base_h + gentle_roll + wave + h1 + h2 + micro_noise
			local max_gy = math.floor(math.max(16, math.min(math.floor(h * 0.38), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Tactical overhang rock ledge projecting out on the hillside
		local ledge_cx = math.floor(w * 0.44)
		local ledge_cy = math.floor(h * 0.26)
		for gx = ledge_cx - 24, ledge_cx + 24 do
			local nx = (gx - ledge_cx) / 24
			local env = math.cos(nx * 1.57079)
			local top_y = math.floor(ledge_cy + env * 8)
			local bot_y = math.floor(ledge_cy - env * 6)
			for gy = bot_y, top_y do
				M.grid[gy * w + gx + 1] = 1
			end
		end
	end
end

return M
