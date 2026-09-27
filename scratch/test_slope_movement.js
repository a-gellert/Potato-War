const fs = require('fs');

console.log('Testing Slope Movement & Terrain Physics Fixes...');

// Simple test grid mock matching terrain_grid.lua logic
const SCALE = 2.0;
const WIDTH = 480;
const HEIGHT = 270;
const WATER_LEVEL = 28;
const grid = new Uint8Array(WIDTH * HEIGHT);

function isSolid(wx, wy) {
    const gx = Math.floor(wx / SCALE);
    const gy = Math.floor(wy / SCALE);
    if (gx < 0 || gx >= WIDTH || gy < 0 || gy >= HEIGHT) return false;
    return grid[gy * WIDTH + gx] === 1;
}

function getGroundY(wx, fromWy) {
    const gx = Math.floor(wx / SCALE);
    if (gx < 0 || gx >= WIDTH) return WATER_LEVEL;
    let startGy = HEIGHT - 1;
    if (fromWy !== undefined) {
        startGy = Math.min(HEIGHT - 1, Math.max(0, Math.floor(fromWy / SCALE)));
    }
    // New fix logic
    if (fromWy !== undefined && isSolid(wx, startGy * SCALE)) {
        for (let gy = startGy + 1; gy < HEIGHT; gy++) {
            if (grid[gy * WIDTH + gx] === 0) {
                return gy * SCALE;
            }
        }
        return HEIGHT * SCALE;
    }
    for (let gy = startGy; gy >= 0; gy--) {
        if (grid[gy * WIDTH + gx] === 1) {
            return (gy + 1) * SCALE;
        }
    }
    return WATER_LEVEL;
}

function getSmoothGroundY(wx, radius = 4.0, fromWy) {
    const samples = 5;
    const step = (radius * 2) / (samples - 1);
    let totalY = 0, weightSum = 0;
    const weights = [1, 2, 4, 2, 1];
    for (let i = 0; i < samples; i++) {
        const sx = (wx - radius) + i * step;
        const gy = getGroundY(sx, fromWy);
        totalY += gy * weights[i];
        weightSum += weights[i];
    }
    return totalY / weightSum;
}

const mockTerrain = {
    is_solid: isSolid,
    get_smooth_ground_y: getSmoothGroundY,
    get_ground_y: getGroundY
};

// Physics constants
const POTATO_RADIUS = 12.0;
const POTATO_WALK_SPEED = 75.0;
const WORLD_WIDTH = 960.0;

function walkPotato(p, dir, dt, terrain) {
    if (!p.is_alive) return;
    p.facing = dir;
    if (!p.is_grounded) {
        p.vel.x = dir * POTATO_WALK_SPEED * 0.85;
        return;
    }

    const radius = POTATO_RADIUS;
    const speed = POTATO_WALK_SPEED;
    const MAX_CLIMB_SLOPE = 1.05;
    const MAX_STEP_UP = 3.5;

    // 1. Wall collision check
    const frontCheckX = p.pos.x + dir * (radius * 0.75);
    if (terrain.is_solid(frontCheckX, p.pos.y) || terrain.is_solid(frontCheckX, p.pos.y + 4.0)) {
        p.vel.x = 0;
        return;
    }

    // 2. Measure ground height
    const currGy = terrain.get_smooth_ground_y(p.pos.x, 4.0, p.pos.y + 8.0);
    const lookAhead = 6.0;
    const aheadX = p.pos.x + dir * lookAhead;
    const aheadGy = terrain.get_smooth_ground_y(aheadX, 4.0, p.pos.y + 8.0);
    const aheadDiff = aheadGy - currGy;

    if (aheadDiff > MAX_STEP_UP) {
        const slope = aheadDiff / lookAhead;
        if (slope > MAX_CLIMB_SLOPE) {
            p.vel.x = 0;
            return; // Blocked by steep slope/mountain!
        }
    }

    // 3. Slope speed regulation
    const slopeAngle = Math.atan2(Math.max(0, aheadDiff), lookAhead);
    const speedMult = Math.max(0.75, 1.0 - 0.25 * Math.sin(slopeAngle));
    const moveSpeed = speed * speedMult;
    const ds = moveSpeed * dt;
    const stepX = dir * ds * Math.cos(slopeAngle);
    const targetX = p.pos.x + stepX;

    if (targetX < radius || targetX > WORLD_WIDTH - radius) {
        p.vel.x = 0;
        return;
    }

    // 4. Immediate step-up check
    const targetGy = terrain.get_smooth_ground_y(targetX, 4.0, p.pos.y + 8.0);
    const stepDiff = targetGy - currGy;
    if (stepDiff > MAX_STEP_UP) {
        const localSlope = stepDiff / Math.max(0.01, Math.abs(stepX));
        if (localSlope > MAX_CLIMB_SLOPE) {
            p.vel.x = 0;
            return;
        }
    }

    // 5. Cliff / steep drop
    if ((currGy - targetGy) > 8.0) {
        p.pos.x = targetX;
        p.is_grounded = false;
        p.vel.x = dir * speed * 0.75;
        p.vel.y = -10.0;
        return;
    }

    p.pos.x = targetX;
    p.pos.y = targetGy + radius;
}

