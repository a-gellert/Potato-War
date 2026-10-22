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

// -----------------------------------------------------------------
// 1. Classic Worms-style Airdrop Parachute (80x80)
// Large, high-visibility dome canopy with alternating red/white stripes
// and suspension cords leading to harness.
// -----------------------------------------------------------------
function generateParachute() {
  const w = 80;
  const h = 80;
  const cv = new PixelCanvas(w, h);

  const cx = 40;
  const topY = 6;
  const canopyBottomY = 38;
  const harnessY = 74;

  const redDark = hex('#a81818');
  const redMid = hex('#e52b2b');
  const redLight = hex('#ff5a5a');

  const whiteDark = hex('#c8d0d8');
  const whiteMid = hex('#edf2f7');
  const whiteLight = hex('#ffffff');

  const outlineCol = hex('#1a1a24');
  const lineCol = hex('#3a3f4d', 230);
  const lineDark = hex('#181a20', 255);

  // 1. Draw canopy dome
  // Semi-ellipse: center at (cx, canopyBottomY), rx = 36, ry = 30
  const rx = 36;
  const ry = 30;

  for (let y = topY; y <= canopyBottomY; y++) {
    for (let x = cx - rx - 2; x <= cx + rx + 2; x++) {
      const dx = (x - cx) / rx;
      const dy = (y - canopyBottomY) / ry;
      const d2 = dx * dx + dy * dy;

      if (d2 <= 1.0 && y <= canopyBottomY) {
        // Determine segment (5 vertical gore panels: Red, White, Red, White, Red)
        // Normalized x from -1 to +1
        const u = (x - cx) / rx; // -1 to +1
        let col;
        let isRed = false;

        if (Math.abs(u) < 0.22) {
          // Center panel (Red)
          isRed = true;
        } else if (Math.abs(u) < 0.58) {
          // Inner-side panels (White)
          isRed = false;
        } else {
          // Outer panels (Red)
          isRed = true;
        }

        // Lighting / 3D sphere shading
        const light = 0.5 + 0.5 * (-dy) - 0.2 * Math.abs(u);
        if (isRed) {
          if (light > 0.75) col = redLight;
          else if (light > 0.45) col = redMid;
          else col = redDark;
        } else {
          if (light > 0.75) col = whiteLight;
          else if (light > 0.45) col = whiteMid;
          else col = whiteDark;
        }

        // Gore panel separation shadow lines
        if (Math.abs(Math.abs(u) - 0.22) < 0.03 || Math.abs(Math.abs(u) - 0.58) < 0.03) {
          col = isRed ? redDark : whiteDark;
        }

        // Scalloped bottom edge mask (4 or 5 scallop arches)
        const scallopCount = 5;
        const scallopNorm = ((u + 1) * 0.5 * scallopCount) % 1.0;
        const arch = Math.sin(scallopNorm * Math.PI) * 4.0;
        if (y > canopyBottomY - arch) {
          continue; // cut out scallop bottom
        }

        cv.setPixel(x, y, col[0], col[1], col[2], col[3]);
      }
    }
  }

  // Canopy outline and bottom hem
  for (let y = topY; y <= canopyBottomY; y++) {
    for (let x = cx - rx - 2; x <= cx + rx + 2; x++) {
      const p = cv.getPixel(x, y);
      if (p[3] > 0) {
        // check neighbors for boundary
        const up = cv.getPixel(x, y - 1);
        const dn = cv.getPixel(x, y + 1);
        const lf = cv.getPixel(x - 1, y);
        const rt = cv.getPixel(x + 1, y);
        if (up[3] === 0 || dn[3] === 0 || lf[3] === 0 || rt[3] === 0) {
          cv.setPixel(x, y, outlineCol[0], outlineCol[1], outlineCol[2], 255);
        }
      }
    }
  }

  // Suspension cords (ropes) connecting canopy ribs to attachment ring at (cx, harnessY)
  const attachmentPoints = [
    cx - 32, canopyBottomY - 1,
    cx - 18, canopyBottomY,
    cx,      canopyBottomY + 1,
    cx + 18, canopyBottomY,
    cx + 32, canopyBottomY - 1
  ];

  for (let i = 0; i < attachmentPoints.length; i += 2) {
    const ax = attachmentPoints[i];
    const ay = attachmentPoints[i + 1];
    cv.drawLine(ax, ay, cx, harnessY, lineCol[0], lineCol[1], lineCol[2], lineCol[3]);
  }

  // Small metal harness ring at bottom
  cv.fillCircle(cx, harnessY, 2.5, outlineCol[0], outlineCol[1], outlineCol[2], 255);
  cv.fillCircle(cx, harnessY, 1.2, whiteLight[0], whiteLight[1], whiteLight[2], 255);

  const outPath = path.join(OUT_DIR, 'parachute.png');
  cv.savePNG(outPath);
  console.log('Saved parachute:', outPath);
}

// -----------------------------------------------------------------
// 2. Medkit Red Cross Icon (32x32)
// White rounded badge with bold medical red cross
// -----------------------------------------------------------------
function generateMedkitCross() {
  const w = 32;
  const h = 32;
  const cv = new PixelCanvas(w, h);

  const cx = 16;
  const cy = 16;

  // 1. Soft dark shadow
  cv.fillCircle(cx, cy + 1, 13, 0, 0, 0, 90);

  // 2. Clean white circle base with subtle bevel
  cv.fillCircle(cx, cy, 13, 220, 225, 230, 255);
  cv.fillCircle(cx, cy - 0.5, 12, 255, 255, 255, 255);

  // 3. Bold Red Cross
  // Vertical bar: width 6, height 18
  // Horizontal bar: width 18, height 6
  const red = [225, 30, 30, 255];
  const redHighlight = [255, 60, 60, 255];
  const redShadow = [175, 15, 15, 255];

  // Vertical bar
  cv.fillRect(cx - 3, cy - 9, 6, 18, red[0], red[1], red[2], red[3]);
  // Horizontal bar
  cv.fillRect(cx - 9, cy - 3, 18, 6, red[0], red[1], red[2], red[3]);

  // Subtle highlights and shading on the cross
  cv.fillRect(cx - 3, cy - 9, 6, 2, redHighlight[0], redHighlight[1], redHighlight[2], 255);
  cv.fillRect(cx - 9, cy - 3, 2, 6, redHighlight[0], redHighlight[1], redHighlight[2], 255);
  cv.fillRect(cx - 3, cy + 7, 6, 2, redShadow[0], redShadow[1], redShadow[2], 255);
  cv.fillRect(cx + 7, cy - 3, 2, 6, redShadow[0], redShadow[1], redShadow[2], 255);

  const outPath = path.join(OUT_DIR, 'medkit_cross.png');
  cv.savePNG(outPath);
  console.log('Saved medkit_cross:', outPath);
}

generateParachute();
generateMedkitCross();
