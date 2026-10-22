// Test write_terrain_pixel on flat terrain
const w = 960;
const h = 270;
const scale = 2.0;

// Flat ground: gy up to 80 is 1, above 80 is 0
const grid = new Uint8Array(w * h);
for (let gx = 0; gx < w; gx++) {
    for (let gy = 0; gy <= 80; gy++) {
        grid[gy * w + gx + 1] = 1;
    }
}

let solidCount = 0;
let transparentCount = 0;
let nonZeroColorCount = 0;

for (let gy = 0; gy < h; gy++) {
    const row = gy * w;
    for (let gx = 0; gx < w; gx++) {
        const solid = (grid[row + gx + 1] === 1);
        if (solid) {
            solidCount++;
            // Calculate depth
            let depth = 20;
            for (let d = 1; d <= 20; d++) {
                const above_y = gy + d;
                if (above_y >= h || grid[above_y * w + gx + 1] === 0) {
                    depth = d - 1;
                    break;
                }
            }
            const is_cliff_side = (gx > 0 && grid[row + gx] === 0) || (gx < w - 1 && grid[row + gx + 2] === 0);
            
            let r = 44, g = 34, b = 26;
            if (is_cliff_side && depth > 0) {
                r = 44; g = 34; b = 26;
            } else if (depth === 0) {
                r = 58; g = 168; b = 35;
            } else if (depth <= 4) {
                r = 48; g = 145; b = 28;
            }
            if (r > 0 || g > 0 || b > 0) {
                nonZeroColorCount++;
            }
        } else {
            transparentCount++;
        }
    }
}

console.log({ solidCount, transparentCount, nonZeroColorCount });
