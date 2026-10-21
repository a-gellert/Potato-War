const fs = require('fs');

let content = fs.readFileSync('gui/hud/hud.gui', 'utf8');

// 1. Update slice9 on all boxes to 7.0 for clean rivet borders
content = content.replace(/slice9\s*\{\s*x:\s*4\.0\s*y:\s*4\.0\s*z:\s*4\.0\s*w:\s*4\.0\s*\}/g,
  'slice9 {\n    x: 7.0\n    y: 7.0\n    z: 7.0\n    w: 7.0\n  }');
content = content.replace(/slice9\s*\{\s*x:\s*5\.0\s*y:\s*5\.0\s*z:\s*5\.0\s*w:\s*5\.0\s*\}/g,
  'slice9 {\n    x: 7.0\n    y: 7.0\n    z: 7.0\n    w: 7.0\n  }');
content = content.replace(/slice9\s*\{\s*x:\s*6\.0\s*y:\s*6\.0\s*z:\s*6\.0\s*w:\s*6\.0\s*\}/g,
  'slice9 {\n    x: 7.0\n    y: 7.0\n    z: 7.0\n    w: 7.0\n  }');

// 2. Unify panel colors to military graphite & khaki
// phase_badge
content = content.replace(/(id:\s*"phase_badge"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.14\n    y: 0.17\n    z: 0.15\n  ' + p3; // Dark military khaki/steel
});
// wind_panel
content = content.replace(/(id:\s*"wind_panel"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.13\n    y: 0.15\n    z: 0.17\n  ' + p3; // Graphite armor
});
// squad_panel
content = content.replace(/(id:\s*"squad_panel"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.12\n    y: 0.14\n    z: 0.16\n  ' + p3;
});
// banner_bg
content = content.replace(/(id:\s*"banner_bg"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.14\n    y: 0.16\n    z: 0.18\n  ' + p3;
});
// weapon_panel
content = content.replace(/(id:\s*"weapon_panel"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.13\n    y: 0.15\n    z: 0.17\n  ' + p3;
});
// btn_pause
content = content.replace(/(id:\s*"btn_pause"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.18\n    y: 0.20\n    z: 0.22\n  ' + p3; // Steel button
});
// btn_inventory
content = content.replace(/(id:\s*"btn_inventory"[\s\S]*?color\s*\{)([^}]+)(\})/m, (match, p1, p2, p3) => {
  return p1 + '\n    x: 0.18\n    y: 0.21\n    z: 0.18\n  ' + p3; // Khaki steel button
});

// 3. Replace marker_player_bg and marker_enemy_bg definitions with compact badge + micro HP + triangle
const oldMarkersRegex = /nodes\s*\{[\s\S]*?id:\s*"marker_player_bg"[\s\S]*?id:\s*"marker_enemy_text"[\s\S]*?\}/m;

const newMarkers = `nodes {
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

if (oldMarkersRegex.test(content)) {
  content = content.replace(oldMarkersRegex, newMarkers);
  console.log('Markers replaced successfully!');
} else {
  console.error('Could not find old markers block in hud.gui!');
  process.exit(1);
}

fs.writeFileSync('gui/hud/hud.gui', content, 'utf8');
console.log('hud.gui updated with military styling and compact badges!');
