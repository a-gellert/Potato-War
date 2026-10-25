const fs = require('fs');
const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');

// Parse blocks in protobuf-like text format
const nodes = [];
let current = null;
let currentDepth = 0;

const lines = content.split('\n');
for (let line of lines) {
  let trimmed = line.trim();
  if (trimmed === 'nodes {') {
    current = { raw: [] };
    nodes.push(current);
  } else if (current) {
    current.raw.push(trimmed);
  }
}

for (let n of nodes) {
  const text = n.raw.join('\n');
  const id = (text.match(/id:\s*"([^"]+)"/) || [])[1];
  const parent = (text.match(/parent:\s*"([^"]+)"/) || [])[1];
  const xanchor = (text.match(/xanchor:\s*(\w+)/) || [])[1];
  const yanchor = (text.match(/yanchor:\s*(\w+)/) || [])[1];
  const type = (text.match(/type:\s*(\w+)/) || [])[1];
  const enabled = (text.match(/enabled:\s*(\w+)/) || [])[1];
  const posMatch = text.match(/position\s*\{([^}]+)\}/);
  let pos = posMatch ? posMatch[1].replace(/\s+/g, ' ') : '';
  const sizeMatch = text.match(/size\s*\{([^}]+)\}/);
  let size = sizeMatch ? sizeMatch[1].replace(/\s+/g, ' ') : '';
  const colorMatch = text.match(/color\s*\{([^}]+)\}/);
  let col = colorMatch ? colorMatch[1].replace(/\s+/g, ' ') : '';
  const alphaMatch = text.match(/alpha:\s*([\d\.]+)/);
  let alpha = alphaMatch ? alphaMatch[1] : '';

  if (yanchor === 'YANCHOR_BOTTOM' || parent === 'touch_controls' || (parent && parent.startsWith('btn_')) || id === 'btn_inventory' || parent === 'btn_inventory') {
    console.log(`ID: ${id} | parent: ${parent} | anchor: ${xanchor}/${yanchor} | pos: ${pos} | size: ${size} | col: ${col} | alpha: ${alpha} | type: ${type} | enabled: ${enabled}`);
  }
}
