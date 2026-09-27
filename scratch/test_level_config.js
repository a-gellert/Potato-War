const fs = require('fs');

const content = fs.readFileSync('lua_modules/level_config.lua', 'utf8');
console.log('level_config.lua size:', content.length, 'bytes');

const requiredKeys = ['level', 'enemy_hp', 'enemy_count', 'terrain_type', 'enemy_skill'];
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

// Check other modules that should reference level_config
const gameState = fs.readFileSync('lua_modules/game_state.lua', 'utf8');
if (!gameState.includes('require("lua_modules.level_config")')) {
    console.error('game_state.lua missing level_config import');
    process.exit(1);
}
console.log('game_state.lua properly requires level_config');

const mainScript = fs.readFileSync('main/main.script', 'utf8');
if (!mainScript.includes('require("lua_modules.level_config")')) {
    console.error('main.script missing level_config import');
    process.exit(1);
}
console.log('main.script properly requires level_config');

const botAi = fs.readFileSync('lua_modules/bot_ai.lua', 'utf8');
if (!botAi.includes('require("lua_modules.level_config")')) {
    console.error('bot_ai.lua missing level_config import');
    process.exit(1);
}
console.log('bot_ai.lua properly requires level_config');

console.log('ALL INTEGRATION CHECKS PASSED SUCCESSFULLY!');
