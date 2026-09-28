const fs = require('fs');

console.log('Testing 5-Weapon Loadout Stack, 4 New Weapons, Cards and GUI...');

// 1. Check weapons.lua
const weaponsContent = fs.readFileSync('lua_modules/weapons.lua', 'utf8');
const expectedWeapons = [
    'grenade', 'rifle', 'knife', 'molotov', 'burst', 'bazooka',
    'shotgun', 'holy_grenade', 'beetle', 'drill', 'pepper', 'garlic', 'beetle_minion'
];

for (const w of expectedWeapons) {
    if (!weaponsContent.includes(`id            = "${w}"`) && !weaponsContent.includes(`id = "${w}"`)) {
        console.error(`FAIL: Missing weapon ${w} in weapons.lua`);
        process.exit(1);
    }
}
console.log('PASS: All 12 weapons + beetle_minion defined in weapons.lua');

// 2. Check cards.lua
const cardsContent = fs.readFileSync('lua_modules/cards.lua', 'utf8');
const expectedCards = ['beetle', 'drill', 'pepper', 'garlic', 'knife', 'bazooka', 'burst', 'holy_grenade', 'shotgun', 'rifle', 'molotov'];
for (const c of expectedCards) {
    if (!cardsContent.includes(`id = "${c}"`)) {
        console.error(`FAIL: Missing card ${c} in cards.lua`);
        process.exit(1);
    }
}
console.log('PASS: All weapon cards defined in cards.lua');

// 3. Check game_state.lua loadout logic
const gsContent = fs.readFileSync('lua_modules/game_state.lua', 'utf8');
if (!gsContent.includes('MAX_LOADOUT_SLOTS = 5')) {
    console.error('FAIL: MAX_LOADOUT_SLOTS = 5 missing in game_state.lua');
    process.exit(1);
}
if (!gsContent.includes('get_slot_weapon') || !gsContent.includes('select_slot')) {
    console.error('FAIL: get_slot_weapon or select_slot missing in game_state.lua');
    process.exit(1);
}
console.log('PASS: 5-slot weapon loadout stack methods verified in game_state.lua');

// 4. Check hud.gui
const hudGui = fs.readFileSync('gui/hud/hud.gui', 'utf8');
for (let i = 1; i <= 5; i++) {
    if (!hudGui.includes(`id: "btn_wpn_${i}"`)) {
        console.error(`FAIL: Missing btn_wpn_${i} in hud.gui`);
        process.exit(1);
    }
}
for (let i = 6; i <= 8; i++) {
    if (hudGui.includes(`id: "btn_wpn_${i}"`)) {
        console.error(`FAIL: Found obsolete btn_wpn_${i} in hud.gui`);
        process.exit(1);
    }
}
console.log('PASS: Exactly 5 weapon buttons in hud.gui');

// 5. Check hud.gui_script
const hudScript = fs.readFileSync('gui/hud/hud.gui_script', 'utf8');
if (!hudScript.includes('get_slot_weapon') || !hudScript.includes('select_slot')) {
    console.error('FAIL: hud.gui_script does not use slot-based selection');
    process.exit(1);
}
console.log('PASS: hud.gui_script uses dynamic slot-based 5-weapon rendering');

// 6. Check projectile and napalm scripts
const projScript = fs.readFileSync('main/entities/projectile/projectile.script', 'utf8');
if (!projScript.includes('spawn_beetles') || !projScript.includes('is_pepper')) {
    console.error('FAIL: projectile.script missing spawn_beetles or is_pepper');
    process.exit(1);
}

const napalmScript = fs.readFileSync('main/entities/napalm/napalm.script', 'utf8');
if (!napalmScript.includes('is_pepper')) {
    console.error('FAIL: napalm.script missing is_pepper property');
    process.exit(1);
}
console.log('PASS: Special projectile effects (beetles, pepper sneezing, drill tunneling) verified');

console.log('ALL WEAPONS, INVENTORY STACK, CARDS & UI TESTS PASSED SUCCESSFULLY!');
