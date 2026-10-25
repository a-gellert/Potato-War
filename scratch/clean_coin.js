const fs = require('fs');

const filePath = 'lua_modules/i18n.lua';
let content = fs.readFileSync(filePath, 'utf8');

// Replace coin emoji (U+1FA99)
content = content.replace(/\u{1FA99}\s*/gu, '');

fs.writeFileSync(filePath, content, 'utf8');
console.log('Cleaned coin emoji!');
