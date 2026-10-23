// Hybrid-casual weapon icon generator (no deps). Usage: node icons.js <out_dir>
// Parts are signed-distance shapes in pixel coords (y down), drawn in order with a thick warm outline.
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const OUT = process.argv[2];
const SS = 5;          // supersampling
const OUTLINE = 1.7;   // outline thickness in px
const OUTLINE_COL = [0x32, 0x1d, 0x16];

// ---------- shapes ----------
const circle = (cx, cy, r) => (x, y) => Math.hypot(x - cx, y - cy) - r;
const ellipse = (cx, cy, rx, ry) => (x, y) => (Math.hypot((x - cx) / rx, (y - cy) / ry) - 1) * Math.min(rx, ry);
const rrect = (x0, y0, x1, y1, r) => {
  const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2, hx = (x1 - x0) / 2 - r, hy = (y1 - y0) / 2 - r;
  return (x, y) => {
    const dx = Math.abs(x - cx) - hx, dy = Math.abs(y - cy) - hy;
    return Math.hypot(Math.max(dx, 0), Math.max(dy, 0)) + Math.min(Math.max(dx, dy), 0) - r;
  };
};
const capsule = (ax, ay, bx, by, r) => (x, y) => {
  const px = x - ax, py = y - ay, bax = bx - ax, bay = by - ay;
  const h = Math.max(0, Math.min(1, (px * bax + py * bay) / (bax * bax + bay * bay)));
  return Math.hypot(px - bax * h, py - bay * h) - r;
};
const poly = (pts) => (x, y) => {
  let d = 1e9, s = 1;
  for (let i = 0, n = pts.length; i < n; i++) {
    const a = pts[i], b = pts[(i + 1) % n];
    const ex = b[0] - a[0], ey = b[1] - a[1], wx = x - a[0], wy = y - a[1];
    const t = Math.max(0, Math.min(1, (wx * ex + wy * ey) / (ex * ex + ey * ey)));
    const dx = wx - ex * t, dy = wy - ey * t;
    d = Math.min(d, dx * dx + dy * dy);
    const c1 = y >= a[1], c2 = y < b[1], c3 = ex * wy > ey * wx;
    if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) s = -s;
  }
  return s * Math.sqrt(d);
};

const hex = (h) => [(h >> 16) & 255, (h >> 8) & 255, h & 255];
// part helpers
const P = (sd, col, o = {}) => ({ sd, col: hex(col), ...o });
const CUT = (sd) => ({ sd, cut: true });
const D = (sd, col, o = {}) => ({ sd, col: hex(col), detail: true, ...o }); // detail: clipped to body
const SHINE = (sd, a = 0.55) => ({ sd, col: [255, 255, 255], alpha: a, detail: true, flat: true });

