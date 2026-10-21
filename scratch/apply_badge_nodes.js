const fs = require('fs');

const path = 'gui/hud/hud.gui';
let content = fs.readFileSync(path, 'utf8');

// Find the node marker_player_bg and marker_enemy_text
const startStr = 'nodes {\n  size {\n    x: 88.0\n    y: 28.0\n  }\n  color {\n    x: 0.12';
const startStrCRLF = 'nodes {\r\n  size {\r\n    x: 88.0\r\n    y: 28.0\r\n  }\r\n  color {\r\n    x: 0.12';

let isCRLF = content.includes('\r\n');
const nl = isCRLF ? '\r\n' : '\n';

const lines = content.split(/\r?\n/);
let startIdx = -1;
let endIdx = -1;

for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('id: "marker_player_bg"')) {
    // Go up to the preceding "nodes {"
    for (let j = i; j >= 0; j--) {
      if (lines[j].trim() === 'nodes {') {
        startIdx = j;
        break;
      }
    }
  }
  if (lines[i].includes('id: "marker_enemy_text"')) {
    // Go down to the closing "}"
    for (let j = i; j < lines.length; j++) {
      if (lines[j].trim() === '}') {
        endIdx = j;
        break;
      }
    }
  }
}

console.log('Replacing lines', startIdx, 'to', endIdx);

if (startIdx === -1 || endIdx === -1) {
  console.error('Failed to locate marker nodes!');
  process.exit(1);
}

const replacement = `nodes {
  size {
    x: 64.0
    y: 18.0
  }
  color {
    x: 0.12
    y: 0.14
    z: 0.16
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "marker_player_bg"
  inherit_alpha: true
  slice9 {
    x: 7.0
    y: 7.0
    z: 7.0
    w: 7.0
  }
  alpha: 0.95
  enabled: false
}
nodes {
  scale {
    x: 0.38
    y: 0.38
  }
  size {
    x: 120.0
    y: 18.0
  }
  position {
    x: 0.0
    y: 2.0
    z: 0.1
  }
  color {
    x: 0.92
    y: 0.92
    z: 0.88
  }
  type: TYPE_TEXT
  text: "ТЫ"
  font: "system_font"
  id: "marker_player_text"
  parent: "marker_player_bg"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  size {
    x: 52.0
    y: 2.5
  }
  position {
    x: 0.0
    y: -5.0
    z: 0.1
  }
  color {
    x: 0.08
    y: 0.09
    z: 0.11
  }
  type: TYPE_BOX
  texture: "game/white_pixel"
  id: "marker_player_hp_bg"
  parent: "marker_player_bg"
  inherit_alpha: true
}
nodes {
  size {
    x: 52.0
    y: 2.5
  }
  position {
    x: -26.0
    y: 0.0
    z: 0.2
  }
  color {
    x: 0.15
    y: 0.78
    z: 0.85
  }
  type: TYPE_BOX
  texture: "game/white_pixel"
  id: "marker_player_hp_fill"
  parent: "marker_player_hp_bg"
  pivot: PIVOT_W
  inherit_alpha: true
}
nodes {
  scale {
    x: 0.38
    y: 0.38
  }
  position {
    x: 0.0
    y: 15.0
    z: 0.1
  }
  color {
    x: 0.18
    y: 0.85
    z: 0.95
  }
  type: TYPE_TEXT
  text: "▼"
  font: "system_font"
  id: "marker_player_arrow"
  parent: "marker_player_bg"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  size {
    x: 68.0
    y: 18.0
  }
  color {
    x: 0.12
    y: 0.14
    z: 0.16
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "marker_enemy_bg"
  inherit_alpha: true
  slice9 {
    x: 7.0
    y: 7.0
    z: 7.0
    w: 7.0
  }
  alpha: 0.95
  enabled: false
}
nodes {
  scale {
    x: 0.38
    y: 0.38
  }
  size {
    x: 120.0
    y: 18.0
  }
  position {
    x: 0.0
    y: 2.0
    z: 0.1
  }
  color {
    x: 0.95
    y: 0.85
    z: 0.85
  }
  type: TYPE_TEXT
  text: "ВРАГ"
  font: "system_font"
  id: "marker_enemy_text"
  parent: "marker_enemy_bg"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  size {
    x: 56.0
    y: 2.5
  }
  position {
    x: 0.0
    y: -5.0
    z: 0.1
  }
  color {
    x: 0.08
    y: 0.09
    z: 0.11
  }
  type: TYPE_BOX
  texture: "game/white_pixel"
  id: "marker_enemy_hp_bg"
  parent: "marker_enemy_bg"
  inherit_alpha: true
}
nodes {
  size {
    x: 56.0
    y: 2.5
  }
  position {
    x: -28.0
    y: 0.0
    z: 0.2
  }
  color {
    x: 0.95
    y: 0.28
    z: 0.24
  }
  type: TYPE_BOX
  texture: "game/white_pixel"
  id: "marker_enemy_hp_fill"
  parent: "marker_enemy_hp_bg"
  pivot: PIVOT_W
  inherit_alpha: true
}
nodes {
  scale {
    x: 0.38
    y: 0.38
  }
  position {
    x: 0.0
    y: 15.0
    z: 0.1
  }
  color {
    x: 1.0
    y: 0.32
    z: 0.28
  }
  type: TYPE_TEXT
  text: "▼"
  font: "system_font"
  id: "marker_enemy_arrow"
  parent: "marker_enemy_bg"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}`;

const repLines = replacement.split('\n');
lines.splice(startIdx, endIdx - startIdx + 1, ...repLines);

fs.writeFileSync(path, lines.join(nl), 'utf8');
console.log('Successfully replaced marker nodes in hud.gui!');
