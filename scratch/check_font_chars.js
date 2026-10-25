const fs = require('fs');
const path = require('path');

function parseFont(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const mChars = content.match(/characters:\s*"([^"\r\n]*)"/);
  const mExtra = content.match(/extra_characters:\s*"([^"\r\n]*)"/);
  const isAll = /all_chars:\s*true/.test(content);
  let str = '';
  if (mChars) str += mChars[1];
  if (mExtra) str += mExtra[1];
  str = str.replace(/\\\\/g, '\\').replace(/\\"/g, '"');
  return { isAll, chars: new Set(str), raw: str };
}

const fontFiles = {
  'ui.font': 'main/assets/ui.font',
  'title.font': 'main/assets/fonts/title.font',
  'label.font': 'main/assets/fonts/label.font',
  'body.font': 'main/assets/fonts/body.font',
  'game.font': 'main/assets/game.font',
};

const fonts = {};
for (const [name, rel] of Object.entries(fontFiles)) {
  fonts[name] = parseFont(rel);
}

// 1. Scan all strings in .gui files
function scanGuiFiles() {
  const guiFiles = [];
  function walk(dir) {
    for (const f of fs.readdirSync(dir)) {
      const full = path.join(dir, f);
      if (fs.statSync(full).isDirectory()) walk(full);
      else if (f.endsWith('.gui')) guiFiles.push(full);
    }
  }
  walk('gui');
  walk('main');

  const texts = [];
  for (const gf of guiFiles) {
    const content = fs.readFileSync(gf, 'utf8');
    const lines = content.split(/\r?\n/);
    const declaredFonts = {};
    const fontMatches = [...content.matchAll(/fonts\s*\{[^}]*name:\s*"([^"]+)"[^}]*font:\s*"([^"]+)"[^}]*\}/g)];
    for (const fm of fontMatches) {
      declaredFonts[fm[1]] = path.basename(fm[2]);
    }

    let nodeText = null;
    let nodeFont = null;
    let nodeId = null;

    for (const line of lines) {
      if (line.trim() === 'nodes {') {
        if (nodeText !== null) {
          texts.push({ file: gf, id: nodeId, text: nodeText, font: nodeFont, resolvedFont: declaredFonts[nodeFont] });
        }
        nodeText = null;
        nodeFont = null;
        nodeId = null;
      }
      const mId = line.match(/id:\s*"([^"]+)"/);
      if (mId) nodeId = mId[1];
      const mFont = line.match(/font:\s*"([^"]+)"/);
      if (mFont) nodeFont = mFont[1];
      const mText = line.match(/text:\s*"((?:[^"\\]|\\.)*)"/);
      if (mText) {
        let raw = mText[1];
        const bytes = [];
        for (let i = 0; i < raw.length; i++) {
          if (raw[i] === '\\' && i + 3 < raw.length && /[0-7]{3}/.test(raw.slice(i + 1, i + 4))) {
            const oct = raw.slice(i + 1, i + 4);
            bytes.push(parseInt(oct, 8));
            i += 3;
          } else if (raw[i] === '\\' && i + 1 < raw.length) {
            const next = raw[i + 1];
            if (next === 'n') bytes.push(10);
            else if (next === 'r') bytes.push(13);
            else if (next === 't') bytes.push(9);
            else if (next === '"') bytes.push(34);
            else if (next === '\\') bytes.push(92);
            else bytes.push(raw.charCodeAt(i + 1));
            i++;
          } else {
            bytes.push(raw.charCodeAt(i));
          }
        }
        nodeText = Buffer.from(bytes).toString('utf8');
      }
    }
    if (nodeText !== null) {
      texts.push({ file: gf, id: nodeId, text: nodeText, font: nodeFont, resolvedFont: declaredFonts[nodeFont] });
    }
  }
  return texts;
}

function scanI18n() {
  const content = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
  const regex = /([a-zA-Z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/g;
  const entries = [];
  let m;
  while ((m = regex.exec(content)) !== null) {
    let s = m[2].replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    entries.push({ key: m[1], val: s });
  }
  return entries;
}

const guiTexts = scanGuiFiles();
const i18nEntries = scanI18n();

console.log('GUI Texts found:', guiTexts.length);
console.log('i18n Entries found:', i18nEntries.length);

// Check 1: Static texts in .gui files vs their specified font
console.log('\n=============================================');
console.log('CHECK 1: Static texts in .gui files');
console.log('=============================================');
let guiMissingCount = 0;
for (const gt of guiTexts) {
  const fontName = gt.resolvedFont || 'ui.font';
  const f = fonts[fontName];
  if (!f) continue;
  for (const ch of gt.text) {
    if (ch === '\n' || ch === '\r' || ch === '\t') continue;
    if (!f.chars.has(ch)) {
      guiMissingCount++;
      const code = ch.charCodeAt(0).toString(16).toUpperCase().padStart(4, '0');
      console.log(`[GUI MISSING] File: ${gt.file}, Node: "${gt.id}", Font: ${fontName} -> Char: '${ch}' (U+${code}) in "${gt.text}"`);
    }
  }
}
if (guiMissingCount === 0) {
  console.log('All static texts in .gui files are supported by their assigned fonts!');
}

// Check 2: Check each font individually for characters used in i18n
console.log('\n=============================================');
console.log('CHECK 2: i18n texts vs Font character coverage');
console.log('=============================================');

for (const [fontName, f] of Object.entries(fonts)) {
  const missing = new Map();
  for (const entry of i18nEntries) {
    for (const ch of entry.val) {
      if (ch === '\n' || ch === '\r' || ch === '\t') continue;
      if (!f.chars.has(ch)) {
        if (!missing.has(ch)) missing.set(ch, []);
        const list = missing.get(ch);
        if (list.length < 3) list.push(`${entry.key}: "${entry.val.slice(0, 35)}"`);
      }
    }
  }
  console.log(`\nFont: ${fontName} -> Missing chars count: ${missing.size}`);
  if (missing.size > 0) {
    const charsList = [...missing.keys()].sort();
    console.log(`Characters: ${charsList.join(' ')}`);
    for (const ch of charsList) {
      const code = ch.charCodeAt(0).toString(16).toUpperCase().padStart(4, '0');
      console.log(`  '${ch}' (U+${code}) -> samples: ${missing.get(ch).join(' | ')}`);
    }
  }
}
