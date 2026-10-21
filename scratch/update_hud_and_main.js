const fs = require('fs');
const path = require('path');

// 1. Update hud.gui_script for military timer and tactical PDA
const hudScriptPath = path.resolve(__dirname, '../gui/hud/hud.gui_script');
let hudScript = fs.readFileSync(hudScriptPath, 'utf8');
const isHudScriptCrlf = hudScript.includes('\r\n');
let normHudScript = hudScript.replace(/\r\n/g, '\n');

// Replace timer colors in update()
const oldTimerCode = `				if seconds_left <= 5 then
					gui.set_color(t_bg, vmath.vector4(0.91, 0.30, 0.24, 1.0))
					gui.set_color(t_fill, vmath.vector4(0.91, 0.30, 0.24, 1.0))
				else
					gui.set_color(t_bg, vmath.vector4(0.95, 0.77, 0.06, 1.0))
					gui.set_color(t_fill, vmath.vector4(0.18, 0.80, 0.44, 1.0))
				end`;

const newTimerCode = `				if seconds_left <= 5 then
					-- Pulsing Alert Red in final 5 seconds
					gui.set_color(t_bg, vmath.vector4(0.85, 0.22, 0.22, 1.0))
					gui.set_color(t_fill, vmath.vector4(0.95, 0.28, 0.24, 1.0))
					gui.set_color(t_txt, vmath.vector4(1.0, 0.95, 0.95, 1.0))
				else
					-- Military Dark Steel Plate with Rivets
					gui.set_color(t_bg, vmath.vector4(0.12, 0.16, 0.22, 1.0))
					-- Tactical Steel Gold / Amber Progress Bar (no toxic green!)
					gui.set_color(t_fill, vmath.vector4(0.92, 0.72, 0.22, 1.0))
					-- Crisp Gold / White Digits
					gui.set_color(t_txt, vmath.vector4(1.0, 0.88, 0.35, 1.0))
				end`;

if (!normHudScript.includes(oldTimerCode)) {
    console.error("oldTimerCode not found in hud.gui_script!");
    process.exit(1);
}
normHudScript = normHudScript.replace(oldTimerCode, newTimerCode);

// Replace squad PDA styling in update_squad_widget
const oldSquadWidget = `		local title_node = gui.get_node("squad_title")
		gui.set_text(title_node, is_ru and "ОТРЯД СИНИХ" or "BLUE SQUAD")`;

const newSquadWidget = `		local title_node = gui.get_node("squad_title")
		gui.set_text(title_node, is_ru and "📟 КПК ОТРЯДА" or "📟 SQUAD PDA")
		gui.set_color(title_node, vmath.vector4(0.15, 0.78, 0.95, 1.0))`;

if (!normHudScript.includes(oldSquadWidget)) {
    console.error("oldSquadWidget not found in hud.gui_script!");
    process.exit(1);
}
normHudScript = normHudScript.replace(oldSquadWidget, newSquadWidget);

// Replace squad slot hp bar color (no neon green!)
const oldHpBarFrac = `					if frac > 0.5 then
						gui.set_color(hp_bar, vmath.vector4(0.18, 0.80, 0.44, 1.0))
					elseif frac > 0.25 then
						gui.set_color(hp_bar, vmath.vector4(0.95, 0.77, 0.06, 1.0))
					else
						gui.set_color(hp_bar, vmath.vector4(0.91, 0.30, 0.24, 1.0))
					end`;

const newHpBarFrac = `					if frac > 0.5 then
						gui.set_color(hp_bar, vmath.vector4(0.15, 0.78, 0.95, 1.0)) -- Tactical Cyan
					elseif frac > 0.25 then
						gui.set_color(hp_bar, vmath.vector4(0.95, 0.77, 0.06, 1.0)) -- Amber
					else
						gui.set_color(hp_bar, vmath.vector4(0.95, 0.35, 0.45, 1.0)) -- Coral
					end`;

if (!normHudScript.includes(oldHpBarFrac)) {
    console.error("oldHpBarFrac not found in hud.gui_script!");
    process.exit(1);
}
normHudScript = normHudScript.replace(oldHpBarFrac, newHpBarFrac);

if (isHudScriptCrlf) normHudScript = normHudScript.replace(/\n/g, '\r\n');
fs.writeFileSync(hudScriptPath, normHudScript, 'utf8');
console.log("Successfully updated hud.gui_script with military timer and tactical PDA!");

// 2. Update hud.gui for squad_panel opacity and styling
const hudGuiPath = path.resolve(__dirname, '../gui/hud/hud.gui');
let hudGui = fs.readFileSync(hudGuiPath, 'utf8');
const isHudGuiCrlf = hudGui.includes('\r\n');
let normHudGui = hudGui.replace(/\r\n/g, '\n');

const oldSquadPanelNode = `  color {
    x: 0.08
    y: 0.11
    z: 0.15
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "squad_panel"
  xanchor: XANCHOR_LEFT
  yanchor: YANCHOR_BOTTOM
  inherit_alpha: true
  slice9 {
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }
  alpha: 0.7`;

const newSquadPanelNode = `  color {
    x: 0.13
    y: 0.17
    z: 0.24
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "squad_panel"
  xanchor: XANCHOR_LEFT
  yanchor: YANCHOR_BOTTOM
  inherit_alpha: true
  slice9 {
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }
  alpha: 0.96`;

if (!normHudGui.includes(oldSquadPanelNode)) {
    console.error("oldSquadPanelNode not found in hud.gui!");
    process.exit(1);
}
normHudGui = normHudGui.replace(oldSquadPanelNode, newSquadPanelNode);

if (isHudGuiCrlf) normHudGui = normHudGui.replace(/\n/g, '\r\n');
fs.writeFileSync(hudGuiPath, normHudGui, 'utf8');
console.log("Successfully updated hud.gui squad_panel opacity!");

// 3. Update main.script for boiling fryer drowning feedback
const mainScriptPath = path.resolve(__dirname, '../main/main.script');
let mainScript = fs.readFileSync(mainScriptPath, 'utf8');
const isMainScriptCrlf = mainScript.includes('\r\n');
let normMain = mainScript.replace(/\r\n/g, '\n');

const oldDrownedBlock = `			elseif result == "drowned" and p.url then
				camera_controller.shake(12, 0.35)
				msg.post("/main#main", "spawn_explosion", {
					x = p.pos.x,
					y = constants.WATER_LEVEL + 4,
					radius = 32
				})
				msg.post(p.url, "drowned")
				p.url = nil`;

const newDrownedBlock = `			elseif result == "drowned" and p.url then
				camera_controller.shake(14, 0.40)
				sound_manager.play_explosion()
				msg.post("/main#main", "spawn_explosion", {
					x = p.pos.x,
					y = constants.WATER_LEVEL + 6,
					radius = 36
				})
				msg.post("/gui_hud#gui", "show_damage", {
					x = p.pos.x,
					y = constants.WATER_LEVEL + 26,
					amount = 999,
					label = "🔥 ФРИТЮРНИЦА!"
				})
				msg.post(p.url, "drowned")
				p.url = nil`;

if (!normMain.includes(oldDrownedBlock)) {
    console.error("oldDrownedBlock not found in main.script!");
    process.exit(1);
}
normMain = normMain.replace(oldDrownedBlock, newDrownedBlock);

if (isMainScriptCrlf) normMain = normMain.replace(/\n/g, '\r\n');
fs.writeFileSync(mainScriptPath, normMain, 'utf8');
console.log("Successfully updated main.script with boiling fryer drowning feedback!");
