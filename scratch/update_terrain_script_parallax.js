const fs = require('fs');
const path = require('path');

const filePath = path.resolve(__dirname, '../main/entities/terrain/terrain.script');
let content = fs.readFileSync(filePath, 'utf8');
const isCrlf = content.includes('\r\n');
let norm = content.replace(/\r\n/g, '\n');

// 1. In init, add wind spores initialization
const oldInitEnd = `	-- Initial setup for expanded 1920x960 world
	local cx = constants.WORLD_WIDTH * 0.5
	local cy = constants.WORLD_HEIGHT * 0.5
	go.set_position(vmath.vector3(cx, cy, 0))
	go.set("#sprite", "scale", vmath.vector3(constants.TERRAIN_SCALE, constants.TERRAIN_SCALE, 1.0))
	go.set("#sky", "scale", vmath.vector3(3.0, 3.0, 1.0))
	go.set("#sky", "position", vmath.vector3(0, 0, -0.3))
	go.set("#water", "position", vmath.vector3(0, constants.WATER_LEVEL - cy, 0.4))
	go.set("#water", "scale.x", 8.0)
	go.set("#water", "scale.y", 4.0)

	-- Initially disable foreground terrain and water for main menu
	pcall(function()
		msg.post("#sprite", "disable")
		msg.post("#water", "disable")
	end)`;

const newInitEnd = `	-- Atmospheric Wind Spores drifting on the breeze
	self.wind_spores = {}
	self.wind_time = 0
	for i = 1, 8 do
		table.insert(self.wind_spores, {
			id = "#spore" .. i,
			x = (math.random() - 0.5) * constants.WORLD_WIDTH,
			y = math.random(-80, 320),
			base_y = math.random(-80, 320),
			speed_mult = 0.65 + math.random() * 0.70,
			flutter_phase = math.random() * 6.28,
			flutter_speed = 1.6 + math.random() * 2.4,
		})
	end

	-- Initial setup for expanded 1920x960 world
	local cx = constants.WORLD_WIDTH * 0.5
	local cy = constants.WORLD_HEIGHT * 0.5
	go.set_position(vmath.vector3(cx, cy, 0))
	pcall(function()
		go.set("#sprite", "scale", vmath.vector3(constants.TERRAIN_SCALE, constants.TERRAIN_SCALE, 1.0))
		go.set("#sky", "scale", vmath.vector3(4.5, 3.5, 1.0))
		go.set("#sky", "position", vmath.vector3(0, 0, -0.45))
		go.set("#bg_distant", "scale", vmath.vector3(2.4, 2.2, 1.0))
		go.set("#bg_distant", "position", vmath.vector3(0, 80, -0.35))
		go.set("#bg_islands", "scale", vmath.vector3(2.2, 2.0, 1.0))
		go.set("#bg_islands", "position", vmath.vector3(0, 120, -0.25))

		-- Deep boiling fryer oil: sits at WATER_LEVEL and extends 300+ px below screen!
		go.set("#water", "position", vmath.vector3(0, constants.WATER_LEVEL - cy - 140, 0.4))
		go.set("#water", "scale.x", 2.5)
		go.set("#water", "scale.y", 2.5)
		go.animate("#water", "scale.y", go.PLAYBACK_LOOP_PINGPONG, 2.65, go.EASING_INOUTSINE, 1.6)
	end)

	-- Initially disable battle layers for main menu
	pcall(function()
		msg.post("#sprite", "disable")
		msg.post("#water", "disable")
		msg.post("#bg_distant", "disable")
		msg.post("#bg_islands", "disable")
		for i = 1, 8 do
			msg.post("#spore" .. i, "disable")
		end
	end)`;

if (!norm.includes(oldInitEnd)) {
    console.error("Target oldInitEnd not found in terrain.script!");
    process.exit(1);
}
norm = norm.replace(oldInitEnd, newInitEnd);

// 2. In update, add parallax and wind spore simulation
const oldUpdate = `function update(self, dt)
	-- Dynamic camera parallax for background (#sky)
	if self.is_initialized and camera_controller and camera_controller.pos then
		local px = (camera_controller.pos.x - constants.WORLD_WIDTH * 0.5) * 0.22
		local py = (camera_controller.pos.y - constants.WORLD_HEIGHT * 0.5) * 0.12
		pcall(function()
			go.set("#sky", "position", vmath.vector3(px, py, -0.3))
		end)
	end`;

const newUpdate = `function update(self, dt)
	-- Multi-plane Parallax based on Camera Controller
	if camera_controller and camera_controller.pos then
		local cx = constants.WORLD_WIDTH * 0.5
		local cy = constants.WORLD_HEIGHT * 0.5
		local rel_x = camera_controller.pos.x - cx
		local rel_y = camera_controller.pos.y - cy

		-- 1. Sky Gradient: moves very slowly with camera (0.88 follow)
		pcall(function()
			go.set("#sky", "position", vmath.vector3(rel_x * 0.88, rel_y * 0.85, -0.45))
		end)

		-- 2. Layer 1 (Distant mountains & farm ridges): deep slow parallax (0.55 follow)
		pcall(function()
			go.set("#bg_distant", "position", vmath.vector3(rel_x * 0.55, rel_y * 0.35 + 20, -0.35))
		end)

		-- 3. Layer 2 (Mid-ground floating islands): mid parallax (0.28 follow)
		pcall(function()
			go.set("#bg_islands", "position", vmath.vector3(rel_x * 0.28, rel_y * 0.18 + 70, -0.25))
		end)
	end

	-- Atmospheric Wind Spores drifting on the wind
	if self.wind_spores then
		local wind = (game_state.wind_vector and game_state.wind_vector.x) or 8.0
		local wind_speed = wind * 4.0
		if math.abs(wind_speed) < 15.0 then
			wind_speed = (wind_speed >= 0) and 15.0 or -15.0
		end

		self.wind_time = (self.wind_time or 0) + dt
		local half_w = constants.WORLD_WIDTH * 0.5 + 80

		for _, sp in ipairs(self.wind_spores) do
			sp.x = sp.x + wind_speed * sp.speed_mult * dt
			local flutter = math.sin(self.wind_time * sp.flutter_speed + sp.flutter_phase) * 18.0
			sp.y = sp.base_y + flutter

			if sp.x > half_w then
				sp.x = -half_w
				sp.base_y = math.random(-80, 320)
			elseif sp.x < -half_w then
				sp.x = half_w
				sp.base_y = math.random(-80, 320)
			end

			pcall(function()
				go.set(sp.id, "position", vmath.vector3(sp.x, sp.y, 0.25))
			end)
		end
	end`;

