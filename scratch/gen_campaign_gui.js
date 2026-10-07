const fs = require('fs');

const SECTORS = [
  // REGION 1: Прибрежные Луга (Meadows) - SW
  { id: 1, name_ru: "Бухта Высадки", reg: 1, x: 85, y: 110 },
  { id: 2, name_ru: "Зеленые Холмы", reg: 1, x: 110, y: 225 },
  { id: 3, name_ru: "Изумрудная Долина", reg: 1, x: 205, y: 165 },
  { id: 4, name_ru: "Маяк Спокойствия", reg: 1, x: 85, y: 335 },

  // REGION 2: Пустынный Каньон (Canyon) - South / Center
  { id: 5, name_ru: "Песчаные Дюны", reg: 2, x: 230, y: 85 },
  { id: 6, name_ru: "Каньон Эхо", reg: 2, x: 325, y: 150 },
  { id: 7, name_ru: "Пыльный Перекресток", reg: 2, x: 310, y: 265 },
  { id: 8, name_ru: "Северный Мост", reg: 2, x: 430, y: 205 },
  { id: 9, name_ru: "Золотой Оазис", reg: 2, x: 420, y: 95 },

  // REGION 3: Ледяной Перевал (Ice Pass) - North / NW
  { id: 10, name_ru: "Морозные Высоты", reg: 3, x: 195, y: 365 },
  { id: 11, name_ru: "Парящие Льдины", reg: 3, x: 295, y: 435 },
  { id: 12, name_ru: "Хребет Метелей", reg: 3, x: 415, y: 365 },
  { id: 13, name_ru: "Ледяной Бастион", reg: 3, x: 320, y: 350 },

  // REGION 4: Вулканические Бастионы (Volcano) - East / NE
  { id: 14, name_ru: "Обсидиановые Врата", reg: 4, x: 515, y: 315 },
  { id: 15, name_ru: "Лавовое Ущелье", reg: 4, x: 525, y: 185 },
  { id: 16, name_ru: "Катакомбы Угля", reg: 4, x: 610, y: 135 },
  { id: 17, name_ru: "Бункер Генералов", reg: 4, x: 620, y: 270 },
  { id: 18, name_ru: "Вулканическая Цитадель", reg: 4, x: 615, y: 415 }
];

let out = `script: "/gui/campaign_map/campaign_map.gui_script"
fonts {
  name: "system_font"
  font: "/druid/fonts/druid_text_bold.font"
}
textures {
  name: "game"
  texture: "/main/assets/game.atlas"
}
`;

function box(id, x, y, w, h, col, opts = {}) {
  const tex = opts.texture ? `texture: "${opts.texture}"\n  ` : '';
  const parent = opts.parent ? `parent: "${opts.parent}"\n  ` : '';
  const alpha = (opts.alpha !== undefined) ? `alpha: ${opts.alpha}\n  ` : '';
  const slice = opts.slice ? `slice9 {\n    x: ${opts.slice}.0\n    y: ${opts.slice}.0\n    z: ${opts.slice}.0\n    w: ${opts.slice}.0\n  }\n  ` : '';
  return `nodes {
  position {
    x: ${x}.0
    y: ${y}.0
  }
  size {
    x: ${w}.0
    y: ${h}.0
  }
  color {
    x: ${col[0]}
    y: ${col[1]}
    z: ${col[2]}
  }
  type: TYPE_BOX
  ${tex}${parent}${alpha}${slice}id: "${id}"
  inherit_alpha: true
}
`;
}

function text(id, x, y, str, scale, col, opts = {}) {
  const parent = opts.parent ? `parent: "${opts.parent}"\n  ` : '';
  const anchor = opts.anchor ? `xanchor: ${opts.anchor}\n  ` : '';
  return `nodes {
  position {
    x: ${x}.0
    y: ${y}.0
  }
  scale {
    x: ${scale}
    y: ${scale}
  }
  size {
    x: ${opts.w || 250}.0
    y: ${opts.h || 30}.0
  }
  color {
    x: ${col[0]}
    y: ${col[1]}
    z: ${col[2]}
  }
  type: TYPE_TEXT
  text: "${str}"
  font: "system_font"
  ${parent}${anchor}id: "${id}"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
`;
}

// 1. Root & Map Background
out += box("map_bg", 480, 270, 960, 540, [0.06, 0.08, 0.12], { texture: "game/white_pixel" });
out += box("tactical_grid", 350, 260, 680, 480, [0.09, 0.13, 0.18], { texture: "game/box", slice: 4, alpha: 0.45 });

