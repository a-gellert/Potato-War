const fs = require('fs');

const l = '\t\tcamp_supplies_fmt = "Припасы: %d 🥔",';
console.log('l.includes =:', l.includes('='));
const idx1 = l.indexOf('"');
const idx2 = l.lastIndexOf('"');
console.log('idx1, idx2:', idx1, idx2);
const val = l.slice(idx1 + 1, idx2);
console.log('val:', val);

const badRegex = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{25A0}-\u{25FF}\u{FE00}-\u{FE0F}]/gu;
console.log('badRegex test:', badRegex.test(val));
console.log('replaced:', val.replace(badRegex, ''));
