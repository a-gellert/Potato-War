const fs = require('fs');

const path = 'main/entities/terrain/terrain.script';
let raw = fs.readFileSync(path, 'utf8');
let isCRLF = raw.includes('\r\n');
let content = raw.replace(/\r\n/g, '\n');

// 1. Add camera_controller require if not present
if (!content.includes('lua_modules.camera_controller')) {
  content = content.replace(
    'local bg_battle = require("lua_modules.bg_battle")',
    'local bg_battle = require("lua_modules.bg_battle")\nlocal camera_controller = require("lua_modules.camera_controller")'
  );
}

// 2. Update BIOME_THEMES for grass
const oldThemesRegex = /grass\s*=\s*\{\s*water\s*=\s*vmath\.vector4\([^)]+\),\s*sky_clear\s*=\s*vmath\.vector4\([^)]+\),?\s*\}/;
const newThemes = `grass = {
		water = vmath.vector4(1.0, 0.72, 0.25, 0.98), -- Sizzling golden boiling oil / deep fryer
		sky_clear = vmath.vector4(0.11, 0.14, 0.22, 1.0), -- Atmospheric twilight slate (no error blue)
	}`;

content = content.replace(oldThemesRegex, newThemes);

// 3. Replace write_terrain_pixel function
const oldPixelStart = 'local function write_terrain_pixel(stream, idx, gx, gy, w, h, grid, biome)';
const oldPixelEnd = 'stream[idx + 3] = 255\nend';

const pStartIdx = content.indexOf(oldPixelStart);
const pEndIdx = content.indexOf(oldPixelEnd, pStartIdx);

if (pStartIdx === -1 || pEndIdx === -1) {
  console.error('Could not find write_terrain_pixel! start:', pStartIdx, 'end:', pEndIdx);
  process.exit(1);
}

