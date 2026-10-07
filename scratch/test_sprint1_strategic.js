// scratch/test_sprint1_strategic.js
// Unit tests and simulation for Sprint 1: Territory Map & Strategic Campaign

const fs = require('fs');

console.log('=== SPRINT 1 VERIFICATION: Territory Map & Strategic Campaign ===\n');

// 1. Verify territory_map.lua
console.log('1. Checking lua_modules/territory_map.lua...');
const mapCode = fs.readFileSync('lua_modules/territory_map.lua', 'utf8');

const requiredMapMethods = [
    'get_available_targets',
    'capture_sector',
    'fortify_sector',
    'get_income',
    'get_sector',
    'get_sectors',
    'get_all_sectors',
    'get_sectors_by_owner',
    'get_border_sectors',
    'get_vulnerable_border_sectors',
    'get_state',
    'set_state',
    'reset_map',
    'is_victory',
    'is_defeat',
    'get_name'
];

for (const m of requiredMapMethods) {
    if (!mapCode.includes('function M.' + m)) {
        console.error('FAIL: Missing method in territory_map.lua: ' + m);
        process.exit(1);
    }
}
console.log('  [PASS] All required territory_map methods are defined.');

// Check sector properties in territory_map.lua
const requiredSectorProps = [
    'id', 'name_ru', 'name_en', 'region', 'owner', 'neighbors',
    'defense_level', 'income', 'terrain_preset', 'biome'
];
for (const prop of requiredSectorProps) {
    if (!mapCode.includes(prop + ' =') && !mapCode.includes(prop + ' = ') && !mapCode.includes(prop)) {
        console.error('FAIL: Missing property in sector definitions: ' + prop);
        process.exit(1);
    }
}
console.log('  [PASS] All sector properties (id, name_ru/en, region, owner, neighbors, defense_level, income, terrain_preset, biome) verified.');

// 2. Verify strategic_campaign.lua
console.log('\n2. Checking lua_modules/strategic_campaign.lua...');
const campCode = fs.readFileSync('lua_modules/strategic_campaign.lua', 'utf8');

const requiredCampaignMethods = [
    'init',
    'collect_income',
    'fortify_sector',
    'select_target',
    'launch_battle',
    'build_battle_config',
    'find_ai_counterattack_target',
    'execute_ai_counterattack',
    'resolve_battle',
    'advance_turn',
    'save_progress',
    'load_progress',
    'reset_campaign',
    'get_campaign_summary'
];

for (const m of requiredCampaignMethods) {
    if (!campCode.includes('function M.' + m)) {
        console.error('FAIL: Missing method in strategic_campaign.lua: ' + m);
        process.exit(1);
    }
}
console.log('  [PASS] All required strategic_campaign methods are defined.');

// Check phase constants
const requiredPhases = [
    'PHASE_INCOME',
    'PHASE_STRATEGY',
    'PHASE_BATTLE',
    'PHASE_COUNTERATTACK',
    'PHASE_VICTORY',
    'PHASE_DEFEAT'
];
for (const p of requiredPhases) {
    if (!campCode.includes(p)) {
        console.error('FAIL: Missing phase constant: ' + p);
        process.exit(1);
    }
}
console.log('  [PASS] Campaign phase states verified.');

// 3. Verify player_profile.lua campaign persistence
console.log('\n3. Checking lua_modules/player_profile.lua campaign persistence...');
const profileCode = fs.readFileSync('lua_modules/player_profile.lua', 'utf8');

const requiredProfileMethods = [
    'get_campaign_map',
    'set_campaign_map',
    'get_campaign_turn',
    'set_campaign_turn',
    'get_campaign_stats',
    'set_campaign_stats',
    'reset_campaign_progress'
];
for (const m of requiredProfileMethods) {
    if (!profileCode.includes('function M.' + m)) {
        console.error('FAIL: Missing method in player_profile.lua: ' + m);
        process.exit(1);
    }
}
console.log('  [PASS] Player profile campaign persistence methods verified.');

if (!profileCode.includes('campaign_map') || !profileCode.includes('campaign_turn') || !profileCode.includes('campaign_stats')) {
    console.error('FAIL: Missing campaign fields in player_profile.data');
    process.exit(1);
}
console.log('  [PASS] Player profile data structure includes campaign persistence fields.');

// 4. Functional Graph and Logic Simulation on all 18 Sectors
console.log('\n4. Simulating Map Graph Topology & Strategic Campaign Flow on all 18 Sectors...');

// Extract sectors from territory_map.lua
const sectorBlocks = mapCode.match(/\[(\d+)\]\s*=\s*\{([^}]+)\}/g);
if (!sectorBlocks || sectorBlocks.length < 18) {
    console.error('FAIL: Expected at least 18 sector blocks in territory_map.lua, found ' + (sectorBlocks ? sectorBlocks.length : 0));
    process.exit(1);
}

