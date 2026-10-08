const fs = require('fs');

const guiText = fs.readFileSync('gui/hud/hud.gui', 'utf8');
const scriptText = fs.readFileSync('gui/hud/hud.gui_script', 'utf8');

const nodeMatches = [...guiText.matchAll(/id:\s*"([^"]+)"/g)].map(m => m[1]);
const nodeSet = new Set(nodeMatches);

const getNodeCalls = [...scriptText.matchAll(/gui\.get_node\("([^"]+)"\)/g)].map(m => m[1]);
const buttonCalls = [...scriptText.matchAll(/self\.ui:button\("([^"]+)"/g)].map(m => m[1]);
const holdCalls = [...scriptText.matchAll(/self\.ui:hold_button\("([^"]+)"/g)].map(m => m[1]);

const allCalls = [...new Set([...getNodeCalls, ...buttonCalls, ...holdCalls])];

const missing = [];
for (const n of allCalls) {
  if (n === 'inv_slot_' || n === 'mode_text') continue;
  if (!nodeSet.has(n)) {
    missing.push(n);
  }
}

console.log('Nodes in hud.gui:', nodeSet.size);
console.log('Total referenced nodes in hud.gui_script:', allCalls.length);
console.log('Missing nodes in hud.gui:');
console.log(JSON.stringify(missing, null, 2));