const newWriteTerrainPixel = `local function write_terrain_pixel(stream, idx, gx, gy, w, h, grid, biome)
	if idx < 1 or (idx + 3) > (w * h * 4) then
		return
	end
	local row = gy * w
	local solid = (grid[row + gx + 1] == 1)
	if not solid then
		stream[idx] = 0
		stream[idx + 1] = 0
		stream[idx + 2] = 0
		stream[idx + 3] = 0
		return
	end

	-- Depth from surface (check up to 20 cells = 40 px for lush turf cap & root strata)
	local depth = 20
	for d = 1, 20 do
		local above_y = gy + d
		if above_y >= h or grid[above_y * w + gx + 1] == 0 then
			depth = d - 1
			break
		end
	end

	-- Fast distance to cut/air edge for 6-10 px Inner Shadow & charred crater cuts
	local min_air_dist = 99
	if gx > 0 and grid[row + gx] == 0 then
		min_air_dist = 1
	elseif gx < w - 1 and grid[row + gx + 2] == 0 then
		min_air_dist = 1
	elseif gy > 0 and grid[(gy - 1) * w + gx + 1] == 0 then
		min_air_dist = 1
	else
		for d = 2, 5 do
			if (gx - d >= 0 and grid[row + gx - d + 1] == 0)
			   or (gx + d < w and grid[row + gx + d + 1] == 0)
			   or (gy - d >= 0 and grid[(gy - d) * w + gx + 1] == 0) then
				min_air_dist = d
				break
			end
		end
	end

	-- Smooth coherent 2D coordinates for natural organic strata (NO noisy white grain!)
	local rnd = hash_val2d(gx * 1.31, gy * 1.73)
	local fold = math.sin(gx * 0.018) * 14 + math.cos(gx * 0.042) * 7
	local layer_y = gy + fold

	local r, g, b = 44, 34, 26

	if biome == "desert" then
		-- CANYON & GOLDEN DESERT BIOME
		if depth <= 2 then
			r = 246; g = 196; b = 108
		elseif depth <= 6 then
			r = 228; g = 156; b = 82
		elseif depth <= 12 then
			r = 205; g = 122; b = 68
		else
			local strata = math.sin(layer_y * 0.08) * 22
			r = clamp(185 + strata, 110, 240)
			g = clamp(108 + strata * 0.6, 60, 165)
			b = clamp(66 + strata * 0.35, 38, 115)
		end

	elseif biome == "arctic" then
		-- FROST & GLACIAL ICE BIOME
		if depth <= 2 then
			r = 242; g = 250; b = 255
		elseif depth <= 6 then
			r = 195; g = 232; b = 252
		elseif depth <= 12 then
			r = 145; g = 198; b = 242
		else
			local strata = math.sin(layer_y * 0.08) * 20
			r = clamp(85 + strata * 0.5, 45, 175)
			g = clamp(145 + strata * 0.8, 90, 215)
			b = clamp(215 + strata, 150, 255)
		end

	elseif biome == "volcano" then
		-- OBSIDIAN & MOLTEN BASALT BIOME
		if depth <= 2 then
			r = 95; g = 52; b = 48
		elseif depth <= 6 then
			r = 78; g = 38; b = 42
		elseif depth <= 12 then
			r = 62; g = 30; b = 36
		else
			local magma = math.sin(layer_y * 0.09 + math.sin(gx * 0.03) * 2)
			if magma > 0.84 then
				r = 255; g = 125; b = 25 -- Magma vein
			else
				local strata = math.sin(layer_y * 0.07) * 14
				r = clamp(58 + strata, 38, 95)
				g = clamp(36 + strata * 0.6, 22, 65)
				b = clamp(42 + strata * 0.7, 28, 72)
			end
		end

	elseif biome == "alien" then
		-- EXOPLANET BIOLUMINESCENT SPORE BIOME
		if depth <= 2 then
			r = 225; g = 75; b = 238
		elseif depth <= 6 then
			r = 175; g = 48; b = 198
		elseif depth <= 12 then
			r = 128; g = 38; b = 165
		else
			local strata = math.sin(layer_y * 0.08) * 20
			r = clamp(78 + strata * 0.6, 45, 160)
			g = clamp(38 + strata * 0.4, 22, 115)
			b = clamp(138 + strata * 0.9, 80, 215)
		end

	else
		-- DEFAULT: LUSH SOIL & NATURAL MEADOW
		-- 30-40 px (15-20 cells) juicy turf cap, roots, dark rich chernozem/clay, pebbles, potato tubers
		if depth == 0 then
			-- Topmost juicy grass edge with blades and wildflower clusters
			local flower_val = math.sin(gx * 0.12)
			if flower_val > 0.88 then
				r = 248; g = 215; b = 45 -- Golden dandelion patch
			elseif flower_val < -0.88 then
				r = 245; g = 245; b = 240 -- Daisy cluster
			elseif rnd > 0.68 then
				r = 75; g = 195; b = 45  -- Grass blade tip
			else
				r = 58; g = 168; b = 35  -- Lush meadow crest
			end
		elseif depth <= 4 then
			-- Thick, juicy upper turf layer (rich natural green)
			r = 48; g = 145; b = 28
		elseif depth <= 8 then
			-- Dense dark emerald moss & turf core
			r = 38; g = 112; b = 24
		elseif depth <= 14 then
			-- Humus transition with intertwined root fibers
			local is_root = (math.sin(gx * 0.38 + gy * 0.45) > 0.62)
			if is_root then
				r = 105; g = 78; b = 52 -- Woody root strand
			else
				r = 46; g = 62; b = 28  -- Peaty turf base
			end
		elseif depth <= 19 then
			-- Hanging root tips extending into the rich black soil
			local is_root = (math.sin(gx * 0.45 + gy * 0.6) > 0.75)
			if is_root then
				r = 92; g = 70; b = 46
			else
				r = 42; g = 33; b = 25
			end
		else
			-- Deep Fertile Black Soil (Чернозем) & Broad Clay Strata (Глина)
			local clay_strata = math.sin(layer_y * 0.065) * 16 + math.cos(layer_y * 0.13) * 8

			-- Rich noble black earth / dark loam base
			r = clamp(44 + clay_strata * 0.65, 26, 72)
			g = clamp(34 + clay_strata * 0.48, 20, 56)
			b = clamp(26 + clay_strata * 0.35, 15, 42)

			-- Embedded smooth slate pebbles & granite stones
			local stone_cx = math.floor(gx / 58) * 58 + 29
			local stone_cy = math.floor(gy / 52) * 52 + 26
			local stone_dx = gx - stone_cx
			local stone_dy = gy - stone_cy
			if (stone_dx * stone_dx + stone_dy * stone_dy * 1.4) < 28 then
				local st_shade = (stone_dy < 0 and stone_dx < 0) and 28 or -18
				r = 86 + st_shade; g = 84 + st_shade; b = 82 + st_shade
			end

			-- Embedded Potato Tubers in the earth! (Картофельные клубни в толще земли)
			local spud_cx = math.floor((gx + 28) / 96) * 96 + 48
			local spud_cy = math.floor((gy + 18) / 84) * 84 + 42
			local sdx = (gx - spud_cx)
			local sdy = (gy - spud_cy) * 1.35
			local sdist2 = sdx * sdx + sdy * sdy
			if sdist2 < 42 then
				local spud_shade = (sdist2 < 20) and 24 or 0
				r = 158 + spud_shade; g = 114 + spud_shade * 0.8; b = 58 + spud_shade * 0.5
				if (sdx == 2 and sdy == 0) or (sdx == -3 and sdy == -1) then
					r = 88; g = 58; b = 28 -- Potato eye
				end
			end
		end
	end

	-- Inner Shadow (6-10 px) and Scorched Charred Edges on Crater Cuts
	if min_air_dist <= 5 and depth > 2 then
		local mult = 1.0
		if min_air_dist == 1 then
			mult = 0.24 -- Charred burnt soot edge!
		elseif min_air_dist == 2 then
			mult = 0.42 -- Burnt gradient
		elseif min_air_dist == 3 then
			mult = 0.62 -- Inner shadow
		elseif min_air_dist == 4 then
			mult = 0.78 -- Ambient occlusion
		elseif min_air_dist == 5 then
			mult = 0.90 -- Soft transition
		end
		r = r * mult
		g = g * mult
		b = b * mult
	end

	stream[idx] = math.floor(r)
	stream[idx + 1] = math.floor(g)
	stream[idx + 2] = math.floor(b)
	stream[idx + 3] = 255
end`;

