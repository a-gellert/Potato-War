-- lua_modules/terrain_grid.lua
-- Optimized 2D Destructible Terrain System for Potato War

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
	
	-- Sample points in circle bounding box
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

-- Find ground Y position at given world X
function M.get_ground_y(wx)
	local gx = math.floor(wx / M.scale)
	if gx < 0 or gx >= M.width then
		return constants.WATER_LEVEL
	end
	
	for gy = M.height - 1, 0, -1 do
		if M.grid[gy * M.width + gx + 1] == 1 then
			return (gy + 1) * M.scale
		end
	end
	return constants.WATER_LEVEL
end

-- Check if a world position is solid terrain
function M.is_solid(wx, wy)
	local gx = math.floor(wx / M.scale)
	local gy = math.floor(wy / M.scale)
	if gx < 0 or gx >= M.width or gy < 0 or gy >= M.height then
		return false
	end
	return M.grid[gy * M.width + gx + 1] == 1
end

-- Simple hash-based value noise (Lua 5.1 compatible, no bitwise ops)
local function hash_val(x)
    x = math.floor(x)
    local h = math.sin(x * 127.1 + x * 311.7) * 43758.5453
    return h - math.floor(h)
end

local function value_noise(x, seed)
    local ix = math.floor(x)
    local fx = x - ix
    fx = fx * fx * (3.0 - 2.0 * fx) -- smoothstep
    local a = hash_val(ix + seed * 7919)
    local b = hash_val(ix + 1 + seed * 7919)
    return a + (b - a) * fx
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

