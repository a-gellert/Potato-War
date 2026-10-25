const fs = require('fs');

function getCharactersField(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const m = content.match(/characters:\s*"([^"\r\n]*)"/);
  return m ? m[1] : '';
}

const rubik = getCharactersField('main/assets/fonts/title.font');
const roboto = getCharactersField('main/assets/ui.font');

console.log('--- SYMBOL CHECKS ---');
const testChars = [
  { ch: '▲', desc: 'Black up-pointing triangle' },
  { ch: '►', desc: 'Black right-pointing pointer' },
  { ch: '◄', desc: 'Black left-pointing pointer' },
  { ch: '★', desc: 'Black star' },
  { ch: '⚔', desc: 'Crossed swords' },
  { ch: '⚠', desc: 'Warning sign' },
  { ch: '⚡', desc: 'High voltage sign' },
  { ch: '•', desc: 'Bullet' },
  { ch: '—', desc: 'Em dash' },
  { ch: '–', desc: 'En dash' },
  { ch: '№', desc: 'Numero sign' },
  { ch: '·', desc: 'Middle dot' },
  { ch: '°', desc: 'Degree sign' },
  { ch: '«', desc: 'Left-pointing double angle quotation mark' },
  { ch: '»', desc: 'Right-pointing double angle quotation mark' },
  { ch: '“', desc: 'Left double quotation mark' },
  { ch: '”', desc: 'Right double quotation mark' },
  { ch: '‘', desc: 'Left single quotation mark' },
  { ch: '’', desc: 'Right single quotation mark' },
  { ch: '…', desc: 'Horizontal ellipsis' },
  { ch: '¡', desc: 'Inverted exclamation mark' },
  { ch: '¿', desc: 'Inverted question mark' }
];

for (const t of testChars) {
  console.log(`${t.ch} (${t.desc}): in Rubik? ${rubik.includes(t.ch)}, in Roboto(ui)? ${roboto.includes(t.ch)}`);
}

// Check what emojis are in i18n
const i18n = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
const emojiRegex = /[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/gu;
const foundEmojis = new Set(i18n.match(emojiRegex) || []);
console.log('\n--- EMOJIS FOUND IN i18n.lua ---');
for (const em of foundEmojis) {
  const code = 'U+' + em.codePointAt(0).toString(16).toUpperCase();
  console.log(`Emoji: ${em} (${code}) -> in Rubik? ${rubik.includes(em)}, in Roboto? ${roboto.includes(em)}`);
}