content = content.substring(0, pStartIdx) + newWriteTerrainPixel + content.substring(pEndIdx + oldPixelEnd.length);
console.log('write_terrain_pixel updated successfully!');

// 4. Update generate_base_background sky & mid-ground layers
const oldGrassSkyRegex = /else\s*--\s*Grass\s*\/\s*Meadow:[\s\S]*?sb\s*=\s*238\s*\*\s*ny\s*\+\s*248\s*\*\s*\(1\s*-\s*ny\)\s*end/;
const newGrassSky = `else
			-- Grass / Meadow: Atmospheric Sunset Dusk (Navy Twilight -> Dusky Mauve -> Sunset Amber -> Golden Horizon)
			if ny > 0.65 then
				local t = (ny - 0.65) / 0.35
				sr = 28 * t + 88 * (1 - t)
				sg = 36 * t + 62 * (1 - t)
				sb = 68 * t + 85 * (1 - t)
			elseif ny > 0.35 then
				local t = (ny - 0.35) / 0.30
				sr = 88 * t + 218 * (1 - t)
				sg = 62 * t + 115 * (1 - t)
				sb = 85 * t + 55 * (1 - t)
			else
				local t = ny / 0.35
				sr = 218 * t + 245 * (1 - t)
				sg = 115 * t + 175 * (1 - t)
				sb = 55 * t + 82 * (1 - t)
			end
		end`;

if (oldGrassSkyRegex.test(content)) {
  content = content.replace(oldGrassSkyRegex, newGrassSky);
  console.log('Grass sky sunset dusk updated!');
} else {
  console.log('Grass sky regex did not match, checking alternate...');
}

// 5. Update grass sun in generate_base_background
const oldSunRegex = /if\s*biome\s*==\s*"grass"\s*then\s*--\s*Radiant\s*golden\s*sun\s*draw_bg_circle\([^)]+\)\s*draw_bg_circle\([^)]+\)/;
const newSun = `if biome == "grass" then
		-- Glowing low setting sun over the potato fields
		local sunset_y = math.floor(h * 0.44)
		draw_bg_circle(math.floor(w * 0.72), sunset_y, 62, 255, 150, 50, 0.48)
		draw_bg_circle(math.floor(w * 0.72), sunset_y, 28, 255, 235, 130, 0.95)`;

if (oldSunRegex.test(content)) {
  content = content.replace(oldSunRegex, newSun);
  console.log('Grass sunset updated!');
}

// 6. Update Mid-Distance Ridge with blurred potato garden beds, fence, old barn, buckets & barrels
const oldRidgeRegex = /--\s*4\.\s*Mid-Distance\s*Battle\s*Ridge[\s\S]*?self\.horizon_profile\[gx\]\s*=\s*max_gy[\s\S]*?stream\[idx\s*\+\s*2\]\s*=\s*clamp\(math\.floor\(stream\[idx\s*\+\s*2\]\s*\*\s*\(1\s*-\s*haze\)\s*\+\s*mb\s*\*\s*haze\),\s*0,\s*255\)\s*end\s*end/;

