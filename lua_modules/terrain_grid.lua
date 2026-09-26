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
	
	for gy = start_gy, 0, -1 do
		if M.grid[gy * M.width + gx + 1] == 1 then
			return (gy + 1) * M.scale
		end
	end
	return constants.WATER_LEVEL
end

-- Find smoothed ground Y position around given world X (filters out sawtooth/pixel jaggedness)
function M.get_smooth_ground_y(wx, radius, from_wy)
	radius = radius or 6.0
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
		local min_gx = math.max(0, math.floor(cx - cur_r))
		local max_gx = math.min(M.width - 1, math.ceil(cx + cur_r))
		local min_gy = math.max(8, math.floor(cy - cur_r)) -- keep water bed protected
		local max_gy = math.min(M.height - 1, math.ceil(cy + cur_r))
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
		local nx = (gx - gcx) / span_gx -- -1 .. +1
		if math.abs(nx) <= 1.0 then
			-- Parabolic / cosine arch curve
			local arch_norm = math.cos(nx * 1.57079) -- 1 at center, 0 at edges
			local base_arch_y = gcy + arch_norm * arch_height_gy
			local top_arch_y = base_arch_y + thickness_gy * (0.85 + 0.3 * math.abs(nx))
			
			-- Add surface roughness to bridge deck and underside
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

-- Add Cavern Ceiling with stalactites
local function add_ceiling(ceiling_gy, thickness_gy, seed)
	local w = M.width
	local h = M.height
	for gx = 0, w - 1 do
		local nx = gx / w
		-- Stalactites and uneven ceiling noise
		local stalactite = ridged_noise(nx * 18.0, 3, seed) * (thickness_gy * 0.8)
		local waviness = math.sin(nx * 6.28 * 2.0 + seed) * (thickness_gy * 0.4)
		local bot_y = math.floor(ceiling_gy - stalactite + waviness)
		bot_y = math.max(math.floor(h * 0.65), math.min(h - 5, bot_y))

		for gy = bot_y, h - 1 do
			M.grid[gy * w + gx + 1] = 1
		end
	end
end

