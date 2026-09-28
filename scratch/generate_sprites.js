const fs = require('fs');
const path = require('path');
const { PixelCanvas } = require('./png_helper');

const OUT_DIR = path.join(__dirname, '..', 'main', 'assets');

// Helper to make color arrays [r, g, b, a]
const hex = (hexStr, a = 255) => {
  const clean = hexStr.replace('#', '');
  const r = parseInt(clean.substring(0, 2), 16);
  const g = parseInt(clean.substring(2, 4), 16);
  const b = parseInt(clean.substring(4, 6), 16);
  return [r, g, b, a];
};

// ==========================================
// 1. POTATO BLUE & RED (32x32)
// ==========================================
function generatePotato(teamColor = 'blue') {
  const cv = new PixelCanvas(32, 32);

  // Palettes
  const PAL = {
    out: hex('#271406'),        // dark outline
    shadow: hex('#4A250B'),     // deep shadow
    darkSkin: hex('#8C5222'),   // dark tone
    midSkin: hex('#BA7532'),    // base skin tone
    lightSkin: hex('#DB944E'),  // light skin
    highSkin: hex('#F5BA7A'),   // bright skin highlight
    specular: hex('#FFE2B8'),   // specular light
    spot: hex('#5C2E0C'),       // potato spots
    blush: hex('#E57373', 130), // rosy cheek
    
    // Eyes
    eyeWhite: hex('#FFFFFF'),
    eyeShade: hex('#CBD5E1'),
    eyePupil: hex('#0F172A'),
    eyeGlint: hex('#FFFFFF'),
    
    // Headband colors
    bandOut: teamColor === 'blue' ? hex('#0B1C38') : hex('#3B0A0E'),
    bandDark: teamColor === 'blue' ? hex('#153E75') : hex('#7F1D1D'),
    bandMid: teamColor === 'blue' ? hex('#2563EB') : hex('#DC2626'),
    bandLight: teamColor === 'blue' ? hex('#60A5FA') : hex('#F87171'),
    bandHigh: teamColor === 'blue' ? hex('#BFDBFE') : hex('#FECACA'),
    
    // Mouth
    mouth: hex('#38180A'),
    mouthLip: hex('#A34C2B'),
    tooth: hex('#FFFFFF')
  };

  // Matrix design for 32x32 Potato
  // . = empty
  // o = out
  // S = shadow
  // d = darkSkin
  // m = midSkin
  // l = lightSkin
  // h = highSkin
  // H = specular
  // p = spot
  // B = bandOut
  // 1 = bandDark
  // 2 = bandMid
  // 3 = bandLight
  // 4 = bandHigh
  // w = eyeWhite
  // e = eyeShade
  // u = eyePupil
  // g = eyeGlint
  // M = mouth
  // T = tooth
  // b = blush

  const potatoMatrix = [
    "................................", // 0
    "................................", // 1
    "................................", // 2
    "............oooooo..............", // 3
    "..........ooHHhhhhS.............", // 4
    ".........oHHhhhhhllldo..........", // 5
    "........oHHhhhhllllllldo........", // 6
    ".......oHhhhhlllllllllddo.......", // 7
    "......oHhhhhhllllllllldddo......", // 8
    "......BBBBBBBBBBBBBBBBBBBB......", // 9 (Headband top edge)
    ".....B44333322222222111111B.....", // 10
    "....B4433333222222221111111B....", // 11
    "...B333222222222222211111111B...", // 12
    "....BBBBBBBBBBBBBBBBBBBBBBBB....", // 13 (Headband bottom edge)
    "......olllhhllooooollllddo......", // 14
    ".....olllhlllowwwoowwwlldo......", // 15 (Eyes)
    ".....olllllloouuwoouuwlddo......", // 16
    "....olllllmmoouugoouugldddo.....", // 17
    "....ollllmllllooeeooeeLdddo.....", // 18
    "....ollllmlllllpooolllddddo.....", // 19
    "....ollblllTMMMTllllllpdddo.....", // 20 (Mouth / Blush)
    "....ollllmmmoMooommmmlddddo.....", // 21
    "....ollllmmmmmmmmmmmmlddddo.....", // 22
    ".....olllllmmmmmmmmmlddddo......", // 23
    ".....olllhhlllpmmmmlddddo.......", // 24
    "......olhhhhhhlllllddddo........", // 25
    ".......olhhhhhhhldddddo.........", // 26
    "........oSSddddddddSo...........", // 27
    "..........oooooooooo............", // 28
    "................................", // 29
    "................................", // 30
    "................................"  // 31
  ];

  // Headband tails (flapping cloth ribbons on left side)
  // We'll overlay them
  const palette = {
    '.': [0,0,0,0],
    'o': PAL.out,
    'S': PAL.shadow,
    'd': PAL.darkSkin,
    'm': PAL.midSkin,
    'l': PAL.lightSkin,
    'h': PAL.highSkin,
    'H': PAL.specular,
    'p': PAL.spot,
    'B': PAL.bandOut,
    '1': PAL.bandDark,
    '2': PAL.bandMid,
    '3': PAL.bandLight,
    '4': PAL.bandHigh,
    'w': PAL.eyeWhite,
    'e': PAL.eyeShade,
    'u': PAL.eyePupil,
    'g': PAL.eyeGlint,
    'M': PAL.mouth,
    'T': PAL.tooth,
    'b': PAL.blush,
    'L': PAL.midSkin
  };

  cv.drawMatrix(0, 0, potatoMatrix, palette);

  // Add headband knot & animated flutter tails on the side
  // Knot at x=3, y=10
  const knotMatrix = [
    ".BB..",
    "B32B.",
    "B211B",
    ".BBB."
  ];
  cv.drawMatrix(2, 10, knotMatrix, {
    '.': [0,0,0,0],
    'B': PAL.bandOut,
    '1': PAL.bandDark,
    '2': PAL.bandMid,
    '3': PAL.bandLight
  });

  // Flapping ribbon 1
  const ribbon1 = [
    ".BB.....",
    "B32BB...",
    ".B212B..",
    "..B112B.",
    "...BBB.."
  ];
  cv.drawMatrix(0, 13, ribbon1, {
    '.': [0,0,0,0],
    'B': PAL.bandOut,
    '1': PAL.bandDark,
    '2': PAL.bandMid,
    '3': PAL.bandLight
  });

  // Flapping ribbon 2
  const ribbon2 = [
    "....BB..",
    "...B32B.",
    "..B322B.",
    ".B211B..",
    ".BBB...."
  ];
  cv.drawMatrix(0, 8, ribbon2, {
    '.': [0,0,0,0],
    'B': PAL.bandOut,
    '1': PAL.bandDark,
    '2': PAL.bandMid,
    '3': PAL.bandLight
  });

  // Additional cute potato spots
  cv.setPixel(10, 7, ...PAL.spot);
  cv.setPixel(11, 7, ...PAL.spot);
  cv.setPixel(24, 18, ...PAL.spot);
  cv.setPixel(25, 23, ...PAL.spot);

  // Rosy cheeks under eyes
  cv.setPixel(8, 19, ...PAL.blush);
  cv.setPixel(9, 19, ...PAL.blush);
  cv.setPixel(8, 20, ...PAL.blush);
  cv.setPixel(9, 20, ...PAL.blush);

  cv.setPixel(22, 19, ...PAL.blush);
  cv.setPixel(23, 19, ...PAL.blush);
  cv.setPixel(22, 20, ...PAL.blush);
  cv.setPixel(23, 20, ...PAL.blush);

  return cv;
}

