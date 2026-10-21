const assert = require('assert');

// Simulate 100x100 terrain
const w = 100;
const h = 100;
const stream = new Uint8Array(w * h * 4);

// Fill with dark soil (r=50, g=35, b=25, a=255)
for (let i = 0; i < w * h * 4; i += 4) {
    stream[i] = 50;
    stream[i + 1] = 35;
    stream[i + 2] = 25;
    stream[i + 3] = 255;
}

// Top 20 rows are grass (r=60, g=180, b=30, a=255)
for (let gy = 80; gy < 100; gy++) {
    for (let gx = 0; gx < w; gx++) {
        const idx = (gy * w + gx) * 4;
        stream[idx] = 60;
        stream[idx + 1] = 180;
        stream[idx + 2] = 30;
        stream[idx + 3] = 255;
    }
}

// Carve crater at (50, 75) with radius 15
const gcx = 50;
const gcy = 75;
const gr = 15;
const gr2 = gr * gr;
const scorch_pad = 4;
const scorch_r = gr + scorch_pad;
const scorch_r2 = scorch_r * scorch_r;

const upd_min_gx = Math.max(0, gcx - scorch_r);
const upd_max_gx = Math.min(w - 1, gcx + scorch_r);
const upd_min_gy = Math.max(0, gcy - scorch_r);
const upd_max_gy = Math.min(h - 1, gcy + scorch_r);

const sub_w = upd_max_gx - upd_min_gx + 1;
const sub_h = upd_max_gy - upd_min_gy + 1;

for (let gy = upd_min_gy; gy <= upd_max_gy; gy++) {
    const dy = gy - gcy;
    const dy2 = dy * dy;
    const row_offset = (gy * w) * 4;
    for (let gx = upd_min_gx; gx <= upd_max_gx; gx++) {
        const dx = gx - gcx;
        const dist2 = dx * dx + dy2;
        const p_idx = row_offset + gx * 4;

        if (dist2 <= gr2) {
            stream[p_idx + 0] = 0;
            stream[p_idx + 1] = 0;
            stream[p_idx + 2] = 0;
            stream[p_idx + 3] = 0;
        } else if (dist2 <= scorch_r2) {
            if (stream[p_idx + 3] > 0) {
                const edge_dist = Math.sqrt(dist2) - gr;
                let scorch = 0.20 + (edge_dist / scorch_pad) * 0.80;
                if (scorch > 1.0) scorch = 1.0;
                stream[p_idx + 0] = Math.floor(stream[p_idx + 0] * scorch);
                stream[p_idx + 1] = Math.floor(stream[p_idx + 1] * scorch);
                stream[p_idx + 2] = Math.floor(stream[p_idx + 2] * scorch);
            }
        }
    }
}

// Verification checks:
// 1. Center of explosion is transparent air
const center_idx = (gcy * w + gcx) * 4;
assert.strictEqual(stream[center_idx + 3], 0, "Center must be transparent");

// 2. Point just outside crater (dist = 16) is scorched (r < 50)
const rim_idx = (gcy * w + (gcx + 16)) * 4;
assert.ok(stream[rim_idx + 3] === 255, "Rim must be solid");
assert.ok(stream[rim_idx + 0] < 50, "Rim must be darkened/scorched");

// 3. Point outside scorch_r (dist = 22, gx = 72) is completely untouched original soil
const untouched_idx = (gcy * w + 72) * 4;
assert.strictEqual(stream[untouched_idx + 0], 50, "Untouched pixel R must be original 50");
assert.strictEqual(stream[untouched_idx + 1], 35, "Untouched pixel G must be original 35");
assert.strictEqual(stream[untouched_idx + 2], 25, "Untouched pixel B must be original 25");
assert.strictEqual(stream[untouched_idx + 3], 255, "Untouched pixel A must be 255");

// 4. Point below crater (gy = 50, gx = 50) is untouched soil, NOT grass
const below_idx = (50 * w + gcx) * 4;
assert.strictEqual(stream[below_idx + 0], 50, "Below crater must remain dark soil");
assert.strictEqual(stream[below_idx + 1], 35, "Below crater G must remain 35 (not green grass!)");

console.log("All crater simulation checks PASSED successfully!");