// 2. Region Landmasses
out += box("reg_blob_1", 130, 220, 220, 260, [0.10, 0.22, 0.14], { texture: "game/box", slice: 6, alpha: 0.40 });
out += text("lbl_reg_1", 110, 48, "MEADOWS", 0.45, [0.4, 0.75, 0.5]);

out += box("reg_blob_2", 340, 175, 270, 230, [0.22, 0.17, 0.09], { texture: "game/box", slice: 6, alpha: 0.40 });
out += text("lbl_reg_2", 330, 48, "CANYON", 0.45, [0.8, 0.7, 0.4]);

out += box("reg_blob_3", 310, 385, 270, 160, [0.09, 0.20, 0.28], { texture: "game/box", slice: 6, alpha: 0.40 });
out += text("lbl_reg_3", 260, 470, "ICE PASS", 0.45, [0.4, 0.75, 0.9]);

out += box("reg_blob_4", 570, 275, 210, 330, [0.24, 0.09, 0.10], { texture: "game/box", slice: 6, alpha: 0.40 });
out += text("lbl_reg_4", 570, 470, "VOLCANO BASTIONS", 0.45, [0.9, 0.4, 0.4]);

// 3. Lines Container (empty anchor for lines)
out += box("lines_container", 0, 0, 1, 1, [0, 0, 0], { alpha: 0.0 });

// 4. Sector Nodes 1..18
for (const s of SECTORS) {
  const i = s.id;
  const isBlue = (i === 1 || i === 2);
  const col = isBlue ? [0.16, 0.42, 0.78] : [0.72, 0.18, 0.20];

  // Glow ring (behind button)
  out += box(`sec_glow_${i}`, s.x, s.y, 64, 64, [1.0, 0.85, 0.25], { texture: "game/box", slice: 4, alpha: 0.0 });

  // Main Sector Button
  out += box(`sec_btn_${i}`, s.x, s.y, 50, 50, col, { texture: "game/box", slice: 4, alpha: 1.0 });

  // Potato Icon inside button
  const tex = isBlue ? "game/potato_blue" : "game/potato_red";
  out += box(`sec_potato_${i}`, 0, 7, 26, 26, [1, 1, 1], { texture: tex, parent: `sec_btn_${i}` });

  // Sector ID text
  const idStr = (i < 10 ? "0" : "") + i;
  out += text(`sec_id_${i}`, 0, -11, idStr, 0.50, [1, 1, 1], { parent: `sec_btn_${i}`, w: 40, h: 20 });

  // Defense Stars
  out += text(`sec_stars_${i}`, 0, 24, "★☆☆", 0.42, [1.0, 0.82, 0.2], { parent: `sec_btn_${i}`, w: 60, h: 20 });

  // Alert Badge (⚠️ under attack)
  out += box(`sec_alert_${i}`, 20, 20, 18, 18, [0.95, 0.15, 0.15], { texture: "game/box", slice: 2, parent: `sec_btn_${i}`, alpha: 0.0 });
  out += text(`sec_alert_txt_${i}`, 0, 0, "!", 0.52, [1, 1, 1], { parent: `sec_alert_${i}`, w: 20, h: 20 });

  // Sector Name Label
  out += text(`sec_lbl_${i}`, 0, -32, s.name_ru, 0.38, [0.85, 0.90, 0.95], { parent: `sec_btn_${i}`, w: 120, h: 20 });
}

// 5. Top Command Bar
out += box("top_bar_bg", 480, 515, 940, 40, [0.10, 0.14, 0.20], { texture: "game/box", slice: 4, alpha: 0.96 });
out += text("txt_top_title", 120, 515, "★ КАРТА ВОЙНЫ", 0.65, [0.95, 0.78, 0.15]);
out += text("txt_top_sectors", 310, 515, "Секторы: 2/18 (11%)", 0.52, [0.85, 0.90, 0.95]);
out += text("txt_top_supplies", 510, 515, "Припасы: 250 🥔", 0.52, [0.95, 0.70, 0.20]);
out += text("txt_top_turn", 680, 515, "Ход: 1", 0.52, [0.75, 0.85, 0.95]);

out += box("btn_top_menu", 880, 515, 100, 30, [0.20, 0.26, 0.35], { texture: "game/box", slice: 3, alpha: 1.0 });
out += text("txt_top_menu", 0, 0, "В МЕНЮ", 0.52, [1, 1, 1], { parent: "btn_top_menu", w: 100, h: 26 });

// 6. Alert Notification Banner (pulsing when counter-attacked)
out += box("alert_banner", 480, 475, 600, 32, [0.75, 0.12, 0.12], { texture: "game/box", slice: 4, alpha: 0.0 });
out += text("txt_alert_banner", 0, 0, "⚠️ ТРЕВОГА! ВРАЖЕСКИЙ ШТУРМ СЕКТОРА!", 0.52, [1, 1, 1], { parent: "alert_banner", w: 580, h: 28 });

