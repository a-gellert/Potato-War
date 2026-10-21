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
// 1. DEEP BOILING FRYER OIL (960x160)
// Replaces water.png with a massive boiling deep fryer pool:
// - Surface sizzling foam, bubbles, and bright golden highlights
// - Hot bubbling amber frying oil in mid-depth
// - Deep dark golden grease extending downwards (no blue void!)
// -------------------------------------------------------------
function generateBoilingFryerOil() {
  const w = 960;
  const h = 160;
  const cv = new PixelCanvas(w, h);

  // Gradient colors from surface down into deep oil
  // Note: Defold texture coordinates: y=0 is bottom, y=159 is top!
  // In PixelCanvas: y=0 is top (surface), y=159 is bottom (deep).
  for (let y = 0; y < h; y++) {
    const ny = y / h; // 0 = top surface, 1 = deep bottom
    let r, g, b;
    if (ny < 0.12) {
      // Surface sizzle line (golden yellow with bright highlights)
      const t = ny / 0.12;
      r = Math.round(255 * (1 - t) + 245 * t);
      g = Math.round(235 * (1 - t) + 175 * t);
      b = Math.round(110 * (1 - t) + 35 * t);
    } else if (ny < 0.50) {
      // Golden bubbling hot oil
      const t = (ny - 0.12) / 0.38;
      r = Math.round(245 * (1 - t) + 205 * t);
      g = Math.round(175 * (1 - t) + 115 * t);
      b = Math.round(35 * (1 - t) + 15 * t);
    } else {
      // Deep dark amber / caramelized frying grease
      const t = (ny - 0.50) / 0.50;
      r = Math.round(205 * (1 - t) + 115 * t);
      g = Math.round(115 * (1 - t) + 52 * t);
      b = Math.round(15 * (1 - t) + 8 * t);
    }

    for (let x = 0; x < w; x++) {
      cv.setPixel(x, y, r, g, b, 255);
    }
  }

  // Draw boiling surface foam and sizzling crackle (top 10 rows)
  for (let x = 0; x < w; x++) {
    const foamWave = Math.sin(x * 0.08) * 2.5 + Math.cos(x * 0.15) * 1.5;
    const foamY = Math.max(0, Math.min(8, Math.round(2 + foamWave)));
    cv.setPixel(x, foamY, 255, 250, 190, 240);
    cv.setPixel(x, foamY + 1, 255, 220, 110, 220);
    if (x % 5 === 0) {
      cv.setPixel(x, foamY + 2, 255, 245, 170, 180);
    }
  }

  // Draw scattered boiling oil bubbles with specular highlights
  const bubbleCount = 140;
  for (let i = 0; i < bubbleCount; i++) {
    const bx = Math.floor((Math.sin(i * 127.1) * 0.5 + 0.5) * w);
    const by = Math.floor(10 + (Math.cos(i * 311.7) * 0.5 + 0.5) * (h - 25));
    const br = 2 + (i % 5);

    // Darker amber bubble rim
    cv.fillCircle(bx, by, br, 145, 65, 10, 180);
    // Golden interior
    cv.fillCircle(bx, by, br - 1, 245, 185, 45, 210);
    // White/yellow specular highlight glint on top-left of bubble
    cv.setPixel(bx - 1, by - 1, 255, 255, 220, 250);
  }

  const outPath = path.join(OUT_DIR, 'water.png');
  cv.savePNG(outPath);
  console.log(`Saved deep boiling oil to ${outPath}`);
}

// -------------------------------------------------------------
// 2. SUNSET TWILIGHT SKY GRADIENT (512x512)
// Vertical gradient: Deep Twilight Slate -> Dusky Mauve -> Sunset Orange -> Golden Horizon
// -------------------------------------------------------------
function generateSkyGradient() {
  const w = 512;
  const h = 512;
  const cv = new PixelCanvas(w, h);

  for (let y = 0; y < h; y++) {
    const ny = y / h; // 0 = top of sky, 1 = horizon
    let r, g, b;

    if (ny < 0.40) {
      // Deep twilight slate to dusky mauve
      const t = ny / 0.40;
      r = Math.round(22 * (1 - t) + 85 * t);
      g = Math.round(28 * (1 - t) + 52 * t);
      b = Math.round(48 * (1 - t) + 75 * t);
    } else if (ny < 0.75) {
      // Dusky mauve to vibrant sunset amber/orange
      const t = (ny - 0.40) / 0.35;
      r = Math.round(85 * (1 - t) + 215 * t);
      g = Math.round(52 * (1 - t) + 105 * t);
      b = Math.round(75 * (1 - t) + 48 * t);
    } else {
      // Sunset orange to golden horizon glow
      const t = (ny - 0.75) / 0.25;
      r = Math.round(215 * (1 - t) + 248 * t);
      g = Math.round(105 * (1 - t) + 185 * t);
      b = Math.round(48 * (1 - t) + 78 * t);
    }

    for (let x = 0; x < w; x++) {
      cv.setPixel(x, y, r, g, b, 255);
    }
  }

  const outPath = path.join(OUT_DIR, 'bg_sky.png');
  cv.savePNG(outPath);
  console.log(`Saved sky gradient to ${outPath}`);
}

