const fs = require('fs');

const path = 'main/entities/explosion/explosion.script';
const raw = fs.readFileSync(path, 'utf8');
const isCRLF = raw.includes('\r\n');

const code = `-- main/entities/explosion/explosion.script
-- Visual blast flash, billowing gunpowder smoke, and dynamic clods of earth

local constants = require("lua_modules.constants")

go.property("radius", 30)

function init(self)
	constants.log(">>> EXPLOSION INIT RADIUS:", self.radius)
	local target_scale = (self.radius * 2.25) / 48.0 -- Juicier blast ring expansion

	-- Vibrant multi-stage flash explosion ring (bright gold -> fiery orange-magenta)
	go.set("#sprite", "scale", vmath.vector3(0.25, 0.25, 1.0))
	go.set("#sprite", "tint", vmath.vector4(1.6, 1.35, 0.45, 1.0))
	go.animate("#sprite", "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(target_scale, target_scale, 1.0), go.EASING_OUTBACK, 0.28)
	go.animate("#sprite", "tint", go.PLAYBACK_ONCE_FORWARD, vmath.vector4(1.3, 0.35, 0.15, 0.0), go.EASING_INQUAD, 0.38, 0.04)

	-- Dense smoky charcoal and gunpowder puffs (lingering & expanding outward)
	go.set("#smoke1", "tint", vmath.vector4(0.24, 0.22, 0.21, 0.95))
	go.animate("#smoke1", "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(2.5, 2.5, 1.0), go.EASING_OUTQUAD, 0.55)
	go.animate("#smoke1", "tint.w", go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_INQUAD, 0.55, 0.08)

	go.set("#smoke2", "tint", vmath.vector4(0.34, 0.31, 0.29, 0.90))
	go.animate("#smoke2", "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(2.8, 2.8, 1.0), go.EASING_OUTQUAD, 0.58)
	go.animate("#smoke2", "tint.w", go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_INQUAD, 0.58, 0.08)

	-- Flying clods of earth & rich soil debris (комья чернозема и глины)
	local dirt_ids = { "#dirt1", "#dirt2", "#dirt3", "#dirt4", "#dirt5", "#dirt6", "#dirt7", "#dirt8" }
	local dirt_colors = {
		vmath.vector4(0.24, 0.18, 0.13, 1.0), -- Dark fertile chernozem
		vmath.vector4(0.32, 0.23, 0.16, 1.0), -- Rich loam
		vmath.vector4(0.18, 0.13, 0.09, 1.0), -- Heavy black earth
		vmath.vector4(0.38, 0.27, 0.19, 1.0), -- Clay chunk
		vmath.vector4(0.26, 0.19, 0.14, 1.0),
		vmath.vector4(0.34, 0.24, 0.17, 1.0),
		vmath.vector4(0.19, 0.14, 0.10, 1.0),
		vmath.vector4(0.36, 0.25, 0.18, 1.0),
	}
	for i, d_id in ipairs(dirt_ids) do
		pcall(function()
			go.set(d_id, "tint", dirt_colors[i])
			go.set(d_id, "scale", vmath.vector3(1.6 + math.random() * 0.8, 1.6 + math.random() * 0.8, 1.0))
			go.animate(d_id, "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(0.2, 0.2, 1.0), go.EASING_INQUAD, 0.55)
			go.animate(d_id, "tint.w", go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_INQUAD, 0.55, 0.15)
		end)
	end

	-- High-speed hot burning ember sparks (8 radiating sparks)
	local spark_ids = { "#spark1", "#spark2", "#spark3", "#spark4", "#spark5", "#spark6", "#spark7", "#spark8" }
	local spark_colors = {
		vmath.vector4(1.9, 1.3, 0.3, 1.0),
		vmath.vector4(2.0, 0.60, 0.15, 1.0),
		vmath.vector4(1.8, 0.85, 0.25, 1.0),
		vmath.vector4(1.9, 1.1, 0.35, 1.0),
		vmath.vector4(2.0, 0.50, 0.18, 1.0),
		vmath.vector4(1.8, 0.90, 0.28, 1.0),
		vmath.vector4(1.9, 0.70, 0.20, 1.0),
		vmath.vector4(2.0, 1.2, 0.40, 1.0),
	}
	for i, s_id in ipairs(spark_ids) do
		pcall(function()
			go.set(s_id, "tint", spark_colors[i])
			go.set(s_id, "scale", vmath.vector3(1.8, 1.8, 1.0))
			go.animate(s_id, "scale", go.PLAYBACK_ONCE_FORWARD, vmath.vector3(0.1, 0.1, 1.0), go.EASING_INQUAD, 0.45)
			go.animate(s_id, "tint.w", go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_INQUAD, 0.45)
		end)
	end

	-- Delete object after all animations settle
	timer.delay(0.60, false, function()
		go.delete()
	end)
end
`;

const finalCode = isCRLF ? code.replace(/\n/g, '\r\n') : code;
fs.writeFileSync(path, finalCode, 'utf8');
console.log('Fixed explosion.script successfully!');
