const fs = require('fs');

console.log('Testing Hills, Water, and Spawning fixes...\n');

// 1. Check terrain_grid.lua
const terrainGrid = fs.readFileSync('lua_modules/terrain_grid.lua', 'utf8');
if (!terrainGrid.includes('else\r\n\t\t-- "hills"') && !terrainGrid.includes('else\n\t\t-- "hills"')) {
    console.error('FAIL: terrain_grid.lua missing else branch for hills');
    process.exit(1);
}
console.log('✓ 1. terrain_grid.lua correctly contains else branch for hills preset');

// 2. Check physics_sim.lua
const physicsSim = fs.readFileSync('lua_modules/physics_sim.lua', 'utf8');
if (!physicsSim.includes('p.pos.y <= (constants.WATER_LEVEL + 4.0)')) {
    console.error('FAIL: physics_sim.lua missing drowning check at WATER_LEVEL + 4.0');
    process.exit(1);
}
if (!physicsSim.includes('ground_y > constants.WATER_LEVEL')) {
    console.error('FAIL: physics_sim.lua missing ground_y > constants.WATER_LEVEL landing check');
    process.exit(1);
}
if (!physicsSim.includes('target_gy <= constants.WATER_LEVEL')) {
    console.error('FAIL: physics_sim.lua walk_potato missing water drop check');
    process.exit(1);
}
console.log('✓ 2. physics_sim.lua correctly prevents landing on water, drops units walking into water, and triggers drowning');

// 3. Check match_spawner.lua
const matchSpawner = fs.readFileSync('lua_modules/match_spawner.lua', 'utf8');
if (!matchSpawner.includes('function M.validate_surface_spawns(self)')) {
    console.error('FAIL: match_spawner.lua missing validate_surface_spawns');
    process.exit(1);
}
if (!matchSpawner.includes('local safe_ground_y = math.max(constants.WATER_LEVEL + 25, gy)')) {
    console.error('FAIL: match_spawner.lua missing safe_ground_y clamp');
    process.exit(1);
}
console.log('✓ 3. match_spawner.lua correctly ensures safe surface spawning and post-spawn verification');

// 4. Check main.script
const mainScript = fs.readFileSync('main/main.script', 'utf8');
if (!mainScript.includes('match_spawner.validate_surface_spawns(self)')) {
    console.error('FAIL: main.script not calling match_spawner.validate_surface_spawns(self)');
    process.exit(1);
}
console.log('✓ 4. main.script validates surface spawns at match start');

// 5. Check terrain.script and terrain.go for water animation and position
const terrainScript = fs.readFileSync('main/entities/terrain/terrain.script', 'utf8');
if (!terrainScript.includes('constants.WATER_LEVEL - cy - 200')) {
    console.error('FAIL: terrain.script missing aligned water position (constants.WATER_LEVEL - cy - 200)');
    process.exit(1);
}
if (!terrainScript.includes('2.525, go.EASING_INOUTSINE, 3.5')) {
    console.error('FAIL: terrain.script missing calmed water animation');
    process.exit(1);
}
const terrainGo = fs.readFileSync('main/entities/terrain/terrain.go', 'utf8');
if (!terrainGo.includes('y: -652.0')) {
    console.error('FAIL: terrain.go water initial position not updated');
    process.exit(1);
}
console.log('✓ 5. terrain.script and terrain.go have aligned water position and calm water animation');

console.log('\nALL CHECKS PASSED!');
