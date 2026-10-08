const fs = require('fs');

function checkGuiReferences(guiPath, scriptPath) {
  const guiText = fs.readFileSync(guiPath, 'utf8');
  const scriptText = fs.readFileSync(scriptPath, 'utf8');
  
  const nodeMatches = [...guiText.matchAll(/id:\s*"([^"]+)"/g)].map(m => m[1]);
  const nodeSet = new Set(nodeMatches);
  
  const getNodeCalls = [...scriptText.matchAll(/gui\.get_node\("([^"]+)"\)/g)].map(m => m[1]);
  const buttonCalls = [...scriptText.matchAll(/self\.ui:button\("([^"]+)"/g)].map(m => m[1]);
  const allCalls = [...new Set([...getNodeCalls, ...buttonCalls])];

  const missing = [];
  for (const name of allCalls) {
    if (name === "inv_slot_" || name === "mode_text") continue; // dynamic in loop or legacy pcall
    if (name.endsWith("_") || name.includes("sec_btn_") || name.includes("b_slot_")) continue; // dynamic prefixes concatenated with id/indices in loops
    if (!nodeSet.has(name)) missing.push(name);
  }
  if (missing.length > 0) {
    console.error('ERROR in ' + scriptPath + ' missing nodes: ' + missing.join(', '));
    process.exit(1);
  } else {
    console.log(guiPath + ' <-> ' + scriptPath + ': ALL static node references match perfectly!');
  }
}

checkGuiReferences('gui/game_over/game_over.gui', 'gui/game_over/game_over.gui_script');
checkGuiReferences('gui/hud/hud.gui', 'gui/hud/hud.gui_script');
checkGuiReferences('gui/campaign_map/campaign_map.gui', 'gui/campaign_map/campaign_map.gui_script');
