const fs = require('fs');
const content = fs.readFileSync('gui/main_menu/main_menu.gui', 'utf8');
const m = [...content.matchAll(/font:\s*"([^"]+)"/g)].map(x => x[1]);
console.log('Fonts in main_menu.gui:', [...new Set(m)]);