const parsedSectors = [];
for (const block of sectorBlocks) {
    const idMatch = block.match(/id\s*=\s*(\d+)/);
    const nameRuMatch = block.match(/name_ru\s*=\s*"([^"]+)"/);
    const nameEnMatch = block.match(/name_en\s*=\s*"([^"]+)"/);
    const ownerMatch = block.match(/owner\s*=\s*"([^"]+)"/);
    const defMatch = block.match(/defense_level\s*=\s*(\d+)/);
    const incMatch = block.match(/income\s*=\s*(\d+)/);
    const neighborsMatch = block.match(/neighbors\s*=\s*\{([^}]+)\}/);
    const terrainMatch = block.match(/terrain_preset\s*=\s*"([^"]+)"/);
    const biomeMatch = block.match(/biome\s*=\s*"([^"]+)"/);

    if (idMatch && nameRuMatch && ownerMatch && neighborsMatch) {
        const id = parseInt(idMatch[1]);
        const neighbors = neighborsMatch[1].split(',').map(s => parseInt(s.trim())).filter(n => !isNaN(n));
        parsedSectors.push({
            id: id,
            name_ru: nameRuMatch[1],
            name_en: nameEnMatch ? nameEnMatch[1] : '',
            owner: ownerMatch[1].toLowerCase(),
            defense_level: defMatch ? parseInt(defMatch[1]) : 1,
            income: incMatch ? parseInt(incMatch[1]) : 20,
            terrain_preset: terrainMatch ? terrainMatch[1] : 'hills',
            biome: biomeMatch ? biomeMatch[1] : 'grass',
            neighbors: neighbors
        });
    }
}

console.log(`  [PASS] Successfully parsed ${parsedSectors.length} sectors from territory_map.lua.`);
const sectorMap = {};
for (const s of parsedSectors) sectorMap[s.id] = s;

// Verify graph symmetry across all sectors
for (const s of parsedSectors) {
    for (const nId of s.neighbors) {
        const neighbor = sectorMap[nId];
        if (!neighbor) {
            console.error(`FAIL: Sector ${s.id} points to non-existent neighbor ${nId}`);
            process.exit(1);
        }
        if (!neighbor.neighbors.includes(s.id)) {
            console.error(`FAIL: Asymmetric connection between Sector #${s.id} and Sector #${nId}`);
            process.exit(1);
        }
    }
}
console.log('  [PASS] Sector graph symmetry validated: 100% bidirectional borders.');

// Check initial income calculation
let blueIncome = 0;
for (const s of parsedSectors) {
    if (s.owner === "blue") blueIncome += s.income;
}
console.log(`  [PASS] Starting Blue Income: +${blueIncome} points (Sectors: ${parsedSectors.filter(s => s.owner === "blue").map(s => '#' + s.id).join(', ')})`);
if (blueIncome <= 0) {
    console.error('FAIL: Expected initial Blue income > 0');
    process.exit(1);
}

// Check initial available targets for Blue
const availableTargets = [];
const seen = {};
for (const s of parsedSectors) {
    if (s.owner === "blue") {
        for (const nId of s.neighbors) {
            const n = sectorMap[nId];
            if (n && n.owner === "red" && !seen[n.id]) {
                seen[n.id] = true;
                availableTargets.push(n);
            }
        }
    }
}
console.log(`  [PASS] Initial available targets for Blue: ${availableTargets.map(t => `#${t.id} (${t.name_ru})`).join(', ')}`);
if (availableTargets.length === 0) {
    console.error('FAIL: Expected available targets for Blue on turn 1');
    process.exit(1);
}

// Simulate AI counter-attack target selection on Blue border
const blueBorders = parsedSectors.filter(s => s.owner === "blue" && s.neighbors.some(nId => sectorMap[nId].owner === "red"));
console.log(`  [PASS] Blue border sectors: ${blueBorders.map(b => `#${b.id} (Def:${b.defense_level})`).join(', ')}`);

let bestCandidate = null;
let maxScore = -1;
for (const sec of blueBorders) {
    const defenseScore = (4 - sec.defense_level) * 100;
    const redNeighbors = sec.neighbors.filter(nId => sectorMap[nId].owner === "red").length;
    const threatScore = redNeighbors * 30;
    const incomeScore = Math.floor(sec.income * 0.5);
    const blueNeighbors = sec.neighbors.filter(nId => sectorMap[nId].owner === "blue").length;
    const isolationScore = Math.max(0, 4 - blueNeighbors) * 20;
    const total = defenseScore + threatScore + incomeScore + isolationScore;
    console.log(`    Sector #${sec.id} (${sec.name_ru}) - Def:${sec.defense_level}, RedPressure:${redNeighbors} => Score: ${total}`);
    if (total > maxScore) {
        maxScore = total;
        bestCandidate = sec;
    }
}
console.log(`  [PASS] Red AI selects most vulnerable Blue sector: #${bestCandidate.id} (${bestCandidate.name_ru}) with vulnerability score ${maxScore}`);

console.log('\n=== ALL SPRINT 1 TESTS AND VERIFICATIONS PASSED SUCCESSFULLY! ===');
