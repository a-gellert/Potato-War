// scratch/test_lobby.js - test lua logic mocking for lobby settings
const fs = require('fs');

console.log('Testing lobby configuration integration logic...');

// Check gui definition
const guiContent = fs.readFileSync('gui/main_menu/main_menu.gui', 'utf8');
const requiredNodes = [
  'lobby_overlay', 'lobby_title', 'lbl_count', 'btn_cnt_1', 'btn_cnt_4',
  'lbl_opponent', 'btn_opp_bot', 'btn_opp_human',
  'lbl_skin_blue', 'btn_skin_blue_prev', 'btn_skin_blue_next',
  'lbl_skin_red', 'btn_skin_red_prev', 'btn_skin_red_next',
  'lbl_biome', 'btn_biome_prev', 'btn_biome_next',
  'lbl_relief', 'btn_relief_prev', 'btn_relief_next',
  'btn_lobby_start', 'btn_lobby_back'
];

for (const nodeId of requiredNodes) {
  if (!guiContent.includes(`id: "${nodeId}"`)) {
    console.error(`MISSING GUI NODE: ${nodeId}`);
    process.exit(1);
  }
}

console.log('ALL REQUIRED LOBBY GUI NODES FOUND!');
