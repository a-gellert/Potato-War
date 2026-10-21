const fs = require('fs');
const path = require('path');

// 1. Update potato.go
const goPath = path.resolve(__dirname, '../main/entities/potato/potato.go');
let goContent = fs.readFileSync(goPath, 'utf8');
const isCrlf = goContent.includes('\r\n');
let normGo = goContent.replace(/\r\n/g, '\n');

const oldHpBlock = `embedded_components {
  id: "hp_bg"
  type: "sprite"
  data: "default_animation: \\"white_pixel\\"\\n"
  "material: \\"/builtins/materials/sprite.material\\"\\n"
  "textures {\\n"
  "  sampler: \\"texture_sampler\\"\\n"
  "  texture: \\"/main/assets/game.atlas\\"\\n"
  "}\\n"
  ""
  position {
    y: 31.0
    z: 0.08
  }
  scale {
    x: 4.0
    y: 0.6
  }
}
embedded_components {
  id: "hp_fill"
  type: "sprite"
  data: "default_animation: \\"white_pixel\\"\\n"
  "material: \\"/builtins/materials/sprite.material\\"\\n"
  "textures {\\n"
  "  sampler: \\"texture_sampler\\"\\n"
  "  texture: \\"/main/assets/game.atlas\\"\\n"
  "}\\n"
  ""
  position {
    y: 31.0
    z: 0.09
  }
  scale {
    x: 3.8
    y: 0.5
  }
}`;

const newHpBlock = `embedded_components {
  id: "hp_bg"
  type: "sprite"
  data: "default_animation: \\"hp_frame\\"\\n"
  "material: \\"/builtins/materials/sprite.material\\"\\n"
  "textures {\\n"
  "  sampler: \\"texture_sampler\\"\\n"
  "  texture: \\"/main/assets/game.atlas\\"\\n"
  "}\\n"
  ""
  position {
    y: 31.0
    z: 0.08
  }
  scale {
    x: 0.74
    y: 0.70
  }
}
embedded_components {
  id: "hp_fill"
  type: "sprite"
  data: "default_animation: \\"white_pixel\\"\\n"
  "material: \\"/builtins/materials/sprite.material\\"\\n"
  "textures {\\n"
  "  sampler: \\"texture_sampler\\"\\n"
  "  texture: \\"/main/assets/game.atlas\\"\\n"
  "}\\n"
  ""
  position {
    y: 31.0
    z: 0.09
  }
  scale {
    x: 2.05
    y: 0.38
  }
}
embedded_components {
  id: "hp_text"
  type: "label"
  data: "size { x: 160.0 y: 24.0 }\\n"
  "color { x: 1.0 y: 1.0 z: 1.0 w: 1.0 }\\n"
  "outline { x: 0.05 y: 0.08 z: 0.12 w: 1.0 }\\n"
  "shadow { x: 0.0 y: 0.0 z: 0.0 w: 0.0 }\\n"
  "leading: 1.0\\n"
  "tracking: 0.0\\n"
  "pivot: PIVOT_CENTER\\n"
  "blend_mode: BLEND_MODE_ALPHA\\n"
  "line_break: false\\n"
  "text: \\"100/100\\"\\n"
  "font: \\"/main/assets/game.font\\"\\n"
  "material: \\"/builtins/fonts/label-df.material\\"\\n"
  position {
    y: 31.0
    z: 0.10
  }
  scale {
    x: 0.22
    y: 0.22
  }
}`;

if (!normGo.includes(oldHpBlock)) {
    console.error("Target oldHpBlock not found in potato.go!");
    process.exit(1);
}

normGo = normGo.replace(oldHpBlock, newHpBlock);
if (isCrlf) normGo = normGo.replace(/\n/g, '\r\n');
fs.writeFileSync(goPath, normGo, 'utf8');
console.log("Successfully updated potato.go with compact segmented HP bar and label!");

// 2. Update potato.script
const scriptPath = path.resolve(__dirname, '../main/entities/potato/potato.script');
let scriptContent = fs.readFileSync(scriptPath, 'utf8');
const isScriptCrlf = scriptContent.includes('\r\n');
let normScript = scriptContent.replace(/\r\n/g, '\n');

const oldUpdateHp = `local function update_hp_bar(self)
	local pct = math.max(0, math.min(1.0, self.hp / self.max_hp))

	go.set("#hp_fill", "scale", vmath.vector3(3.8 * pct, 0.5, 1.0))

	-- HP bar color distinguishes the team! (Blue team = bright cyan/blue, Red team = vivid red/coral)
	local team_hp_color
	if self.team == 1 then
		-- Blue Team
		team_hp_color = vmath.vector4(0.18, 0.65, 1.0, 1.0)
	else
		-- Red Team
		team_hp_color = vmath.vector4(1.0, 0.28, 0.24, 1.0)
	end
	go.set("#hp_fill", "tint", team_hp_color)
end`;

const newUpdateHp = `local function update_hp_bar(self)
	local pct = math.max(0, math.min(1.0, self.hp / self.max_hp))

	-- Compact shoulder-width HP bar (~34px wide)
	local total_w = 2.05
	local cur_w = total_w * pct
	local offset_x = -((total_w - cur_w) * 16.0) * 0.5
	go.set("#hp_fill", "scale", vmath.vector3(cur_w, 0.38, 1.0))
	go.set("#hp_fill", "position", vmath.vector3(offset_x, 31.0, 0.09))

	-- Crisp white HP counter inside bar
	pcall(function()
		label.set_text("#hp_text", string.format("%d/%d", math.max(0, math.floor(self.hp)), math.floor(self.max_hp)))
	end)

	-- HP bar color distinguishes the team!
	local team_hp_color
	if self.team == 1 then
		-- Blue Team: Soft Serene Cyan
		team_hp_color = vmath.vector4(0.15, 0.78, 0.95, 1.0)
	else
		-- Red Team: Vivid Soft Coral
		team_hp_color = vmath.vector4(0.96, 0.35, 0.48, 1.0)
	end
	go.set("#hp_fill", "tint", team_hp_color)
end`;

if (!normScript.includes(oldUpdateHp)) {
    console.error("Target oldUpdateHp not found in potato.script!");
    process.exit(1);
}

normScript = normScript.replace(oldUpdateHp, newUpdateHp);

// Update init tint
normScript = normScript.replace(
    'go.set("#hp_bg", "tint", vmath.vector4(0.08, 0.10, 0.14, 0.75))',
    'go.set("#hp_bg", "tint", vmath.vector4(1.0, 1.0, 1.0, 0.95))'
);

// Also enable/disable hp_text in potato.script
normScript = normScript.replace(
    'msg.post("#hp_fill", "enable")',
    'msg.post("#hp_fill", "enable")\n\tpcall(function() msg.post("#hp_text", "enable") end)'
);
normScript = normScript.replace(
    'msg.post("#hp_fill", "disable")',
    'msg.post("#hp_fill", "disable")\n\tpcall(function() msg.post("#hp_text", "disable") end)'
);

if (isScriptCrlf) normScript = normScript.replace(/\n/g, '\r\n');
fs.writeFileSync(scriptPath, normScript, 'utf8');
console.log("Successfully updated potato.script with compact HP bar logic and label text!");
