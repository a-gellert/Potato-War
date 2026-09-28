const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

function decodeRGBA(filePath) {
  const buf = fs.readFileSync(filePath);
  let pos = 8;
  let width = 0, height = 0;
  let idatChunks = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const data = buf.slice(pos + 8, pos + 8 + len);
    pos += 12 + len;
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
    } else if (type === 'IDAT') {
      idatChunks.push(data);
    }
  }
  const uncompressed = zlib.inflateSync(Buffer.concat(idatChunks));
  const pixels = [];
  const stride = width * 4 + 1;
  for (let y = 0; y < height; y++) {
    const row = [];
    const filter = uncompressed[y * stride];
    // Simple reader assuming filter 0 for rough display or reconstruct
    for (let x = 0; x < width; x++) {
      const idx = y * stride + 1 + x * 4;
      const r = uncompressed[idx], g = uncompressed[idx+1], b = uncompressed[idx+2], a = uncompressed[idx+3];
      row.push({r, g, b, a});
    }
    pixels.push(row);
  }
  return { width, height, pixels };
}

function printAscii(name) {
  const data = decodeRGBA(path.join(__dirname, '..', 'main', 'assets', name));
  console.log('=== ' + name + ' ===');
  for (let y = 0; y < data.height; y++) {
    let line = '';
    for (let x = 0; x < data.width; x++) {
      const p = data.pixels[y][x];
      if (p.a < 30) line += '  ';
      else line += '██';
    }
    console.log(line);
  }
}

printAscii('potato_blue.png');
printAscii('masher_bazooka.png');
printAscii('skewer_rifle.png');
printAscii('grenade.png');
