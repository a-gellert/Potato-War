const fs = require('fs');

const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');
const nodes = content.split(/^nodes\s*\{/m).slice(1);
for (const raw of nodes) {
    const id = (raw.match(/id:\s*"([^"]+)"/) || [])[1];
    const parent = (raw.match(/parent:\s*"([^"]+)"/) || [])[1];
    const texture = (raw.match(/texture:\s*"([^"]+)"/) || [])[1];
    const type = (raw.match(/type:\s*(\w+)/) || [])[1];
    const size = (raw.match(/size\s*\{([^}]+)\}/) || [])[1];
    const pos = (raw.match(/position\s*\{([^}]+)\}/) || [])[1];
    const color = (raw.match(/color\s*\{([^}]+)\}/) || [])[1];
    const alpha = (raw.match(/alpha:\s*([-\d.]+)/) || [])[1];
    if (parent === 'touch_controls' || id === 'touch_controls' || (parent && (parent.startsWith('btn_') && !parent.startsWith('btn_wpn_')))) {
        console.log({ id, parent, type, texture, size: size ? size.replace(/\s+/g, ' ') : '', pos: pos ? pos.replace(/\s+/g, ' ') : '', color: color ? color.replace(/\s+/g, ' ') : 'white', alpha });
    }
}
