const fs = require('fs');

function extractChars(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const idx = content.indexOf('characters: "');
  if (idx === -1) return '';
  const start = idx + 'characters: "'.length;
  const lastQuote = content.lastIndexOf('"');
  return content.slice(start, lastQuote);
}

const rubikStr = extractChars('main/assets/fonts/title.font');
const robotoStr = extractChars('main/assets/ui.font');

console.log('Rubik length:', rubikStr.length);
console.log('Roboto length:', robotoStr.length);

const i18n = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
const regex = /=\s*"((?:[^"\\]|\\.)*)"/g;

const missingRubik = new Map();
const missingRoboto = new Map();

let m;
while ((m = regex.exec(i18n)) !== null) {
  const str = m[1].replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\');
  for (let i = 0; i < str.length; i++) {
    const cp = str.codePointAt(i);
    const ch = String.fromCodePoint(cp);
    if (ch.length > 1) i++;
    if (ch === '\n' || ch === '\r' || ch === '\t') continue;
    if (!rubikStr.includes(ch)) {
      if (!missingRubik.has(ch)) missingRubik.set(ch, []);
      missingRubik.get(ch).push(str);
    }
    if (!robotoStr.includes(ch)) {
      if (!missingRoboto.has(ch)) missingRoboto.set(ch, []);
      missingRoboto.get(ch).push(str);
    }
  }
}

console.log('\n=== REAL MISSING IN RUBIK (title/label/body.font) ===');
for (const [ch, samples] of missingRubik.entries()) {
  const hex = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`Char: ${ch} (${hex}) -> sample: "${samples[0].slice(0, 40)}"`);
}

console.log('\n=== REAL MISSING IN ROBOTO (ui.font) ===');
for (const [ch, samples] of missingRoboto.entries()) {
  const hex = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`Char: ${ch} (${hex}) -> sample: "${samples[0].slice(0, 40)}"`);
}
