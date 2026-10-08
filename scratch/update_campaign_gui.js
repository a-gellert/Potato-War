const fs = require('fs');
const path = require('path');

const guiPath = path.join(__dirname, '..', 'gui', 'campaign_map', 'campaign_map.gui');
let gui = fs.readFileSync(guiPath, 'utf8');

// Normalize newlines to \n for consistent replacement
const isCRLF = gui.includes('\r\n');
if (isCRLF) {
  gui = gui.replace(/\r\n/g, '\n');
}

// 1. Replace txt_top_title text: "★ КАРТА ВОЙНЫ" -> "КАРТА ВОЙНЫ"
gui = gui.replace('text: "★ КАРТА ВОЙНЫ"', 'text: "КАРТА ВОЙНЫ"');

// 2. btn_top_barracks: replace text "★ КАЗАРМА" and add star icon
const oldTopBarracksTxt = `nodes {
  position {
    x: 0.0
    y: 0.0
  }
  scale {
    x: 0.50
    y: 0.50
  }
  size {
    x: 130.0
    y: 26.0
  }
  color {
    x: 1
    y: 1
    z: 1
  }
  type: TYPE_TEXT
  text: "★ КАЗАРМА"
  font: "system_font"
  parent: "btn_top_barracks"
  id: "txt_top_barracks"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}`;

const newTopBarracksWithIcon = `nodes {
  position {
    x: -44.0
    y: 0.0
  }
  size {
    x: 18.0
    y: 18.0
  }
  color {
    x: 1
    y: 1
    z: 1
  }
  type: TYPE_BOX
  texture: "game/star"
  parent: "btn_top_barracks"
  id: "top_barracks_star_icon"
  inherit_alpha: true
}
nodes {
  position {
    x: 10.0
    y: 0.0
  }
  scale {
    x: 0.50
    y: 0.50
  }
  size {
    x: 100.0
    y: 26.0
  }
  color {
    x: 1
    y: 1
    z: 1
  }
  type: TYPE_TEXT
  text: "КАЗАРМА"
  font: "system_font"
  parent: "btn_top_barracks"
  id: "txt_top_barracks"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}`;

if (!gui.includes(oldTopBarracksTxt)) {
  console.error('Error: Could not locate oldTopBarracksTxt!');
  process.exit(1);
}
gui = gui.replace(oldTopBarracksTxt, newTopBarracksWithIcon);

// 3. Barracks header
gui = gui.replace('text: "★ КАЗАРМА И ПРОКАЧКА БАНДЫ ★"', 'text: "КАЗАРМА И ПРОКАЧКА БАНДЫ"');

// 4. barracks_stars_txt and add star icon
const oldBarracksStars = `nodes {
  position {
    x: -260.0
    y: 180.0
  }
  scale {
    x: 0.55
    y: 0.55
  }
  size {
    x: 350.0
    y: 30.0
  }
  color {
    x: 1.0
    y: 0.88
    z: 0.25
  }
  type: TYPE_TEXT
  text: "Звезды: 0 ★"
  font: "system_font"
  parent: "barracks_window"
  id: "barracks_stars_txt"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}`;

const newBarracksStarsWithIcon = `nodes {
  position {
    x: -330.0
    y: 180.0
  }
  size {
    x: 24.0
    y: 24.0
  }
  color {
    x: 1
    y: 1
    z: 1
  }
  type: TYPE_BOX
  texture: "game/star"
  parent: "barracks_window"
  id: "barracks_star_icon"
  inherit_alpha: true
}
nodes {
  position {
    x: -220.0
    y: 180.0
  }
  scale {
    x: 0.55
    y: 0.55
  }
  size {
    x: 200.0
    y: 30.0
  }
  color {
    x: 1.0
    y: 0.88
    z: 0.25
  }
  type: TYPE_TEXT
  text: "Звезды: 0"
  font: "system_font"
  parent: "barracks_window"
  id: "barracks_stars_txt"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}`;

if (!gui.includes(oldBarracksStars)) {
  console.error('Error: Could not locate oldBarracksStars!');
  process.exit(1);
}
gui = gui.replace(oldBarracksStars, newBarracksStarsWithIcon);

// 5. txt_barracks_buy_star
gui = gui.replace('text: "+1★ за 1000 очков"', 'text: "+1 звезда за 1000 очков"');

// 6. b_slot_unlock_txt_3
gui = gui.replace('text: "Открыть бойца\\n(3 ★)"', 'text: "Открыть бойца\\n(3 звезды)"');

// 7. b_slot_unlock_txt_4
gui = gui.replace('text: "Открыть бойца\\n(7 ★)"', 'text: "Открыть бойца\\n(7 звезд)"');

// 8. insp_def_txt
gui = gui.replace('text: "Оборона: ★☆☆ (Полевой лагерь)"', 'text: "Оборона: [1/3] (Полевой лагерь)"');

// 9. sec_stars_1 .. 18
gui = gui.split('text: "★☆☆"').join('text: "[1/3]"');

if (isCRLF) {
  gui = gui.replace(/\n/g, '\r\n');
}

fs.writeFileSync(guiPath, gui, 'utf8');
console.log('Successfully updated campaign_map.gui!');
