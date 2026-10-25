const fs = require('fs');
const js = fs.readFileSync('res/playgama-bridge.js', 'utf8');

const regex = /createElement\(['"](\w+)['"]\)/g;
let m;
const tags = [];
while ((m = regex.exec(js)) !== null) {
  tags.push(m[1]);
}
console.log('HTML elements created by playgama-bridge:', tags);
