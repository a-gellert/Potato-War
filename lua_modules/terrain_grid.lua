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

-- Carve smooth organic bubble hollow chamber
local function carve_bubble(cx, cy, rx, ry, seed, deform_strength)
	deform_strength = deform_strength or 0.22
	local min_gx = math.max(2, math.floor(cx - rx * 1.3))
	local max_gx = math.min(M.width - 3, math.ceil(cx + rx * 1.3))
	local min_gy = math.max(16, math.floor(cy - ry * 1.3))
	local max_gy = math.min(M.height - 2, math.ceil(cy + ry * 1.3))

	for gy = min_gy, max_gy do
		local dy = (gy - cy) / ry
		local row = gy * M.width
		for gx = min_gx, max_gx do
			local dx = (gx - cx) / rx
			local angle = math.atan2(dy, dx)
			local dist = math.sqrt(dx * dx + dy * dy)
			local deform = 1.0 + deform_strength * math.sin(angle * 3.0 + seed * 0.2) + (deform_strength * 0.5) * math.cos(angle * 5.0 + seed * 0.5)
			if dist <= deform then
				M.grid[row + gx + 1] = 0
			end
		end
	end
end

-- Add Arch / Bridge structure across a chasm
local function add_arch(gcx, gcy, span_gx, arch_height_gy, thickness_gy, seed)
	local bridge_start = math.max(0, math.floor(gcx - span_gx))
	local bridge_end = math.min(M.width - 1, math.ceil(gcx + span_gx))
	
	for gx = bridge_start, bridge_end do
		local nx = (gx - gcx) / span_gx
		if math.abs(nx) <= 1.0 then
			local arch_curve = math.cos(nx * 1.57079)
			local base_arch_y = gcy + arch_curve * arch_height_gy
			local top_arch_y = base_arch_y + thickness_gy * (0.85 + 0.3 * math.abs(nx))
			
			local rough_top = (value_noise(gx * 0.15, seed) - 0.5) * 4.0
			local rough_bot = (value_noise(gx * 0.18, seed + 22) - 0.5) * 5.0

			local min_y = math.max(16, math.floor(base_arch_y + rough_bot))
			local max_y = math.min(M.height - 1, math.floor(top_arch_y + rough_top))
			for gy = min_y, max_y do
				M.grid[gy * M.width + gx + 1] = 1
			end
		end
	end
end

-- Add floating island slab with flat or gently rolling top and icicle/stalactite bottom
local function add_island(gcx, gcy, span_x, thickness, iseed, with_icicles)
	local min_gx = math.max(2, math.floor(gcx - span_x * 1.25))
	local max_gx = math.min(M.width - 3, math.ceil(gcx + span_x * 1.25))
	for gx = min_gx, max_gx do
		local nx = (gx - gcx) / span_x
		if math.abs(nx) <= 1.0 then
			local env = math.cos(nx * 1.57079)
			local top_rough = (fractal_noise(gx * 0.08, 2, iseed) - 0.5) * 8.0
			local bot_icicles = with_icicles and (ridged_noise(gx * 0.14, 3, iseed + 19) * (thickness * 0.55)) or 0
			local top_y = gcy + env * (thickness * 0.35) + top_rough
			local bot_y = gcy - env * thickness - bot_icicles * env
			local min_y = math.max(16, math.floor(bot_y))
			local max_y = math.min(M.height - 2, math.floor(top_y))
			for gy = min_y, max_y do
				M.grid[gy * M.width + gx + 1] = 1
			end
		end
	end
end

-- Add classic Worms mushroom rock (thin stem, wide platform cap)
local function add_mushroom_spire(cx, cy, stem_w, stem_h, cap_rx, cap_ry, seed)
	local stem_min_x = math.max(2, math.floor(cx - stem_w * 0.5))
	local stem_max_x = math.min(M.width - 3, math.ceil(cx + stem_w * 0.5))
	for gx = stem_min_x, stem_max_x do
		local s_warp = (value_noise(gx * 0.15, seed) - 0.5) * 4.0
		for gy = math.max(16, math.floor(cy - stem_h)), math.floor(cy + s_warp) do
			M.grid[gy * M.width + gx + 1] = 1
		end
	end
	add_blob(cx, cy, cap_rx, cap_ry, seed + 33, 0.18)
