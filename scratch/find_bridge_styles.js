const fs = require('fs');
const js = fs.readFileSync('res/playgama-bridge.js', 'utf8');

const matches = js.match(/textContent\s*=\s*`([^`]+)`/g);
if (matches) {
  matches.forEach((m, i) => {
    console.log(`--- Style ${i} ---`);
    console.log(m.slice(0, 300));
  });
}
