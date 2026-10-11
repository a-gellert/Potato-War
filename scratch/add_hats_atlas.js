const fs = require('fs');
let atlas = fs.readFileSync('main/assets/game.atlas', 'utf8');

const hats = [
  'hat_crown', 'hat_beret', 'hat_viking', 'hat_tophat', 'hat_bandana', 'hat_cap'
];

let added = 0;
hats.forEach(name => {
  const line = 'image: "/main/assets/' + name + '.png"';
  if (!atlas.includes(line)) {
    const entry = 'images {\n  ' + line + '\n  sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n}\n';
    const idx = atlas.indexOf('margin:');
    atlas = atlas.slice(0, idx) + entry + atlas.slice(idx);
    added++;
  }
});
fs.writeFileSync('main/assets/game.atlas', atlas);
console.log('Added hats to game.atlas:', added);
