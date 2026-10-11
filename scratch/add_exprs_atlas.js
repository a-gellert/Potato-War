const fs = require('fs');
let atlas = fs.readFileSync('main/assets/game.atlas', 'utf8');

const exprs = [
  'expr_idle', 'expr_happy', 'expr_aim', 'expr_hurt', 'expr_scared', 'expr_dead'
];

let added = 0;
exprs.forEach(name => {
  const line = 'image: "/main/assets/' + name + '.png"';
  if (!atlas.includes(line)) {
    const entry = 'images {\n  ' + line + '\n  sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n}\n';
    const idx = atlas.indexOf('margin:');
    atlas = atlas.slice(0, idx) + entry + atlas.slice(idx);
    added++;
  }
});
fs.writeFileSync('main/assets/game.atlas', atlas);
console.log('Added expressions to game.atlas:', added);
