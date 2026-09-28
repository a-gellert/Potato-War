const fs = require('fs');
const path = require('path');

function getPngSize(filePath) {
  const buf = fs.readFileSync(filePath);
  if (buf.length > 24 && buf.toString('ascii', 12, 16) === 'IHDR') {
    const width = buf.readUInt32BE(16);
    const height = buf.readUInt32BE(20);
    return { width, height, size: buf.length };
  }
  return { size: buf.length };
}

const dir = path.join(__dirname, '..', 'main', 'assets');
fs.readdirSync(dir).forEach(file => {
  if (file.endsWith('.png')) {
    const p = path.join(dir, file);
    console.log(file.padEnd(22), JSON.stringify(getPngSize(p)));
  }
});
