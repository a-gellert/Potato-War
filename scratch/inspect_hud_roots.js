const fs = require('fs');
const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');
const blocks = content.split('nodes {');
console.log('Total nodes:', blocks.length - 1);
blocks.slice(1).forEach(b => {
    const idMatch = b.match(/id:\s*"([^"]+)"/);
    const typeMatch = b.match(/type:\s*([^\s]+)/);
    const parentMatch = b.match(/parent:\s*"([^"]+)"/);
    const posMatch = b.match(/position\s*\{([^}]+)\}/);
    const colorMatch = b.match(/color\s*\{([^}]+)\}/);
    const sizeMatch = b.match(/size\s*\{([^}]+)\}/);
    const textMatch = b.match(/text:\s*"([^"]*)"/);
    const id = idMatch ? idMatch[1] : '';
    const type = typeMatch ? typeMatch[1] : '';
    const parent = parentMatch ? parentMatch[1] : '';
    const pos = posMatch ? posMatch[1].replace(/\s+/g, ' ').trim() : '0';
    const color = colorMatch ? colorMatch[1].replace(/\s+/g, ' ').trim() : '';
    const size = sizeMatch ? sizeMatch[1].replace(/\s+/g, ' ').trim() : '';
    const text = textMatch ? textMatch[1] : '';
    
    if (type === 'TYPE_BOX' && !parent) {
        console.log('ROOT BOX:', id, 'pos:', pos, 'size:', size, 'color:', color);
    }
});
