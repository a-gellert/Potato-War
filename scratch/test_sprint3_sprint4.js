// scratch/test_sprint3_sprint4.js
// Verification suite for Sprint 3 (HUD & Defense Mode) and Sprint 4 (Debriefing & Polish)

const fs = require('fs');

console.log('========================================================');
console.log('RUNNING SPRINT 3 & SPRINT 4 INTEGRATION SUITE');
console.log('========================================================\n');

let testsPassed = 0;
let testsFailed = 0;

function assert(cond, desc) {
  if (cond) {
    console.log('  [PASS] ' + desc);
    testsPassed++;
  } else {
    console.error('  [FAIL] ' + desc);
    testsFailed++;
  }
}

// 1. Verify sound_manager.lua cues
console.log('1. Sound Manager Cues:');
const soundSrc = fs.readFileSync('lua_modules/sound_manager.lua', 'utf8');
assert(soundSrc.includes('function M.play_siren()'), 'sound_manager has play_siren');
assert(soundSrc.includes('function M.play_flag_captured()'), 'sound_manager has play_flag_captured');
assert(soundSrc.includes('function M.play_victory_march()'), 'sound_manager has play_victory_march');
assert(soundSrc.includes('function M.play_defeat_accent()'), 'sound_manager has play_defeat_accent');
assert(soundSrc.includes('function M.play_fortify()'), 'sound_manager has play_fortify');

// 2. Verify terrain_grid.lua defense mode fortification logic
console.log('\n2. Terrain Grid Defense Fortifications:');
const terrainSrc = fs.readFileSync('lua_modules/terrain_grid.lua', 'utf8');
assert(terrainSrc.includes('function M.apply_defense_fortifications()'), 'terrain_grid has apply_defense_fortifications');
assert(terrainSrc.includes('function M.get_defense_spawn_points(count)'), 'terrain_grid has get_defense_spawn_points');
assert(terrainSrc.includes('is_defense'), 'terrain_grid supports is_defense param in generate');

// 3. Verify main.script defense mode integration
console.log('\n3. Main Script Defense Mode & Game Over Flow:');
const mainSrc = fs.readFileSync('main/main.script', 'utf8');
assert(mainSrc.includes('local is_defense = (config and config.battle_type == "defense")'), 'main.script detects defense battle mode');
assert(mainSrc.includes('terrain_grid.get_defense_spawn_points(blue_count)'), 'Defenders spawn on high ground redoubts');
assert(mainSrc.includes('c_url = factory.create("#crate_factory", crate_pos'), 'Defensive sandbag/crate barriers spawn on parapets');
assert(mainSrc.includes('campaign_outcome = campaign_outcome'), 'main.script passes campaign_outcome to game_over_data');
assert(mainSrc.includes('strategic_campaign.resolve_battle'), 'main.script calls strategic_campaign.resolve_battle');

// 4. Verify HUD layout & script
console.log('\n4. Combat HUD Redesign:');
const hudGui = fs.readFileSync('gui/hud/hud.gui', 'utf8');
const hudScript = fs.readFileSync('gui/hud/hud.gui_script', 'utf8');
assert(hudGui.includes('id: "wind_panel"'), 'HUD contains wind_panel');
assert(hudGui.includes('id: "wind_arrow"'), 'HUD contains dynamic wind_arrow');
assert(hudGui.includes('id: "wind_val"'), 'HUD contains wind_val text');
assert(hudGui.includes('id: "phase_badge"'), 'HUD contains phase_badge');
assert(hudGui.includes('id: "txt_battle_phase"'), 'HUD contains txt_battle_phase');
assert(hudGui.includes('id: "squad_panel"'), 'HUD contains squad_panel');
assert(hudGui.includes('id: "spud_slot_1"'), 'HUD contains squad slots');
assert(hudScript.includes('update_wind_widget'), 'hud.gui_script updates dynamic wind widget');
assert(hudScript.includes('update_squad_widget'), 'hud.gui_script updates squad members widget');
assert(hudScript.includes('update_phase_widget'), 'hud.gui_script updates assault/defense phase widget');

// 5. Verify Military Debriefing GUI & Script
console.log('\n5. Military Debriefing (game_over):');
const goGui = fs.readFileSync('gui/game_over/game_over.gui', 'utf8');
const goScript = fs.readFileSync('gui/game_over/game_over.gui_script', 'utf8');
assert(goGui.includes('id: "header_badge"'), 'game_over contains military header_badge');
assert(goGui.includes('id: "debrief_banner"'), 'game_over contains debrief_banner');
assert(goGui.includes('id: "debrief_stats_bg"'), 'game_over contains debrief_stats_bg');
assert(goGui.includes('id: "minimap_bg"'), 'game_over contains minimap_bg');
assert(goGui.includes('id: "m_sec_pulse"'), 'game_over minimap contains active pulsing sector ring');
for (let i = 1; i <= 18; i++) {
  assert(goGui.includes('id: "m_sec_' + i + '"'), 'game_over minimap contains m_sec_' + i);
}
assert(goScript.includes('sound_manager.play_flag_captured()'), 'game_over plays flag captured fanfare');
assert(goScript.includes('sound_manager.play_victory_march()'), 'game_over plays victory march');
assert(goScript.includes('sound_manager.play_siren()'), 'game_over plays alarm siren on lost defense');
assert(goScript.includes('sound_manager.play_defeat_accent()'), 'game_over plays defeat accent');
assert(goScript.includes('show_campaign_map'), 'btn_next_level navigates back to campaign headquarters');
assert(goScript.includes('m_dot'), 'game_over animates contested sector dot on frontline minimap');

// 6. Verify i18n Debriefing Translations
console.log('\n6. Localization of Debriefing:');
const i18nSrc = fs.readFileSync('lua_modules/i18n.lua', 'utf8');
assert(i18nSrc.includes('debrief_sector_liberated'), 'i18n has debrief_sector_liberated');
assert(i18nSrc.includes('debrief_attack_repelled'), 'i18n has debrief_attack_repelled');
assert(i18nSrc.includes('debrief_sector_lost'), 'i18n has debrief_sector_lost');
assert(i18nSrc.includes('debrief_assault_failed'), 'i18n has debrief_assault_failed');
assert(i18nSrc.includes('btn_return_hq'), 'i18n has btn_return_hq');
assert(i18nSrc.includes('frontline_minimap'), 'i18n has frontline_minimap');

console.log('\n========================================================');
console.log(`RESULTS: ${testsPassed} passed, ${testsFailed} failed.`);
console.log('========================================================');
if (testsFailed > 0) process.exit(1);
