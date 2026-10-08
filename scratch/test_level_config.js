const fs = require('fs');

const content = fs.readFileSync('lua_modules/level_config.lua', 'utf8');
console.log('level_config.lua size:', content.length, 'bytes');

const requiredKeys = ['level', 'enemy_hp', 'enemy_count', 'terrain_type', 'enemy_skill', 'enemy_classes', 'enemy_levels'];
let allFound = true;
for (const key of requiredKeys) {
    if (!content.includes(key)) {
        console.error('Missing key:', key);
        allFound = false;
    } else {
        console.log('Found required field:', key);
    }
}

if (!allFound) {
    process.exit(1);
}

// Verify that all 18 levels are present
for (let i = 1; i <= 18; i++) {
    const levelPattern = new RegExp(`level\\s*=\\s*${i}[^0-9]`);
    if (!levelPattern.test(content)) {
        console.error(`Missing level ${i} definition in level_config.lua!`);
        process.exit(1);
    }
}
console.log('All 18 levels verified present in level_config.lua!');

// Check getters exist
const requiredGetters = ['get_enemy_class', 'get_enemy_level', 'get_enemy_hp', 'get_enemy_count'];
for (const getter of requiredGetters) {
    if (!content.includes(getter)) {
        console.error('Missing getter:', getter);
        process.exit(1);
    }
    console.log('Found getter:', getter);
}

// Check modules referencing level_config
const modules = [
    { name: 'lua_modules/game_state.lua', check: 'level_config' },
    { name: 'main/main.script', check: 'level_config.get_enemy_class' },
    { name: 'lua_modules/strategic_campaign.lua', check: 'level_config.get' },
    { name: 'gui/campaign_map/campaign_map.gui_script', check: 'level_config.get' }
];

for (const mod of modules) {
    const code = fs.readFileSync(mod.name, 'utf8');
    if (!code.includes(mod.check)) {
        console.error(`${mod.name} missing check: ${mod.check}`);
        process.exit(1);
    }
    console.log(`${mod.name} verified check: ${mod.check}`);
}

console.log('ALL 18 LEVELS & INTEGRATION CHECKS PASSED 100% SUCCESSFULLY!');
