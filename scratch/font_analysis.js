const fs = require('fs');

function getChars(file) {
  const c = fs.readFileSync(file, 'utf8');
  const m = c.match(/characters:\s*"([^"\r\n]*)"/);
  return m ? m[1] : '';
}

const rubikChars = getChars('main/assets/fonts/title.font');
const uiChars = getChars('main/assets/ui.font');

const i18n = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
const regex = /([a-zA-Z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/g;
let m;
const missingRubik = new Map();
const missingUI = new Map();

while ((m = regex.exec(i18n)) !== null) {
  const key = m[1];
  const str = m[2].replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\');
  for (let i = 0; i < str.length; i++) {
    const cp = str.codePointAt(i);
    const ch = String.fromCodePoint(cp);
    if (ch.length > 1) i++; // skip surrogate pair
    if (ch === '\n' || ch === '\r' || ch === '\t') continue;
    if (!rubikChars.includes(ch)) {
      if (!missingRubik.has(ch)) missingRubik.set(ch, { key, str });
    }
    if (!uiChars.includes(ch)) {
      if (!missingUI.has(ch)) missingUI.set(ch, { key, str });
    }
  }
}

console.log('=== MISSING IN RUBIK (main_menu, campaign_map, arsenal, game_over, squad) ===');
for (const [ch, info] of missingRubik.entries()) {
  const code = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`${ch} (${code}) in [${info.key}]: "${info.str}"`);
}

console.log('\n=== MISSING IN ROBOTO (hud.gui) ===');
for (const [ch, info] of missingUI.entries()) {
  const code = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`${ch} (${code}) in [${info.key}]: "${info.str}"`);
}
