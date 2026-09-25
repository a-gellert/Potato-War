const fs = require('fs');

const files = [
    'main/entities/terrain/terrain.script',
    'main/entities/explosion/explosion.script',
    'main/entities/projectile/projectile.script',
    'main/entities/potato/potato.script',
    'main/main.script',
    'gui/main_menu/main_menu.gui_script',
    'gui/hud/hud.gui_script',
    'lua_modules/weapons.lua',
    'lua_modules/cards.lua',
    'lua_modules/i18n.lua',
    'lua_modules/game_state.lua',
    'lua_modules/bot_ai.lua',
    'lua_modules/physics_sim.lua'
];

for (const filePath of files) {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    let parens = 0, braces = 0, brackets = 0;
    for (let i = 0; i < lines.length; i++) {
        let line = lines[i].replace(/--.*$/, '');
        line = line.replace(/"(\\.|[^"\\])*"/g, '""');
        line = line.replace(/'(\\.|[^'\\])*'/g, "''");
        for (const ch of line) {
            if (ch === '(') parens++;
            if (ch === ')') parens--;
            if (ch === '{') braces++;
            if (ch === '}') braces--;
            if (ch === '[') brackets++;
            if (ch === ']') brackets--;
        }
    }
    if (parens !== 0 || braces !== 0 || brackets !== 0) {
        console.error('MISMATCH in ' + filePath + ': parens=' + parens + ', braces=' + braces + ', brackets=' + brackets);
        process.exit(1);
    }
    console.log(filePath + ': OK');
}
console.log('ALL 13 FILES VERIFIED AND PASSED SYNTAX CHECK!');
