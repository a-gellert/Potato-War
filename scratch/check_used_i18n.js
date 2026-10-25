const fs = require('fs');
const content = fs.readFileSync('lua_modules/i18n.lua', 'utf8');

const regex = /([a-zA-Z0-9_]+)\s*=\s*"((?:[^"\\]|\\.)*)"/g;
let m;
const allKeys = new Map();
while ((m = regex.exec(content)) !== null) {
  if (!allKeys.has(m[1])) allKeys.set(m[1], m[2]);
}

const codeFiles = [];
function walk(dir) {
  for (const f of fs.readdirSync(dir)) {
    const full = dir + '/' + f;
    if (fs.statSync(full).isDirectory()) {
      if (f !== 'build' && f !== '.git' && f !== '.internal' && f !== 'scratch') walk(full);
    } else if (f.endsWith('.lua') || f.endsWith('.gui_script') || f.endsWith('.script') || f.endsWith('.gui')) {
      codeFiles.push(full);
    }
  }
}
walk('gui');
walk('main');
walk('lua_modules');

const allCode = codeFiles.filter(f => !f.includes('i18n.lua')).map(f => fs.readFileSync(f, 'utf8')).join('\n');

const usedKeys = new Set();
const unusedKeys = new Set();

for (const [k, v] of allKeys.entries()) {
  if (allCode.includes(k)) {
    usedKeys.add(k);
  } else {
    unusedKeys.add(k);
  }
}

console.log('Total keys in i18n:', allKeys.size);
console.log('Used keys in codebase:', usedKeys.size);
console.log('Unused keys in codebase:', unusedKeys.size);

const badChars = /[▲►◄★🥔🔵🔴⚡🔒⚠️🛡⚔🤖🎯🎩🏆💀🎖🔄🎉🪙]/u;
console.log('\nUsed keys that have emojis/symbols:');
for (const k of usedKeys) {
  const val = allKeys.get(k);
  if (badChars.test(val)) {
    console.log(`  ${k}: "${val}"`);
  }
}

console.log('\nUnused keys that have emojis/symbols:');
for (const k of unusedKeys) {
  const val = allKeys.get(k);
  if (badChars.test(val)) {
    console.log(`  ${k}: "${val}"`);
  }
}