// TEST 1: Vertical Wall Block
// Setup wall from x=100 to 200, y=0 to 150. Floor at y=50.
for (let gx = 0; gx < WIDTH; gx++) {
    const wx = gx * SCALE;
    const topWy = (wx >= 100 && wx <= 200) ? 150 : 50;
    const maxGy = Math.floor(topWy / SCALE);
    for (let gy = 0; gy <= maxGy; gy++) {
        grid[gy * WIDTH + gx] = 1;
    }
}

const potato = {
    is_alive: true,
    is_grounded: true,
    pos: { x: 85, y: 50 + POTATO_RADIUS },
    vel: { x: 0, y: 0 },
    facing: 1
};

// Walk towards wall for 60 frames (1 second)
let maxPosY = potato.pos.y;
for (let f = 0; f < 60; f++) {
    walkPotato(potato, 1, 1/60, mockTerrain);
    maxPosY = Math.max(maxPosY, potato.pos.y);
}
console.log('Test 1 (Vertical Wall): Final X:', potato.pos.x.toFixed(1), 'Final Y:', potato.pos.y.toFixed(1), 'Max Y:', maxPosY.toFixed(1));
if (potato.pos.x > 95 || maxPosY > 70) {
    console.error('FAIL: Potato penetrated or teleported up vertical wall!');
    process.exit(1);
}
console.log('PASS: Potato correctly stopped at base of vertical wall without climbing or teleporting!');

// TEST 2: Steep Mountain (60 degrees)
// Create 60 degree slope: slope = tan(60) = 1.732 from x=300 to 400
grid.fill(0);
for (let gx = 0; gx < WIDTH; gx++) {
    const wx = gx * SCALE;
    let topWy = 50;
    if (wx >= 300 && wx <= 400) {
        topWy = 50 + (wx - 300) * 1.732;
    } else if (wx > 400) {
        topWy = 50 + (100) * 1.732;
    }
    const maxGy = Math.floor(topWy / SCALE);
    for (let gy = 0; gy <= maxGy; gy++) {
        grid[gy * WIDTH + gx] = 1;
    }
}

potato.pos = { x: 285, y: 50 + POTATO_RADIUS };
potato.is_grounded = true;
let startX = potato.pos.x;
for (let f = 0; f < 60; f++) {
    walkPotato(potato, 1, 1/60, mockTerrain);
}
console.log('Test 2 (60° Mountain): Final X:', potato.pos.x.toFixed(1), 'Final Y:', potato.pos.y.toFixed(1));
if (potato.pos.x > 303 || potato.pos.y > 70) {
    console.error('FAIL: Potato climbed a 60° mountain!');
    process.exit(1);
}
console.log('PASS: Potato correctly stopped at 60° mountain base without climbing or teleporting!');

// TEST 3: Walkable 30° Hill
// Create 30 degree slope: slope = tan(30) = 0.577 from x=300 to 400
grid.fill(0);
for (let gx = 0; gx < WIDTH; gx++) {
    const wx = gx * SCALE;
    let topWy = 50;
    if (wx >= 300 && wx <= 400) {
        topWy = 50 + (wx - 300) * 0.577;
    } else if (wx > 400) {
        topWy = 50 + 100 * 0.577;
    }
    const maxGy = Math.floor(topWy / SCALE);
    for (let gy = 0; gy <= maxGy; gy++) {
        grid[gy * WIDTH + gx] = 1;
    }
}

potato.pos = { x: 285, y: 50 + POTATO_RADIUS };
potato.is_grounded = true;
let prevY = potato.pos.y;
let maxSingleFrameRise = 0;
for (let f = 0; f < 60; f++) {
    walkPotato(potato, 1, 1/60, mockTerrain);
    const rise = potato.pos.y - prevY;
    maxSingleFrameRise = Math.max(maxSingleFrameRise, rise);
    prevY = potato.pos.y;
}
console.log('Test 3 (30° Walkable Hill): Final X:', potato.pos.x.toFixed(1), 'Final Y:', potato.pos.y.toFixed(1), 'Max Rise/Frame:', maxSingleFrameRise.toFixed(2));
if (potato.pos.x < 330 || maxSingleFrameRise > 2.0) {
    console.error('FAIL: Potato did not walk smoothly up 30° hill!');
    process.exit(1);
}
console.log('PASS: Potato smoothly climbed 30° hill with max rise per frame = ' + maxSingleFrameRise.toFixed(2) + 'px (no teleporting)!');

// TEST 4: Small 2.5px Voxel Curb
grid.fill(0);
for (let gx = 0; gx < WIDTH; gx++) {
    const wx = gx * SCALE;
    let topWy = (wx >= 300) ? 52.5 : 50;
    const maxGy = Math.floor(topWy / SCALE);
    for (let gy = 0; gy <= maxGy; gy++) {
        grid[gy * WIDTH + gx] = 1;
    }
}
potato.pos = { x: 290, y: 50 + POTATO_RADIUS };
potato.is_grounded = true;
for (let f = 0; f < 20; f++) {
    walkPotato(potato, 1, 1/60, mockTerrain);
}
console.log('Test 4 (Small curb): Final X:', potato.pos.x.toFixed(1), 'Final Y:', potato.pos.y.toFixed(1));
if (potato.pos.x < 305) {
    console.error('FAIL: Potato got stuck on small 2.5px curb!');
    process.exit(1);
}
console.log('PASS: Potato stepped cleanly over 2.5px voxel curb without getting stuck!');

console.log('ALL MOVEMENT & TERRAIN PHYSICS TESTS PASSED!');
