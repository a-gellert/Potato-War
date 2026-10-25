const fs = require('fs');

function getCharSetFromFont(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const m = content.match(/characters:\s*"([^"\r\n]*)"/);
  if (!m) return new Set();
  const raw = m[1].replace(/\\\\/g, '\\').replace(/\\"/g, '"');
  return new Set(raw);
}

const rubikChars = getCharSetFromFont('main/assets/fonts/title.font');
const robotoChars = getCharSetFromFont('main/assets/ui.font');

const i18n = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
const regex = /([a-zA-Z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/g;
let m;

const rubikMissing = new Map();
const robotoMissing = new Map();

while ((m = regex.exec(i18n)) !== null) {
  const key = m[1];
  const str = m[2].replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\');
  for (let i = 0; i < str.length; i++) {
    const cp = str.codePointAt(i);
    const ch = String.fromCodePoint(cp);
    if (ch.length > 1) i++;
    if (ch === '\n' || ch === '\r' || ch === '\t') continue;
    if (!rubikChars.has(ch)) {
      if (!rubikMissing.has(ch)) rubikMissing.set(ch, new Set());
      rubikMissing.get(ch).add(key);
    }
    if (!robotoChars.has(ch)) {
      if (!robotoMissing.has(ch)) robotoMissing.set(ch, new Set());
      robotoMissing.get(ch).add(key);
    }
  }
}

console.log('=== MISSING IN RUBIK (title/label/body.font) ===');
for (const [ch, keys] of rubikMissing.entries()) {
  const code = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`Char: ${ch} (${code}) | used in keys: ${[...keys].join(', ')}`);
}

console.log('\n=== MISSING IN ROBOTO (ui.font) ===');
for (const [ch, keys] of robotoMissing.entries()) {
  const code = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`Char: ${ch} (${code}) | used in keys: ${[...keys].join(', ')}`);
}
