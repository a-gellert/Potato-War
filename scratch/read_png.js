const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

function decodePNG(filePath) {
  const buf = fs.readFileSync(filePath);
  let pos = 8;
  let width = 0, height = 0, bitDepth = 0, colorType = 0;
  let idatChunks = [];
  
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const data = buf.slice(pos + 8, pos + 8 + len);
    pos += 12 + len;
    
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
    } else if (type === 'IDAT') {
      idatChunks.push(data);
    }
  }
  
  const idat = Buffer.concat(idatChunks);
  const uncompressed = zlib.inflateSync(idat);
  return { width, height, bitDepth, colorType, uncompressed };
}

['potato_blue.png', 'potato_red.png', 'masher_bazooka.png', 'grenade.png'].forEach(file => {
  const p = path.join(__dirname, '..', 'main', 'assets', file);
  const dec = decodePNG(p);
  console.log(file, dec.width, 'x', dec.height, 'uncompressed len:', dec.uncompressed.length);
});
