const fs = require('fs');
const zlib = require('zlib');

function makePng(width, height, getPixel) {
  const scanlines = Buffer.alloc(height * (1 + width * 4));
  let offset = 0;
  for (let y = 0; y < height; y++) {
    scanlines[offset++] = 0; // filter None
    for (let x = 0; x < width; x++) {
      const p = getPixel(x, y) || [0, 0, 0, 0];
      scanlines[offset++] = p[0];
      scanlines[offset++] = p[1];
      scanlines[offset++] = p[2];
      scanlines[offset++] = p[3];
    }
  }
  const idatData = zlib.deflateSync(scanlines);
  
  function crc32(buf) {
    let c = 0xffffffff;
    for (let i = 0; i < buf.length; i++) {
      c ^= buf[i];
      for (let k = 0; k < 8; k++) {
        c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
      }
    }
    return (c ^ 0xffffffff) >>> 0;
  }
  function chunk(type, data) {
    const t = Buffer.from(type, 'ascii');
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
    return Buffer.concat([len, t, data, crc]);
  }
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;
  
  return Buffer.concat([
    sig,
    chunk('IHDR', ihdr),
    chunk('IDAT', idatData),
    chunk('IEND', Buffer.alloc(0))
  ]);
}

// 1. Military Helmet (hat_helmet.png)
function drawHelmet(x, y) {
  // Dome centered at x=15.5, y=10..18
  const dx = x - 15.5;
  const dy = y - 14.0;
  // Rim at y=17..18
  if (y >= 17 && y <= 18 && Math.abs(dx) <= 10.5) {
    return [45, 60, 35, 255]; // dark rim
  }
  if (y >= 19 && y <= 20 && Math.abs(dx) <= 9.0 && (y === 20 ? (x === 8 || x === 23) : false)) {
    return [30, 40, 25, 255]; // strap
  }
  // Dome ellipse
  if (y >= 8 && y <= 16) {
    const rx = 9.5;
    const ry = 8.0;
    const norm = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry);
    if (norm <= 1.0) {
      if (dx < -3 && dy < -2) return [100, 140, 75, 255]; // highlight
      if (dx > 3 || dy > 1) return [55, 78, 40, 255]; // shadow
      return [75, 105, 55, 255]; // base army green
    }
  }
  return [0, 0, 0, 0];
}

// 2. Pirate Tricorn (hat_pirate.png)
function drawPirate(x, y) {
  const dx = x - 15.5;
  // Gold skull in center (y=11..13, x=14..17)
  if (y >= 11 && y <= 12 && Math.abs(dx) <= 1.5) {
    return [240, 240, 240, 255]; // skull
  }
  if (y === 13 && (x === 14 || x === 17)) {
    return [220, 220, 220, 255]; // crossbones
  }
  // Tricorn turned up sides (left peak around x=5..8, right peak x=23..26, center top x=14..17)
  if (y >= 6 && y <= 18) {
    // left upturn
    if (x >= 4 && x <= 8 && y >= 7 && y <= 16) {
      if (x === 4 || y === 7) return [230, 180, 40, 255]; // gold trim
      return [35, 32, 42, 255];
    }
    // right upturn
    if (x >= 23 && x <= 27 && y >= 7 && y <= 16) {
      if (x === 27 || y === 7) return [230, 180, 40, 255]; // gold trim
      return [35, 32, 42, 255];
    }
    // center crown
    if (Math.abs(dx) <= 8.5 && y >= 9 && y <= 18) {
      if (y === 18 || Math.abs(dx) >= 7.5) return [230, 180, 40, 255]; // gold trim
      return [45, 42, 54, 255];
    }
  }
  return [0, 0, 0, 0];
}

