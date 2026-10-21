const fs = require('fs');

const files = [
  'gui/main_menu/main_menu.gui',
  'gui/campaign_map/campaign_map.gui',
  'gui/game_over/game_over.gui',
  'gui/hud/hud.gui'
];

for (const f of files) {
  let content = fs.readFileSync(f, 'utf8');
  if (content.includes('font: "/main/assets/game.font"')) {
    content = content.replace('font: "/main/assets/game.font"', 'font: "/druid/fonts/druid_text_bold.font"');
    fs.writeFileSync(f, content, 'utf8');
    console.log('Restored font in', f);
  } else {
    console.log('Already had correct font:', f);
  }
}
