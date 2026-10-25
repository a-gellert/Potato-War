// scratch/test_narrow_pit_sim.js
// Simulates a potato falling into a narrow pit/crevice to ensure it settles and never falls through terrain.

const SCALE = 2.0;
const WIDTH = 960;
const HEIGHT = 480;
const WATER_LEVEL = 28;
const POTATO_RADIUS = 15.0;
const GRAVITY = 460.0;
const MAX_FALL_SPEED = 600.0;

const grid = new Uint8Array(WIDTH * HEIGHT);

// Fill solid terrain up to y = 150 (gy = 75)
for (let gx = 0; gx < WIDTH; gx++) {
    for (let gy = 0; gy <= 75; gy++) {
        grid[gy * WIDTH + gx] = 1;
    }
}

// Carve a narrow vertical pit around wx = 400 (gx = 200)
// Width: 18 world pixels (9 cells, from gx = 196 to 204)
// Depth: down to y = 60 (gy = 30)
for (let gx = 196; gx <= 204; gx++) {
    for (let gy = 31; gy <= 75; gy++) {
        grid[gy * WIDTH + gx] = 0; // air in the pit
    }
}
// Pit bottom at gx = 200 is gy = 30 (y = 62)

function is_solid(wx, wy) {
    const gx = Math.floor(wx / SCALE);
    const gy = Math.floor(wy / SCALE);
    if (gx < 0 || gx >= WIDTH || gy < 0 || gy >= HEIGHT) return false;
    return grid[gy * WIDTH + gx] === 1;
}

function get_ground_y(wx, from_wy) {
    const gx = Math.floor(wx / SCALE);
    if (gx < 0 || gx >= WIDTH) return WATER_LEVEL;
    let start_gy = HEIGHT - 1;
    if (from_wy !== undefined) {
        start_gy = Math.min(HEIGHT - 1, Math.max(0, Math.floor(from_wy / SCALE)));
    }

    if (from_wy !== undefined && grid[start_gy * WIDTH + gx] === 1) {
        const max_up = Math.min(HEIGHT - 1, start_gy + 10);
        for (let gy = start_gy + 1; gy <= max_up; gy++) {
            if (grid[gy * WIDTH + gx] === 0) {
                return gy * SCALE;
            }
        }
        return (start_gy + 1) * SCALE;
    }

    for (let gy = start_gy; gy >= 0; gy--) {
        if (grid[gy * WIDTH + gx] === 1) {
            return (gy + 1) * SCALE;
        }
    }
    return WATER_LEVEL;
}

function get_smooth_ground_y(wx, radius = 4.0, from_wy) {
    const center_gy = get_ground_y(wx, from_wy);
    const samples = 5;
    const step = (radius * 2) / (samples - 1);
    let total_y = 0;
    let weight_sum = 0;
    const weights = [1, 2, 4, 2, 1];

    for (let i = 0; i < samples; i++) {
        const sample_x = (wx - radius) + i * step;
        let gy = (i === 2) ? center_gy : get_ground_y(sample_x, from_wy);
        if (Math.abs(gy - center_gy) > 4.0) {
            gy = center_gy;
        }
        total_y += gy * weights[i];
        weight_sum += weights[i];
    }
    return total_y / weight_sum;
}

function check_circle_collision(cx, cy, radius) {
    const r2 = radius * radius;
    const min_x = cx - radius;
    const max_x = cx + radius;
    const min_y = cy - radius;
    const max_y = cy + radius;
    const step = SCALE;
    let colliding = false;
    let pen_x = 0, pen_y = 0;
    let count = 0;

    for (let py = min_y; py <= max_y; py += step) {
        for (let px = min_x; px <= max_x; px += step) {
            const dx = px - cx;
            const dy = py - cy;
            if (dx * dx + dy * dy <= r2) {
                if (is_solid(px, py)) {
                    colliding = true;
                    pen_x -= dx;
                    pen_y -= dy;
                    count++;
                }
            }
        }
    }
    if (colliding && count > 0) {
        const len = Math.sqrt(pen_x * pen_x + pen_y * pen_y);
        if (len > 0.0001) {
            return { hit: true, nx: pen_x / len, ny: pen_y / len };
        } else {
            return { hit: true, nx: 0, ny: 1 };
        }
    }
    return { hit: false, nx: 0, ny: 0 };
}

const terrain = {
    is_solid,
    get_ground_y,
    get_smooth_ground_y,
    check_circle_collision
};

// Simulate potato
const p = {
    is_alive: true,
    is_grounded: false,
    pos: { x: 400.0, y: 200.0 }, // directly above the narrow pit
    vel: { x: 0.0, y: -50.0 },
};

console.log("Starting simulation of potato falling into narrow pit at x = 400, y = 200...");

const dt = 1 / 60;
let frames = 0;
let landed = false;

