const fs = require('fs');
const path = require('path');
const { PixelCanvas } = require('./png_helper');

const OUT_DIR = path.join(__dirname, '..', 'main', 'assets');

// Helper to convert hex to RGBA
function hex(hexStr, a = 255) {
  const clean = hexStr.replace('#', '');
  const r = parseInt(clean.substring(0, 2), 16);
  const g = parseInt(clean.substring(2, 4), 16);
  const b = parseInt(clean.substring(4, 6), 16);
  return [r, g, b, a];
}

// -------------------------------------------------------------
// 1. MILITARY ARMORED UI BOX (32x32)
// Designed for 9-slice (slice9 { x: 7, y: 7, z: 7, w: 7 })
// Features: 
// - 3D steel bevel / chamfer on outer perimeter
// - 4 corner industrial rivets (заклепки) at (4,4), (27,4), (4,27), (27,27)
// - Inner recessed groove (фаска)
// - Subtle steel plate texture inside
// -------------------------------------------------------------
function generateMilitaryBox() {
  const cv = new PixelCanvas(32, 32);

  // Colors
  const cOuterBorder = hex('#121518');
  const cBevelLight  = hex('#6d7782'); // Top/Left metallic highlight
  const cBevelMid    = hex('#404750');
  const cBevelDark   = hex('#1b1f24'); // Bottom/Right steel shadow
  const cGroove      = hex('#14171a'); // Recessed chamfer groove
  const cInnerPlate  = hex('#2a3038'); // Neutral steel plate base

  // Rivet colors
  const cRivetRim    = hex('#121417');
  const cRivetLight  = hex('#94a0ac');
  const cRivetBody   = hex('#4e5762');
  const cRivetShadow = hex('#181b1f');

  // Fill base plate
  for (let y = 0; y < 32; y++) {
    for (let x = 0; x < 32; x++) {
      // Base inner plate with subtle micro-brush
      const grain = ((x * 7 + y * 13) % 5) - 2;
      const pr = Math.max(0, Math.min(255, cInnerPlate[0] + grain));
      const pg = Math.max(0, Math.min(255, cInnerPlate[1] + grain));
      const pb = Math.max(0, Math.min(255, cInnerPlate[2] + grain));
      cv.setPixel(x, y, pr, pg, pb, 255);
    }
  }

  // Draw 3D outer bevels & border
  for (let i = 0; i < 32; i++) {
    // Outer 1px dark border
    cv.setPixel(i, 0, ...cOuterBorder);
    cv.setPixel(i, 31, ...cOuterBorder);
    cv.setPixel(0, i, ...cOuterBorder);
    cv.setPixel(31, i, ...cOuterBorder);

    // Bevel layer 1 (px 1)
    cv.setPixel(i, 1, ...cBevelLight);
    cv.setPixel(1, i, ...cBevelLight);
    cv.setPixel(i, 30, ...cBevelDark);
    cv.setPixel(30, i, ...cBevelDark);

    // Bevel layer 2 (px 2)
    if (i >= 2 && i <= 29) {
      cv.setPixel(i, 2, ...cBevelMid);
      cv.setPixel(2, i, ...cBevelMid);
      cv.setPixel(i, 29, ...cBevelDark);
      cv.setPixel(29, i, ...cBevelDark);
    }

    // Inner recessed groove (px 6)
    if (i >= 6 && i <= 25) {
      cv.setPixel(i, 6, ...cGroove);
      cv.setPixel(6, i, ...cGroove);
      cv.setPixel(i, 25, ...cBevelMid);
      cv.setPixel(25, i, ...cBevelMid);
    }
  }

  // Draw 4 industrial rivets in corners
  // Corners at: (4, 4), (27, 4), (4, 27), (27, 27)
  const rivets = [
    [4, 4], [27, 4], [4, 27], [27, 27]
  ];

  rivets.forEach(([rx, ry]) => {
    // 3x3 circular rivet
    // Rim
    cv.setPixel(rx - 1, ry, ...cRivetRim);
    cv.setPixel(rx + 1, ry, ...cRivetRim);
    cv.setPixel(rx, ry - 1, ...cRivetRim);
    cv.setPixel(rx, ry + 1, ...cRivetRim);
    // Center & 3D highlight
    cv.setPixel(rx, ry, ...cRivetBody);
    cv.setPixel(rx - 1, ry - 1, ...cRivetLight); // top-left glint
    cv.setPixel(rx + 1, ry + 1, ...cRivetShadow); // bottom-right shadow
  });

  return cv;
}

