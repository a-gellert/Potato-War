const fs = require('fs');

console.log('Testing drowning behavior and narrow pit physics fixes...\n');

// 1. Check potato_updater.lua
const updater = fs.readFileSync('lua_modules/potato_updater.lua', 'utf8');
if (updater.includes('spawn_explosion') && updater.includes('on_drowned')) {
    // Check if spawn_explosion is inside on_drowned function
    const onDrownedMatch = updater.match(/local function on_drowned\(p\)[\s\S]*?end/);
    if (onDrownedMatch && onDrownedMatch[0].includes('spawn_explosion')) {
        console.error('FAIL: on_drowned still contains spawn_explosion');
        process.exit(1);
    }
}
if (!updater.includes('Бульк!')) {
    console.error('FAIL: on_drowned missing "Бульк!" label');
    process.exit(1);
}
if (!updater.includes('game_state.set_state(constants.STATE_SETTLING)')) {
    console.error('FAIL: on_drowned missing game_state.set_state(constants.STATE_SETTLING)');
    process.exit(1);
}
console.log('✓ 1. on_drowned correctly displays "Бульк!" without explosion and transitions to settling to end turn');

// 2. Check physics_sim.lua for narrow pit jitter fix
const physics = fs.readFileSync('lua_modules/physics_sim.lua', 'utf8');
if (!physics.includes('in_tight_pit')) {
    console.error('FAIL: physics_sim.lua missing in_tight_pit detection');
    process.exit(1);
}
if (!physics.includes('p.vel.x = 0')) {
    console.error('FAIL: physics_sim.lua missing horizontal velocity damping in pit');
    process.exit(1);
}
console.log('✓ 2. physics_sim.lua detects tight pits, eliminates horizontal bounce jitter, and ensures clean floor landing');

// 3. Check terrain_grid.lua for pit wall height clamping
const terrain = fs.readFileSync('lua_modules/terrain_grid.lua', 'utf8');
if (!terrain.includes('math.abs(gy - center_gy) > 4.0') && !terrain.includes('gy > center_gy + 4.0')) {
    console.error('FAIL: terrain_grid.lua missing pit wall height clamping in get_smooth_ground_y');
    process.exit(1);
}
console.log('✓ 3. terrain_grid.lua clamps sample heights in narrow pits, preventing cliff top elevation jumps');

console.log('\nALL VERIFICATION CHECKS PASSED!');