const newMidGround = `-- 4. Mid-Ground: Depth-of-Field Rural Potato Battlefield (Ridges, Fence, Old Barn, Barrels)
	local mid_h_base = math.floor(h * 0.24)
	local barn_x = math.floor(w * 0.24)
	local barn_w = 34

	for gx = 0, w - 1 do
		local nx = gx / w
		-- Undulating tilled potato garden beds (грядки)
		local r1 = bg_noise(nx * 5.5, seed + 30) * (h * 0.12)
		local garden_ridge = math.sin(nx * 24.0) * (h * 0.02)
		local max_gy = math.floor(mid_h_base + r1 + garden_ridge)

		-- Silhouette: Old Farm Barn / Shed (старый сарай с двускатной крышей)
		if gx >= barn_x and gx <= barn_x + barn_w then
			local bx = gx - barn_x
			local roof_peak = 18 - math.abs(bx - (barn_w * 0.5)) * 1.0
			max_gy = max_gy + math.max(0, math.floor(roof_peak))
		end

		-- Silhouette: Rustic Wooden Post Fence (деревянный забор)
		if (gx % 18 == 0) and (gx > barn_x + barn_w + 10) then
			max_gy = max_gy + 7 -- Post
		elseif (gx % 18 == 4 or gx % 18 == 5) and (gx > barn_x + barn_w + 10) then
			max_gy = max_gy + 4 -- Rail
		end

		-- Silhouette: Overturned Buckets and Barrels (бочки и ведра)
		local b1 = math.floor(w * 0.65)
		local b2 = math.floor(w * 0.82)
		if (gx >= b1 and gx <= b1 + 8) or (gx >= b2 and gx <= b2 + 7) then
			max_gy = max_gy + 6
		end

		self.horizon_profile[gx] = max_gy

		for gy = 0, max_gy do
			local idx = (gy * w + gx) * 4 + 1
			-- Depth-of-field soft atmospheric perspective haze
			local haze = (biome == "grass") and 0.68 or 0.82
			local mr = (biome == "alien") and 42 or ((biome == "desert") and 125 or ((biome == "volcano") and 65 or 52))
			local mg = (biome == "alien") and 22 or ((biome == "desert") and 55 or ((biome == "volcano") and 24 or 42))
			local mb = (biome == "alien") and 68 or ((biome == "desert") and 45 or ((biome == "volcano") and 28 or 36))

			stream[idx]     = clamp(math.floor(stream[idx] * (1 - haze) + mr * haze), 0, 255)
			stream[idx + 1] = clamp(math.floor(stream[idx + 1] * (1 - haze) + mg * haze), 0, 255)
			stream[idx + 2] = clamp(math.floor(stream[idx + 2] * (1 - haze) + mb * haze), 0, 255)
		end
	end`;

if (oldRidgeRegex.test(content)) {
  content = content.replace(oldRidgeRegex, newMidGround);
  console.log('Mid-ground rural DoF landscape updated!');
} else {
  console.log('Mid-ground regex did not match directly, checking alternate...');
}

// 7. Update update(self, dt) to include dynamic parallax for #sky
const oldUpdateStart = 'function update(self, dt)\n\t-- Update background warfare simulation at smooth 25 FPS rate';
const newUpdateStart = `function update(self, dt)
	-- Dynamic camera parallax for background (#sky)
	if self.is_initialized and camera_controller and camera_controller.pos then
		local px = (camera_controller.pos.x - constants.WORLD_WIDTH * 0.5) * 0.22
		local py = (camera_controller.pos.y - constants.WORLD_HEIGHT * 0.5) * 0.12
		pcall(function()
			go.set("#sky", "position", vmath.vector3(px, py, -0.3))
		end)
	end

	-- Update background warfare simulation at smooth 25 FPS rate`;

if (content.includes(oldUpdateStart)) {
  content = content.replace(oldUpdateStart, newUpdateStart);
  console.log('Sky parallax update added!');
}

if (isCRLF) {
  content = content.replace(/\n/g, '\r\n');
}

fs.writeFileSync(path, content, 'utf8');
console.log('terrain.script updated successfully!');
