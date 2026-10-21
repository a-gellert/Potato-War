const fs = require('fs');
const path = require('path');

const filePath = path.resolve(__dirname, '../lua_modules/physics_sim.lua');
let content = fs.readFileSync(filePath, 'utf8');
const isCrlf = content.includes('\r\n');
let normalized = content.replace(/\r\n/g, '\n');

const target = `	-- Check water level (splash rescue or drowning)
	if p.pos.y < constants.WATER_LEVEL or new_y < constants.WATER_LEVEL then
		if game_state and game_state.mode == constants.MODE_TUTORIAL then
			-- Fail-safe tutorial rescue: teleport back to safe edge without damage or penalty!
			p.pos.x = 380.0
			p.pos.y = 180.0
			p.vel.x = 0
			p.vel.y = 0
			p.is_grounded = true
			return "tutorial_rescue"
		elseif p.hp > 30 then
			-- Water Splash Rescue: takes 30 water damage and bounces back up toward the map!
			p.hp = p.hp - 30
			local to_center_dir = (new_x < constants.WORLD_WIDTH * 0.5) and 1 or -1
			p.vel.y = 380.0
			p.vel.x = to_center_dir * 160.0
			p.pos.y = constants.WATER_LEVEL + 6
			p.is_grounded = false
			return "water_splash"
		else
			p.pos.x = new_x
			p.pos.y = math.min(p.pos.y, constants.WATER_LEVEL - 5)
			p.hp = 0
			p.is_alive = false
			p.is_grounded = false
			return "drowned"
		end
	end`;

const replacement = `	-- Check water level: Instant death into boiling deep fryer!
	if p.pos.y < constants.WATER_LEVEL or new_y < constants.WATER_LEVEL then
		if game_state and game_state.mode == constants.MODE_TUTORIAL then
			-- Fail-safe tutorial rescue: teleport back to safe edge without penalty
			p.pos.x = 380.0
			p.pos.y = 180.0
			p.vel.x = 0
			p.vel.y = 0
			p.is_grounded = true
			return "tutorial_rescue"
		else
			-- Worms instant death upon falling into the boiling fryer oil!
			p.pos.x = new_x
			p.pos.y = math.min(p.pos.y, constants.WATER_LEVEL - 5)
			p.hp = 0
			p.is_alive = false
			p.is_grounded = false
			return "drowned"
		end
	end`;

if (!normalized.includes(target)) {
    console.error("Target not found in physics_sim.lua!");
    process.exit(1);
}

normalized = normalized.replace(target, replacement);
if (isCrlf) normalized = normalized.replace(/\n/g, '\r\n');
fs.writeFileSync(filePath, normalized, 'utf8');
console.log("Successfully updated physics_sim.lua for instant fryer oil death!");
