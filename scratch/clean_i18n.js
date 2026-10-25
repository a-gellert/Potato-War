const fs = require('fs');

const filePath = 'lua_modules/i18n.lua';
const content = fs.readFileSync(filePath, 'utf8');

const badRegex = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{25A0}-\u{25FF}\u{FE00}-\u{FE0F}]/gu;

const lines = content.split(/\r?\n/);
let modifiedCount = 0;

const newLines = lines.map(line => {
  const eqIdx = line.indexOf('=');
  if (eqIdx === -1) return line;

  const firstQuote = line.indexOf('"', eqIdx);
  const lastQuote = line.lastIndexOf('"');
  if (firstQuote === -1 || lastQuote <= firstQuote) return line;

  const prefix = line.slice(0, firstQuote + 1);
  const val = line.slice(firstQuote + 1, lastQuote);
  const suffix = line.slice(lastQuote);

  if (badRegex.test(val)) {
    modifiedCount++;
    let cleaned = val.replace(badRegex, '');
    cleaned = cleaned.replace(/[ ]{2,}/g, ' ');
    cleaned = cleaned.trim();
    return `${prefix}${cleaned}${suffix}`;
  }
  return line;
});

fs.writeFileSync(filePath, newLines.join('\n'), 'utf8');
console.log(`Cleaned i18n.lua: modified ${modifiedCount} lines.`);
