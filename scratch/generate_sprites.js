const fs = require('fs');
const path = require('path');
const { PixelCanvas } = require('./png_helper');

const OUT_DIR = path.join(__dirname, '..', 'main', 'assets');

const hex = (hexStr, a = 255) => {
  const clean = hexStr.replace('#', '');
  const r = parseInt(clean.substring(0, 2), 16);
  const g = parseInt(clean.substring(2, 4), 16);
  const b = parseInt(clean.substring(4, 6), 16);
  return [r, g, b, a];
};

// ==========================================
// 1. UI BOX PANEL (32x32) - Clean 9-Slice UI Box
// ==========================================
function generateUIBox() {
  const cv = new PixelCanvas(32, 32);
  const white = [255, 255, 255, 255];
  const borderLight = [255, 255, 255, 240];
  const cornerAntiAlias1 = [255, 255, 255, 180];
  const cornerAntiAlias2 = [255, 255, 255, 80];

  // Fill rounded rectangle with 4px corner radius
  for (let y = 0; y < 32; y++) {
    for (let x = 0; x < 32; x++) {
      // Corner distances for r=4
      let dx = 0, dy = 0;
      if (x < 4) dx = 4 - x;
      else if (x >= 28) dx = x - 27;

      if (y < 4) dy = 4 - y;
      else if (y >= 28) dy = y - 27;

      if (dx > 0 && dy > 0) {
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist <= 3.2) {
          cv.setPixel(x, y, ...white);
        } else if (dist <= 4.0) {
          cv.setPixel(x, y, ...cornerAntiAlias1);
        } else if (dist <= 4.8) {
          cv.setPixel(x, y, ...cornerAntiAlias2);
        }
      } else {
        cv.setPixel(x, y, ...white);
      }
    }
  }
  return cv;
}

