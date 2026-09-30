const fs = require('fs');
let hud = fs.readFileSync('gui/hud/hud.gui', 'utf8');
const snippet = fs.readFileSync('scratch/inventory_nodes.gui_snippet', 'utf8');
const target = 'material: "/builtins/materials/gui.material"';
if (hud.includes(target)) {
  hud = hud.replace(target, snippet + target);
  fs.writeFileSync('gui/hud/hud.gui', hud, 'utf8');
  console.log('Successfully inserted inventory nodes into hud.gui');
} else {
  console.error('Target not found!');
  process.exit(1);
}
