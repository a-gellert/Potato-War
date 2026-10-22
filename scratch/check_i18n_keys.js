const fs = require('fs');

const content = fs.readFileSync('lua_modules/i18n.lua', 'utf8');

const langs = ['en', 'ru', 'tr', 'es', 'pt', 'fr'];
const dicts = {};

for (let i = 0; i < langs.length; i++) {
  const lang = langs[i];
  const startIdx = content.indexOf(`\t${lang} = {`);
  if (startIdx !== -1) {
    const nextLangIdx = i < langs.length - 1
      ? content.indexOf(`\t${langs[i + 1]} = {`, startIdx)
      : content.indexOf('\n}\n', startIdx);
    
    const slice = content.substring(startIdx, nextLangIdx !== -1 ? nextLangIdx : startIdx + 15000);
    const keys = [];
    const lines = slice.split('\n');
    for (const l of lines) {
      const km = l.match(/^\s*([a-zA-Z0-9_]+)\s*=/);
      if (km && km[1] !== lang) keys.push(km[1]);
    }
    dicts[lang] = new Set(keys);
    console.log(lang, 'keys count:', keys.length);
  } else {
    console.error('Could not find dict for', lang);
  }
}

const enKeys = dicts['en'];
for (const lang of ['ru', 'tr', 'es', 'pt', 'fr']) {
  const cur = dicts[lang];
  const missing = [];
  for (const k of enKeys) {
    if (!cur.has(k)) missing.push(k);
  }
  if (missing.length > 0) {
    console.log(`⚠️ Missing in ${lang} (${missing.length}):`, missing.join(', '));
  } else {
    console.log(`✅ ${lang} has all ${enKeys.size} keys!`);
  }
}
