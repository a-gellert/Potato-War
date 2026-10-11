const fs = require('fs');
let atlas = fs.readFileSync('main/assets/game.atlas', 'utf8');

const toAdd = [
  'recruit', 'assault', 'medic', 'sapper', 'sniper', 'tank',
  'potato_tank', 'potato_tank_blue', 'potato_tank_red',
  'potato_recruit', 'potato_recruit_blue', 'potato_recruit_red'
];

let added = 0;
toAdd.forEach(name => {
  const line = 'image: "/main/assets/' + name + '.png"';
  if (!atlas.includes(line)) {
    const entry = 'images {\n  ' + line + '\n  sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n}\n';
    const idx = atlas.indexOf('margin:');
    atlas = atlas.slice(0, idx) + entry + atlas.slice(idx);
    added++;
  }
});
fs.writeFileSync('main/assets/game.atlas', atlas);
console.log('Added entries to game.atlas:', added);
