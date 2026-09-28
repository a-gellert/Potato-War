const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

// CRC32 implementation for PNG chunks
function createCrcTable() {
  const table = [];
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      if (c & 1) c = 0xedb88320 ^ (c >>> 1);
      else c = c >>> 1;
    }
    table[n] = c;
  }
  return table;
}

const crcTable = createCrcTable();
function crc32(buf) {
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc = crcTable[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function makeChunk(type, data) {
  const len = data.length;
  const buf = Buffer.alloc(12 + len);
  buf.writeUInt32BE(len, 0);
  buf.write(type, 4, 4, 'ascii');
  data.copy(buf, 8);
  const typeAndData = buf.slice(4, 8 + len);
  const crcVal = crc32(typeAndData);
  buf.writeUInt32BE(crcVal, 8 + len);
  return buf;
}

class PixelCanvas {
  constructor(width, height) {
    this.width = width;
    this.height = height;
    this.data = new Uint8ClampedArray(width * height * 4); // RGBA
  }

  setPixel(x, y, r, g, b, a = 255) {
    x = Math.round(x);
    y = Math.round(y);
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return;
    const idx = (y * this.width + x) * 4;
    // Alpha blending if alpha < 255
    if (a === 255) {
      this.data[idx] = r;
      this.data[idx + 1] = g;
      this.data[idx + 2] = b;
      this.data[idx + 3] = a;
    } else if (a > 0) {
      const srcA = a / 255;
      const dstA = this.data[idx + 3] / 255;
      const outA = srcA + dstA * (1 - srcA);
      if (outA > 0) {
        this.data[idx] = Math.round((r * srcA + this.data[idx] * dstA * (1 - srcA)) / outA);
        this.data[idx + 1] = Math.round((g * srcA + this.data[idx + 1] * dstA * (1 - srcA)) / outA);
        this.data[idx + 2] = Math.round((b * srcA + this.data[idx + 2] * dstA * (1 - srcA)) / outA);
        this.data[idx + 3] = Math.round(outA * 255);
      }
    }
  }

  getPixel(x, y) {
    x = Math.round(x);
    y = Math.round(y);
    if (x < 0 || x >= this.width || y < 0 || y >= this.height) return [0, 0, 0, 0];
    const idx = (y * this.width + x) * 4;
    return [this.data[idx], this.data[idx + 1], this.data[idx + 2], this.data[idx + 3]];
  }

  fillRect(rx, ry, rw, rh, r, g, b, a = 255) {
    for (let y = ry; y < ry + rh; y++) {
      for (let x = rx; x < rx + rw; x++) {
        this.setPixel(x, y, r, g, b, a);
      }
    }
  }

  fillCircle(cx, cy, radius, r, g, b, a = 255) {
    const r2 = radius * radius;
    for (let y = Math.floor(cy - radius - 1); y <= Math.ceil(cy + radius + 1); y++) {
      for (let x = Math.floor(cx - radius - 1); x <= Math.ceil(cx + radius + 1); x++) {
        const dx = x - cx;
        const dy = y - cy;
        const dist2 = dx * dx + dy * dy;
        if (dist2 <= r2) {
          this.setPixel(x, y, r, g, b, a);
        }
      }
    }
  }

  fillEllipse(cx, cy, rx, ry, r, g, b, a = 255) {
    for (let y = Math.floor(cy - ry - 1); y <= Math.ceil(cy + ry + 1); y++) {
      for (let x = Math.floor(cx - rx - 1); x <= Math.ceil(cx + rx + 1); x++) {
        const dx = (x - cx) / rx;
        const dy = (y - cy) / ry;
        if (dx * dx + dy * dy <= 1.0) {
          this.setPixel(x, y, r, g, b, a);
        }
      }
    }
  }

  drawLine(x0, y0, x1, y1, r, g, b, a = 255) {
    x0 = Math.round(x0); y0 = Math.round(y0);
    x1 = Math.round(x1); y1 = Math.round(y1);
    const dx = Math.abs(x1 - x0);
    const dy = Math.abs(y1 - y0);
    const sx = (x0 < x1) ? 1 : -1;
    const sy = (y0 < y1) ? 1 : -1;
    let err = dx - dy;

    while (true) {
      this.setPixel(x0, y0, r, g, b, a);
      if (x0 === x1 && y0 === y1) break;
      const e2 = 2 * err;
      if (e2 > -dy) { err -= dy; x0 += sx; }
      if (e2 < dx) { err += dx; y0 += sy; }
    }
  }

  // Draw from an ASCII matrix with palette
  drawMatrix(startX, startY, matrix, palette) {
    for (let y = 0; y < matrix.length; y++) {
      const row = matrix[y];
      for (let x = 0; x < row.length; x++) {
        const char = row[x];
        const col = palette[char];
        if (col && col[3] > 0) {
          this.setPixel(startX + x, startY + y, col[0], col[1], col[2], col[3]);
        }
      }
    }
  }

  savePNG(filePath) {
    // Signature
    const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

    // IHDR
    const ihdrData = Buffer.alloc(13);
    ihdrData.writeUInt32BE(this.width, 0);
    ihdrData.writeUInt32BE(this.height, 4);
    ihdrData[8] = 8; // bit depth
    ihdrData[9] = 6; // RGBA color type
    ihdrData[10] = 0; // compression
    ihdrData[11] = 0; // filter
    ihdrData[12] = 0; // interlace
    const ihdrChunk = makeChunk('IHDR', ihdrData);

    // IDAT
    const rowLen = 1 + this.width * 4;
    const rawData = Buffer.alloc(rowLen * this.height);
    for (let y = 0; y < this.height; y++) {
      rawData[y * rowLen] = 0; // Filter 0 (None)
      for (let x = 0; x < this.width; x++) {
        const srcIdx = (y * this.width + x) * 4;
        const dstIdx = y * rowLen + 1 + x * 4;
        rawData[dstIdx] = this.data[srcIdx];
        rawData[dstIdx + 1] = this.data[srcIdx + 1];
        rawData[dstIdx + 2] = this.data[srcIdx + 2];
        rawData[dstIdx + 3] = this.data[srcIdx + 3];
      }
    }

    const compressed = zlib.deflateSync(rawData, { level: 9 });
    const idatChunk = makeChunk('IDAT', compressed);

    // IEND
    const iendChunk = makeChunk('IEND', Buffer.alloc(0));

    const finalBuf = Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
    fs.writeFileSync(filePath, finalBuf);
  }
}

module.exports = { PixelCanvas };
