const fs = require('fs');

const guiFiles = [
  { gui: 'gui/main_menu/main_menu.gui', script: 'gui/main_menu/main_menu.gui_script' },
  { gui: 'gui/hud/hud.gui', script: 'gui/hud/hud.gui_script' },
  { gui: 'gui/game_over/game_over.gui', script: 'gui/game_over/game_over.gui_script' },
  { gui: 'gui/campaign_map/campaign_map.gui', script: 'gui/campaign_map/campaign_map.gui_script' }
];

for (const { gui, script } of guiFiles) {
  console.log('\n=== Checking', gui, '===');
  const gContent = fs.readFileSync(gui, 'utf8');
  const sContent = fs.readFileSync(script, 'utf8');
  
  const nodeBlocks = gContent.split(/nodes\s*\{/);
  const unhandled = [];
  
  for (const block of nodeBlocks) {
    if (block.includes('type: TYPE_TEXT')) {
      const idM = block.match(/id:\s*"([^"]+)"/);
      const textM = block.match(/text:\s*"([^"]*)"/);
      if (idM) {
        const id = idM[1];
        const defaultText = textM ? textM[1] : '';
        // Check if id is directly mentioned
        let matched = sContent.includes(`"${id}"`) || sContent.includes(`'${id}'`);
        // Check dynamic prefixes like sec_lbl_1..18, b_slot_title_1..4
        if (!matched) {
          const prefixM = id.match(/^(.*?)_?\d+$/);
          if (prefixM) {
            const prefix = prefixM[1];
            if (sContent.includes(`"${prefix}_"`) || sContent.includes(`'${prefix}_'`) ||
                sContent.includes(`"${prefix}"`) || sContent.includes(`'${prefix}'`)) {
              matched = true;
            }
          }
        }
        // Symbols / numbers / math are okay
        if (!matched && (defaultText === '' || /^[0-9\s★✕►◄💀\-\+\%\:\.\/]+$/.test(defaultText))) {
          matched = true;
        }
        if (!matched) {
          unhandled.push({ id, defaultText });
        }
      }
    }
  }
  
  if (unhandled.length === 0) {
    console.log('  ✅ ALL text nodes are dynamically or statically updated in script!');
  } else {
    for (const u of unhandled) {
      console.log('  ⚠️ NOT UPDATED:', u.id, '-> default text:', JSON.stringify(u.defaultText));
    }
  }
}