function bbox(part, w, h) {
  let y0 = 1e9, y1 = -1e9;
  for (let y = 0; y < h; y += 0.5) for (let x = 0; x < w; x += 0.5) if (part.sd(x, y) < 0) { y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
  return [y0, Math.max(y1, y0 + 1)];
}

function render(w, h, parts) {
  for (const p of parts) if (!p.cut && !p.flat) p.bb = bbox(p, w, h);
  const body = parts.filter(p => !p.cut && !p.detail);
  const cuts = parts.filter(p => p.cut);
  const buf = Buffer.alloc(w * h * 4);
  for (let py = 0; py < h; py++) for (let px = 0; px < w; px++) {
    let ar = 0, ag = 0, ab = 0, aa = 0;
    for (let sy = 0; sy < SS; sy++) for (let sx = 0; sx < SS; sx++) {
      const x = px + (sx + 0.5) / SS, y = py + (sy + 0.5) / SS;
      let usd = 1e9;
      for (const p of body) usd = Math.min(usd, p.sd(x, y));
      for (const c of cuts) usd = Math.max(usd, -c.sd(x, y));
      let col = null, alpha = 0;
      if (usd <= 0) {
        alpha = 1;
        let cur = null;
        for (const p of parts) {
          if (p.cut) { if (p.sd(x, y) < 0) cur = null; continue; }
          if (p.sd(x, y) >= 0) continue;
          if (p.detail && usd > 0) continue;
          let c = p.col;
          if (!p.flat) {
            const t = Math.max(0, Math.min(1, (y - p.bb[0]) / (p.bb[1] - p.bb[0])));
            const k = 1.16 - 0.34 * t;
            c = [Math.min(255, c[0] * k), Math.min(255, c[1] * k), Math.min(255, c[2] * k)];
          }
          if (p.alpha !== undefined) {
            const base = cur || OUTLINE_COL;
            cur = [base[0] + (c[0] - base[0]) * p.alpha, base[1] + (c[1] - base[1]) * p.alpha, base[2] + (c[2] - base[2]) * p.alpha];
          } else cur = c;
        }
        col = cur || OUTLINE_COL;
      } else if (usd <= OUTLINE) {
        alpha = 1; col = OUTLINE_COL;
      }
      if (alpha > 0) { ar += col[0]; ag += col[1]; ab += col[2]; aa += 1; }
    }
    const i = (py * w + px) * 4, n = SS * SS;
    if (aa > 0) {
      buf[i] = Math.round(ar / aa); buf[i + 1] = Math.round(ag / aa); buf[i + 2] = Math.round(ab / aa);
      buf[i + 3] = Math.round(255 * aa / n);
    }
  }
  return buf;
}

// ---------- PNG ----------
const crcTable = (() => { const t = []; for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
const crc32 = (b) => { let c = 0xffffffff; for (const x of b) c = crcTable[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function png(w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) { raw[y * (w * 4 + 1)] = 0; rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4); }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

// ---------- icons ----------
const ICONS = {};

// Hot potato grenade (36x42)
ICONS.grenade = [36, 42, [
  P(ellipse(18, 27, 13.5, 13.5), 0xffc24a),
  P(rrect(11, 8, 25, 15, 2.5), 0x9aa6c0),
  P(capsule(22, 8.5, 31, 13, 1.8), 0xff5b3a),
  P(circle(30.5, 5.5, 3), 0xffd23c),
  D(ellipse(12, 31, 2.4, 1.7), 0xc98532, { flat: true }),
  D(ellipse(23, 33, 2.2, 1.6), 0xc98532, { flat: true }),
  D(ellipse(20, 24, 1.8, 1.3), 0xc98532, { flat: true }),
  SHINE(ellipse(12.5, 21, 2.6, 5), 0.6),
]];

// Skewer rifle (56x24) — points right
ICONS.skewer_rifle = [56, 24, [
  P(rrect(2, 8, 18, 19, 4), 0xc27a3a),
  P(rrect(14, 9, 40, 16, 3), 0x7f8aa6),
  P(capsule(38, 12.5, 49, 12.5, 2.6), 0xb8c3dc),
  P(poly([[48, 9.5], [55, 12.5], [48, 15.5]]), 0xe9eef8),
  P(ellipse(27, 6.5, 8.5, 4), 0xffc24a),
  P(rrect(20, 14, 25, 22, 2), 0xc27a3a),
  D(circle(24, 6, 1.1), 0xc98532, { flat: true }),
  D(circle(30, 7, 1.0), 0xc98532, { flat: true }),
  SHINE(capsule(16, 10.6, 38, 10.6, 0.8), 0.5),
  SHINE(ellipse(24, 4.8, 4.5, 1), 0.7),
]];

// Assault "burst" rifle (48x26)
ICONS.rifle = [48, 26, [
  P(rrect(2, 8, 13, 18, 3), 0x8a5a34),
  P(rrect(10, 7, 34, 16, 3), 0xff8a3d),
  P(rrect(31, 9, 45, 14, 2), 0x6f7a96),
  P(rrect(19, 14, 26, 24, 2.5), 0xffd23c),
  P(rrect(14, 3.5, 24, 8, 2), 0x6f7a96),
  P(rrect(30, 15, 34, 21, 1.5), 0x8a5a34),
  SHINE(rrect(12, 8.4, 33, 10, 0.8), 0.55),
  D(circle(26, 11.5, 1.2), 0x32211a, { flat: true }),
]];

// Knife (44x44) — blade up-right
ICONS.knife = [44, 44, [
  P(capsule(8, 37, 17, 28, 3.6), 0xc27a3a),
  P(capsule(15.5, 30.5, 21, 25, 4.2), 0xffc24a),
  P(poly([[19, 24], [36, 4], [41, 6], [40, 17], [26, 31]]), 0xdfe7f7),
  D(capsule(24, 22, 37, 8, 0.9), 0xffffff, { flat: true, alpha: 0.7 }),
  D(capsule(28, 26, 39, 15, 0.7), 0x9aa6c0, { flat: true }),
]];

// Potato peeler (44x26)
ICONS.peeler = [44, 26, [
  P(capsule(7, 14, 24, 14, 4.5), 0xff8a3d),
  P(rrect(22, 4, 40, 22, 5), 0xc9d3ea),
  CUT(ellipse(32, 13, 4.2, 5.2)),
  P(poly([[34, 3], [41, 5], [38, 9]]), 0x7f8aa6),
  SHINE(capsule(8, 12.4, 22, 12.4, 0.9), 0.55),
  SHINE(ellipse(26, 8, 2.2, 1.2), 0.7),
]];

// Masher bazooka (48x24)
ICONS.masher_bazooka = [48, 24, [
  P(capsule(7, 11.5, 36, 11.5, 6.2), 0xff5b3a),
  P(rrect(34, 3.5, 44, 19.5, 3), 0x9aa6c0),
  P(circle(44, 11.5, 3.6), 0xffc24a),
  P(rrect(1.5, 6, 8, 17, 2.5), 0x7f8aa6),
  P(rrect(17, 15, 24, 23, 2.5), 0xc27a3a),
  D(rrect(15, 5, 18, 18, 1), 0xffd23c, { flat: true }),
  D(rrect(26, 5, 29, 18, 1), 0xffd23c, { flat: true }),
  SHINE(capsule(10, 8.2, 32, 8.2, 1.2), 0.55),
]];

// Grater shotgun (48x24)
ICONS.grater = [48, 24, [
  P(rrect(1.5, 8, 18, 17, 3.5), 0xc27a3a),
  P(rrect(14, 4, 46, 19, 3.5), 0xcdd6ee),
  P(rrect(26, 17, 33, 23, 2), 0xc27a3a),
  D(circle(21, 9, 1.3), 0x6f7a96, { flat: true }), D(circle(26, 9, 1.3), 0x6f7a96, { flat: true }),
  D(circle(31, 9, 1.3), 0x6f7a96, { flat: true }), D(circle(36, 9, 1.3), 0x6f7a96, { flat: true }),
  D(circle(41, 9, 1.3), 0x6f7a96, { flat: true }),
  D(circle(23.5, 14, 1.3), 0x6f7a96, { flat: true }), D(circle(28.5, 14, 1.3), 0x6f7a96, { flat: true }),
  D(circle(33.5, 14, 1.3), 0x6f7a96, { flat: true }), D(circle(38.5, 14, 1.3), 0x6f7a96, { flat: true }),
  SHINE(rrect(16, 5.2, 44, 6.6, 0.6), 0.7),
]];

// Drill missile (40x20) — points right
ICONS.drill_missile = [40, 20, [
  P(poly([[2, 2.5], [11, 5], [11, 15], [2, 17.5]]), 0xffd23c),
  P(capsule(8, 10, 29, 10, 6.5), 0xff4d4d),
  P(poly([[28, 3.5], [38.5, 10], [28, 16.5]]), 0xdfe7f7),
  D(capsule(31, 5.5, 35, 14, 0.9), 0x7f8aa6, { flat: true }),
  D(capsule(29, 7, 36, 11.5, 0.9), 0x7f8aa6, { flat: true }),
  P(circle(18, 10, 2.8), 0x9fe4ff),
  SHINE(capsule(10, 6.6, 26, 6.6, 0.9), 0.55),
]];

// Molotov (32x40)
ICONS.oil_bottle = [32, 40, [
  P(rrect(8, 17, 24, 38.5, 5.5), 0xffa63a),
  P(rrect(12.5, 8, 19.5, 19, 2.5), 0xffa63a),
  P(rrect(12, 6, 20, 10.5, 1.8), 0xfff1d0),
  P(ellipse(16, 3.8, 4.4, 3.6), 0xff6a2a),
  P(ellipse(16.5, 4.6, 2.2, 2.2), 0xffe35a),
  D(rrect(8, 25, 24, 31, 0), 0xfff1d0, { flat: true }),
  SHINE(rrect(10.5, 19.5, 12.7, 35, 1), 0.65),
]];

// Chili pepper bomb (34x36)
ICONS.pepper_bomb = [34, 36, [
  P(capsule(11.5, 13, 14.5, 23, 7.2), 0xff3b30),
  P(capsule(14.5, 23, 24, 31, 4.8), 0xff3b30),
  P(ellipse(11, 9.5, 6.4, 3.2), 0x45c24a),
  P(capsule(11, 8, 13, 3.5, 2.2), 0x45c24a),
  P(capsule(12, 5.5, 23, 3.5, 1.2), 0xffd23c),
  P(circle(25, 3.5, 2.8), 0xffb03a),
  SHINE(capsule(8.6, 14, 10.4, 22, 1.2), 0.6),
]];

// Garlic bomb (34x36)
ICONS.garlic_bomb = [34, 36, [
  P(ellipse(17, 22.5, 12.5, 11.5), 0xfff0d6),
  P(poly([[12.5, 13], [17, 3.5], [21.5, 13]]), 0xfff0d6),
  P(capsule(17, 5, 24, 3, 1.1), 0x8a5a34),
  P(circle(26, 3.5, 2.6), 0xffb03a),
  D(capsule(11.5, 14, 9.5, 28, 0.75), 0xd9bfa0, { flat: true }),
  D(capsule(17, 13, 17, 32, 0.75), 0xd9bfa0, { flat: true }),
  D(capsule(22.5, 14, 24.5, 28, 0.75), 0xd9bfa0, { flat: true }),
  P(rrect(13, 31, 21, 34, 1.5), 0xb98860),
  SHINE(ellipse(11.5, 19, 2.2, 4), 0.65),
]];

// Holy spud (24x26) — golden potato with halo and a face
ICONS.holy_spud = [24, 26, [
  P(ellipse(12, 3.6, 8, 2.4), 0xfff6a8),
  P(ellipse(12, 16, 9.4, 9.4), 0xffd23c),
  D(circle(8.8, 15, 1.2), 0x32211a, { flat: true }),
  D(circle(15.2, 15, 1.2), 0x32211a, { flat: true }),
  D(capsule(10.2, 19, 13.8, 19, 0.7), 0x32211a, { flat: true }),
  SHINE(ellipse(8, 11, 2, 3), 0.65),
]];

// Beetle crate (20x20)
ICONS.beetle_crate = [20, 20, [
  P(rrect(1.5, 1.5, 18.5, 18.5, 2.5), 0xd68f40),
  D(rrect(1.5, 6.5, 18.5, 7.8, 0), 0x9c5e22, { flat: true }),
  D(rrect(1.5, 12.2, 18.5, 13.5, 0), 0x9c5e22, { flat: true }),
  P(ellipse(10, 10, 3.6, 4.4), 0x4cd964),
  D(capsule(10, 6.2, 10, 14, 0.5), 0x1f5a2a, { flat: true }),
  SHINE(rrect(3, 2.8, 17, 3.8, 0.4), 0.55),
]];

// Air bomb (38x24) — nose right
ICONS.air_bomb = [38, 24, [
  P(poly([[2, 3], [10, 6.5], [10, 17.5], [2, 21]]), 0xffd23c),
  P(ellipse(19, 12, 14, 8.6), 0x6bcf3a),
  P(circle(32.5, 12, 3.4), 0x4ea02a),
  D(rrect(18, 0, 22, 24, 0), 0xffd23c, { flat: true }),
  D(rrect(24, 0, 26, 24, 0), 0xffd23c, { flat: true }),
  SHINE(ellipse(17, 7.2, 8, 1.6), 0.6),
]];

fs.mkdirSync(OUT, { recursive: true });
for (const [name, [w, h, parts]] of Object.entries(ICONS)) {
  fs.writeFileSync(path.join(OUT, name + '.png'), png(w, h, render(w, h, parts)));
  console.log('wrote', name, w + 'x' + h);
}

// Contact sheet (6x nearest-neighbor on a grey-green bg) for review
if (process.argv[3] === 'sheet') {
  const Z = 6, cols = 4, cell = 60 * Z / 2 * 2;
  const names = Object.keys(ICONS);
  const rows = Math.ceil(names.length / cols);
  const SW = cols * 62 * Z / 2, SH = rows * 52 * Z / 2;
  const sheet = Buffer.alloc(SW * SH * 4);
  for (let i = 0; i < SW * SH; i++) { sheet[i * 4] = 120; sheet[i * 4 + 1] = 170; sheet[i * 4 + 2] = 200; sheet[i * 4 + 3] = 255; }
  names.forEach((n, idx) => {
    const [w, h, parts] = ICONS[n];
    const buf = render(w, h, parts);
    const ox = (idx % cols) * 62 * Z / 2 + 10, oy = Math.floor(idx / cols) * 52 * Z / 2 + 10;
    for (let y = 0; y < h * Z / 2; y++) for (let x = 0; x < w * Z / 2; x++) {
      const si = (Math.floor(y / (Z / 2)) * w + Math.floor(x / (Z / 2))) * 4;
      const a = buf[si + 3] / 255; const di = ((oy + y) * SW + ox + x) * 4;
      if (a > 0) for (let c = 0; c < 3; c++) sheet[di + c] = buf[si + c] * a + sheet[di + c] * (1 - a);
    }
  });
  fs.writeFileSync('sheet.png', png(SW, SH, sheet));
}