// ==========================================
// 2. COMPACT BEETLE CRATE (20x20)
// ==========================================
function generateBeetleCrate() {
  const cv = new PixelCanvas(20, 20);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    // Metal frame
    'g': hex('#27272A'),
    's': hex('#52525B'),
    'S': hex('#A1A1AA'),
    'w': hex('#E4E4E7'),
    // Colorado Beetle hazard stripes
    'Y': hex('#FACC15'),
    'y': hex('#CA8A04'),
    'B': hex('#18181B'),
    'b': hex('#27272A'),
    // Warning Bug Emblem
    'R': hex('#DC2626'),
    'H': hex('#F87171')
  };

  const matrix = [
    "....oooooooooooo....", // 0
    "..oosswwwwwwwwssoo..", // 1 (Top reinforced bevel)
    ".osSssssssssssssSso.", // 2
    ".oswBByyBByyBByywso.", // 3 (Compact neat stripes)
    "oswrBBYYBBYYBBYrwso.", // 4
    "oswrBBYYBBYYBBYrwso.", // 5
    "oswrBBYYBBYYBBYrwso.", // 6
    "oswrBBooRRoYBBYrwso.", // 7 (Mini red bug emblem)
    "oswrBBoRHHRoBBYrwso.", // 8
    "oswrBBoRHHRoBBYrwso.", // 9
    "oswrBBooRRoYBBYrwso.", // 10
    "oswrBBYYBBYYBBYrwso.", // 11
    "oswrBBYYBBYYBBYrwso.", // 12
    "oswrBBYYBBYYBBYrwso.", // 13
    "oswrBByyBByyBByrwso.", // 14
    ".osSssssssssssssSso.", // 15
    "..oosggggggggggssoo.", // 16
    "....oooooooooooo....", // 17
    "....................", // 18
    "...................."  // 19
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 3. COLORADO BEETLE MINION (16x16)
// ==========================================
function generateBeetleMinion() {
  const cv = new PixelCanvas(16, 16);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#0F172A'), // outline
    // Head & legs
    'b': hex('#1E293B'),
    'B': hex('#334155'),
    'r': hex('#DC2626'), // red head shield
    'R': hex('#EF4444'),
    // Striped Shell
    'Y': hex('#FACC15'), // yellow stripes
    'y': hex('#CA8A04'),
    'K': hex('#0F172A'), // black stripes
    // Eyes
    'w': hex('#FFFFFF'),
    'W': hex('#FFFFFF')
  };

  const matrix = [
    "................", // 0
    ".....o.oo.o.....", // 1 (Antennae)
    ".....o.oo.o.....", // 2
    "....oorRRroo....", // 3 (Red head with shiny black spots)
    "....orwRRwro....", // 4 (Eyes)
    "...ooKKKKKKoo...", // 5 (Wing case starts)
    "..obKYYKYKYKbo..", // 6 (Iconic Colorado beetle 10-striped shell)
    ".obbKYYKYKYKkbo.", // 7 (Tiny walking legs)
    ".obbKYYKYKYKkbo.", // 8
    "..obKyyKyKykbo..", // 9
    "...ooKKKKKKoo...", // 10
    "....obboobbo....", // 11 (Rear legs)
    "....o..oo..o....", // 12
    "................", // 13
    "................", // 14
    "................"  // 15
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 4. POTATO ROCKET (28x14) - For Masher Bazooka
// ==========================================
function generateMasherRocket() {
  const cv = new PixelCanvas(28, 14);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    // Metal Nosecone / Masher tip
    'g': hex('#374151'),
    's': hex('#6B7280'),
    'S': hex('#9CA3AF'),
    'w': hex('#E5E7EB'),
    'W': hex('#FFFFFF'),
    // Potato Warhead Body
    'd': hex('#78350F'),
    'm': hex('#B45309'),
    'l': hex('#D97706'),
    'h': hex('#FBBF24'),
    'H': hex('#FDE68A'),
    // Stabilizer Fins
    'F': hex('#DC2626'),
    'f': hex('#991B1B'),
    // Rocket Thruster & Fire exhaust
    'r': hex('#EA580C'),
    'y': hex('#FACC15'),
    'e': hex('#FFFFFF')
  };

  // Points to the RIGHT (angle 0)
  const matrix = [
    "............................", // 0
    ".....oo.....................", // 1 (Top fin)
    "....oFfo....................", // 2
    "...oFFfo.ooooooooooo........", // 3
    ".yroFFfoohhllllmmddossswwoo.", // 4 (Masher rocket nosecone)
    "eyrooooodHhhllllmmddssWWWSoo", // 5 (Razor tip)
    "eyyroooddHHHHhhllmmddssWWsso", // 6
    "eyrooooodHhhllllmmddssWWWSoo", // 7
    ".yroFFfoohhllllmmddossswwoo.", // 8
    "...oFFfo.ooooooooooo........", // 9
    "....oFfo....................", // 10 (Bottom fin)
    ".....oo.....................", // 11
    "............................", // 12
    "............................"  // 13
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 5. SKEWER DART (24x8) - For Skewer Sniper Rifle
// ==========================================
function generateSkewerDart() {
  const cv = new PixelCanvas(24, 8);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    // Bamboo/wood shaft
    'd': hex('#78350F'),
    'm': hex('#B45309'),
    'l': hex('#D97706'),
    'h': hex('#FDE68A'),
    // Stainless steel needle tip
    's': hex('#71717A'),
    'S': hex('#A1A1AA'),
    'w': hex('#E4E4E7'),
    'W': hex('#FFFFFF'),
    // Tail fletching / flight feathers
    'F': hex('#2563EB'),
    'f': hex('#1D4ED8')
  };

  const matrix = [
    "...oo...................", // 0 (Top feather)
    "..oFfooooooooooooooooooo", // 1 (Stainless steel needle)
    ".oFFfddllllmmmSSSSSSSSSW", // 2 (Razor point)
    ".oFFfdhhhhllllsssssssssW", // 3
    "..oFfooooooooooooooooooo", // 4
    "...oo...................", // 5 (Bottom feather)
    "........................", // 6
    "........................"  // 7
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 6. FRENCH FRY BULLET (16x8) - For Fry Assault Rifle
// ==========================================
function generateFryBullet() {
  const cv = new PixelCanvas(16, 8);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#451A03'), // dark fry crust
    'd': hex('#92400E'),
    'm': hex('#B45309'),
    'f': hex('#D97706'), // golden fry
    'F': hex('#FBBF24'), // bright crispy fry
    'k': hex('#FEF08A'), // salted highlight
    'w': hex('#FFFFFF'), // salt crystal glint
    // Speed / steam trail
    's': hex('#FDE047', 180),
    't': hex('#FFFFFF', 200)
  };

  const matrix = [
    "................", // 0
    "....oooooooooooo", // 1
    ".stodkFFFFFFFFFF", // 2 (Crispy French Fry bullet)
    "sstodkFFFFFFwwFF", // 3
    ".stodmffffffffff", // 4
    "....oooooooooooo", // 5
    "................", // 6
    "................"  // 7
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 7. POTATO CHIP SHARD (14x12) - For Kitchen Grater Shotgun
// ==========================================
function generatePotatoChip() {
  const cv = new PixelCanvas(14, 12);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#451A03'),
    'd': hex('#92400E'),
    'm': hex('#B45309'),
    'c': hex('#D97706'),
    'C': hex('#FBBF24'), // crispy golden chip
    'k': hex('#FDE68A'), // chip highlight
    'W': hex('#FFFFFF')  // crunch glint
  };

  const matrix = [
    "....ooooo.....", // 0
    "...okCCCCoo...", // 1
    "..okCCCCCCCoo.", // 2 (Curved razor potato chip shard)
    ".okCCCCWCCCCco", // 3
    ".oCCCCCCCkCCCco", // 4
    "oCCCCCCCCCCCCco", // 5
    "odcccccccccccco", // 6
    ".odddddddddddo.", // 7
    "..oodddddddoo.", // 8
    "....ooooooo...", // 9
    "..............", // 10
    ".............."  // 11
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 8. DRILL MISSILE (24x10) - For Ground Drill
// ==========================================
function generateDrillMissile() {
  const cv = new PixelCanvas(24, 10);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'),
    'g': hex('#27272A'),
    's': hex('#52525B'),
    'S': hex('#A1A1AA'),
    'w': hex('#E4E4E7'),
    'W': hex('#FFFFFF'),
    // Spark glow
    'C': hex('#38BDF8'),
    'Y': hex('#FACC15')
  };

  const matrix = [
    "........................", // 0
    "....ooooooooooooooooo...", // 1
    "..oosswSsswSsswSssswWoo.", // 2 (Spiral steel drilling threads)
    ".osswswSswswSswswSsswWWo", // 3 (Ultra hard drill bit tip)
    ".osSWWWsSWWWsSWWWsssswWo", // 4
    ".osgggggggggggggggggwoo.", // 5
    "..ooooooooooooooooooo...", // 6
    "........................", // 7
    "........................", // 8
    "........................"  // 9
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 9. PEPPER BOMB (20x20) - For Chili Pepper Weapon
// ==========================================
function generatePepperBomb() {
  const cv = new PixelCanvas(20, 20);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'),
    // Burning fuse
    'F': hex('#EF4444'),
    'Y': hex('#FDE047'),
    'W': hex('#FFFFFF'),
    'c': hex('#78350F'),
    // Green stem
    'G': hex('#15803D'),
    'g': hex('#22C55E'),
    // Red Chili Pepper Bulb
    'd': hex('#7F1D1D'),
    'm': hex('#991B1B'),
    'r': hex('#DC2626'),
    'R': hex('#EF4444'),
    'H': hex('#FCA5A5'),
    's': hex('#FFFFFF')
  };

  const matrix = [
    "........YFW.........", // 0 (Spark)
    ".......c............", // 1 (Fuse)
    "......ogGo..........", // 2 (Stem)
    ".....oggGgo.........", // 3
    "....oRRRmmddo.......", // 4 (Hot chili bomb body)
    "...oRHRRRmmddo......", // 5
    "..oRHsRRRRmmddo.....", // 6
    "..oRRRRRRRmmddo.....", // 7
    "..oRRRRRRRmmddo.....", // 8
    "...oRRRRRRmmddo.....", // 9
    "....oRRRRmmddo......", // 10
    ".....oRRmmddo.......", // 11
    "......ommddo........", // 12
    ".......omdo.........", // 13 (Curved chili tip)
    "........oo..........", // 14
    "....................", // 15
    "....................", // 16
    "....................", // 17
    "....................", // 18
    "...................."  // 19
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 10. GARLIC BOMB (20x22) - For Garlic Dynamite
// ==========================================
function generateGarlicBomb() {
  const cv = new PixelCanvas(20, 22);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'),
    // Fuse
    'F': hex('#EF4444'),
    'Y': hex('#FDE047'),
    'W': hex('#FFFFFF'),
    'c': hex('#78350F'),
    // Red dynamite stick
    'R': hex('#DC2626'),
    'r': hex('#991B1B'),
    'K': hex('#F87171'),
    // White Garlic Bulb
    'd': hex('#64748B'),
    'm': hex('#94A3B8'),
    'l': hex('#CBD5E1'),
    'h': hex('#F1F5F9'),
    'w': hex('#FFFFFF'),
    'p': hex('#B45309') // roots
  };

  const matrix = [
    ".........YFW........", // 0
    "........c...........", // 1
    ".......oo...........", // 2
    "......oKKro.........", // 3 (Dynamite cap strapped to garlic)
    ".....oKKKRRro.......", // 4
    ".....oKKKRRro.......", // 5
    "....ohhhhllllldo....", // 6 (Garlic cloves)
    "...ohwwhhhllllmdo...", // 7
    "..ohwwwhhhlhllmmdo..", // 8
    "..ohwwhhhhlhllmmdo..", // 9
    "..ohhhhhhhlhllmmdo..", // 10
    "...ohhhhhhlhllmdo...", // 11
    "....ohhhhhllllmdo...", // 12
    ".....olllllmmmdo....", // 13
    "......odddddddo.....", // 14
    ".......oppppo.......", // 15 (Garlic root whiskers)
    "........oooo........", // 16
    "....................", // 17
    "....................", // 18
    "....................", // 19
    "....................", // 20
    "...................."  // 21
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 11. AIR BOMB (24x16) - Aerial Potato Bomb
// ==========================================
function generateAirBomb() {
  const cv = new PixelCanvas(24, 16);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'),
    // Heavy iron body & yellow hazard stripe
    'g': hex('#1F2937'),
    's': hex('#374151'),
    'S': hex('#6B7280'),
    'w': hex('#9CA3AF'),
    'Y': hex('#FACC15'),
    'y': hex('#CA8A04'),
    'F': hex('#DC2626') // tail fins
  };

  const matrix = [
    "........................", // 0
    "....oo..................", // 1 (Tail fin)
    "...oFFo.................", // 2
    "..oFFFFoooooooooo.......", // 3
    ".osswwwssssssssssswoo...", // 4
    "osssYYYYsssssssssssswo..", // 5 (Stout heavy aerial bomb)
    "osssYYYYssssssssssssswo.", // 6
    "osssyyyyggggggggggggggo.", // 7
    "osssyyyyggggggggggggggo.", // 8
    "osssYYYYgggggggggggggwo.", // 9
    ".osswwwggggggggggggwoo..", // 10
    "..oFFFFoooooooooo.......", // 11
    "...oFFo.................", // 12 (Tail fin)
    "....oo..................", // 13
    "........................", // 14
    "........................"  // 15
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// Generate files!
console.log('Generating updated & dedicated projectile sprites...');

// 1. Restore clean UI box.png
const uiBox = generateUIBox();
uiBox.savePNG(path.join(OUT_DIR, 'box.png'));

// 2. Beetle crate & minion
const beetleCrate = generateBeetleCrate();
beetleCrate.savePNG(path.join(OUT_DIR, 'beetle_crate.png'));

const beetleMinion = generateBeetleMinion();
beetleMinion.savePNG(path.join(OUT_DIR, 'beetle_minion.png'));

// 3. Dedicated Projectiles
const rocket = generateMasherRocket();
rocket.savePNG(path.join(OUT_DIR, 'masher_rocket.png'));

const skewerDart = generateSkewerDart();
skewerDart.savePNG(path.join(OUT_DIR, 'skewer_dart.png'));

const fryBullet = generateFryBullet();
fryBullet.savePNG(path.join(OUT_DIR, 'fry_bullet.png'));

const potatoChip = generatePotatoChip();
potatoChip.savePNG(path.join(OUT_DIR, 'potato_chip.png'));

const drillMissile = generateDrillMissile();
drillMissile.savePNG(path.join(OUT_DIR, 'drill_missile.png'));

const pepperBomb = generatePepperBomb();
pepperBomb.savePNG(path.join(OUT_DIR, 'pepper_bomb.png'));

const garlicBomb = generateGarlicBomb();
garlicBomb.savePNG(path.join(OUT_DIR, 'garlic_bomb.png'));

const airBomb = generateAirBomb();
airBomb.savePNG(path.join(OUT_DIR, 'air_bomb.png'));

console.log('All dedicated projectiles and UI box successfully generated!');
