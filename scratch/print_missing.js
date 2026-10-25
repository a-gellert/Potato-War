const fs = require('fs');

const rubik = fs.readFileSync('main/assets/fonts/title.font', 'utf8');
const roboto = fs.readFileSync('main/assets/ui.font', 'utf8');

const rubikChars = rubik.match(/characters:\s*"([^"\r\n]*)"/)[1];
const robotoChars = roboto.match(/characters:\s*"([^"\r\n]*)"/)[1];

const i18n = fs.readFileSync('lua_modules/i18n.lua', 'utf8');

function findMissing(charsStr, label) {
  const missing = new Map();
  for (let i = 0; i < i18n.length; i++) {
    const cp = i18n.codePointAt(i);
    const ch = String.fromCodePoint(cp);
    if (ch.length > 1) i++;
    if (cp <= 32) continue; // whitespace
    if (!charsStr.includes(ch)) {
      if (!missing.has(ch)) missing.set(ch, 0);
      missing.set(ch, missing.get(ch) + 1);
    }
  }
  console.log(`\n=== UNIQUE MISSING IN ${label} (${missing.size} unique) ===`);
  for (const [ch, count] of missing.entries()) {
    const code = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
    console.log(`  '${ch}' (${code}) [count: ${count}]`);
  }
}

findMissing(rubikChars, 'RUBIK (title, label, body fonts)');
findMissing(robotoChars, 'ROBOTO (ui.font)');
