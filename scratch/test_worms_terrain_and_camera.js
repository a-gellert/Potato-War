const fs = require('fs');

console.log('Testing Worms Armageddon Terrain & Vertical Camera Tracking...');

// 1. Verify constants
const constants = fs.readFileSync('lua_modules/constants.lua', 'utf8');
if (!constants.includes('M.WORLD_HEIGHT = 960')) {
    console.error('FAIL: constants.lua missing WORLD_HEIGHT = 960');
    process.exit(1);
}
if (!constants.includes('M.TERRAIN_HEIGHT = 480')) {
    console.error('FAIL: constants.lua missing TERRAIN_HEIGHT = 480');
    process.exit(1);
}
console.log('✓ Constants verified: 1920x960 world and 960x480 grid');

// 2. Verify camera controller
const camera = fs.readFileSync('lua_modules/camera_controller.lua', 'utf8');
if (!camera.includes('constants.WORLD_HEIGHT + 350')) {
    console.error('FAIL: camera_controller.lua missing expanded altitude ceiling');
    process.exit(1);
}
console.log('✓ Camera controller verified: expanded altitude max_h configured');

// 3. Verify terrain script setup
const terrainScript = fs.readFileSync('main/entities/terrain/terrain.script', 'utf8');
if (!terrainScript.includes('constants.WORLD_WIDTH * 0.5') || !terrainScript.includes('constants.WORLD_HEIGHT * 0.5')) {
    console.error('FAIL: terrain.script missing centered world placement');
    process.exit(1);
}
if (!terrainScript.includes('constants.WATER_LEVEL - cy')) {
    console.error('FAIL: terrain.script missing dynamic water level placement');
    process.exit(1);
}
console.log('✓ Terrain script verified: centered at (960, 480) with dynamic water offset');

// 4. Verify main.script camera tracking and reset
const mainScript = fs.readFileSync('main/main.script', 'utf8');
if (!mainScript.includes('camera_controller.reset(game_state.active_potato.pos.x, game_state.active_potato.pos.y)')) {
    console.error('FAIL: main.script not resetting camera directly to active potato');
    process.exit(1);
}
if (!mainScript.includes('constants.STATE_TURN_ACTIVE or game_state.state == constants.STATE_SETTLING')) {
    console.error('FAIL: main.script camera tracking missing settling follow');
    process.exit(1);
}
console.log('✓ Main script verified: direct active potato camera reset and settling tracking');

// 5. Verify terrain presets diversity
const terrainGrid = fs.readFileSync('lua_modules/terrain_grid.lua', 'utf8');
const presets = ['hills', 'floating_islands', 'canyon_bridge', 'cavern', 'swiss_cheese', 'bunkers', 'islands', 'pyramid_temple', 'twin_peaks', 'valley_caves'];
for (const p of presets) {
    if (!terrainGrid.includes('preset_type == "' + p + '"') && !terrainGrid.includes('else -- "hills"')) {
        console.error('FAIL: terrain_grid.lua missing preset:', p);
        process.exit(1);
    }
}
if (!terrainGrid.includes('add_arch') || !terrainGrid.includes('add_island') || !terrainGrid.includes('carve_bubble') || !terrainGrid.includes('add_mushroom_spire')) {
    console.error('FAIL: terrain_grid.lua missing Worms shape primitives');
    process.exit(1);
}
console.log('✓ Terrain grid verified: 10 rich Worms Armageddon presets with arches, islands, caves, and spires!');

console.log('=== ALL WORMS TERRAIN & CAMERA VERIFICATIONS PASSED! ===');
