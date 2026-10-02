const fs = require('fs');
const path = require('path');

const guiPath = path.join(__dirname, '..', 'gui', 'main_menu', 'main_menu.gui');
let content = fs.readFileSync(guiPath, 'utf8');

const lobbyNodes = `nodes {
  position {
    x: 480.0
    y: 270.0
  }
  size {
    x: 960.0
    y: 540.0
  }
  color {
    x: 0.06
    y: 0.09
    z: 0.14
  }
  type: TYPE_BOX
  texture: "game/white_pixel"
  id: "lobby_overlay"
  inherit_alpha: true
  alpha: 0.98
}
nodes {
  position {
    y: 225.0
  }
  scale {
    x: 1.1
    y: 1.1
  }
  size {
    x: 400.0
    y: 35.0
  }
  color {
    x: 0.95
    y: 0.77
    z: 0.06
  }
  type: TYPE_TEXT
  text: "\\320\\235\\320\\220\\320\\241\\320\\242\\320\\240\\320\\236\\320\\229\\320\\232\\320\\220 \\320\\221\\320\\236\\320\\257"
  font: "system_font"
  id: "lobby_title"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    y: 190.0
  }
  scale {
    x: 0.52
    y: 0.52
  }
  size {
    x: 400.0
    y: 25.0
  }
  color {
    x: 0.75
    y: 0.8
    z: 0.85
  }
  type: TYPE_TEXT
  text: "\\320\\241\\320\\272\\320\\276\\320\\275\\321\\201\\321\\202\\321\\200\\321\\203\\320\\270\\321\\200\\321\\203\\320\\271\\321\\202\\320\\265 \\320\\274\\320\\260\\321\\202\\321\\207 \\320\\272\\320\\276\\320\\274\\320\\260\\320\\275\\320\\264"
  font: "system_font"
  id: "lobby_subtitle"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: -240.0
    y: 130.0
  }
  scale {
    x: 0.52
    y: 0.52
  }
  size {
    x: 220.0
    y: 30.0
  }
  color {
    x: 0.9
    y: 0.92
    z: 0.95
  }
  type: TYPE_TEXT
  text: "\\320\\232\\320\\260\\321\\200\\320\\276\\321\\205\\320\\265\\320\\272 \\320\\262 \\320\\272\\320\\276\\320\\274\\320\\260\\320\\275\\320\\264\\320\\265:"
  font: "system_font"
  id: "lbl_count"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    x: -30.0
    y: 130.0
  }
  size {
    x: 52.0
    y: 36.0
  }
  color {
    x: 0.18
    y: 0.5
    z: 0.82
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_cnt_1"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.6 y: 0.6 }
  size { x: 40.0 y: 30.0 }
  type: TYPE_TEXT
  text: "1"
  font: "system_font"
  id: "txt_cnt_1"
  parent: "btn_cnt_1"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: 35.0
    y: 130.0
  }
  size {
    x: 52.0
    y: 36.0
  }
  color {
    x: 0.2
    y: 0.25
    z: 0.32
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_cnt_2"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.6 y: 0.6 }
  size { x: 40.0 y: 30.0 }
  type: TYPE_TEXT
  text: "2"
  font: "system_font"
  id: "txt_cnt_2"
  parent: "btn_cnt_2"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: 100.0
    y: 130.0
  }
  size {
    x: 52.0
    y: 36.0
  }
  color {
    x: 0.2
    y: 0.25
    z: 0.32
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_cnt_3"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.6 y: 0.6 }
  size { x: 40.0 y: 30.0 }
  type: TYPE_TEXT
  text: "3"
  font: "system_font"
  id: "txt_cnt_3"
  parent: "btn_cnt_3"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: 165.0
    y: 130.0
  }
  size {
    x: 52.0
    y: 36.0
  }
  color {
    x: 0.2
    y: 0.25
    z: 0.32
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_cnt_4"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.6 y: 0.6 }
  size { x: 40.0 y: 30.0 }
  type: TYPE_TEXT
  text: "4"
  font: "system_font"
  id: "txt_cnt_4"
  parent: "btn_cnt_4"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: -240.0
    y: 75.0
  }
  scale {
    x: 0.52
    y: 0.52
  }
  size {
    x: 220.0
    y: 30.0
  }
  color {
    x: 0.9
    y: 0.92
    z: 0.95
  }
  type: TYPE_TEXT
  text: "\\320\\241\\320\\276\\320\\277\\320\\265\\321\\200\\320\\275\\320\\270\\320\\272:"
  font: "system_font"
  id: "lbl_opponent"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    x: -20.0
    y: 75.0
  }
  size {
    x: 170.0
    y: 36.0
  }
  color {
    x: 0.18
    y: 0.5
    z: 0.82
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_opp_bot"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.48 y: 0.48 }
  size { x: 160.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\320\\237\\320\\240\\320\\236\\320\\242\\320\\230\\320\\222 \\320\\221\\320\\236\\320\\242\\320\\220"
  font: "system_font"
  id: "txt_opp_bot"
  parent: "btn_opp_bot"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: 165.0
    y: 75.0
  }
  size {
    x: 180.0
    y: 36.0
  }
  color {
    x: 0.2
    y: 0.25
    z: 0.32
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_opp_human"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.48 y: 0.48 }
  size { x: 170.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\320\\237\\320\\240\\320\\236\\320\\242\\320\\230\\320\\222 \\320\\247\\320\\225\\320\\233\\320\\236\\320\\222\\320\\225\\320\\232\\320\\220"
  font: "system_font"
  id: "txt_opp_human"
  parent: "btn_opp_human"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position {
    x: -240.0
    y: 20.0
  }
  scale { x: 0.52 y: 0.52 }
  size { x: 220.0 y: 30.0 }
  color { x: 0.9 y: 0.92 z: 0.95 }
  type: TYPE_TEXT
  text: "\\320\\241\\320\\272\\320\\270\\320\\275 \\320\\241\\320\\270\\320\\275\\320\\270\\321\\205:"
  font: "system_font"
  id: "lbl_skin_blue"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: -80.0 y: 20.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_skin_blue_prev"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\227\\204"
  font: "system_font"
  id: "txt_skin_blue_prev"
  parent: "btn_skin_blue_prev"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 45.0 y: 20.0 }
  size { x: 195.0 y: 34.0 }
  color { x: 0.15 y: 0.18 z: 0.24 }
  type: TYPE_BOX
  texture: "game/box"
  id: "bg_skin_blue_val"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.48 y: 0.48 }
  size { x: 185.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\320\\236\\320\\261\\321\\213\\321\\207\\320\\275\\321\\213\\320\\231"
  font: "system_font"
  id: "txt_skin_blue_val"
  parent: "bg_skin_blue_val"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 170.0 y: 20.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_skin_blue_next"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\226\\27Options"
  text: "\\342\\226\\272"
  font: "system_font"
  id: "txt_skin_blue_next"
  parent: "btn_skin_blue_next"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position { x: -240.0 y: -35.0 }
  scale { x: 0.52 y: 0.52 }
  size { x: 220.0 y: 30.0 }
  color { x: 0.9 y: 0.92 z: 0.95 }
  type: TYPE_TEXT
  text: "\\320\\241\\320\\272\\320\\270\\320\\275 \\320\\232\\321\\200\\320\\260\\321\\201\\320\\275\\321\\213\\321\\205:"
  font: "system_font"
  id: "lbl_skin_red"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: -80.0 y: -35.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_skin_red_prev"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\227\\204"
  font: "system_font"
  id: "txt_skin_red_prev"
  parent: "btn_skin_red_prev"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 45.0 y: -35.0 }
  size { x: 195.0 y: 34.0 }
  color { x: 0.15 y: 0.18 z: 0.24 }
  type: TYPE_BOX
  texture: "game/box"
  id: "bg_skin_red_val"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.48 y: 0.48 }
  size { x: 185.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\320\\236\\320\\261\\321\\213\\321\\207\\320\\275\\321\\213\\320\\231"
  font: "system_font"
  id: "txt_skin_red_val"
  parent: "bg_skin_red_val"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 170.0 y: -35.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_skin_red_next"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\226\\272"
  font: "system_font"
  id: "txt_skin_red_next"
  parent: "btn_skin_red_next"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position { x: -240.0 y: -90.0 }
  scale { x: 0.52 y: 0.52 }
  size { x: 220.0 y: 30.0 }
  color { x: 0.9 y: 0.92 z: 0.95 }
  type: TYPE_TEXT
  text: "\\320\\234\\320\\265\\321\\201\\321\\202\\320\\275\\320\\276\\321\\201\\321\\202\\321\\214:"
  font: "system_font"
  id: "lbl_biome"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: -80.0 y: -90.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_biome_prev"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\227\\204"
  font: "system_font"
  id: "txt_biome_prev"
  parent: "btn_biome_prev"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 45.0 y: -90.0 }
  size { x: 195.0 y: 34.0 }
  color { x: 0.15 y: 0.18 z: 0.24 }
  type: TYPE_BOX
  texture: "game/box"
  id: "bg_biome_val"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.48 y: 0.48 }
  size { x: 185.0 y: 30.0 }
  type: TYPE_TEXT
  text: "Зеленые Холмы"
  font: "system_font"
  id: "txt_biome_val"
  parent: "bg_biome_val"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 170.0 y: -90.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_biome_next"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\226\\272"
  font: "system_font"
  id: "txt_biome_next"
  parent: "btn_biome_next"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position { x: -240.0 y: -145.0 }
  scale { x: 0.52 y: 0.52 }
  size { x: 220.0 y: 30.0 }
  color { x: 0.9 y: 0.92 z: 0.95 }
  type: TYPE_TEXT
  text: "\\320\\240\\320\\265\\320\\273\\321\\214\\320\\265\\321\\204:"
  font: "system_font"
  id: "lbl_relief"
  parent: "lobby_overlay"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: -80.0 y: -145.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_relief_prev"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\227\\204"
  font: "system_font"
  id: "txt_relief_prev"
  parent: "btn_relief_prev"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 45.0 y: -145.0 }
  size { x: 195.0 y: 34.0 }
  color { x: 0.15 y: 0.18 z: 0.24 }
  type: TYPE_BOX
  texture: "game/box"
  id: "bg_relief_val"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.48 y: 0.48 }
  size { x: 185.0 y: 30.0 }
  type: TYPE_TEXT
  text: "Холмы"
  font: "system_font"
  id: "txt_relief_val"
  parent: "bg_relief_val"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position { x: 170.0 y: -145.0 }
  size { x: 38.0 y: 34.0 }
  color { x: 0.22 y: 0.28 z: 0.36 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_relief_next"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 30.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\342\\226\\272"
  font: "system_font"
  id: "txt_relief_next"
  parent: "btn_relief_next"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position { x: 100.0 y: -215.0 }
  size { x: 210.0 y: 46.0 }
  color { x: 0.18 y: 0.76 z: 0.38 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_lobby_start"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.62 y: 0.62 }
  size { x: 190.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\320\\222 \\320\\221\\320\\236\\320\\257!"
  font: "system_font"
  id: "txt_lobby_start"
  parent: "btn_lobby_start"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}

nodes {
  position { x: -160.0 y: -215.0 }
  size { x: 160.0 y: 46.0 }
  color { x: 0.22 y: 0.28 z: 0.35 }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_lobby_back"
  parent: "lobby_overlay"
  inherit_alpha: true
  slice9 { x: 4.0 y: 4.0 z: 4.0 w: 4.0 }
}
nodes {
  scale { x: 0.55 y: 0.55 }
  size { x: 140.0 y: 30.0 }
  type: TYPE_TEXT
  text: "\\320\\235\\320\\220\\320\\227\\320\\220\\320\\224"
  font: "system_font"
  id: "txt_lobby_back"
  parent: "btn_lobby_back"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
`;

// fix typo in text
const cleanLobbyNodes = lobbyNodes.replace('\\342\\226\\27Options\n  text: ', '');

const matIdx = content.lastIndexOf('material:');
if (matIdx !== -1) {
  content = content.slice(0, matIdx) + cleanLobbyNodes + content.slice(matIdx);
  fs.writeFileSync(guiPath, content, 'utf8');
  console.log('SUCCESS: Lobby nodes added to main_menu.gui');
} else {
  console.error('ERROR: material: tag not found in main_menu.gui');
}