// ==========================================
// 2. GRENADE - HOT POTATO (24x24)
// ==========================================
function generateGrenade() {
  const cv = new PixelCanvas(24, 24);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#271406'),       // outline
    'm': hex('#8C4A1D'),       // baked potato skin
    'l': hex('#B86B2C'),       // mid potato
    'h': hex('#E0964A'),       // light potato
    'H': hex('#F7C379'),       // highlight
    // Molten heat cracks & embers
    'F': hex('#FF1E00'),       // deep lava red
    'O': hex('#FF7700'),       // fiery orange
    'Y': hex('#FFEA00'),       // glowing bright yellow
    'W': hex('#FFFFFF'),       // white heat core
    // Grenade metal cap & pin
    'g': hex('#374151'),       // metal dark
    's': hex('#9CA3AF'),       // steel mid
    'S': hex('#E5E7EB'),       // steel bright
    'r': hex('#CBD5E1'),       // pin ring
    // Fuse cord
    'c': hex('#78350F'),       // cord
    'P': hex('#FDE047')        // spark spark
  };

  const matrix = [
    "...........YYW..........", // 0 (Sparks)
    "..........OYWPP.........", // 1
    "..........cco...........", // 2 (Fuse)
    "........oogssgo.........", // 3 (Metal cap & ring)
    ".......rogssssgo........", // 4
    ".......rogSssSgo........", // 5
    "......rooggggggoo.......", // 6
    ".....oHHhhhhhllldo......", // 7 (Potato body starts)
    "....oHHhhhhllOOlldo.....", // 8 (Lava cracks)
    "...oHhhhhllOFFYldddo....", // 9
    "...oHhhlhhllOYYlldddo...", // 10
    "..ohhhhllFOOYYYYlldddo..", // 11
    "..ohhhllOFFYWYYllddddo..", // 12 (Molten core)
    "..ohhhlllOOYYYlldddddo..", // 13
    "..ohhlllllOOFllddddddo..", // 14
    "...ohhllllllldddddddo...", // 15
    "...ohhhlllllddddddddo...", // 16
    "....ohhllllddddddddo....", // 17
    ".....ollllllddddddo.....", // 18
    "......oddddddddddo......", // 19
    ".......oddddddddo.......", // 20
    ".........oooooo.........", // 21
    "........................", // 22
    "........................"  // 23
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 3. MASHER BAZOOKA (32x16)
// ==========================================
function generateMasherBazooka() {
  const cv = new PixelCanvas(32, 16);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#111827'), // black outline
    'G': hex('#1F2937'), // dark steel
    'g': hex('#374151'), // gunmetal
    's': hex('#6B7280'), // steel mid
    'S': hex('#9CA3AF'), // steel light
    'w': hex('#E5E7EB'), // chrome highlight
    'W': hex('#FFFFFF'), // glint
    'd': hex('#451A03'), // dark wood stock
    'm': hex('#78350F'), // wood mid
    'l': hex('#B45309'), // wood light
    // Potato rocket tip
    'p': hex('#B86B2C'), // potato rocket head
    'P': hex('#F7C379'), // potato highlight
    // Scope lens
    'C': hex('#06B6D4'), // cyan scope
    'c': hex('#A5F3FC')  // bright cyan glint
  };

  const matrix = [
    "................................", // 0
    "............ooo.................", // 1 (Scope)
    "...........oCcCo................", // 2
    "...........ogggo................", // 3
    ".oo........ogggo............ooo.", // 4 (Masher grid disc at front)
    "odmmoooooooossssoooooooooooosWs.", // 5
    "odlllmmmmmmmssssssssssssssssswso", // 6 (Main barrel)
    "odllllmmmmmmggggggggggggggggswso", // 7
    "odllllmmmmmmGGGGGGGGGGGGGGGGswso", // 8
    "odlllmmmoooogggsGGGGGGGGGGGGoWso", // 9
    ".odmmo..ogggsogo............ooo.", // 10 (Grip & Trigger)
    "..oo....oggsogo.................", // 11
    "........ogggoo..................", // 12
    ".........ooo....................", // 13
    "................................", // 14
    "................................"  // 15
  ];

  cv.drawMatrix(0, 0, matrix, PAL);

  // Masher grid teeth detail in front (x=27..31)
  cv.setPixel(28, 4, ...PAL.w);
  cv.setPixel(30, 4, ...PAL.w);
  cv.setPixel(28, 10, ...PAL.w);
  cv.setPixel(30, 10, ...PAL.w);
  cv.setPixel(29, 6, ...PAL.W);
  cv.setPixel(29, 8, ...PAL.W);

  // Add loaded potato rocket warhead in the barrel nozzle
  cv.setPixel(26, 6, ...PAL.P);
  cv.setPixel(27, 6, ...PAL.P);
  cv.setPixel(26, 7, ...PAL.p);
  cv.setPixel(27, 7, ...PAL.p);

  return cv;
}