-- Terrain Preset Generators
function M.generate(preset_type)
	preset_type = preset_type or "hills"
	local w = M.width
	local h = M.height
	local total = w * h
	M.grid = {}
	for i = 1, total do
		M.grid[i] = 0
	end

	local seed = math.random(1, 99999)

	if preset_type == "flat" then
		-- Gentle training field with a couple small bumps
		local base_h = h * 0.32
		for gx = 0, w - 1 do
			local nx = gx / w
			local gentle = fractal_noise(nx * 5.0, 3, seed) * (h * 0.08)
			local bump1 = math.exp(-((nx - 0.35) * 6) ^ 2) * (h * 0.06)
			local bump2 = math.exp(-((nx - 0.7) * 8) ^ 2) * (h * 0.04)
			local height_val = base_h + gentle + bump1 + bump2

			local max_gy = math.floor(math.max(8, math.min(h - 15, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "islands" then
		-- Jagged archipelago: 3 islands separated by deep water, each with crags
		for gx = 0, w - 1 do
			local nx = gx / w

			-- Island envelopes with varying width and height
			local i1 = math.exp(-((nx - 0.17) * 7.0) ^ 2) * (h * 0.35)
			local i2 = math.exp(-((nx - 0.52) * 5.0) ^ 2) * (h * 0.50)
			local i3 = math.exp(-((nx - 0.84) * 7.5) ^ 2) * (h * 0.30)

			-- Pick max island, water between
			local envelope = math.max(i1, math.max(i2, i3))

			-- Craggy ridged noise on surfaces
			local crag = ridged_noise(nx * 25.0, 4, seed) * (h * 0.12)
			local detail = fractal_noise(nx * 40.0, 3, seed + 50) * (h * 0.05)

			-- Deep water floor between islands
			local water_depth = h * 0.04
			local height_val = water_depth + envelope + crag + detail

			-- Carve gaps between islands more aggressively
			local gap1 = math.exp(-((nx - 0.35) * 12.0) ^ 2) * (h * 0.25)
			local gap2 = math.exp(-((nx - 0.68) * 14.0) ^ 2) * (h * 0.20)
			height_val = height_val - gap1 - gap2

			local max_gy = math.floor(math.max(8, math.min(h - 15, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "bunkers" then
		-- Two fortified plateaus with steep walls, deep trench, and rugged tops
		for gx = 0, w - 1 do
			local nx = gx / w

			-- Plateaus: steep sigmoid walls
			local wall_steepness = 18.0
			local p1 = 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.15)))
				     - 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.42)))
			local p2 = 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.58)))
				     - 1.0 / (1.0 + math.exp(-wall_steepness * (nx - 0.85)))
			p1 = math.max(0, p1)
			p2 = math.max(0, p2)

			-- Plateau heights (left higher for asymmetry)
			local plateau = p1 * (h * 0.40) + p2 * (h * 0.35)

			-- Trench floor
			local trench_floor = h * 0.12

			-- Rugged plateau tops
			local rough = ridged_noise(nx * 30.0, 3, seed) * (h * 0.10)
			local micro = fractal_noise(nx * 50.0, 2, seed + 77) * (h * 0.04)

			-- Bunker outcrops on edges
			local edge1 = math.exp(-((nx - 0.42) * 25.0) ^ 2) * (h * 0.12)
			local edge2 = math.exp(-((nx - 0.58) * 25.0) ^ 2) * (h * 0.10)

			local height_val = trench_floor + plateau + rough + micro + edge1 + edge2

			local max_gy = math.floor(math.max(8, math.min(h - 15, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	elseif preset_type == "canyon" then
		-- Deep canyon: two towering cliffs, narrow valley, optional rock bridge
		for gx = 0, w - 1 do
			local nx = gx / w

			-- Left cliff (0..0.3) and right cliff (0.7..1.0)
			local left_cliff = 1.0 / (1.0 + math.exp(20.0 * (nx - 0.28)))
			local right_cliff = 1.0 / (1.0 + math.exp(-20.0 * (nx - 0.72)))
			local cliff = math.max(left_cliff, right_cliff)

			-- Cliff height with jagged tops
			local cliff_h = cliff * (h * 0.55)
			local jagged = ridged_noise(nx * 20.0, 4, seed) * (h * 0.12) * cliff
			local detail = fractal_noise(nx * 35.0, 3, seed + 33) * (h * 0.06)

			-- Valley floor (rocky, not perfectly flat)
			local valley_floor = h * 0.10 + fractal_noise(nx * 15.0, 2, seed + 99) * (h * 0.05)

			-- Natural rock bridge in the middle (narrow arch)
			local bridge = math.exp(-((nx - 0.50) * 30.0) ^ 2) * (h * 0.20)
			-- Only create bridge sometimes (seed-dependent)
			if hash_val(seed * 3 + 42) > 0.4 then
				bridge = 0
			end

			local height_val = valley_floor + cliff_h + jagged + detail + bridge

			local max_gy = math.floor(math.max(8, math.min(h - 15, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end

	else -- "hills" (default)
		-- Rich hilly terrain: dramatic peaks, valleys, rocky outcrops
		local base_h = h * 0.25
		-- Random prominent features
		local features = {}
		for i = 1, math.random(3, 5) do
			table.insert(features, {
				x = math.random() * 0.7 + 0.15,
				height = (math.random() * 0.20 + 0.10) * h,
				width = math.random() * 8.0 + 6.0,
			})
		end
		-- Random valleys (negative features)
		local valleys = {}
		for i = 1, math.random(1, 3) do
			table.insert(valleys, {
				x = math.random() * 0.6 + 0.2,
				depth = (math.random() * 0.12 + 0.05) * h,
				width = math.random() * 6.0 + 4.0,
			})
		end

		for gx = 0, w - 1 do
			local nx = gx / w

			-- Multi-layer noise: big shapes + medium detail + fine grit
			local big = fractal_noise(nx * 3.5, 4, seed) * (h * 0.28)
			local med = ridged_noise(nx * 8.0, 3, seed + 20) * (h * 0.12)
			local fine = fractal_noise(nx * 25.0, 2, seed + 40) * (h * 0.05)

			-- Sinusoidal base undulation
			local wave = math.sin(nx * 6.28 * 1.5 + seed * 0.01) * (h * 0.08)

			local height_val = base_h + big + med + fine + wave

			-- Add prominent peaks
			for _, f in ipairs(features) do
				height_val = height_val + math.exp(-((nx - f.x) * f.width) ^ 2) * f.height
			end
			-- Carve valleys
			for _, v in ipairs(valleys) do
				height_val = height_val - math.exp(-((nx - v.x) * v.width) ^ 2) * v.depth
			end

			local max_gy = math.floor(math.max(8, math.min(h - 15, height_val)))
			for gy = 0, max_gy do
				M.grid[gy * w + gx + 1] = 1
			end
		end
	end
end

return M