// -------------------------------------------------------------
// 3. LAYER 1: DISTANT SILHOUETTES & HORIZON (960x240)
// Features:
// - Rolling distant mountain peaks with atmospheric haze (35% darker than sky)
// - Rustic farm fence posts & distant barn silhouette
// - Giant vegetable patch / furrow ridges in the far distance
// -------------------------------------------------------------
function generateDistantLayer() {
  const w = 960;
  const h = 240;
  const cv = new PixelCanvas(w, h);

  // Background is transparent
  // Mountain baseline at y = 140 (pixel 0 is top, pixel 239 is bottom)
  for (let x = 0; x < w; x++) {
    const nx = x / w;
    // Multi-frequency mountain profile
    const m1 = Math.sin(nx * 5.2 + 0.4) * 45;
    const m2 = Math.cos(nx * 11.5 + 1.2) * 22;
    const m3 = Math.sin(nx * 22.0) * 10;
    const peakY = Math.round(135 - m1 - m2 - m3);

    // Far mountain fill (deep slate with atmospheric perspective haze, alpha 230)
    for (let y = Math.max(0, peakY); y < h; y++) {
      const depth = (y - peakY) / (h - peakY);
      // Soft haze gradient: lighter at peak, deeper blue-slate down below
      const r = Math.round(58 + depth * 14);
      const g = Math.round(48 + depth * 12);
      const b = Math.round(68 + depth * 18);
      const a = Math.round(195 + depth * 55);
      cv.setPixel(x, y, r, g, b, a);
    }
  }

  // Mid-distance ridge: Rustic fence & vegetable garden ridges (furrows)
  const barnX = 260;
  const barnW = 44;
  for (let x = 0; x < w; x++) {
    const ridgeY = Math.round(180 + Math.sin(x * 0.03) * 14 + Math.cos(x * 0.07) * 7);

    // Old barn silhouette at x=260..304
    let currentTop = ridgeY;
    if (x >= barnX && x <= barnX + barnW) {
      const bx = x - barnX;
      const roof = 24 - Math.abs(bx - barnW * 0.5) * 1.05;
      currentTop = Math.min(currentTop, Math.round(ridgeY - roof));
    }

    // Rustic fence posts every 20px
    if (x % 20 === 0 && (x < barnX - 10 || x > barnX + barnW + 10)) {
      currentTop = Math.min(currentTop, ridgeY - 12);
    } else if ((x % 20 === 5 || x % 20 === 6) && (x < barnX - 10 || x > barnX + barnW + 10)) {
      currentTop = Math.min(currentTop, ridgeY - 7); // Rail
    }

    // Overturned barrels at x=640 and x=780
    if ((x >= 640 && x <= 649) || (x >= 780 && x <= 788)) {
      currentTop = Math.min(currentTop, ridgeY - 9);
    }

    for (let y = Math.max(0, currentTop); y < h; y++) {
      const r = 44;
      const g = 38;
      const b = 52;
      const a = 245;
      cv.setPixel(x, y, r, g, b, a);
    }
  }

  const outPath = path.join(OUT_DIR, 'bg_distant.png');
  cv.savePNG(outPath);
  console.log(`Saved distant parallax layer to ${outPath}`);
}

// -------------------------------------------------------------
// 4. LAYER 2: MID-GROUND FLOATING ISLANDS (960x240)
// Semi-transparent blurred floating potato islands in the sky:
// - Organic floating earth masses with hanging roots and soft green crowns
// - Subtle depth-of-field soft atmospheric haze (alpha 140..190)
// -------------------------------------------------------------
function generateIslandsLayer() {
  const w = 960;
  const h = 240;
  const cv = new PixelCanvas(w, h);

  // Define 4 floating islands: { cx, cy, rx, ry, seed }
  const islands = [
    { cx: 160, cy: 95,  rx: 75, ry: 32 },
    { cx: 440, cy: 65,  rx: 60, ry: 26 },
    { cx: 720, cy: 110, rx: 85, ry: 36 },
    { cx: 910, cy: 75,  rx: 50, ry: 22 }
  ];

  for (const isl of islands) {
    const minX = Math.max(0, Math.floor(isl.cx - isl.rx * 1.3));
    const maxX = Math.min(w - 1, Math.ceil(isl.cx + isl.rx * 1.3));
    const minY = Math.max(0, Math.floor(isl.cy - isl.ry * 1.5));
    const maxY = Math.min(h - 1, Math.ceil(isl.cy + isl.ry * 2.2));

    for (let y = minY; y <= maxY; y++) {
      const dy = y - isl.cy;
      for (let x = minX; x <= maxX; x++) {
        const dx = x - isl.cx;
        // Asymmetric island profile: flatter top, tapering jagged bottom with hanging roots
        const normX = dx / isl.rx;
        let effectiveRy = isl.ry;
        if (dy > 0) {
          // Bottom underbelly: rough and tapering with root bumps
          const rootBump = Math.sin(dx * 0.25) * 5 + Math.cos(dx * 0.45) * 3;
          effectiveRy = isl.ry * 1.25 + rootBump;
        }

        const normY = dy / effectiveRy;
        const dist2 = normX * normX + normY * normY;

        if (dist2 <= 1.0) {
          // Inside floating island
          if (dy < -isl.ry * 0.25) {
            // Lush turf crest (soft emerald moss / grass with DoF haze)
            cv.setPixel(x, y, 78, 142, 68, 175);
          } else if (dy < 0) {
            // Humus soil transition
            cv.setPixel(x, y, 92, 85, 72, 170);
          } else {
            // Rocky underbelly / roots
            const rootStrand = (Math.sin(dx * 0.5 + dy * 0.3) > 0.4);
            if (rootStrand) {
              cv.setPixel(x, y, 82, 65, 52, 180); // Root fiber
            } else {
              cv.setPixel(x, y, 68, 62, 58, 165); // Dark slate loam
            }
          }
        }
      }
    }
  }

  const outPath = path.join(OUT_DIR, 'bg_islands.png');
  cv.savePNG(outPath);
  console.log(`Saved mid-ground islands layer to ${outPath}`);
}

