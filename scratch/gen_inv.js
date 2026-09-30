const fs = require('fs');

const weapons = [
  { id: 'grenade', name: 'Граната', icon: 'grenade' },
  { id: 'rifle', name: 'Винтовка', icon: 'skewer_rifle' },
  { id: 'knife', name: 'Нож-чистка', icon: 'peeler' },
  { id: 'molotov', name: 'Молотов', icon: 'oil_bottle' },
  { id: 'burst', name: 'Автомат', icon: 'rifle' },
  { id: 'bazooka', name: 'Базука', icon: 'masher_bazooka' },
  { id: 'shotgun', name: 'Дробовик', icon: 'grater' },
  { id: 'holy_grenade', name: 'Золотой клубень', icon: 'holy_spud' },
  { id: 'beetle', name: 'Десант жуков', icon: 'beetle_crate' },
  { id: 'drill', name: 'Бур-ракета', icon: 'drill_missile' },
  { id: 'pepper', name: 'Чили-перцемолка', icon: 'pepper_bomb' },
  { id: 'garlic', name: 'Чеснок-динамит', icon: 'garlic_bomb' }
];

const col_x = [-198.0, -66.0, 66.0, 198.0];
const row_y = [55.0, -15.0, -85.0];

let out = `nodes {
  position {
    x: 65.0
    y: 125.0
  }
  size {
    x: 110.0
    y: 42.0
  }
  color {
    x: 0.12
    y: 0.15
    z: 0.18
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_inventory"
  xanchor: XANCHOR_LEFT
  yanchor: YANCHOR_BOTTOM
  inherit_alpha: true
  slice9 {
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }
  alpha: 0.90
}
nodes {
  scale {
    x: 0.42
    y: 0.42
  }
  size {
    x: 230.0
    y: 30.0
  }
  color {
    x: 0.95
    y: 0.77
    z: 0.06
  }
  type: TYPE_TEXT
  text: "ОРУЖИЕ [Q]"
  font: "system_font"
  id: "txt_inventory"
  parent: "btn_inventory"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    x: 480.0
    y: 270.0
  }
  size {
    x: 960.0
    y: 540.0
  }
  color {
    x: 0.04
    y: 0.06
    z: 0.10
  }
  type: TYPE_BOX
  texture: "game/white_pixel"
  id: "inventory_overlay"
  inherit_alpha: true
  alpha: 0.88
  enabled: false
}
nodes {
  size {
    x: 570.0
    y: 340.0
  }
  color {
    x: 0.10
    y: 0.13
    z: 0.18
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "inventory_modal"
  parent: "inventory_overlay"
  inherit_alpha: true
  slice9 {
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }
  alpha: 0.98
}
nodes {
  position {
    y: 135.0
  }
  scale {
    x: 0.75
    y: 0.75
  }
  size {
    x: 400.0
    y: 32.0
  }
  color {
    x: 0.95
    y: 0.77
    z: 0.06
  }
  type: TYPE_TEXT
  text: "ИНВЕНТАРЬ ОРУЖИЯ [Q]"
  font: "system_font"
  id: "inventory_title"
  parent: "inventory_modal"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    y: 105.0
  }
  scale {
    x: 0.40
    y: 0.40
  }
  size {
    x: 400.0
    y: 24.0
  }
  color {
    x: 0.78
    y: 0.84
    z: 0.92
  }
  type: TYPE_TEXT
  text: "ВЫБЕРИТЕ ОРУЖИЕ ДЛЯ ВЫСТРЕЛА"
  font: "system_font"
  id: "inventory_sub"
  parent: "inventory_modal"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    x: 248.0
    y: 135.0
  }
  size {
    x: 42.0
    y: 34.0
  }
  color {
    x: 0.75
    y: 0.20
    z: 0.18
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_inv_close"
  parent: "inventory_modal"
  inherit_alpha: true
  slice9 {
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }
}
nodes {
  scale {
    x: 0.45
    y: 0.45
  }
  size {
    x: 30.0
    y: 20.0
  }
  type: TYPE_TEXT
  text: "X"
  font: "system_font"
  id: "txt_inv_close"
  parent: "btn_inv_close"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
`;

weapons.forEach((w, idx) => {
  const i = idx + 1;
  const col = idx % 4;
  const row = Math.floor(idx / 4);
  const px = col_x[col];
  const py = row_y[row];

  out += `nodes {
  position {
    x: ${px.toFixed(1)}
    y: ${py.toFixed(1)}
  }
  size {
    x: 124.0
    y: 56.0
  }
  color {
    x: 0.18
    y: 0.24
    z: 0.32
  }
  type: TYPE_BOX
  texture: "game/box"
  id: "inv_slot_${i}"
  parent: "inventory_modal"
  inherit_alpha: true
  slice9 {
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }
}
nodes {
  position {
    x: -36.0
    y: 0.0
  }
  size {
    x: 32.0
    y: 32.0
  }
  type: TYPE_BOX
  texture: "game/${w.icon}"
  id: "inv_icon_${i}"
  parent: "inv_slot_${i}"
  inherit_alpha: true
}
nodes {
  position {
    x: 18.0
    y: 10.0
  }
  scale {
    x: 0.35
    y: 0.35
  }
  size {
    x: 170.0
    y: 22.0
  }
  type: TYPE_TEXT
  text: "${w.name}"
  font: "system_font"
  id: "inv_name_${i}"
  parent: "inv_slot_${i}"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
nodes {
  position {
    x: 18.0
    y: -10.0
  }
  scale {
    x: 0.38
    y: 0.38
  }
  size {
    x: 170.0
    y: 20.0
  }
  color {
    x: 0.95
    y: 0.77
    z: 0.06
  }
  type: TYPE_TEXT
  text: "x0"
  font: "system_font"
  id: "inv_ammo_${i}"
  parent: "inv_slot_${i}"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
`;
});

fs.writeFileSync('scratch/inventory_nodes.gui_snippet', out);
console.log('Successfully generated scratch/inventory_nodes.gui_snippet');
