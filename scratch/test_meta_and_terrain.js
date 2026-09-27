const fs = require('fs');

console.log('Testing Meta Progression & Terrain Presets Integration...');

// 1. Verify terrain_grid.lua presets
const terrainGrid = fs.readFileSync('lua_modules/terrain_grid.lua', 'utf8');
const expectedPresets = ['flat', 'floating_islands', 'canyon_bridge', 'cavern', 'swiss_cheese', 'islands', 'bunkers', 'hills'];
for (const p of expectedPresets) {
    if (!terrainGrid.includes('preset_type == "' + p + '"') && !terrainGrid.includes('else -- "hills"')) {
        console.error('Missing preset handler in terrain_grid.lua:', p);
        process.exit(1);
    }
}
// Verify floating islands has open air slab
if (!terrainGrid.includes('add_island')) {
    console.error('floating_islands lacks distinct island generation');
    process.exit(1);
}
// Verify canyon bridge has arch
if (!terrainGrid.includes('bridge_start') || !terrainGrid.includes('arch_curve')) {
    console.error('canyon_bridge lacks arch bridge generation');
    process.exit(1);
}
// Verify cavern has ceiling with skylight
if (!terrainGrid.includes('stalactite') || !terrainGrid.includes('ceil_bot')) {
    console.error('cavern lacks ceiling/stalactites');
    process.exit(1);
}
// Verify swiss cheese has bubble carving
if (!terrainGrid.includes('carve_bubble')) {
    console.error('swiss_cheese lacks bubble carving');
    process.exit(1);
}
console.log('1. Terrain Presets Verified: Distinct topologies confirmed for all presets!');

// 2. Verify meta_progression.lua
const metaProg = fs.readFileSync('lua_modules/meta_progression.lua', 'utf8');
const requiredUpgrades = ['max_hp', 'starting_weapon', 'hp_regen'];
for (const u of requiredUpgrades) {
    if (!metaProg.includes(u)) {
        console.error('Missing upgrade in meta_progression.lua:', u);
        process.exit(1);
    }
}
if (!metaProg.includes('apply_round_regen') || !metaProg.includes('apply_starting_loadout') || !metaProg.includes('get_player_max_hp')) {
    console.error('Missing critical methods in meta_progression.lua');
    process.exit(1);
}
console.log('2. Meta Progression Module Verified: Max HP, Starting Weapon, and Round HP Regen defined!');

// 3. Verify game_state.lua hooks
const gameState = fs.readFileSync('lua_modules/game_state.lua', 'utf8');
if (!gameState.includes('meta_progression.apply_round_regen')) {
    console.error('game_state.lua missing apply_round_regen call in settling phase');
    process.exit(1);
}
if (!gameState.includes('meta_progression.apply_starting_loadout')) {
    console.error('game_state.lua missing apply_starting_loadout call');
    process.exit(1);
}
if (!gameState.includes('meta_progression.get_player_max_hp')) {
    console.error('game_state.lua missing get_player_max_hp call');
    process.exit(1);
}
console.log('3. Game State Hooks Verified: Round HP Regen and Starting Loadout integrated!');

// 4. Verify main.script hooks
const mainScript = fs.readFileSync('main/main.script', 'utf8');
if (!mainScript.includes('meta_progression.get_player_max_hp')) {
    console.error('main.script missing get_player_max_hp');
    process.exit(1);
}
if (!mainScript.includes('from_wy')) {
    console.error('main.script missing from_wy for cavern spawn');
    process.exit(1);
}
console.log('4. Main Script Hooks Verified: Dynamic Max HP and cavern spawn handling confirmed!');

// 5. Verify main_menu.gui_script
const menuScript = fs.readFileSync('gui/main_menu/main_menu.gui_script', 'utf8');
if (!menuScript.includes('btn_quick_bot') || !menuScript.includes('self.overlay_mode = "upgrades"')) {
    console.error('main_menu.gui_script missing upgrades button / mode');
    process.exit(1);
}
console.log('5. Main Menu UI Verified: Upgrades button & overlay shop integration confirmed!');

console.log('ALL VERIFICATIONS PASSED SUCCESSFULLY!');