// ==========================================
// 4. SKEWER SNIPER RIFLE (32x14)
// ==========================================
function generateSkewerRifle() {
  const cv = new PixelCanvas(32, 14);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    'd': hex('#451A03'), // dark wood/bamboo stock
    'm': hex('#78350F'), // wood mid
    'l': hex('#B45309'), // wood light
    'h': hex('#D97706'), // wood highlight
    'g': hex('#3F3F46'), // gunmetal
    's': hex('#A1A1AA'), // steel
    'S': hex('#E4E4E7'), // bright steel
    'W': hex('#FFFFFF'), // needle glint
    // Scope
    'C': hex('#0284C7'), // scope lens
    'c': hex('#38BDF8'), // scope glint
    'K': hex('#BAE6FD')  // high glint
  };

  const matrix = [
    "..........ooooo.................", // 0 (Sniper Scope)
    ".........oCKccCo................", // 1
    ".........ogggggo................", // 2
    "..........ogggo.................", // 3
    ".oo.......ogggo.................", // 4
    "odmmooooooosssssoooooooooooooooo", // 5 (Stainless steel skewer rod)
    "odllmmmmmmmSSSSSSSSSSSSSSSSSSSSW", // 6 (Razor sharp needle tip!)
    "odllhmmmmmmsssssssssssssssssssss", // 7
    "odlmmooooggggggsssssssssssssssoo", // 8
    ".odmo...oggsgogo................", // 9 (Grip + trigger)
    "..oo....oggsogo.................", // 10
    "........ogggoo..................", // 11
    ".........ooo....................", // 12
    "................................"  // 13
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 5. POTATO PEELER (24x24)
// ==========================================
function generatePeeler() {
  const cv = new PixelCanvas(24, 24);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    'r': hex('#991B1B'), // red ergonomic handle
    'R': hex('#DC2626'), // red bright
    'H': hex('#F87171'), // red highlight
    'g': hex('#374151'), // dark steel
    's': hex('#9CA3AF'), // steel mid
    'S': hex('#E5E7EB'), // bright chrome blade
    'W': hex('#FFFFFF'), // blade razor shine
    // Potato peel curl
    'p': hex('#92400E'), // peel dark
    'y': hex('#D97706'), // peel mid
    'Y': hex('#FBBF24'), // peel bright yellow
    'k': hex('#FDE68A')  // peel highlight
  };

  const matrix = [
    "............oooo........", // 0 (Y-blade frame)
    "...........oSWWSo.......", // 1
    "..........oSW..WSo......", // 2 (Razor slit)
    ".........oSW....WSo.....", // 3
    "........oSW..kYY.WSo....", // 4 (Peel curling through!)
    ".......osSs.yYkkY.sSo...", // 5
    "......osssg.YY..Yy.gso..", // 6
    "......ogggo.yY..Yy..oo..", // 7
    ".......ooo...YyyY.......", // 8
    "........oHRRo.YY........", // 9 (Handle starts)
    ".......oHHRRRo..........", // 10
    "......oHHRRRRRo.........", // 11
    ".....oHHRRRRRRRo........", // 12
    "....oHHRRRRRRRRRo.......", // 13
    "...oHHRRRRRRRRRRRo......", // 14
    "..oHHRRRRRRRRRRRRo......", // 15
    "..oHRRRRRRRRRRRRRo......", // 16
    "...oRRRRRRRRRRRRo.......", // 17
    "....orRRRRRRRRro........", // 18
    ".....oorrrrrroo.........", // 19
    ".......oooooo...........", // 20
    "........................", // 21
    "........................", // 22
    "........................"  // 23
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 6. BOILING OIL MOLOTOV (20x24)
// ==========================================
function generateOilBottle() {
  const cv = new PixelCanvas(20, 24);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#0F172A'), // outline
    // Fire flame
    'F': hex('#DC2626'), // red flame
    'O': hex('#F97316'), // orange flame
    'Y': hex('#FDE047'), // yellow flame
    'W': hex('#FFFFFF'), // white hot core
    // Cloth rag
    'c': hex('#78716C'), // rag dark
    'C': hex('#D6D3D1'), // rag light
    // Glass bottle
    'g': hex('#1E293B'), // glass dark rim
    'G': hex('#475569'), // glass edge
    't': hex('#94A3B8'), // glass highlight
    // Boiling golden oil
    'd': hex('#92400E'), // oil deep amber
    'a': hex('#D97706'), // oil amber
    'm': hex('#F59E0B'), // bubbling golden oil
    'h': hex('#FCD34D'), // oil froth/bubble highlight
    'b': hex('#FFFBEB')  // bubble glint
  };

  const matrix = [
    "........WW..........", // 0 (Fire)
    ".......YWWY.........", // 1
    "......OYYYYO........", // 2
    "......FOYYOF........", // 3
    ".......oCCo.........", // 4 (Burning rag)
    ".......ocCo.........", // 5
    "......ogttgo........", // 6 (Bottle neck)
    "......oGttGo........", // 7
    ".....ogGttGgo.......", // 8
    "....ogGttttGgo......", // 9 (Shoulder)
    "...ogGtmhhmtGgo.....", // 10 (Boiling oil level with bubbles)
    "..ogGtmmmmmmtGgo....", // 11
    "..ogGtmahbamtGgo....", // 12 (Floating bubble)
    "..ogGtammmmatGgo....", // 13
    "..ogGtamhmatGgdo....", // 14
    "..ogGtammadatGdo....", // 15
    "..ogGtamdddatGdo....", // 16
    "..ogGtaadddaGddo....", // 17
    "...ogGddddddGdo.....", // 18
    "....ogGGGGGGgdo.....", // 19 (Bottle base)
    ".....oooooooo.......", // 20
    "....................", // 21
    "....................", // 22
    "...................."  // 23
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 7. FRENCH FRY ASSAULT RIFLE (32x16)
// ==========================================
function generateRifle() {
  const cv = new PixelCanvas(32, 16);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    'g': hex('#27272A'), // dark receiver
    's': hex('#52525B'), // gunmetal
    'S': hex('#A1A1AA'), // light steel
    'w': hex('#E4E4E7'), // metal highlight
    'W': hex('#FFFFFF'), // glint
    // Fry magazine
    'd': hex('#92400E'), // fry shadow
    'f': hex('#D97706'), // golden fry
    'F': hex('#FBBF24'), // crispy yellow fry
    'k': hex('#FEF08A'), // fry salt glint
    // Red tactical LED
    'r': hex('#EF4444'),
    'R': hex('#FCA5A5')
  };

  const matrix = [
    "................................", // 0
    "..........oRro..................", // 1 (Red dot sight)
    "..........oggo..................", // 2
    "..oo......oswo..................", // 3
    ".oswoooooosswooooooooooooooosswo", // 4 (Barrel + Muzzle brake)
    ".ossssssssssssssssssssssssssswSo", // 5
    ".ossssssssssssssssssssssssssswSo", // 6 (Receiver)
    ".osggssssssgggggggggggggggggssSo", // 7
    "..oogggggggggffkkooooooooooooooo", // 8 (Fry magazine begins!)
    "....oggggooooffFko..............", // 9
    ".....oggsogo.oFffo..............", // 10 (Curved fry magazine)
    ".....ogssogo..oFFdo.............", // 11
    "......oggooo...ofdo.............", // 12
    ".......oo.......oo..............", // 13
    "................................", // 14
    "................................"  // 15
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 8. KITCHEN GRATER SHOTGUN (28x16)
// ==========================================
function generateGrater() {
  const cv = new PixelCanvas(28, 16);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#0F172A'), // outline
    'g': hex('#334155'), // dark metal
    's': hex('#64748B'), // steel
    'S': hex('#94A3B8'), // bright steel
    'w': hex('#E2E8F0'), // chrome highlight
    'W': hex('#FFFFFF'), // shine
    // Perforations/holes
    'h': hex('#020617'), // punch hole
    'H': hex('#F8FAFC'), // punch tooth sharp edge
    // Wooden handle
    'd': hex('#451A03'),
    'm': hex('#78350F'),
    'l': hex('#B45309')
  };

  const matrix = [
    "............................", // 0
    ".....oooooooooo.............", // 1 (Grater top handle)
    "....odlllmmmmmmdo...........", // 2
    "....odlllmmmmmmdo...oooo....", // 3
    "....ooooooooooooo..ossswo...", // 4
    "..osswwwwwwwwwwwssswsswSo...", // 5 (Stainless steel body)
    ".oswhHhswwhHhswwhHhswswSo...", // 6 (Sharp grating teeth/holes)
    ".osswwwswwswwwswwswwwswso...", // 7
    ".oswhHhswwhHhswwhHhswswso...", // 8
    ".osswwwswwswwwswwswwwswso...", // 9
    ".oswhHhswwhHhswwhHhswswso...", // 10
    "..osggggggggggggggggggso....", // 11
    "...oggssogggsgooooooooo.....", // 12 (Trigger & grip)
    "....ogssoggsogo.............", // 13
    ".....ogggooo................", // 14
    "......ooo..................."  // 15
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 9. HOLY SPUD (24x26)
// ==========================================
function generateHolySpud() {
  const cv = new PixelCanvas(24, 26);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#451A03'), // outline
    // Holy Angel Halo
    'H': hex('#FEF08A'), // bright halo
    'h': hex('#FDE047'), // mid halo
    'Y': hex('#EAB308'), // halo edge
    // Cross
    'c': hex('#CA8A04'), // cross base
    'C': hex('#FACC15'), // cross mid
    'K': hex('#FEF08A'), // cross bright
    'W': hex('#FFFFFF'), // divine shine
    // Golden Potato Body
    '1': hex('#713F12'), // deepest gold shadow
    '2': hex('#A16207'), // dark gold
    '3': hex('#CA8A04'), // base gold
    '4': hex('#EAB308'), // rich gold
    '5': hex('#FACC15'), // bright gold
    '6': hex('#FDE047'), // shiny gold
    '7': hex('#FEF08A'), // highlight gold
    // Divine glint stars
    's': hex('#FFFFFF', 200)
  };

  const matrix = [
    ".......s........s.......", // 0 (Sparkles)
    "......s.HHHHHHHH.s......", // 1 (Hovering Golden Halo)
    ".....s.HhhhhhhhhH.s.....", // 2
    ".......HYYYYYYYYH.......", // 3
    "..........oKKo..........", // 4 (Holy Crucifix)
    ".........oKKKKo.........", // 5
    "..........oKKo..........", // 6
    ".........o7765o.........", // 7 (Golden Spud top)
    "........oW765432o.......", // 8
    ".......oWW7654321o......", // 9
    "......oW7765543211o.....", // 10
    ".....oW776555432111o....", // 11
    "....o776555544321111o...", // 12
    "....o765554443321111o...", // 13
    "....o655444333221111o...", // 14
    "....o654433322211111o...", // 15
    "....o543322221111111o...", // 16
    ".....o4322211111111o....", // 17
    ".....o3221111111111o....", // 18
    "......o21111111111o.....", // 19
    ".......o111111111o......", // 20
    "........ooooooooo.......", // 21
    ".......s........s.......", // 22
    "........................", // 23
    "........................", // 24
    "........................"  // 25
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 10. CHEF KNIFE (24x24)
// ==========================================
function generateKnife() {
  const cv = new PixelCanvas(24, 24);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    'd': hex('#271406'), // dark rosewood handle
    'm': hex('#54260C'), // handle mid
    'l': hex('#85421B'), // handle light
    'b': hex('#F59E0B'), // brass rivet
    'B': hex('#FDE68A'), // rivet glint
    // Steel Blade
    'g': hex('#334155'), // blade spine dark
    's': hex('#64748B'), // blade steel
    'S': hex('#94A3B8'), // blade bright
    'w': hex('#E2E8F0'), // razor edge
    'W': hex('#FFFFFF')  // mirror glint
  };

  const matrix = [
    "..................oooo..", // 0 (Blade tip)
    ".................oSWWSo.", // 1
    "................oSWWwSo.", // 2
    "...............oSWWwwso.", // 3
    "..............oSWWwwsso.", // 4
    ".............oSWWwwssgo.", // 5
    "............oSWWwwssggo.", // 6
    "...........oSWWwwssggo..", // 7
    "..........oSWWwwssggo...", // 8
    ".........oSWWwwssggo....", // 9
    "........oSWWwwssggo.....", // 10
    ".......oSWWwwssggo......", // 11
    "......oSWWwwssggo.......", // 12
    ".....osswwwssggoo.......", // 13 (Bolster)
    "....oBbbosssggo.........", // 14 (Handle with brass rivets)
    "...obBBboldmmo..........", // 15
    "..oldmmolllmdo..........", // 16
    ".oldmmoBbboldmo.........", // 17
    ".odmmo.bBBboldmo........", // 18
    "..oo..oldmmoldmo........", // 19
    ".......odmmodmo.........", // 20
    "........oooooo..........", // 21
    "........................", // 22
    "........................"  // 23
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 11. COLORADO BEETLE CRATE / BOX (32x32)
// ==========================================
function generateBox() {
  const cv = new PixelCanvas(32, 32);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    // Metal reinforced frame
    'g': hex('#27272A'),
    's': hex('#52525B'),
    'S': hex('#A1A1AA'),
    'w': hex('#E4E4E7'),
    'r': hex('#71717A'), // rivets
    // Colorado Beetle hazard stripes
    'Y': hex('#FACC15'), // vibrant yellow
    'y': hex('#CA8A04'), // dark yellow
    'B': hex('#18181B'), // black stripe
    'b': hex('#27272A'), // dark stripe
    // Biohazard / Bug icon center
    'R': hex('#DC2626'), // red warning icon
    'H': hex('#F87171')
  };

  const matrix = [
    "................................", // 0
    "ssssssssssssssssssssssssssssssss", // 1 (Top steel plate)
    "swwwwwwwwwwwwwwwwwwwwwwwwwwwwwso", // 2
    "swrsSSSSSSSSSSSSSSSSSSSSSSSSsrso", // 3
    "swoBBBBByyyyyyBBBBByyyyyyBBBbwso", // 4 (Striped hazard pattern)
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 5
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 6
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 7
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 8
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 9
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 10
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 11
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 12
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 13
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 14
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 15
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 16
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 17
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 18
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 19
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 20
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 21
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 22
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 23
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 24
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 25
    "swoBBBBBYYYYYYBBBBBYYYYYYBBBbwso", // 26
    "swoBBBBByyyyyyBBBBByyyyyyBBBbwso", // 27
    "swrsSSSSSSSSSSSSSSSSSSSSSSSSsrso", // 28
    "sgggggggggggggggggggggggggggggso", // 29
    "oooooooooooooooooooooooooooooooo", // 30
    "................................"  // 31
  ];

  cv.drawMatrix(0, 0, matrix, PAL);

  // Add beetle silhouette stamp in center
  const bug = [
    "...oo...",
    "..oRRo..",
    ".oRRRRo.",
    "oRoRRORo",
    "oRRRRRRo",
    ".oRRoRo.",
    "..oooo.."
  ];
  cv.drawMatrix(12, 12, bug, {
    '.': [0,0,0,0],
    'o': hex('#000000'),
    'R': hex('#DC2626'),
    'O': hex('#F87171')
  });

  return cv;
}

// ==========================================
// 12. TNT BARREL (32x38)
// ==========================================
function generateTntBarrel() {
  const cv = new PixelCanvas(32, 38);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#18181B'), // outline
    // Fuse & Spark
    'F': hex('#EF4444'),
    'Y': hex('#FDE047'),
    'W': hex('#FFFFFF'),
    'c': hex('#78350F'), // fuse cord
    // Wood planks
    'd': hex('#3D1A04'), // dark wood
    'm': hex('#78350F'), // wood mid
    'l': hex('#B45309'), // wood light
    'h': hex('#D97706'), // wood highlight
    // Iron Hoops
    'g': hex('#27272A'), // iron dark
    's': hex('#52525B'), // iron mid
    'S': hex('#A1A1AA'), // iron bright
    'r': hex('#E4E4E7'), // rivet
    // Red TNT Banner
    'R': hex('#B91C1C'),
    'E': hex('#EF4444'),
    't': hex('#FDE047'), // yellow TNT letters
    'T': hex('#FEF08A')
  };

  const matrix = [
    "................WW..............", // 0 (Spark)
    "...............YYFW.............", // 1
    "..............c.................", // 2 (Fuse)
    ".............c..................", // 3
    "...........ooooo................", // 4 (Lid)
    ".........ooSrrSsoo..............", // 5 (Top iron ring)
    "........osSSSSSSSSso............", // 6
    ".......ohhllllmmmmddo...........", // 7 (Upper stave swell)
    "......ohhhllllmmmmddddo.........", // 8
    ".....osrssSSSSSSSSsssrso........", // 9 (Upper iron hoop)
    ".....ossssssssssssssssso........", // 10
    "....ohhhllllmmmmmmmmddddo.......", // 11
    "....ohhRRRRRRRRRRRRRRdddo.......", // 12 (Red TNT Label!)
    "....ohhREEEEEEEEEEEERdddo.......", // 13
    "....ohhREtTTEtTTEtTTERddo.......", // 14 (TNT Letters)
    "....ohhRE.TE..TE..TE.Rddo.......", // 15
    "....ohhRE.TE..TE..TE.Rddo.......", // 16
    "....ohhRE.TE..TE..TE.Rddo.......", // 17
    "....ohhREEEEEEEEEEEERdddo.......", // 18
    "....ohhRRRRRRRRRRRRRRdddo.......", // 19
    "....ohhhllllmmmmmmmmddddo.......", // 20
    ".....osrssSSSSSSSSsssrso........", // 21 (Lower iron hoop)
    ".....ossssssssssssssssso........", // 22
    "......ohhhllllmmmmddddo.........", // 23
    ".......ohhllllmmmmddo...........", // 24
    "........osSSSSSSSSso............", // 25 (Bottom iron ring)
    ".........ooSrrSsoo..............", // 26
    "...........ooooo................", // 27
    "................................", // 28
    "................................", // 29
    "................................", // 30
    "................................", // 31
    "................................", // 32
    "................................", // 33
    "................................", // 34
    "................................", // 35
    "................................", // 36
    "................................"  // 37
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// ==========================================
// 13. TOMBSTONE (24x28)
// ==========================================
function generateTombstone() {
  const cv = new PixelCanvas(24, 28);
  const PAL = {
    '.': [0,0,0,0],
    'o': hex('#0F172A'), // outline
    'd': hex('#334155'), // stone dark
    'm': hex('#64748B'), // stone mid
    'l': hex('#94A3B8'), // stone light
    'h': hex('#CBD5E1'), // stone highlight
    'W': hex('#F1F5F9'), // bevel shine
    'k': hex('#1E293B'), // engraved text "R.I.P."
    // Sprouting potato plant!
    'G': hex('#15803D'), // leaf dark
    'g': hex('#22C55E'), // leaf mid
    'L': hex('#86EFAC'), // leaf highlight
    'p': hex('#B45309')  // baby potato root
  };

  const matrix = [
    "........oooooo..........", // 0 (Rounded tombstone top)
    "......ooWhhhhldoo.......", // 1
    ".....oWWhhhhhlllldo.....", // 2
    "....oWhhhhhhhlllllldo...", // 3
    "...oWhhhhhhhhhlllllldo..", // 4
    "..oWhhhhhhhhhhllllllldo.", // 5
    "..oWhhhhhhhhhhllllllldo.", // 6
    "..oWhhhhhhhhhhllllllldo.", // 7
    "..oWhh.k.k.k..llllllldo.", // 8 (R . I . P)
    "..oWhh.kkkkk..llllllldo.", // 9
    "..oWhh.k.k.k..llllllldo.", // 10
    "..oWhhhhhhhhhhllllllldo.", // 11
    "..oWhhhhhhhhhhllllllldo.", // 12
    "..oWhhhhhh..hhllllllldo.", // 13 (Crack in stone)
    "..oWhhhhh.d.hhllllllldo.", // 14
    "..oWhhhh.d.hhhllllllldo.", // 15
    "..oWhhhhhhhhhhllllllldo.", // 16
    "..oWhhhhhhhhhhllllllldo.", // 17
    "..oWhhhhhhhhhhllllllldo.", // 18
    "..oWhhhhhhhhhhllllllldo.", // 19
    ".ooWhhhhhhhhhhllllllldoo", // 20 (Base pedestal)
    "oWWWhhhhhhhhhhlllllllddd", // 21
    "ogggWhhhhhhhhhlllllllddo", // 22 (Green potato sprout blooming!)
    "oGLgWhhhhhhhhhlllllllddo", // 23
    ".ooGooooooooooooooooooo.", // 24
    "...p....................", // 25
    "........................", // 26
    "........................"  // 27
  ];

  cv.drawMatrix(0, 0, matrix, PAL);
  return cv;
}

// Generate all assets
console.log('Generating sprites...');

const potatoBlue = generatePotato('blue');
potatoBlue.savePNG(path.join(OUT_DIR, 'potato_blue.png'));

const potatoRed = generatePotato('red');
potatoRed.savePNG(path.join(OUT_DIR, 'potato_red.png'));

const grenade = generateGrenade();
grenade.savePNG(path.join(OUT_DIR, 'grenade.png'));

const bazooka = generateMasherBazooka();
bazooka.savePNG(path.join(OUT_DIR, 'masher_bazooka.png'));

const skewerRifle = generateSkewerRifle();
skewerRifle.savePNG(path.join(OUT_DIR, 'skewer_rifle.png'));

const peeler = generatePeeler();
peeler.savePNG(path.join(OUT_DIR, 'peeler.png'));

const oilBottle = generateOilBottle();
oilBottle.savePNG(path.join(OUT_DIR, 'oil_bottle.png'));

const rifle = generateRifle();
rifle.savePNG(path.join(OUT_DIR, 'rifle.png'));

const grater = generateGrater();
grater.savePNG(path.join(OUT_DIR, 'grater.png'));

const holySpud = generateHolySpud();
holySpud.savePNG(path.join(OUT_DIR, 'holy_spud.png'));

const knife = generateKnife();
knife.savePNG(path.join(OUT_DIR, 'knife.png'));

const box = generateBox();
box.savePNG(path.join(OUT_DIR, 'box.png'));

const tntBarrel = generateTntBarrel();
tntBarrel.savePNG(path.join(OUT_DIR, 'tnt_barrel.png'));

const tombstone = generateTombstone();
tombstone.savePNG(path.join(OUT_DIR, 'tombstone.png'));

console.log('All sprites successfully generated in main/assets!');
