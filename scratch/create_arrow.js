const { PixelCanvas } = require('./png_helper');
const path = require('path');

// 32x32 clean white arrow pointing right (default orientation: 0 deg points Right)
// Base shaft and arrowhead pointing right: (x increases to the right)
const canvas = new PixelCanvas(32, 32);

// Draw clean, stylish arrow pointing right (along +X axis):
// Shaft: from x=4 to x=18, y=13..18 (thickness 6px)
// Arrowhead: triangular head pointing at (28, 15.5)
const W = 32, H = 32;

// Draw shaft
for (let y = 13; y <= 18; y++) {
  for (let x = 4; x <= 18; x++) {
    canvas.setPixel(x, y, 255, 255, 255, 255);
  }
}

// Draw triangle head
// Tip at x = 28, y = 15.5
// Base of triangle at x = 18, y from 6 to 25
for (let x = 18; x <= 28; x++) {
  const progress = (x - 18) / (28 - 18); // 0 to 1
  const halfHeight = (1 - progress) * 10;
  const minY = Math.round(15.5 - halfHeight);
  const maxY = Math.round(15.5 + halfHeight);
  for (let y = minY; y <= maxY; y++) {
    canvas.setPixel(x, y, 255, 255, 255, 255);
  }
}

// Add anti-aliasing / soft outline on border
canvas.savePNG(path.join(__dirname, '../main/assets/arrow.png'));
console.log('arrow.png created successfully!');
