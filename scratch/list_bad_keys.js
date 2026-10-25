const fs = require('fs');
const content = fs.readFileSync('lua_modules/i18n.lua', 'utf8');

const regex = /([a-zA-Z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/g;
let m;
const usesSymbols = [];
const badChars = /[▲►◄★🥔🔵🔴⚡🔒⚠️🛡⚔🤖🎯🎩🏆💀🎖🔄🎉🪙]/u;

while ((m = regex.exec(content)) !== null) {
  if (badChars.test(m[2])) {
    usesSymbols.push({ key: m[1], val: m[2] });
  }
}
console.log('Total entries with emojis/arrows/stars:', usesSymbols.length);
const uniqueKeys = [...new Set(usesSymbols.map(x => x.key))];
console.log('Unique keys (' + uniqueKeys.length + '):');
for (const k of uniqueKeys) {
  const sample = usesSymbols.find(x => x.key === k).val;
  console.log(`  ${k}: "${sample}"`);
}