end

---------------------------------------------------------
-- Terrain Preset Generators (Domain-warped & noise-rich)
---------------------------------------------------------

function M.generate(preset_type, campaign_level, is_defense)
	preset_type = preset_type or "hills"
	local all_presets = {
		"hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese",
		"bunkers", "islands", "pyramid_temple", "twin_peaks", "valley_caves"
	}
	if preset_type == "random" then
		preset_type = all_presets[math.random(1, #all_presets)]
	end

	local w = M.width
	local h = M.height
	local total = w * h
	M.grid = {}
	for i = 1, total do
		M.grid[i] = 0
	end

	local seed = math.random(1, 99999)

	if preset_type == "flat" then
		-- Training Arena: domain-warped dunes and sniper berms with comfortable verticality
		local base_h = math.floor(h * 0.35)
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.06, 2.5)
			local gentle = fractal_noise(wx * 4.0, 3, seed) * (h * 0.08)
			local mound1 = math.exp(-((wx - 0.32) * 6) ^ 2) * (h * 0.07)
			local mound2 = math.exp(-((wx - 0.68) * 6) ^ 2) * (h * 0.07)
			local micro = (value_noise(gx * 0.15, seed + 8) - 0.5) * 4
			local height_val = math.floor(math.max(18, math.min(math.floor(h * 0.55), base_h + gentle + mound1 + mound2 + micro)))
			for gy = 0, height_val do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "floating_islands" then
		-- Arena 2 (Arctic): Sky Archipelago of floating icebergs hanging in mid-air over the open ocean
		-- 1. Submerged icy reef bed
		for gx = 0, w - 1 do
			local nx = gx / w
			local seabed = math.floor(6 + fractal_noise(nx * 8.0, 2, seed) * 4)
			for gy = 0, seabed do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Three majestic floating sky islands: Left, Center Citadel (high altitude), Right
		add_island(math.floor(w * 0.22), math.floor(h * 0.52), math.floor(w * 0.16), math.floor(h * 0.16), seed, true)
		add_island(math.floor(w * 0.50), math.floor(h * 0.68), math.floor(w * 0.17), math.floor(h * 0.18), seed + 40, true)
		add_island(math.floor(w * 0.78), math.floor(h * 0.52), math.floor(w * 0.16), math.floor(h * 0.16), seed + 80, true)

		-- Stepping stone ice shards connecting the islands
		add_island(math.floor(w * 0.35), math.floor(h * 0.38), math.floor(w * 0.05), math.floor(h * 0.08), seed + 120, true)
		add_island(math.floor(w * 0.65), math.floor(h * 0.38), math.floor(w * 0.05), math.floor(h * 0.08), seed + 160, true)

		-- Carve ice caves & worm tunnels through the floating islands
		carve_worm_tunnel(math.floor(w * 0.22), math.floor(h * 0.52), 16, 0.0, 16, 0.35, seed + 200)
		carve_worm_tunnel(math.floor(w * 0.50), math.floor(h * 0.68), 18, 0.1, 18, 0.30, seed + 210)
		carve_worm_tunnel(math.floor(w * 0.78), math.floor(h * 0.52), 16, 3.14, 16, 0.35, seed + 220)

	elseif preset_type == "canyon_bridge" or preset_type == "canyon" then
		-- Arena 3 (Desert): Grand Canyon with sheer sandstone mesas, hoodoos, and a colossal arch bridge!
		local canyon_left = math.floor(w * 0.28)
		local canyon_right = math.floor(w * 0.72)
		local mesa_top = math.floor(h * 0.66)
		local floor_h = 24

		-- Left & Right towering mesas with stepped geological strata terraces
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.08, 3.5)
			local max_gy = floor_h

			if gx <= canyon_left then
				local drop = math.min(1.0, math.max(0.0, (canyon_left - gx) / 22.0))
				local terraced_drop = stepped_terrace(drop * (mesa_top - floor_h), 18)
				local strata_noise = (fractal_noise(wx * 8.0, 2, seed) - 0.5) * 8
				max_gy = math.floor(floor_h + terraced_drop + strata_noise)
			elseif gx >= canyon_right then
				local drop = math.min(1.0, math.max(0.0, (gx - canyon_right) / 22.0))
				local terraced_drop = stepped_terrace(drop * (mesa_top - floor_h), 18)
				local strata_noise = (fractal_noise(wx * 8.0, 2, seed + 50) - 0.5) * 8
				max_gy = math.floor(floor_h + terraced_drop + strata_noise)
			else
				-- Canyon floor with desert dunes and sandstone hoodoos (rock needles)
				local hoodoo1 = math.exp(-((nx - 0.42) * 35) ^ 2) * (h * 0.18)
				local hoodoo2 = math.exp(-((nx - 0.58) * 35) ^ 2) * (h * 0.18)
				local dune = fractal_noise(nx * 10.0, 2, seed) * 10
				max_gy = math.floor(floor_h + dune + hoodoo1 + hoodoo2)
			end

			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Grand Sandstone Arch Bridge across the abyss
		local bridge_start = math.floor(w * 0.24)
		local bridge_end = math.floor(w * 0.76)
		local b_span = (bridge_end - bridge_start) * 0.5
		local b_center = (bridge_start + bridge_end) * 0.5
		local b_deck_y = math.floor(h * 0.56)

		for gx = bridge_start, bridge_end do
			local nx = (gx - b_center) / b_span
			if math.abs(nx) <= 1.0 then
				local wnx, _ = warp_coord_2d(nx, 0.5, seed + 88, 0.08, 0.05)
				local arch_curve = math.cos(math.max(-1.0, math.min(1.0, wnx)) * 1.57079)
				local arch_bot = math.floor(h * 0.34 + arch_curve * (h * 0.18))
				local deck_top = math.floor(b_deck_y + (fractal_noise(gx * 0.10, 2, seed) - 0.5) * 6)
				for gy = arch_bot, deck_top do
					M.grid[gy * w + gx + 1] = 1
				end
			end
		end

		-- Central rock pillar anchoring into the canyon bed
		local p_center = math.floor(w * 0.50)
		for gx = p_center - 10, p_center + 10 do
			for gy = floor_h, math.floor(h * 0.44) do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Cave grottos inside mesa bases
		carve_worm_tunnel(math.floor(w * 0.14), math.floor(h * 0.35), 20, 0.2, 18, 0.3, seed + 44)
		carve_worm_tunnel(math.floor(w * 0.86), math.floor(h * 0.35), 20, 3.0, 18, 0.3, seed + 55)

	elseif preset_type == "cavern" then
		-- Arena 4 (Volcano): Underground volcanic caldera with rugged basalt floor, stalactite ceiling & magma chimney
		-- 1. Multi-tier floor with lava platforms and basalt fighting ring
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.09, 3.2)
			local m1 = math.exp(-((wx - 0.22) * 5.5) ^ 2) * (h * 0.22)
			local m2 = math.exp(-((wx - 0.78) * 5.5) ^ 2) * (h * 0.22)
			local center_platform = math.exp(-((wx - 0.50) * 12) ^ 2) * (h * 0.14)
			local rough = fractal_noise(nx * 10.0, 3, seed) * (h * 0.08)
			local floor_y = math.floor(h * 0.22 + m1 + m2 + center_platform + rough)
			for gy = 0, floor_y do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- 2. Hanging Stalactite Ceiling with central volcano chimney opening (nx = 0.40 .. 0.60)
		for gx = 0, w - 1 do
			local nx = gx / w
			if nx < 0.40 or nx > 0.60 then
				local wx = warp_coord_1d(nx, seed + 33, 0.08, 4.0)
				local stalactite = ridged_noise(wx * 18.0, 3, seed + 44) * (h * 0.20)
				local undulation = math.sin(wx * 6.28 * 2.0 + seed) * (h * 0.06)
				local ceil_bot = math.max(math.floor(h * 0.62), math.floor(h * 0.84 - stalactite + undulation))
				for gy = ceil_bot, h - 1 do
					M.grid[gy * w + gx + 1] = 1
				end
			end
		end

		-- 3. Suspended basalt monolith floating in the skylight gap
		local m_start = math.floor(w * 0.45)
		local m_end = math.floor(w * 0.55)
		for gx = m_start, m_end do
			local nx = (gx - w * 0.50) / (w * 0.05)
			local env = math.cos(nx * 1.57079)
			local min_y = math.floor(h * 0.56 - env * 10)
			local max_y = math.floor(h * 0.64 + env * 8)
			for gy = min_y, max_y do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Procedural lava tunnels through the floor
		carve_worm_tunnel(math.floor(w * 0.20), math.floor(h * 0.24), 22, 0.1, 16, 0.35, seed + 77)
		carve_worm_tunnel(math.floor(w * 0.80), math.floor(h * 0.24), 22, 3.1, 16, 0.35, seed + 88)

	elseif preset_type == "swiss_cheese" then
		-- Arena 5 (Alien): High organic rock massif riddled with 18+ bio-bubbles and winding worm tunnels
		local block_top = math.floor(h * 0.70)
		for gx = 0, w - 1 do
			local nx = gx / w
			local wave = math.sin(nx * 6.28 * 2.0 + seed) * (h * 0.07)
			local rough = (fractal_noise(nx * 6.0, 2, seed) - 0.5) * 10
			local max_gy = math.floor(block_top + wave + rough)
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- 3 intersecting winding procedural excavator worm tunnels
		carve_worm_tunnel(math.floor(w * 0.15), math.floor(h * 0.45), 32, 0.25, 20, 0.40, seed + 10)
		carve_worm_tunnel(math.floor(w * 0.50), math.floor(h * 0.32), 36, -0.10, 22, 0.45, seed + 20)
		carve_worm_tunnel(math.floor(w * 0.85), math.floor(h * 0.45), 32, 2.90, 20, 0.40, seed + 30)

		-- 16 organic bio-bubbles forming multi-tier rooms and shooting niches
		local bubbles = {
			{ 0.16, 0.30, 26, 22 }, { 0.32, 0.46, 28, 24 }, { 0.48, 0.26, 30, 24 },
			{ 0.65, 0.46, 28, 24 }, { 0.84, 0.30, 26, 22 }, { 0.24, 0.58, 22, 18 },
			{ 0.76, 0.58, 22, 18 }, { 0.50, 0.50, 24, 20 }, { 0.36, 0.22, 22, 18 },
			{ 0.62, 0.22, 22, 18 }, { 0.10, 0.44, 20, 16 }, { 0.90, 0.44, 20, 16 },
			{ 0.42, 0.38, 20, 18 }, { 0.58, 0.38, 20, 18 }, { 0.28, 0.16, 18, 14 },
			{ 0.72, 0.16, 18, 14 }
		}
		for i, b in ipairs(bubbles) do
			local cx = math.floor(w * b[1] + (value_noise(b[1] * 10, seed + i) - 0.5) * 20)
			local cy = math.floor(h * b[2] + (value_noise(b[2] * 10, seed + i * 3) - 0.5) * 16)
			carve_bubble(cx, cy, b[3], b[4], seed + i * 7, 0.20)
		end

	elseif preset_type == "islands" then
		-- 4 Distinct scenic sea islands with sea stacks, coastal shelves, and marine grottos
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.09, 3.5)
			local i1 = math.exp(-((wx - 0.18) * 7.0) ^ 2) * (h * 0.42)
			local i2 = math.exp(-((wx - 0.44) * 8.5) ^ 2) * (h * 0.58) -- Tall needle peak
			local i3 = math.exp(-((wx - 0.68) * 8.0) ^ 2) * (h * 0.44)
			local i4 = math.exp(-((wx - 0.88) * 7.5) ^ 2) * (h * 0.46)
			local peak = math.max(i1, math.max(i2, math.max(i3, i4)))

			local height_val = 8 -- submerged seabed
			if peak > 2.0 then
				local cliff_warp = (fractal_noise(wx * 8.0, 2, seed) - 0.5) * 8
				local shelf = stepped_terrace(peak, 20)
				height_val = 8 + shelf + cliff_warp
			end

			-- Towering sea stack needle rock in center-left channel
			local needle = math.exp(-((nx - 0.33) * 45) ^ 2) * (h * 0.52)
			height_val = math.max(height_val, 8 + needle)

			local max_gy = math.floor(math.max(4, math.min(math.floor(h * 0.68), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Natural sea cave arch through center island at waterline
		carve_worm_tunnel(math.floor(w * 0.44), math.floor(h * 0.16), 18, 0.0, 18, 0.20, seed + 99)

	elseif preset_type == "bunkers" then
		-- Fortified concrete bunkers with multi-tier ramparts, watchtowers, embrasure slits, and shell craters
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.05, 3.0)
			local height_val = 24

			if nx >= 0.10 and nx <= 0.38 then
				local dist_edge = math.min(nx - 0.10, 0.38 - nx)
				local wall = math.min(1.0, dist_edge / 0.03)
				local rampart = stepped_terrace(wall * (h * 0.34), 16)
				local tower = (nx >= 0.13 and nx <= 0.19) and (h * 0.12) or 0
				height_val = h * 0.22 + rampart + tower + (fractal_noise(wx * 10, 2, seed) - 0.5) * 4
			elseif nx >= 0.62 and nx <= 0.90 then
				local dist_edge = math.min(nx - 0.62, 0.90 - nx)
				local wall = math.min(1.0, dist_edge / 0.03)
				local rampart = stepped_terrace(wall * (h * 0.34), 16)
				local tower = (nx >= 0.81 and nx <= 0.87) and (h * 0.12) or 0
				height_val = h * 0.22 + rampart + tower + (fractal_noise(wx * 10, 2, seed + 20) - 0.5) * 4
			elseif nx > 0.38 and nx < 0.62 then
				-- No-man's land trench with deep bomb craters
				local crater1 = math.exp(-((nx - 0.46) * 24) ^ 2) * (h * 0.12)
				local crater2 = math.exp(-((nx - 0.54) * 24) ^ 2) * (h * 0.12)
				local trench_floor = h * 0.20
				height_val = math.max(20, trench_floor - crater1 - crater2 + (fractal_noise(wx * 8, 2, seed) - 0.5) * 4)
			else
				height_val = h * 0.22 + fractal_noise(wx * 4, 2, seed) * 6
			end

			local max_gy = math.floor(math.max(20, math.min(math.floor(h * 0.68), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Pillbox embrasure slits through the concrete bunkers
		local embrasures = {
			{ math.floor(w * 0.25), math.floor(h * 0.38), 24, 5 },
			{ math.floor(w * 0.75), math.floor(h * 0.38), 24, 5 },
			{ math.floor(w * 0.16), math.floor(h * 0.52), 16, 4 },
			{ math.floor(w * 0.84), math.floor(h * 0.52), 16, 4 }
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

		-- Underground bunker rooms
		carve_bubble(math.floor(w * 0.24), math.floor(h * 0.26), 34, 18, seed + 11, 0.15)
		carve_bubble(math.floor(w * 0.76), math.floor(h * 0.26), 34, 18, seed + 22, 0.15)

	elseif preset_type == "pyramid_temple" then
		-- Stepped Ziggurat / Pyramid Terraces with central fighting plaza and obelisk pillars
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.06, 3.0)
			local height_val = 22

			if nx >= 0.08 and nx <= 0.42 then
				local dist_edge = math.min(nx - 0.08, 0.42 - nx)
				local wall = math.min(1.0, dist_edge / 0.16)
				local pyramid = stepped_terrace(wall * (h * 0.44), 20)
				height_val = h * 0.20 + pyramid + (fractal_noise(wx * 8, 2, seed) - 0.5) * 4
			elseif nx >= 0.58 and nx <= 0.92 then
				local dist_edge = math.min(nx - 0.58, 0.92 - nx)
				local wall = math.min(1.0, dist_edge / 0.16)
				local pyramid = stepped_terrace(wall * (h * 0.44), 20)
				height_val = h * 0.20 + pyramid + (fractal_noise(wx * 8, 2, seed + 20) - 0.5) * 4
			elseif nx > 0.42 and nx < 0.58 then
				-- Central temple plaza with tall obelisk pillars
				local obelisk1 = math.exp(-((nx - 0.46) * 45) ^ 2) * (h * 0.26)
				local obelisk2 = math.exp(-((nx - 0.54) * 45) ^ 2) * (h * 0.26)
				local valley_floor = h * 0.22
				height_val = math.max(22, valley_floor + obelisk1 + obelisk2 + (fractal_noise(wx * 6, 2, seed) - 0.5) * 4)
			else
				height_val = h * 0.20 + fractal_noise(wx * 4, 2, seed) * 6
			end

			local max_gy = math.floor(math.max(20, math.min(math.floor(h * 0.68), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Procedural crypt tunnel through pyramid bases
		carve_worm_tunnel(math.floor(w * 0.20), math.floor(h * 0.32), 26, 0.1, 18, 0.35, seed + 11)
		carve_worm_tunnel(math.floor(w * 0.80), math.floor(h * 0.32), 26, 3.14, 18, 0.35, seed + 22)

	elseif preset_type == "twin_peaks" then
		-- Two towering mountain peaks soaring up to h * 0.75 flanking a deep chasm with an elevated rock bridge
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.09, 3.5)
			local p1 = math.exp(-((wx - 0.24) * 4.8) ^ 2) * (h * 0.56)
			local p2 = math.exp(-((wx - 0.76) * 4.8) ^ 2) * (h * 0.56)
			local peak = math.max(p1, p2)
			local ridged = ridged_noise(wx * 10.0, 3, seed) * (h * 0.12)

			local max_gy = math.floor(math.max(18, math.min(math.floor(h * 0.75), h * 0.18 + peak + ridged)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Suspended high rock bridge connecting both peaks
		add_arch(math.floor(w * 0.50), math.floor(h * 0.44), math.floor(w * 0.20), math.floor(h * 0.12), math.floor(h * 0.06), seed + 55)

		-- Mountain cave hollows
		carve_bubble(math.floor(w * 0.24), math.floor(h * 0.35), 30, 20, seed + 81, 0.20)
		carve_bubble(math.floor(w * 0.76), math.floor(h * 0.35), 30, 20, seed + 82, 0.20)

	elseif preset_type == "valley_caves" then
		-- Rolling highlands with 2-tier interconnecting underground cavern tunnels
		local base_h = math.floor(h * 0.42)
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.08, 3.2)
			local roll = math.sin(wx * 6.28 * 1.5 + seed) * (h * 0.14)
			local micro = fractal_noise(nx * 10.0, 3, seed + 9) * (h * 0.06)
			local max_gy = math.floor(math.max(22, math.min(math.floor(h * 0.65), base_h + roll + micro)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- 2-tier winding underground cave network
		carve_worm_tunnel(math.floor(w * 0.25), math.floor(h * 0.32), 34, 0.3, 18, 0.4, seed + 101)
		carve_worm_tunnel(math.floor(w * 0.75), math.floor(h * 0.32), 34, 2.8, 18, 0.4, seed + 202)
		carve_worm_tunnel(math.floor(w * 0.50), math.floor(h * 0.20), 32, 0.0, 20, 0.3, seed + 303)

	else -- "hills" (Classic Worms Green: Massive rolling peaks, high stone bridge arch, mushroom spire, and caves!)
		local base_h = math.floor(h * 0.34)
		for gx = 0, w - 1 do
			local nx = gx / w
			local wx = warp_coord_1d(nx, seed, 0.08, 3.2)

			local gentle_roll = math.sin(wx * 6.28 * 1.1 + seed * 0.05) * (h * 0.10)
			local wave = math.cos(wx * 6.28 * 2.2 + seed * 0.1) * (h * 0.06)
			local h1 = math.exp(-((wx - 0.25) * 5.0) ^ 2) * (h * 0.28) -- Left mountain peak
			local h2 = math.exp(-((wx - 0.75) * 5.0) ^ 2) * (h * 0.30) -- Right mountain peak
			local micro_noise = (fractal_noise(nx * 12.0, 3, seed + 15) - 0.5) * (h * 0.04)

			local height_val = base_h + gentle_roll + wave + h1 + h2 + micro_noise
			local max_gy = math.floor(math.max(20, math.min(math.floor(h * 0.66), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- High Stone Bridge Arch spanning the central valley (gx = 360 .. 600)
		add_arch(math.floor(w * 0.50), math.floor(h * 0.34), math.floor(w * 0.14), math.floor(h * 0.10), math.floor(h * 0.05), seed + 77)

		-- Cantilevered cliff diving-board ledge on the left mountain slope
		local ledge_cx = math.floor(w * 0.34)
		local ledge_cy = math.floor(h * 0.42)
		for gx = ledge_cx - 28, ledge_cx + 28 do
			local nx = (gx - ledge_cx) / 28
			local env = math.cos(nx * 1.57079)
			local top_y = math.floor(ledge_cy + env * 10)
			local bot_y = math.floor(ledge_cy - env * 8)
			for gy = bot_y, top_y do
				M.grid[gy * w + gx + 1] = 1
			end
		end

		-- Mushroom rock spire with wide battle platform on the right
		add_mushroom_spire(math.floor(w * 0.72), math.floor(h * 0.46), 14, math.floor(h * 0.12), 26, 10, seed + 88)

		-- Procedural worm caves through the mountain bases
		carve_worm_tunnel(math.floor(w * 0.22), math.floor(h * 0.24), 26, 0.2, 18, 0.35, seed + 111)
		carve_worm_tunnel(math.floor(w * 0.78), math.floor(h * 0.24), 26, 2.9, 18, 0.35, seed + 222)
	end

	if is_defense then
		M.defense_spawn_points = {}
		M.apply_defense_fortifications()
	end
end

-- Defense Mode Fortification Specialization:
-- When Blue defends, sculpt elevated bunkers/redoubts on the left with firing parapets
function M.apply_defense_fortifications()
	local w = M.width or 960
	local h = M.height or 480
	local b_start_gx = math.floor(w * 0.10)
	local b_end_gx = math.floor(w * 0.38)
	local parapet_gx = math.floor(w * 0.35)

	for gx = b_start_gx, b_end_gx do
		local nx = (gx - b_start_gx) / math.max(1, b_end_gx - b_start_gx)
		local hill_boost = math.floor(math.sin(nx * 3.14159) * 45) + 20
		local current_top = 0
		for gy = h - 1, 0, -1 do
			if M.grid[gy * w + gx + 1] == 1 then
				current_top = gy
				break
			end
		end

		local new_top = math.min(math.floor(h * 0.64), current_top + hill_boost)
		-- Protective concrete breastwork at the forward edge
		if gx >= parapet_gx - 6 and gx <= parapet_gx + 3 then
			new_top = math.min(math.floor(h * 0.70), new_top + 20)
		end

		for gy = current_top, new_top do
			M.grid[gy * w + gx + 1] = 1
		end
	end

	-- Carve embrasures (firing slots) in the breastwork so defenders can aim through
	local embrasures = { math.floor(parapet_gx - 3), math.floor(parapet_gx + 1) }
	for _, egx in ipairs(embrasures) do
		local top_gy = 0
		for gy = h - 1, 0, -1 do
			if M.grid[gy * w + egx + 1] == 1 then
				top_gy = gy
				break
			end
		end
		for gy = top_gy - 6, top_gy do
			if gy >= 0 then
				M.grid[gy * w + egx + 1] = 0
			end
		end
	end
end

-- Return recommended high-ground spawn positions for Blue defenders
function M.get_defense_spawn_points(count)
	count = count or 3
	local w = M.width or 960
	local pts = {}
	local start_x = 220
	local end_x = 550
	local step = (end_x - start_x) / math.max(1, count)

	for i = 1, count do
		local cx = start_x + (i - 0.5) * step + (math.random() - 0.5) * 20
		local gy = M.get_smooth_ground_y(cx, 4.0)
		table.insert(pts, { x = cx, y = gy })
	end
	return pts
end

return M
