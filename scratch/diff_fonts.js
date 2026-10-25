const fs = require('fs');
const u = fs.readFileSync('main/assets/ui.font', 'utf8');
const t = fs.readFileSync('main/assets/fonts/title.font', 'utf8');

const uChars = u.slice(u.indexOf('characters: "') + 13, u.lastIndexOf('"'));
const tChars = t.slice(t.indexOf('characters: "') + 13, t.lastIndexOf('"'));

console.log('in title but not ui:', [...tChars].filter(c => !uChars.includes(c)).join(' '));
console.log('in ui but not title:', [...uChars].filter(c => !tChars.includes(c)).join(' '));