for (let step = 0; step < 300; step++) {
    frames++;
    const check_radius = POTATO_RADIUS;

    if (!p.is_grounded) {
        p.vel.y = Math.max(-MAX_FALL_SPEED, p.vel.y - GRAVITY * dt);
        p.vel.x = p.vel.x * Math.max(0, 1.0 - 2.0 * dt);
    } else {
        p.vel.x = p.vel.x * Math.max(0, 1.0 - 16.0 * dt);
        if (Math.abs(p.vel.x) < 2.0) p.vel.x = 0;
    }

    let new_x = p.pos.x + p.vel.x * dt;
    let new_y = p.pos.y;

    if (p.pos.y <= WATER_LEVEL + 4.0 || new_y <= WATER_LEVEL + 4.0) {
        console.error(`FAILED: Potato drowned at frame ${frames}! pos.y = ${p.pos.y}`);
        process.exit(1);
    }

    if (!p.is_grounded) {
        new_y = p.pos.y + p.vel.y * dt;
        const ground_y = terrain.get_smooth_ground_y(new_x, 4.0, p.pos.y + 6.0);
        const target_standing_y = ground_y + check_radius;

        const probe_dx = check_radius * 1.5;
        const wall_left = terrain.is_solid(new_x - probe_dx, new_y) || terrain.is_solid(new_x - probe_dx, new_y + check_radius);
        const wall_right = terrain.is_solid(new_x + probe_dx, new_y) || terrain.is_solid(new_x + probe_dx, new_y + check_radius);
        const in_tight_pit = wall_left && wall_right;
        const in_wall = terrain.is_solid(new_x, new_y);

        if (in_tight_pit || in_wall) {
            p.vel.x = 0;
        }

        if (ground_y > WATER_LEVEL && p.vel.y <= 0 && new_y <= (target_standing_y + 3.0)) {
            const impact_speed = Math.abs(p.vel.y);
            if (impact_speed > 90.0 && !in_tight_pit && !in_wall) {
                p.vel.y = impact_speed * 0.35;
                p.vel.x = p.vel.x * 0.5;
                new_y = target_standing_y + 2.0;
                p.is_grounded = false;
                p.pos.x = new_x;
                p.pos.y = new_y;
            } else {
                new_y = target_standing_y;
                p.vel.y = 0;
                p.vel.x = in_tight_pit ? 0 : (p.vel.x * 0.3);
                p.is_grounded = true;
                p.pos.x = new_x;
                p.pos.y = new_y;
                landed = true;
            }
        } else {
            const { hit, nx, ny } = terrain.check_circle_collision(new_x, new_y, check_radius);
            if (hit) {
                if (in_tight_pit || in_wall || (Math.abs(nx) > 0.45 && (Math.abs(p.vel.x) < 40.0 || ny > 0.35))) {
                    p.vel.x = 0;
                    if (in_wall && p.vel.y > 0) {
                        p.vel.y = 0;
                    }
                    if (ground_y > WATER_LEVEL && p.vel.y <= 0) {
                        p.is_grounded = true;
                        p.vel.y = 0;
                        if (in_tight_pit && new_y > target_standing_y) {
                            new_y = Math.max(target_standing_y, Math.min(new_y, p.pos.y));
                        } else {
                            new_y = target_standing_y;
                        }
                        p.pos.x = new_x;
                        p.pos.y = new_y;
                        landed = true;
                    }
                }
            }
        }
    } else {
        const ground_y = terrain.get_smooth_ground_y(new_x, 4.0, p.pos.y + 8.0);
        const target_standing_y = ground_y + check_radius;

        if (ground_y <= WATER_LEVEL) {
            p.is_grounded = false;
            p.vel.y = -50.0;
            new_y = p.pos.y + p.vel.y * dt;
        } else if (p.vel.y > 5.0) {
            p.is_grounded = false;
            new_y = p.pos.y + p.vel.y * dt;
        } else {
            const probe_dx = check_radius * 1.5;
            const wall_left = terrain.is_solid(new_x - probe_dx, p.pos.y) || terrain.is_solid(new_x - probe_dx, p.pos.y + check_radius);
            const wall_right = terrain.is_solid(new_x + probe_dx, p.pos.y) || terrain.is_solid(new_x + probe_dx, p.pos.y + check_radius);
            const in_tight_pit = wall_left && wall_right;
            const is_supported = in_tight_pit || terrain.check_circle_collision(new_x, p.pos.y, check_radius).hit;

            if ((p.pos.y - target_standing_y) > 8.0 && !is_supported) {
                p.is_grounded = false;
                p.vel.y = -20.0;
                new_y = p.pos.y + p.vel.y * dt;
            } else if ((target_standing_y - p.pos.y) > 6.0 && !in_tight_pit) {
                new_x = p.pos.x;
                new_y = p.pos.y;
                p.vel.x = 0;
            } else {
                if (in_tight_pit && (p.pos.y - target_standing_y) > 4.0) {
                    new_y = p.pos.y;
                } else {
                    new_y = target_standing_y;
                }
                p.vel.y = 0;
            }
        }
    }

    p.pos.x = new_x;
    p.pos.y = new_y;
}

console.log(`Simulation finished at frame ${frames}: pos.y = ${p.pos.y}, is_grounded = ${p.is_grounded}, landed = ${landed}`);

if (p.pos.y > WATER_LEVEL && p.is_grounded) {
    console.log("SUCCESS! Potato stably settled inside the narrow pit without falling through terrain!");
} else {
    console.error("FAILED! Potato is not grounded or fell through!");
    process.exit(1);
}
