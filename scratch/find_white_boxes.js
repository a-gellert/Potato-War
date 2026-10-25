const fs = require('fs');

const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');
const nodes = content.split(/^nodes\s*\{/m).slice(1);
console.log(`Total nodes in hud.gui: ${nodes.length}`);

for (const raw of nodes) {
    const id = (raw.match(/id:\s*"([^"]+)"/) || [])[1];
    const parent = (raw.match(/parent:\s*"([^"]+)"/) || [])[1];
    const texture = (raw.match(/texture:\s*"([^"]+)"/) || [])[1];
    const type = (raw.match(/type:\s*(\w+)/) || [])[1];
    const size = (raw.match(/size\s*\{([^}]+)\}/) || [])[1];
    const pos = (raw.match(/position\s*\{([^}]+)\}/) || [])[1];
    const color = (raw.match(/color\s*\{([^}]+)\}/) || [])[1];
    const enabled = (raw.match(/enabled:\s*(\w+)/) || [])[1];
    const text = (raw.match(/text:\s*"([^"]*)"/) || [])[1];
    const xanchor = (raw.match(/xanchor:\s*(\w+)/) || [])[1];
    const yanchor = (raw.match(/yanchor:\s*(\w+)/) || [])[1];

    // If type is TYPE_BOX with no texture or texture is white or color is white or near bottom-left
    if (type === 'TYPE_BOX' && (!texture || texture === 'ui/white')) {
        console.log(`WHITE/UNTEXTURED BOX: id=${id}, parent=${parent}, texture=${texture}, pos=${pos}, size=${size}, color=${color}, enabled=${enabled}, xanchor=${xanchor}, yanchor=${yanchor}`);
    }
}
