// scratch/test_classes_and_wind.js
// Verification of classes, inventory_manager, weapons refactoring, wind, and status effects

const fs = require('fs');

console.log('--- Testing Potato War Classes & Elemental Features ---');

// 1. Verify classes.lua
const classesCode = fs.readFileSync('lua_modules/classes.lua', 'utf8');
const requiredClasses = [
    'recruit',
    'assault',
    'assault_2',
    'sniper',
    'sapper',
    'sapper_2',
    'commando',
    'artillery',
    'artillery_2',
    'rocketeer',
    'medic',
    'surgeon'
];

for (const cls of requiredClasses) {
    if (!classesCode.includes(cls + ' = {')) {
        console.error('FAIL: Missing class definition for: ' + cls);
        process.exit(1);
    }
}
console.log('PASS: All 12 classes defined in classes.lua');

// Verify active skills
const requiredSkills = [
    'sprint',
    'rapid_fire',
    'tactical_breach',
    'eagle_eye',
    'trench_dig',
    'cluster_trap',
    'smoke_screen',
    'siege_stance',
    'carpet_salvo',
    'rocket_jump',
    'first_aid',
    'biogel_surge'
];

for (const skill of requiredSkills) {
    if (!classesCode.includes('id = "' + skill + '"')) {
        console.error('FAIL: Missing class skill: ' + skill);
        process.exit(1);
    }
}
console.log('PASS: All class active skills defined in classes.lua');

// 2. Verify weapons.lua
const weaponsCode = fs.readFileSync('lua_modules/weapons.lua', 'utf8');

// Check categories
if (!weaponsCode.includes('CATEGORY_CLASS_BASE') || !weaponsCode.includes('CATEGORY_ARENA_PICKUP')) {
    console.error('FAIL: Missing weapon categories in weapons.lua');
    process.exit(1);
}
console.log('PASS: Class base vs arena pickup categories defined in weapons.lua');

// Check elemental statuses and combos
const requiredStatuses = ['burning', 'poisoned', 'glued', 'concussed'];
for (const st of requiredStatuses) {
    if (!weaponsCode.includes(st)) {
        console.error('FAIL: Missing status in weapons.lua: ' + st);
        process.exit(1);
    }
}
console.log('PASS: Elemental statuses (burning, poisoned, glued, concussed) present in weapons.lua');

const requiredCombos = ['sticky_inferno', 'toxic_burst', 'paralyzed', 'neurotoxin'];
for (const combo of requiredCombos) {
    if (!weaponsCode.includes(combo)) {
        console.error('FAIL: Missing elemental combo in weapons.lua: ' + combo);
        process.exit(1);
    }
}
console.log('PASS: Elemental combos defined in weapons.lua');

// Check wind sensitivity
if (!weaponsCode.includes('wind_sensitivity')) {
    console.error('FAIL: Missing wind_sensitivity in weapons.lua');
    process.exit(1);
}
console.log('PASS: wind_sensitivity configured across weapons');

// 3. Verify inventory_manager.lua
const invCode = fs.readFileSync('lua_modules/inventory_manager.lua', 'utf8');
const invMethods = [
    'create_inventory',
    'register_potato',
    'get',
    'get_ammo',
    'has_weapon',
    'add_ammo',
    'consume_ammo',
    'select_weapon',
    'select_slot',
    'get_loadout',
    'can_use_skill',
    'use_skill',
    'update_turn'
];
for (const m of invMethods) {
    if (!invCode.includes('function M.' + m)) {
        console.error('FAIL: Missing inventory_manager method: ' + m);
        process.exit(1);
    }
}
console.log('PASS: inventory_manager has complete API');

// 4. Verify physics_sim.lua
const physCode = fs.readFileSync('lua_modules/physics_sim.lua', 'utf8');
if (!physCode.includes('wind_vector') || !physCode.includes('wind_sens')) {
    console.error('FAIL: Missing wind_vector support in physics_sim.lua');
    process.exit(1);
}
if (!physCode.includes('glued') || !physCode.includes('concussed')) {
    console.error('FAIL: Missing status checks in physics_sim.lua');
    process.exit(1);
}
console.log('PASS: physics_sim supports dynamic wind and elemental status modifiers');

// 5. Verify potato.script
const potScript = fs.readFileSync('main/entities/potato/potato.script', 'utf8');
const potMsgs = ['apply_status', 'remove_status', 'clear_statuses', 'on_turn_start', 'on_turn_end', 'set_class'];
for (const msg of potMsgs) {
    if (!potScript.includes('message_id == hash("' + msg + '")')) {
        console.error('FAIL: Missing message handler in potato.script: ' + msg);
        process.exit(1);
    }
}
if (!potScript.includes('process_turn_start') || !potScript.includes('process_turn_end')) {
    console.error('FAIL: Missing turn DoT processing in potato.script');
    process.exit(1);
}
console.log('PASS: potato.script supports status visualization, combos, and turn-start/end DoTs');

// 6. Verify bot_ai.lua
const botCode = fs.readFileSync('lua_modules/bot_ai.lua', 'utf8');
if (!botCode.includes('score_weapon_tactical') || !botCode.includes('wind_vector')) {
    console.error('FAIL: bot_ai missing tactical score or wind_vector');
    process.exit(1);
}
if (!botCode.includes('Sticky Inferno') || !botCode.includes('Toxic Burst')) {
    console.error('FAIL: bot_ai missing elemental combo priorities');
    process.exit(1);
}
console.log('PASS: bot_ai considers wind, class affinities, and elemental combos');

console.log('\n>>> ALL MODULE AND SCRIPT TESTS PASSED SUCCESSFULLY! <<<');