// -------------------------------------------------------------
// 2. BOILING DEEP FRYER / BUBBLING HAZARD OIL (480x36)
// Features:
// - Golden boiling oil gradient (deep heated red-amber at bottom to vibrant golden surface)
// - Translucent undulating sizzling wave crests
// - Bubbling foam & boiling bubbles rising and popping
// -------------------------------------------------------------
function generateBoilingFryer() {
  const width = 480;
  const height = 36;
  const cv = new PixelCanvas(width, height);

  for (let x = 0; x < width; x++) {
    // Sizzling surface wave
    const wave1 = Math.sin(x * 0.08) * 2.0;
    const wave2 = Math.cos(x * 0.17) * 1.2;
    const wave3 = Math.sin(x * 0.35) * 0.8;
    const surfaceY = 3 + Math.floor(wave1 + wave2 + wave3);

    for (let y = 0; y < height; y++) {
      if (y < surfaceY - 1) {
        // Above surface: transparent
        cv.setPixel(x, y, 0, 0, 0, 0);
      } else if (y === surfaceY - 1 || y === surfaceY) {
        // Surface foam & sizzling crest (bright golden-white sizzle)
        const froth = ((x * 17) % 7 > 2) ? 255 : 220;
        cv.setPixel(x, y, 255, 235, 160, froth);
      } else if (y <= surfaceY + 2) {
        // Vibrant hot surface ripple (golden-amber)
        cv.setPixel(x, y, 255, 175, 35, 245);
      } else {
        // Body of boiling oil: gradient from warm golden amber to deep roasted magma red
        const t = (y - surfaceY) / (height - surfaceY);
        const r = Math.floor(245 * (1 - t * 0.45));
        const g = Math.floor(145 * (1 - t * 0.75));
        const b = Math.floor(25 * (1 - t * 0.6));
        cv.setPixel(x, y, r, g, b, 245);
      }
    }

    // Embed procedural boiling bubbles inside the oil
    if ((x * 19 + 7) % 31 === 0) {
      const bubbleY = 8 + ((x * 13) % 20);
      const r_bubble = ((x % 3) === 0) ? 2 : 1;
      cv.fillCircle(x, bubbleY, r_bubble, 255, 240, 180, 220);
      // Bubble highlight
      cv.setPixel(x, bubbleY - 1, 255, 255, 240, 255);
    }
  }

  return cv;
}

// -------------------------------------------------------------
// 3. RICH SOIL CHUNK (8x8)
// -------------------------------------------------------------
function generateDirtParticle() {
  const cv = new PixelCanvas(8, 8);
  const PAL = {
    '.': [0,0,0,0],
    'D': hex('#211914'), // Deep dark loam
    'd': hex('#33251c'), // Rich soil
    'm': hex('#473426'), // Medium earth
    'h': hex('#614833')  // Earth highlight
  };
  const matrix = [
    "..hhhh..",
    ".hmmddD.",
    "hmmddDDD",
    "hmddDDDD",
    "mddDDDDD",
    ".mdDDDD.",
    "..dDDD..",
    "........"
  ];
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      const ch = matrix[y][x];
      cv.setPixel(x, y, ...PAL[ch]);
    }
  }
  return cv;
}

// -------------------------------------------------------------
// 4. BILLOWING DENSE SMOKE (24x24)
// -------------------------------------------------------------
function generateSmokeParticle() {
  const cv = new PixelCanvas(24, 24);
  const cx = 11.5, cy = 11.5, rMax = 11;

  for (let y = 0; y < 24; y++) {
    for (let x = 0; x < 24; x++) {
      const dx = x - cx;
      const dy = y - cy;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist <= rMax) {
        const falloff = 1.0 - (dist / rMax);
        const smoothAlpha = Math.floor(255 * (falloff * falloff * (3 - 2 * falloff)));
        // Smoky charcoal to warm ash
        const shade = Math.floor(180 + falloff * 55);
        cv.setPixel(x, y, shade, shade - 8, shade - 16, smoothAlpha);
      } else {
        cv.setPixel(x, y, 0, 0, 0, 0);
      }
    }
  }
  return cv;
}

// Generate and write all files
console.log('Generating military box UI...');
const box = generateMilitaryBox();
box.savePNG(path.join(OUT_DIR, 'box.png'));

console.log('Generating boiling fryer...');
const fryer = generateBoilingFryer();
fryer.savePNG(path.join(OUT_DIR, 'water.png'));

console.log('Generating dirt particle...');
const dirt = generateDirtParticle();
dirt.savePNG(path.join(OUT_DIR, 'dirt_particle.png'));

console.log('Generating smoke particle...');
const smoke = generateSmokeParticle();
smoke.savePNG(path.join(OUT_DIR, 'smoke.png'));

console.log('ALL UPGRADED SPRITES GENERATED SUCCESSFULLY!');
