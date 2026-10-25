const fs = require('fs');
const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');

// Split nodes
const rawNodes = content.split(/^nodes\s*\{/m).slice(1);
console.log('Total nodes:', rawNodes.length);

for (let r of rawNodes) {
  // extract id
  const idM = r.match(/id:\s*"([^"]+)"/);
  const id = idM ? idM[1] : '?';
  const parentM = r.match(/parent:\s*"([^"]+)"/);
  const parent = parentM ? parentM[1] : null;
  const posM = r.match(/position\s*\{([^}]+)\}/);
  const sizeM = r.match(/size\s*\{([^}]+)\}/);
  const enabledM = r.match(/enabled:\s*(\w+)/);
  const typeM = r.match(/type:\s*(\w+)/);
  const textureM = r.match(/texture:\s*"([^"]+)"/);
  const textM = r.match(/text:\s*"([^"]*)"/);
  const colorM = r.match(/color\s*\{([^}]+)\}/);

  let px = 0, py = 0, pz = 0;
  if (posM) {
    let xm = posM[1].match(/x:\s*([-\d\.]+)/);
    let ym = posM[1].match(/y:\s*([-\d\.]+)/);
    let zm = posM[1].match(/z:\s*([-\d\.]+)/);
    if (xm) px = parseFloat(xm[1]);
    if (ym) py = parseFloat(ym[1]);
    if (zm) pz = parseFloat(zm[1]);
  }

  // If node has no parent, and position is near 0,0 or default
  if (!parent) {
    console.log(`ROOT NODE: ${id} | pos: (${px}, ${py}) | size: ${sizeM ? sizeM[1].replace(/\s+/g, ' ') : 'none'} | type: ${typeM ? typeM[1] : ''} | enabled: ${enabledM ? enabledM[1] : 'true'} | tex: ${textureM ? textureM[1] : ''}`);
  }
}
