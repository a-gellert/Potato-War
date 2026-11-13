// Generates the background-life silhouettes (bird flap frames, fighter and bomber planes) into
// main/assets/bg_life/. White on transparent: terrain.script tints them per biome.
// Usage: node tools/gen_bg_life.js   (no dependencies, 4x4 supersampled anti-aliasing)
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT = path.join(__dirname, '..', 'main', 'assets', 'bg_life');
fs.mkdirSync(OUT, { recursive: true });

function crc32(buf) {
  let c, crc = ~0;
  for (let n = 0; n < buf.length; n++) {
    c = (crc ^ buf[n]) & 0xff;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    crc = (crc >>> 8) ^ c;
  }
  return ~crc >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function writePng(file, w, h, alphaAt) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    for (let x = 0; x < w; x++) {
      let a = 0;
      for (let sy = 0; sy < 4; sy++) for (let sx = 0; sx < 4; sx++) {
        // PNG rows go top-down; shapes are authored with y up
        a += alphaAt(x + (sx + 0.5) / 4, h - (y + (sy + 0.5) / 4));
      }
      const o = y * (w * 4 + 1) + 1 + x * 4;
      raw[o] = raw[o + 1] = raw[o + 2] = 255;
      raw[o + 3] = Math.round(Math.min(1, a / 16) * 255);
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  fs.writeFileSync(file, Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
  ]));
  console.log('wrote', path.relative(process.cwd(), file));
}

// ---- shape helpers (return coverage 0/1 for a point) ----
const ellipse = (cx, cy, rx, ry) => (x, y) => ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1;
function poly(pts) {
  return (x, y) => {
    let inside = false;
    for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      const [xi, yi] = pts[i], [xj, yj] = pts[j];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
    return inside;
  };
}
// Thick segment whose half-width tapers from w0 to w1
function stroke(x0, y0, x1, y1, w0, w1) {
  return (x, y) => {
    const dx = x1 - x0, dy = y1 - y0;
    const t = Math.max(0, Math.min(1, ((x - x0) * dx + (y - y0) * dy) / (dx * dx + dy * dy)));
    const px = x0 + dx * t, py = y0 + dy * t;
    return Math.hypot(x - px, y - py) <= w0 + (w1 - w0) * t;
  };
}
const union = (...fs) => (x, y) => (fs.some(f => f(x, y)) ? 1 : 0);

// ---- birds: distant gull "M" silhouette, 3 flap frames ----
// [elbow lift, tip lift] relative to the body centre
const FLAP = [[5, 2.5], [1.5, 0.5], [-2.5, -5]];
FLAP.forEach(([e, t], i) => {
  const cx = 16, cy = 12;
  const wing = s => union(
    stroke(cx, cy, cx + s * 6.5, cy + e, 1.7, 1.3),
    stroke(cx + s * 6.5, cy + e, cx + s * 14.5, cy + t, 1.3, 0.35),
  );
  writePng(path.join(OUT, `bird_${i}.png`), 32, 24, union(
    ellipse(cx, cy - 0.4, 2.4, 1.9), ellipse(cx, cy + 1.2, 1.2, 1.2), wing(-1), wing(1),
  ));
});

// ---- fighter (side view, nose right) ----
writePng(path.join(OUT, 'plane_fighter.png'), 96, 32, union(
  poly([[6, 15], [20, 13.5], [58, 11], [76, 12], [85, 14], [88, 16], [85, 18], [76, 20], [58, 20.5], [20, 18], [6, 17]]),
  poly([[5, 15.5], [3, 26], [9, 26], [21, 15]]), // fin
  ellipse(13, 15.5, 9, 1.6), // stabilizer
  ellipse(52, 13.2, 17, 2.2), // wing seen edge-on
  ellipse(61, 21, 7, 3.2), // canopy
  ellipse(89.5, 16, 1.2, 10), // propeller blur
));

// ---- bomber (side view, nose right, twin engines) ----
writePng(path.join(OUT, 'plane_bomber.png'), 144, 48, union(
  poly([[6, 22], [30, 20], [100, 17], [124, 18], [136, 21], [139, 24], [136, 27], [124, 30], [100, 31], [30, 27], [6, 25]]),
  poly([[4, 23], [0, 40], [10, 40], [26, 22]]), // fin
  ellipse(16, 23.5, 14, 2.2), // stabilizer
  ellipse(80, 20, 30, 3), // wing
  ellipse(74, 17.5, 11, 4.2), ellipse(96, 17.5, 10, 4), // engine nacelles
  ellipse(86.5, 17.5, 0.9, 7), ellipse(107, 17.5, 0.9, 7), // propeller blurs
  ellipse(118, 29.5, 9, 4), // cockpit
  ellipse(52, 30.5, 5, 3), // dorsal turret
));
