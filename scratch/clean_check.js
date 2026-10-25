const fs = require('fs');

const rubik = fs.readFileSync('main/assets/fonts/title.font', 'utf8');
const roboto = fs.readFileSync('main/assets/ui.font', 'utf8');

const rubikChars = rubik.match(/characters:\s*"([^"\r\n]*)"/)[1];
const robotoChars = roboto.match(/characters:\s*"([^"\r\n]*)"/)[1];

console.log('Roboto includes "A"?', robotoChars.includes('A'));
console.log('Roboto includes "а"?', robotoChars.includes('а'));
console.log('Roboto includes "1"?', robotoChars.includes('1'));

const i18n = fs.readFileSync('lua_modules/i18n.lua', 'utf8');

// Parse i18n strings strictly
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
    if (!rubikChars.includes(ch)) {
      if (!missingRubik.has(ch)) missingRubik.set(ch, []);
      missingRubik.get(ch).push(str);
    }
    if (!robotoChars.includes(ch)) {
      if (!missingRoboto.has(ch)) missingRoboto.set(ch, []);
      missingRoboto.get(ch).push(str);
    }
  }
}

console.log('--- MISSING IN RUBIK (title/label/body.font) ---');
for (const [ch, samples] of missingRubik.entries()) {
  const hex = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`'${ch}' (${hex}) -> ${samples[0]}`);
}

console.log('\n--- MISSING IN ROBOTO (ui.font) ---');
for (const [ch, samples] of missingRoboto.entries()) {
  const hex = 'U+' + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0');
  console.log(`'${ch}' (${hex}) -> ${samples[0]}`);
}