if (!norm.includes(oldUpdate)) {
    console.error("Target oldUpdate not found in terrain.script!");
    process.exit(1);
}
norm = norm.replace(oldUpdate, newUpdate);

// 3. In generate_terrain, enable all parallax layers & spores
const oldGenTerrain = `		-- Enable foreground terrain and water for battle
		pcall(function()
			msg.post("#sprite", "enable")
			msg.post("#water", "enable")
		end)

		-- Expanded 1920x960 Worms Armageddon Battlefield
		local cx = constants.WORLD_WIDTH * 0.5
		local cy = constants.WORLD_HEIGHT * 0.5
		go.set_position(vmath.vector3(cx, cy, 0))
		pcall(function()
			go.set("#sprite", "scale", vmath.vector3(constants.TERRAIN_SCALE, constants.TERRAIN_SCALE, 1.0))
			go.set("#sky", "scale", vmath.vector3(3.0, 3.0, 1.0))
			go.set("#sky", "position", vmath.vector3(0, 0, -0.3))
			go.set("#water", "position", vmath.vector3(0, constants.WATER_LEVEL - cy, 0.4))
			go.set("#water", "scale.x", 8.0)
			go.animate("#water", "scale.y", go.PLAYBACK_LOOP_PINGPONG, 4.25, go.EASING_INOUTSINE, 1.8)
		end)`;

const newGenTerrain = `		-- Enable foreground terrain, parallax layers, deep fryer oil, and wind spores
		pcall(function()
			msg.post("#sprite", "enable")
			msg.post("#water", "enable")
			msg.post("#bg_distant", "enable")
			msg.post("#bg_islands", "enable")
			for i = 1, 8 do
				msg.post("#spore" .. i, "enable")
			end
		end)

		-- Expanded 1920x960 Worms Armageddon Battlefield
		local cx = constants.WORLD_WIDTH * 0.5
		local cy = constants.WORLD_HEIGHT * 0.5
		go.set_position(vmath.vector3(cx, cy, 0))
		pcall(function()
			go.set("#sprite", "scale", vmath.vector3(constants.TERRAIN_SCALE, constants.TERRAIN_SCALE, 1.0))
			go.set("#sky", "scale", vmath.vector3(4.5, 3.5, 1.0))
			go.set("#sky", "position", vmath.vector3(0, 0, -0.45))
			go.set("#bg_distant", "scale", vmath.vector3(2.4, 2.2, 1.0))
			go.set("#bg_islands", "scale", vmath.vector3(2.2, 2.0, 1.0))

			-- Deep boiling fryer oil: sits at WATER_LEVEL and extends 300+ px below screen!
			go.set("#water", "position", vmath.vector3(0, constants.WATER_LEVEL - cy - 140, 0.4))
			go.set("#water", "scale.x", 2.5)
			go.set("#water", "scale.y", 2.5)
			go.animate("#water", "scale.y", go.PLAYBACK_LOOP_PINGPONG, 2.65, go.EASING_INOUTSINE, 1.6)
		end)`;

if (!norm.includes(oldGenTerrain)) {
    console.error("Target oldGenTerrain not found in terrain.script!");
    process.exit(1);
}
norm = norm.replace(oldGenTerrain, newGenTerrain);

// 4. In set_menu_mode, enable/disable layers
const oldMenuMode = `	elseif message_id == hash("set_menu_mode") then
		local is_menu = (message.is_menu ~= false)
		if is_menu then
			pcall(function()
				msg.post("#sprite", "disable")
				msg.post("#water", "disable")
			end)
		else
			pcall(function()
				msg.post("#sprite", "enable")
				msg.post("#water", "enable")
			end)
		end`;

const newMenuMode = `	elseif message_id == hash("set_menu_mode") then
		local is_menu = (message.is_menu ~= false)
		if is_menu then
			pcall(function()
				msg.post("#sprite", "disable")
				msg.post("#water", "disable")
				msg.post("#bg_distant", "disable")
				msg.post("#bg_islands", "disable")
				for i = 1, 8 do
					msg.post("#spore" .. i, "disable")
				end
			end)
		else
			pcall(function()
				msg.post("#sprite", "enable")
				msg.post("#water", "enable")
				msg.post("#bg_distant", "enable")
				msg.post("#bg_islands", "enable")
				for i = 1, 8 do
					msg.post("#spore" .. i, "enable")
				end
			end)
		end`;

if (!norm.includes(oldMenuMode)) {
    console.error("Target oldMenuMode not found in terrain.script!");
    process.exit(1);
}
norm = norm.replace(oldMenuMode, newMenuMode);

if (isCrlf) norm = norm.replace(/\n/g, '\r\n');
fs.writeFileSync(filePath, norm, 'utf8');
console.log("Successfully updated terrain.script with multi-layer parallax and wind spores!");