// 3. Wizard Hat (hat_wizard.png)
function drawWizard(x, y) {
  const dx = x - 15.5;
  // Wide curved brim at y=17..19
  if (y >= 17 && y <= 19 && Math.abs(dx) <= 12.0) {
    if (y === 17 && Math.abs(dx) <= 4.0) return [250, 190, 40, 255]; // gold buckle
    return [55, 30, 95, 255]; // dark purple brim
  }
  // Tall cone from y=2 to y=16
  if (y >= 3 && y <= 16) {
    // Slight tip bend towards right
    const tipX = 15.5 + (16 - y) * 0.25;
    const curDx = Math.abs(x - tipX);
    const halfWidth = 1.0 + (y - 3) * 0.55;
    if (curDx <= halfWidth) {
      if (y === 4 || y === 5) return [255, 215, 60, 255]; // gold star at tip
      if (x - tipX < -1) return [110, 60, 180, 255]; // highlight
      return [80, 42, 135, 255]; // mystic purple
    }
  }
  return [0, 0, 0, 0];
}

// 4. Sombrero (hat_sombrero.png)
function drawSombrero(x, y) {
  const dx = x - 15.5;
  // Very wide festive brim at y=16..19
  if (y >= 16 && y <= 19 && Math.abs(dx) <= 13.5) {
    if (y === 16 && Math.abs(dx) <= 12.5) return [220, 50, 50, 255]; // red ribbon edge
    if (y === 17 && Math.abs(dx) <= 11.5 && (x % 2 === 0)) return [60, 180, 75, 255]; // green zig-zag
    return [215, 170, 85, 255]; // straw gold
  }
  // High round crown at y=8..15
  if (y >= 7 && y <= 15 && Math.abs(dx) <= 5.5) {
    if (y === 15) return [220, 50, 50, 255]; // red band
    if (dx < -1) return [240, 195, 110, 255]; // highlight
    return [215, 165, 80, 255]; // straw
  }
  return [0, 0, 0, 0];
}

// 5. Ushanka (hat_ushanka.png)
function drawUshanka(x, y) {
  const dx = x - 15.5;
  // Fluffy crown y=7..15
  if (y >= 7 && y <= 16 && Math.abs(dx) <= 9.0) {
    if (y >= 10 && y <= 12 && Math.abs(dx) <= 1.5) return [225, 45, 45, 255]; // Red army star!
    if (dx < -2) return [175, 150, 125, 255]; // fur highlight
    return [135, 110, 85, 255]; // warm brown fur
  }
  // Ear flaps hanging down on sides y=16..22
  if (y >= 16 && y <= 21) {
    if (x >= 6 && x <= 9) return [120, 95, 75, 255]; // left flap
    if (x >= 22 && x <= 25) return [110, 85, 65, 255]; // right flap
  }
  return [0, 0, 0, 0];
}

// 6. Chef Toque (hat_chef.png)
function drawChef(x, y) {
  const dx = x - 15.5;
  // Base band y=16..18
  if (y >= 16 && y <= 18 && Math.abs(dx) <= 7.5) {
    return [220, 225, 235, 255];
  }
  // Puffy mushroom folds y=5..15
  if (y >= 4 && y <= 15) {
    const rx = 9.0;
    const ry = 6.0;
    const dy = y - 10.0;
    if ((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0) {
      if (x % 3 === 0 && y >= 8) return [205, 210, 220, 255]; // pleat shadow
      if (dx < -2 && dy < -1) return [255, 255, 255, 255]; // bright white
      return [240, 242, 248, 255]; // clean chef white
    }
  }
  return [0, 0, 0, 0];
}

const hats = [
  { file: 'main/assets/hat_helmet.png', fn: drawHelmet },
  { file: 'main/assets/hat_pirate.png', fn: drawPirate },
  { file: 'main/assets/hat_wizard.png', fn: drawWizard },
  { file: 'main/assets/hat_sombrero.png', fn: drawSombrero },
  { file: 'main/assets/hat_ushanka.png', fn: drawUshanka },
  { file: 'main/assets/hat_chef.png', fn: drawChef },
];

for (const h of hats) {
  const pngBuf = makePng(32, 24, h.fn);
  fs.writeFileSync(h.file, pngBuf);
  console.log('Saved', h.file, pngBuf.length, 'bytes');
}
