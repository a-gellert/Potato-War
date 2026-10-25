const fs = require('fs');

function parseFont(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const mChars = content.match(/characters:\s*"([^"\r\n]*)"/);
  const mExtra = content.match(/extra_characters:\s*"([^"\r\n]*)"/);
  let str = '';
  if (mChars) str += mChars[1];
  if (mExtra) str += mExtra[1];
  str = str.replace(/\\\\/g, '\\').replace(/\\"/g, '"');
  return { chars: new Set(str), raw: str };
}

const fontFiles = {
  'ui.font (Roboto-Bold)': 'main/assets/ui.font',
  'title.font (Rubik-Black)': 'main/assets/fonts/title.font',
  'label.font (Rubik-ExtraBold)': 'main/assets/fonts/label.font',
  'body.font (Rubik-ExtraBold)': 'main/assets/fonts/body.font',
  'game.font (metapro_bold)': 'main/assets/game.font',
};

const fonts = {};
for (const [name, rel] of Object.entries(fontFiles)) {
  fonts[name] = parseFont(rel);
}

const i18nContent = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
const regex = /([a-zA-Z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/g;
const allStrings = [];
let m;
while ((m = regex.exec(i18nContent)) !== null) {
  let s = m[2].replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\');
  allStrings.push({ key: m[1], val: s });
}

// Group characters: emojis, special symbols, letters
for (const [fontName, f] of Object.entries(fonts)) {
  const missing = new Map();
  for (const item of allStrings) {
    for (const ch of item.val) {
      if (ch === '\n' || ch === '\r' || ch === '\t') continue;
      if (!f.chars.has(ch)) {
        if (!missing.has(ch)) missing.set(ch, new Set());
        missing.get(ch).add(item.key);
      }
    }
  }

  console.log(`\n========================================`);
  console.log(`FONT: ${fontName}`);
  console.log(`Missing count: ${missing.size}`);
  
  // Categorize
  const emojis = [];
  const latinExt = [];
  const symbols = [];
  const other = [];

  for (const [ch, keys] of missing.entries()) {
    const cp = ch.codePointAt(0);
    const hex = 'U+' + cp.toString(16).toUpperCase().padStart(4, '0');
    const info = `${ch} (${hex}, keys: ${[...keys].slice(0, 3).join(', ')})`;
    if (cp > 0x2000 && cp < 0x3000) {
      symbols.push(info);
    } else if (cp >= 0x1F000 || cp === 0xFE0F || (cp >= 0xD800 && cp <= 0xDFFF)) {
      emojis.push(info);
    } else if ((cp >= 0xC0 && cp <= 0x024F)) {
      latinExt.push(info);
    } else {
      other.push(info);
    }
  }

  if (symbols.length) console.log('  Symbols (arrows, bullets, stars, etc.):\n   ', symbols.join('\n    '));
  if (latinExt.length) console.log('  Latin Extended (accents, Turkish/Portuguese/etc.):\n   ', latinExt.join('\n    '));
  if (emojis.length) console.log('  Emojis:\n   ', emojis.join('\n    '));
  if (other.length) console.log('  Other:\n   ', other.join('\n    '));
}
