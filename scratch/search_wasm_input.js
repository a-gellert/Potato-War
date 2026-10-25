const fs = require('fs');
const js = fs.readFileSync('wasm-web/Potato War/PotatoWar_wasm.js', 'utf8');
const matches = js.match(/.{0,40}createElement\(['"](?:input|textarea)['"]/g);
console.log(matches ? matches : 'no input elements found');