// -------------------------------------------------------------
// 5. COMPACT TACTICAL HP FRAME (48x12)
// Fits potato shoulder width:
// - Dark metallic frame with 1px rounded border
// - 3 vertical segment notch dividers at 25%, 50%, 75%
// -------------------------------------------------------------
function generateHpFrame() {
  const w = 48;
  const h = 12;
  const cv = new PixelCanvas(w, h);

  const cBorder = hex('#18202c'); // Steel dark outer border
  const cBevel  = hex('#3c4a5c'); // 1px metallic highlight
  const cBack   = hex('#0c1017'); // Dark recessed cavity
  const cTick   = hex('#263242'); // 25 HP segment tick marks

  // Fill outer border with corner rounding
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      // Round 4 corners (1px)
      if ((x === 0 || x === w - 1) && (y === 0 || y === h - 1)) {
        continue;
      }
      cv.setPixel(x, y, ...cBorder);
    }
  }

  // Draw 1px inner metallic highlight on top & left
  for (let x = 1; x < w - 1; x++) {
    cv.setPixel(x, 1, ...cBevel);
  }
  for (let y = 1; y < h - 1; y++) {
    cv.setPixel(1, y, ...cBevel);
  }

  // Draw inner cavity for the HP fill
  for (let y = 2; y < h - 1; y++) {
    for (let x = 2; x < w - 1; x++) {
      cv.setPixel(x, y, ...cBack);
    }
  }

  // Draw 3 segment dividers at 25% (x=13), 50% (x=24), 75% (x=35)
  const ticks = [13, 24, 35];
  for (const tx of ticks) {
    for (let y = 1; y < h - 1; y++) {
      cv.setPixel(tx, y, ...cTick);
    }
  }

  const outPath = path.join(OUT_DIR, 'hp_frame.png');
  cv.savePNG(outPath);
  console.log(`Saved compact tactical HP frame to ${outPath}`);
}

// -------------------------------------------------------------
// 6. ATMOSPHERIC WIND SPORE / DANDELION SEED (10x10)
// Feathered tuft with a tiny seed core that drifts with wind
// -------------------------------------------------------------
function generateWindSpore() {
  const size = 10;
  const cv = new PixelCanvas(size, size);

  // Tiny dark seed at bottom center (4, 7)
  cv.setPixel(4, 7, 75, 55, 35, 240);
  cv.setPixel(5, 7, 65, 45, 25, 240);
  cv.setPixel(4, 8, 55, 38, 20, 220);

  // Stem
  cv.setPixel(4, 6, 185, 175, 155, 200);
  cv.setPixel(5, 5, 205, 195, 175, 210);

  // Feathered radial tuft rays
  cv.fillCircle(5, 3, 2.5, 255, 252, 240, 195);
  cv.setPixel(2, 2, 255, 255, 255, 160);
  cv.setPixel(7, 2, 255, 255, 255, 160);
  cv.setPixel(1, 4, 255, 250, 230, 150);
  cv.setPixel(8, 4, 255, 250, 230, 150);
  cv.setPixel(5, 1, 255, 255, 255, 180);

  const outPath = path.join(OUT_DIR, 'spore.png');
  cv.savePNG(outPath);
  console.log(`Saved wind spore particle to ${outPath}`);
}

// Execute all generators
generateBoilingFryerOil();
generateSkyGradient();
generateDistantLayer();
generateIslandsLayer();
generateHpFrame();
generateWindSpore();

console.log("\nALL PARALLAX & HUD ASSETS GENERATED SUCCESSFULLY!");
