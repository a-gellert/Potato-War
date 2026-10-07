const fs = require('fs');

console.log('--- TESTING GRAPH ALGORITHMS & CONNECTIVITY ---');

// Parse sectors from lua_modules/territory_map.lua
const content = fs.readFileSync('lua_modules/territory_map.lua', 'utf8');

// Extract DEFAULT_SECTORS block
const defaultSectorsRegex = /M\.DEFAULT_SECTORS\s*=\s*\{([\s\S]*?)\n\}\s*\n\s*-- Current/m;
const match = content.match(defaultSectorsRegex);
if (!match) {
  console.error('Could not find DEFAULT_SECTORS block');
  process.exit(1);
}

// Extract sector id, neighbors, x, y, owner, defense_level, income
const sectorRegex = /\[(\d+)\]\s*=\s*\{[\s\S]*?name_ru\s*=\s*"([^"]+)"[\s\S]*?region\s*=\s*(\d+)[\s\S]*?biome\s*=\s*"([^"]+)"[\s\S]*?terrain_preset\s*=\s*"([^"]+)"[\s\S]*?owner\s*=\s*"([^"]+)"[\s\S]*?defense_level\s*=\s*(\d+)[\s\S]*?income\s*=\s*(\d+)[\s\S]*?garrison\s*=\s*(\d+)[\s\S]*?x\s*=\s*(\d+)[\s\S]*?y\s*=\s*(\d+)[\s\S]*?neighbors\s*=\s*\{([^}]+)\}/g;

const sectors = {};
let sMatch;
while ((sMatch = sectorRegex.exec(match[1])) !== null) {
  const id = parseInt(sMatch[1]);
  const name_ru = sMatch[2];
  const region = parseInt(sMatch[3]);
  const biome = sMatch[4];
  const terrain_preset = sMatch[5];
  const owner = sMatch[6];
  const defense_level = parseInt(sMatch[7]);
  const income = parseInt(sMatch[8]);
  const garrison = parseInt(sMatch[9]);
  const x = parseInt(sMatch[10]);
  const y = parseInt(sMatch[11]);
  const neighbors = sMatch[12].split(',').map(s => parseInt(s.trim())).filter(n => !isNaN(n));
  sectors[id] = { id, name_ru, region, biome, terrain_preset, owner, defense_level, income, garrison, x, y, neighbors };
}

const sectorCount = Object.keys(sectors).length;
console.log(`Parsed ${sectorCount} sectors.`);
if (sectorCount !== 18) {
  console.error('Expected 18 sectors, found:', sectorCount);
  process.exit(1);
}

// Verify neighbor symmetry
for (const [id, s] of Object.entries(sectors)) {
  for (const nid of s.neighbors) {
    const neighbor = sectors[nid];
    if (!neighbor) {
      console.error(`Sector ${id} references non-existent neighbor ${nid}`);
      process.exit(1);
    }
    if (!neighbor.neighbors.includes(s.id)) {
      console.error(`Asymmetry: Sector ${id} connects to ${nid}, but ${nid} does not connect back to ${id}!`);
      process.exit(1);
    }
  }
}
console.log('✓ All neighbor relations are fully symmetric and valid');

// Verify graph connectivity (Island is fully connected)
const visited = new Set();
const queue = [1];
visited.add(1);
while (queue.length > 0) {
  const cur = queue.shift();
  for (const nid of sectors[cur].neighbors) {
    if (!visited.has(nid)) {
      visited.add(nid);
      queue.push(nid);
    }
  }
}
if (visited.size !== 18) {
  console.error(`Graph is not connected! Visited only ${visited.size} of 18 sectors.`);
  process.exit(1);
}
console.log('✓ Island graph is 100% connected: all 18 sectors are reachable');

// Verify available attack targets on Turn 1 (Blue owns 1 and 2)
const targetsTurn1 = [];
for (const [id, s] of Object.entries(sectors)) {
  if (s.owner === 'red') {
    const bordersBlue = s.neighbors.some(nid => sectors[nid].owner === 'blue');
    if (bordersBlue) targetsTurn1.push(s.id);
  }
}
console.log('Turn 1 Attack Targets for Blue:', targetsTurn1.map(tid => `#${tid} ${sectors[tid].name_ru}`));
if (!targetsTurn1.includes(3) || !targetsTurn1.includes(4) || !targetsTurn1.includes(5) || !targetsTurn1.includes(10)) {
  console.error('Expected sectors 3, 4, 5, 10 to border Blue on Turn 1');
  process.exit(1);
}
console.log('✓ Turn 1 frontline targets correctly calculated');

// Check coordinates bounds within 960x540
for (const [id, s] of Object.entries(sectors)) {
  if (s.x < 40 || s.x > 660) {
    console.error(`Sector ${id} x=${s.x} is out of map area [40, 660]!`);
    process.exit(1);
  }
  if (s.y < 50 || s.y > 480) {
    console.error(`Sector ${id} y=${s.y} is out of map area [50, 480]!`);
    process.exit(1);
  }
}
console.log('✓ All 18 sector screen coordinates fit inside map area (x: 40..660, y: 50..480), leaving right area for inspector');

console.log('=== GRAPH SIMULATION VERIFICATION PASSED! ===');
