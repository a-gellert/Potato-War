const fs = require('fs');
const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');

const rawNodes = content.split(/^nodes\s*\{/m).slice(1);
console.log('Total nodes:', rawNodes.length);

for (let r of rawNodes) {
  const idM = r.match(/id:\s*"([^"]+)"/);
  const id = idM ? idM[1] : '?';
  const parentM = r.match(/parent:\s*"([^"]+)"/);
  const parent = parentM ? parentM[1] : null;
  const posM = r.match(/position\s*\{([^}]+)\}/);
  const sizeM = r.match(/size\s*\{([^}]+)\}/);
  const colorM = r.match(/color\s*\{([^}]+)\}/);
  const typeM = r.match(/type:\s*(\w+)/);
  const textureM = r.match(/texture:\s*"([^"]+)"/);
  const enabledM = r.match(/enabled:\s*(\w+)/);

  if (typeM && typeM[1] === 'TYPE_BOX') {
    let sizeStr = sizeM ? sizeM[1].replace(/\s+/g, ' ') : '';
    let posStr = posM ? posM[1].replace(/\s+/g, ' ') : '(0,0)';
    let colStr = colorM ? colorM[1].replace(/\s+/g, ' ') : 'default';
    let enabledStr = enabledM ? enabledM[1] : 'true';
    console.log(`${id} (parent: ${parent}) | size: ${sizeStr} | pos: ${posStr} | col: ${colStr} | tex: ${textureM ? textureM[1] : 'none'} | enabled: ${enabledStr}`);
  }
}