---------------------------------------------------------
-- Terrain Preset Generators (Worms-style hybrid architectures)
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
		-- Gentle training arena
		local base_h = h * 0.26
		for gx = 0, w - 1 do
			local nx = gx / w
			local gentle = fractal_noise(nx * 4.0, 3, seed) * (h * 0.06)
			local bump1 = math.exp(-((nx - 0.35) * 6) ^ 2) * (h * 0.05)
			local bump2 = math.exp(-((nx - 0.7) * 8) ^ 2) * (h * 0.04)
			local height_val = base_h + gentle + bump1 + bump2

			local max_gy = math.floor(math.max(12, math.min(max_allowed_gy, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "floating_islands" then
		-- Arena 2 (Arctic): Open, low-profile archipelago with smooth walkable islands and shallow ice bridges
		for gx = 0, w - 1 do
			local nx = gx / w
			-- Three broad, comfortable islands (left, center, right) at low-to-mid elevation
			local left_isl = math.exp(-((nx - 0.22) * 5.5) ^ 2) * (h * 0.18)
			local center_isl = math.exp(-((nx - 0.50) * 6.5) ^ 2) * (h * 0.14)
			local right_isl = math.exp(-((nx - 0.78) * 5.5) ^ 2) * (h * 0.18)
			local base_shelf = h * 0.16
			local gentle_wave = fractal_noise(nx * 6.0, 2, seed) * (h * 0.05)

			local height_val = base_shelf + math.max(left_isl, math.max(center_isl, right_isl)) + gentle_wave
			local max_gy = math.floor(math.max(12, math.min(math.floor(h * 0.38), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "canyon_bridge" or preset_type == "canyon" then
		-- Arena 3 (Desert): Scenic open canyon with low side plateaus and a gentle central sand-stone bridge
		for gx = 0, w - 1 do
			local nx = gx / w
			local left_plateau = 1.0 / (1.0 + math.exp(16.0 * (nx - 0.30)))
			local right_plateau = 1.0 / (1.0 + math.exp(-16.0 * (nx - 0.70)))
			local side_weight = math.max(left_plateau, right_plateau)

			local bridge_hump = math.exp(-((nx - 0.50) * 7.0) ^ 2) * (h * 0.12)
			local dunes = fractal_noise(nx * 5.0, 2, seed) * (h * 0.05)
			local base_floor = h * 0.18

			local total_h = base_floor + side_weight * (h * 0.16) + bridge_hump + dunes
			local max_gy = math.floor(math.max(14, math.min(math.floor(h * 0.40), total_h)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "cavern" then
		-- Arena 4 (Volcano): Open volcanic caldera basin with low basalt ridges (no blocking ceiling or pillars!)
		for gx = 0, w - 1 do
			local nx = gx / w
			local rim_left = math.exp(-((nx - 0.20) * 5.0) ^ 2) * (h * 0.14)
			local rim_right = math.exp(-((nx - 0.80) * 5.0) ^ 2) * (h * 0.14)
			local center_mound = math.exp(-((nx - 0.50) * 8.0) ^ 2) * (h * 0.08)
			local rough = fractal_noise(nx * 7.0, 2, seed + 100) * (h * 0.06)

			local floor_h = (h * 0.20) + rim_left + rim_right + center_mound + rough
			local max_gy = math.floor(math.max(14, math.min(math.floor(h * 0.40), floor_h)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "swiss_cheese" then
		-- Arena 5 (Alien): Open terraced alien crater valley with smooth undulating bowls (no underground traps!)
		for gx = 0, w - 1 do
			local nx = gx / w
			local base_h = h * 0.24
			local wave1 = math.sin(nx * 6.28 * 2.0 + seed * 0.1) * (h * 0.06)
			local wave2 = fractal_noise(nx * 6.0, 2, seed) * (h * 0.08)
			local crater1 = math.exp(-((nx - 0.36) * 10.0) ^ 2) * (h * 0.07)
			local crater2 = math.exp(-((nx - 0.64) * 10.0) ^ 2) * (h * 0.07)

			local height_val = base_h + wave1 + wave2 - crater1 - crater2
			local max_gy = math.floor(math.max(14, math.min(math.floor(h * 0.40), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "islands" then
		-- 3 Low Scenic Islands with shallow water channels
		for gx = 0, w - 1 do
			local nx = gx / w
			local i1 = math.exp(-((nx - 0.20) * 6.5) ^ 2) * (h * 0.20)
			local i2 = math.exp(-((nx - 0.50) * 6.5) ^ 2) * (h * 0.22)
			local i3 = math.exp(-((nx - 0.80) * 6.5) ^ 2) * (h * 0.20)

			local envelope = math.max(i1, math.max(i2, i3))
			local detail = fractal_noise(nx * 8.0, 2, seed + 50) * (h * 0.04)

			local height_val = (h * 0.14) + envelope + detail
			local max_gy = math.floor(math.max(12, math.min(max_allowed_gy, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "bunkers" then
		-- Twin Low Plateaus with gentle central valley
		for gx = 0, w - 1 do
			local nx = gx / w
			local wall_steepness = 14.0
			local p1 = 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.12)))
				     - 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.42)))
			local p2 = 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.58)))
				     - 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.88)))
			p1 = math.max(0, p1)
			p2 = math.max(0, p2)

			local plateau = p1 * (h * 0.16) + p2 * (h * 0.16)
			local trench_floor = h * 0.18
			local rough = fractal_noise(nx * 8.0, 2, seed) * (h * 0.04)

			local height_val = trench_floor + plateau + rough
			local max_gy = math.floor(math.max(12, math.min(max_allowed_gy, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	else -- "hills" (Arena 1: Smooth, gentle, low rolling meadow hills)
		local base_h = h * 0.22
		local hill1_x = 0.25 + (math.random() - 0.5) * 0.08
		local hill2_x = 0.52 + (math.random() - 0.5) * 0.08
		local hill3_x = 0.78 + (math.random() - 0.5) * 0.08

		for gx = 0, w - 1 do
			local nx = gx / w
			local gentle_roll = fractal_noise(nx * 3.0, 2, seed) * (h * 0.08)
			local wave = math.sin(nx * 6.28 * 1.2 + seed * 0.01) * (h * 0.04)
			local h1 = math.exp(-((nx - hill1_x) * 6.0) ^ 2) * (h * 0.06)
			local h2 = math.exp(-((nx - hill2_x) * 7.0) ^ 2) * (h * 0.07)
			local h3 = math.exp(-((nx - hill3_x) * 6.0) ^ 2) * (h * 0.06)

			local height_val = base_h + gentle_roll + wave + h1 + h2 + h3
			local max_gy = math.floor(math.max(14, math.min(math.floor(h * 0.36), height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end
	end
end

return M
