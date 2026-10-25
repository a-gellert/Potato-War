const fs = require('fs');
const js = fs.readFileSync('wasm-web/Potato War/dmloader.js', 'utf8');

const regex = /createElement\(['"](\w+)['"]\)/g;
let m;
const tags = new Set();
while ((m = regex.exec(js)) !== null) {
  tags.add(m[1]);
}
console.log('HTML elements created by dmloader:', Array.from(tags));