// 7. Bottom Tactical Bar
out += box("bot_bar_bg", 350, 18, 670, 26, [0.08, 0.11, 0.16], { texture: "game/box", slice: 3, alpha: 0.85 });
out += text("txt_bot_hint", 350, 18, "Кликните на сектор для разведданных. Золотая линия — линия фронта.", 0.40, [0.70, 0.78, 0.88], { w: 660 });

// 8. Sector Inspector Panel (Right side)
out += box("panel_inspector", 810, 260, 270, 470, [0.08, 0.12, 0.17], { texture: "game/box", slice: 4, alpha: 0.98 });
out += box("insp_border", 810, 260, 264, 464, [0.18, 0.28, 0.40], { texture: "game/box", slice: 3, alpha: 0.35 });

out += box("insp_badge_bg", 810, 468, 200, 22, [0.14, 0.22, 0.32], { texture: "game/box", slice: 3 });
out += text("insp_badge_txt", 810, 468, "ДОСЬЕ РАЗВЕДКИ", 0.46, [0.70, 0.85, 1.0], { w: 190 });

out += text("insp_title", 810, 436, "[#01] БУХТА ВЫСАДКИ", 0.68, [0.95, 0.85, 0.25], { w: 250 });
out += text("insp_region", 810, 412, "🌿 Прибрежные Луга", 0.48, [0.55, 0.85, 0.65], { w: 250 });

out += box("insp_div_1", 810, 396, 240, 2, [0.20, 0.28, 0.38], { texture: "game/white_pixel" });

out += box("insp_owner_card", 810, 370, 240, 32, [0.12, 0.24, 0.38], { texture: "game/box", slice: 3 });
out += text("insp_owner_txt", 810, 370, "Контроль: 🔵 СИНИЕ", 0.52, [1, 1, 1], { w: 230 });

out += box("insp_def_card", 810, 325, 240, 38, [0.12, 0.16, 0.22], { texture: "game/box", slice: 3 });
out += text("insp_def_txt", 810, 334, "Оборона: ★☆☆ (Полевой лагерь)", 0.48, [1.0, 0.85, 0.3], { w: 230 });
out += text("insp_gar_txt", 810, 315, "Гарнизон: 2 картошки", 0.44, [0.75, 0.85, 0.95], { w: 230 });

out += box("insp_inc_card", 810, 272, 240, 30, [0.12, 0.16, 0.22], { texture: "game/box", slice: 3 });
out += text("insp_inc_txt", 810, 272, "Доход: +20 🥔 / ход", 0.48, [0.95, 0.75, 0.2], { w: 230 });

out += box("insp_ter_card", 810, 230, 240, 30, [0.12, 0.16, 0.22], { texture: "game/box", slice: 3 });
out += text("insp_ter_txt", 810, 230, "Рельеф: Холмы", 0.46, [0.80, 0.88, 0.95], { w: 230 });

out += box("insp_stat_card", 810, 175, 240, 42, [0.14, 0.18, 0.25], { texture: "game/box", slice: 3 });
out += text("insp_stat_txt", 810, 175, "⚡ Рубеж готов к штурму", 0.46, [0.3, 0.9, 0.5], { w: 230 });

out += box("insp_div_2", 810, 140, 240, 2, [0.20, 0.28, 0.38], { texture: "game/white_pixel" });

out += box("btn_insp_attack", 810, 96, 240, 48, [0.18, 0.72, 0.35], { texture: "game/box", slice: 4 });
out += text("txt_insp_attack", 0, 0, "⚔️ В АТАКУ!", 0.65, [1, 1, 1], { parent: "btn_insp_attack", w: 230, h: 36 });

out += box("btn_insp_fortify", 810, 44, 240, 40, [0.85, 0.62, 0.15], { texture: "game/box", slice: 4 });
out += text("txt_insp_fortify", 0, 0, "🛡️ УКРЕПИТЬ (40 🥔)", 0.52, [1, 1, 1], { parent: "btn_insp_fortify", w: 230, h: 32 });

out += box("btn_insp_close", 932, 475, 22, 22, [0.35, 0.15, 0.15], { texture: "game/box", slice: 2 });
out += text("txt_insp_close", 0, 0, "✕", 0.55, [1, 1, 1], { parent: "btn_insp_close", w: 22, h: 22 });

fs.writeFileSync('gui/campaign_map/campaign_map.gui', out, 'utf8');
console.log('campaign_map.gui generated successfully! Size:', out.length);
