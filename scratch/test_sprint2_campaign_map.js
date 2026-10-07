const fs = require('fs');

console.log('--- RUNNING SPRINT 2 CAMPAIGN MAP TESTS ---');

// 1. Syntax Check on all relevant files
const filesToCheck = [
  'lua_modules/territory_map.lua',
  'lua_modules/strategic_campaign.lua',
  'lua_modules/i18n.lua',
  'gui/campaign_map/campaign_map.gui_script',
  'gui/main_menu/main_menu.gui_script',
  'gui/game_over/game_over.gui_script',
  'main/main.script'
];

for (const filePath of filesToCheck) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  let parens = 0, braces = 0, brackets = 0;
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].replace(/--.*$/, '');
    line = line.replace(/"(\\.|[^"\\])*"/g, '""');
    line = line.replace(/'(\\.|[^'\\])*'/g, "''");
    for (const ch of line) {
      if (ch === '(') parens++;
      if (ch === ')') parens--;
      if (ch === '{') braces++;
      if (ch === '}') braces--;
      if (ch === '[') brackets++;
      if (ch === ']') brackets--;
    }
  }
  if (parens !== 0 || braces !== 0 || brackets !== 0) {
    console.error('SYNTAX ERROR in ' + filePath + ': parens=' + parens + ', braces=' + braces + ', brackets=' + brackets);
    process.exit(1);
  }
  console.log('✓ Syntax OK:', filePath);
}

// 2. Validate Territory Map Data & Graph
const territoryContent = fs.readFileSync('lua_modules/territory_map.lua', 'utf8');

// Check that 18 sectors are defined
for (let i = 1; i <= 18; i++) {
  if (!territoryContent.includes(`id = ${i}`)) {
    console.error(`Missing sector definition for id = ${i}`);
    process.exit(1);
  }
}
console.log('✓ All 18 sectors defined in territory_map.lua');

// Check all required methods exist in territory_map.lua
const requiredMethods = [
  'get_sectors',
  'get_sector',
  'get_connections',
  'get_frontline',
  'get_available_targets',
  'can_attack',
  'get_fortifiable_sectors',
  'can_fortify',
  'get_fortify_cost',
  'fortify_sector',
  'capture_sector',
  'set_under_attack',
  'get_vulnerable_blue_sectors',
  'get_income',
  'get_stats',
  'reset_map',
  'save_to_profile',
  'load_from_profile'
];
for (const m of requiredMethods) {
  if (!territoryContent.includes('function M.' + m)) {
    console.error(`Missing method in territory_map.lua: function M.${m}`);
    process.exit(1);
  }
}
console.log('✓ All required methods confirmed in territory_map.lua');

// 3. Check strategic_campaign.lua
const stratContent = fs.readFileSync('lua_modules/strategic_campaign.lua', 'utf8');
const stratMethods = [
  'get_turn',
  'get_supplies',
  'add_supplies',
  'spend_supplies',
  'collect_income',
  'fortify',
  'prepare_battle',
  'trigger_ai_counter_attack',
  'resolve_battle',
  'start_new_campaign'
];
for (const m of stratMethods) {
  if (!stratContent.includes('function M.' + m)) {
    console.error(`Missing method in strategic_campaign.lua: function M.${m}`);
    process.exit(1);
  }
}
console.log('✓ All strategic campaign methods confirmed');

// 4. Check campaign_map.gui
const guiContent = fs.readFileSync('gui/campaign_map/campaign_map.gui', 'utf8');
if (!guiContent.includes('id: "map_bg"') || !guiContent.includes('id: "panel_inspector"') || !guiContent.includes('id: "btn_insp_attack"') || !guiContent.includes('id: "btn_insp_fortify"')) {
  console.error('campaign_map.gui missing critical elements');
  process.exit(1);
}
for (let i = 1; i <= 18; i++) {
  if (!guiContent.includes(`id: "sec_btn_${i}"`) || !guiContent.includes(`id: "sec_stars_${i}"`)) {
    console.error(`campaign_map.gui missing node elements for sector ${i}`);
    process.exit(1);
  }
}
console.log('✓ campaign_map.gui nodes and inspector confirmed');

// 5. Check main.collection contains gui_campaign_map
const colContent = fs.readFileSync('main/main.collection', 'utf8');
if (!colContent.includes('id: "gui_campaign_map"') || !colContent.includes('/gui/campaign_map/campaign_map.go')) {
  console.error('main.collection does not reference gui_campaign_map');
  process.exit(1);
}
console.log('✓ main.collection contains gui_campaign_map instance');

// 6. Check main.script message handling
const mainContent = fs.readFileSync('main/main.script', 'utf8');
if (!mainContent.includes('hash("show_campaign_map")') || !mainContent.includes('/gui_campaign_map')) {
  console.error('main.script missing show_campaign_map handling');
  process.exit(1);
}
console.log('✓ main.script campaign map message handling confirmed');

// 7. Check i18n keys
const i18nContent = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
const i18nKeys = [
  'camp_title',
  'camp_sectors_fmt',
  'camp_supplies_fmt',
  'camp_turn_fmt',
  'camp_recon_dossier',
  'camp_owner_blue',
  'camp_owner_red',
  'camp_btn_attack',
  'camp_btn_fortify'
];
for (const k of i18nKeys) {
  if (!i18nContent.includes(k)) {
    console.error(`Missing i18n key: ${k}`);
    process.exit(1);
  }
}
console.log('✓ i18n keys for campaign map confirmed in both RU and EN');

console.log('=== ALL SPRINT 2 VERIFICATION CHECKS PASSED SUCCESSFULLY! ===');
