const fs = require('fs');
const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');

const rawNodes = content.split(/^nodes\s*\{/m).slice(1);

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
  const textM = r.match(/text:\s*"([^"]*)"/);
  const enabledM = r.match(/enabled:\s*(\w+)/);
  const xanchorM = r.match(/xanchor:\s*(\w+)/);
  const yanchorM = r.match(/yanchor:\s*(\w+)/);

  // If node has color white (or default white)
  console.log(`Node: ${id} | parent: ${parent} | type: ${typeM?typeM[1]:''} | tex: ${textureM?textureM[1]:''} | col: ${colorM?colorM[1].replace(/\s+/g,' '):'WHITE'} | anchor: ${xanchorM?xanchorM[1]:''}/${yanchorM?yanchorM[1]:''} | enabled: ${enabledM?enabledM[1]:'true'}`);
}
