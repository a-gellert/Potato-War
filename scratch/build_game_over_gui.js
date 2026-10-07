const fs = require('fs');

const sectors = [
  { id: 1, x: 85, y: 110 },
  { id: 2, x: 110, y: 225 },
  { id: 3, x: 205, y: 165 },
  { id: 4, x: 85, y: 335 },
  { id: 5, x: 230, y: 85 },
  { id: 6, x: 325, y: 150 },
  { id: 7, x: 310, y: 265 },
  { id: 8, x: 430, y: 205 },
  { id: 9, x: 420, y: 95 },
  { id: 10, x: 195, y: 365 },
  { id: 11, x: 295, y: 435 },
  { id: 12, x: 415, y: 365 },
  { id: 13, x: 320, y: 350 },
  { id: 14, x: 515, y: 315 },
  { id: 15, x: 525, y: 185 },
  { id: 16, x: 610, y: 135 },
  { id: 17, x: 620, y: 270 },
  { id: 18, x: 615, y: 415 }
];

function fmtF(val) {
  let s = val.toFixed(1);
  return s;
}

let out = '';
out += 'script: "/gui/game_over/game_over.gui_script"\n';
out += 'fonts {\n  name: "system_font"\n  font: "/druid/fonts/druid_text_bold.font"\n}\n';
out += 'textures {\n  name: "game"\n  texture: "/main/assets/game.atlas"\n}\n';

function nodeBox(id, pos, size, color, alpha, texture, slice, parent, pivot) {
  let res = 'nodes {\n';
  res += '  position {\n    x: ' + fmtF(pos[0]) + '\n    y: ' + fmtF(pos[1]) + '\n  }\n';
  res += '  size {\n    x: ' + fmtF(size[0]) + '\n    y: ' + fmtF(size[1]) + '\n  }\n';
  res += '  color {\n    x: ' + color[0] + '\n    y: ' + color[1] + '\n    z: ' + color[2] + '\n  }\n';
  res += '  type: TYPE_BOX\n';
  if (texture) res += '  texture: "' + texture + '"\n';
  res += '  id: "' + id + '"\n';
  if (parent) res += '  parent: "' + parent + '"\n';
  if (pivot) res += '  pivot: ' + pivot + '\n';
  res += '  inherit_alpha: true\n';
  if (slice) {
    res += '  slice9 {\n    x: ' + fmtF(slice[0]) + '\n    y: ' + fmtF(slice[1]) + '\n    z: ' + fmtF(slice[2]) + '\n    w: ' + fmtF(slice[3]) + '\n  }\n';
  }
  if (alpha !== undefined) res += '  alpha: ' + alpha + '\n';
  res += '}\n';
  return res;
}

function nodeText(id, pos, size, scale, color, text, parent, pivot) {
  let res = 'nodes {\n';
  res += '  position {\n    x: ' + fmtF(pos[0]) + '\n    y: ' + fmtF(pos[1]) + '\n  }\n';
  if (scale) res += '  scale {\n    x: ' + scale[0] + '\n    y: ' + scale[1] + '\n  }\n';
  res += '  size {\n    x: ' + fmtF(size[0]) + '\n    y: ' + fmtF(size[1]) + '\n  }\n';
  res += '  color {\n    x: ' + color[0] + '\n    y: ' + color[1] + '\n    z: ' + color[2] + '\n  }\n';
  res += '  type: TYPE_TEXT\n';
  res += '  text: "' + text + '"\n';
  res += '  font: "system_font"\n';
  res += '  id: "' + id + '"\n';
  if (parent) res += '  parent: "' + parent + '"\n';
  if (pivot) res += '  pivot: ' + pivot + '\n';
  res += '  inherit_alpha: true\n  outline_alpha: 0.0\n  shadow_alpha: 0.0\n';
  res += '}\n';
  return res;
}

// 1. Overlay
out += nodeBox('overlay', [480, 270], [960, 540], [0.04, 0.06, 0.1], 0.92, 'game/white_pixel');

// 2. Header badge
out += nodeText('header_badge', [480, 502], [600, 26], [0.52, 0.52], [0.4, 0.85, 1.0], '★ ВОЕННАЯ СВОДКА ГЕНШТАБА ★');

// 3. Debrief Banner
out += nodeBox('debrief_banner', [480, 440], [740, 64], [0.10, 0.16, 0.24], 0.95, 'game/box', [4, 4, 4, 4]);
out += nodeText('title_text', [0, 11], [680, 36], [0.85, 0.85], [0.18, 0.82, 0.44], 'СЕКТОР ОСВОБОЖДЕН!', 'debrief_banner');
out += nodeText('subtitle_text', [0, -15], [720, 28], [0.45, 0.45], [0.85, 0.90, 0.95], 'Флаг Синих поднят над освобожденным сектором.', 'debrief_banner');

// 4. Reward Box (Left column)
out += nodeBox('reward_bg', [295, 338], [390, 72], [0.11, 0.17, 0.25], 0.92, 'game/box', [4, 4, 4, 4]);
out += nodeText('reward_text', [0, 13], [440, 32], [0.65, 0.65], [1.0, 0.85, 0.20], '+150 ОЧКОВ', 'reward_bg');
out += nodeText('achieve_text', [0, -14], [640, 26], [0.42, 0.42], [0.35, 0.95, 0.65], '', 'reward_bg');

// 5. Debrief Stats Box
out += nodeBox('debrief_stats_bg', [295, 238], [390, 92], [0.08, 0.13, 0.20], 0.95, 'game/box', [4, 4, 4, 4]);
out += nodeText('txt_stats_title', [0, 27], [500, 26], [0.42, 0.42], [1.0, 0.82, 0.28], '★ БОЕВОЕ ДОНЕСЕНИЕ ★', 'debrief_stats_bg');
out += nodeText('txt_stats_detail', [0, 4], [620, 28], [0.42, 0.42], [0.90, 0.94, 0.98], 'Сектор: Бухта Высадки • Гарнизон разбит', 'debrief_stats_bg');
out += nodeText('txt_stats_front', [0, -21], [620, 28], [0.42, 0.42], [0.45, 0.88, 0.95], 'Укрепления: ★★☆ • Доход: +25🪙/ход', 'debrief_stats_bg');

// 6. Skin Progress
out += nodeBox('skin_progress_bg', [295, 166], [390, 26], [0.07, 0.11, 0.17], 0.95, 'game/box', [4, 4, 4, 4]);
out += nodeText('skin_progress_txt', [0, 0], [680, 24], [0.40, 0.40], [1.0, 0.85, 0.25], '🩑 180 / 250 до скина НИНДЗЯ', 'skin_progress_bg');

// 7. Minimap Panel (Right column)
out += nodeBox('minimap_bg', [675, 252], [310, 244], [0.08, 0.13, 0.20], 0.96, 'game/box', [4, 4, 4, 4]);
out += nodeText('minimap_header', [0, 100], [420, 26], [0.44, 0.44], [0.88, 0.92, 0.98], 'КАРТА ЛИНИИ ФРОНТА', 'minimap_bg');
out += nodeText('minimap_legend', [0, 81], [460, 24], [0.38, 0.38], [0.70, 0.80, 0.90], '🔵 СИНИЕ: 11    🔴 КРАСНЫЕ: 7', 'minimap_bg');
out += nodeBox('minimap_radar_bg', [0, -8], [276, 140], [0.04, 0.07, 0.12], 0.95, 'game/box', [4, 4, 4, 4], 'minimap_bg');

// Pulsing ring
out += nodeBox('m_sec_pulse', [0, 0], [24, 24], [1.0, 0.90, 0.30], 0.65, 'game/circle', null, 'minimap_radar_bg');

// 18 sectors
sectors.forEach(s => {
  const u = (s.x - 85) / 535;
  const v = (s.y - 85) / 350;
  const px = Math.round(-120 + u * 240);
  const py = Math.round(-65 + v * 125);
  out += nodeBox('m_sec_' + s.id, [px, py], [14, 14], [0.20, 0.62, 0.98], 1.0, 'game/circle', null, 'minimap_radar_bg');
});

// Minimap bar
out += nodeBox('minimap_bar_bg', [0, -90], [250, 8], [0.85, 0.25, 0.22], 1.0, 'game/white_pixel', null, 'minimap_bg');
out += nodeBox('minimap_bar_fill', [-125, -90], [150, 8], [0.18, 0.62, 0.95], 1.0, 'game/white_pixel', null, 'minimap_bg', 'PIVOT_W');
out += nodeText('minimap_status_lbl', [0, -106], [460, 24], [0.38, 0.38], [0.35, 0.90, 0.60], 'Контроль острова: 11 / 18 (61%)', 'minimap_bg');

// 8. Action Buttons
out += nodeBox('btn_next_level', [480, 95], [340, 44], [0.18, 0.78, 0.44], 1.0, 'game/box', [4, 4, 4, 4]);
out += nodeText('txt_next_level', [0, 0], [320, 30], [0.58, 0.58], [1.0, 1.0, 1.0], 'ВЕРНУТЬСЯ В ШТАБ 🎖️', 'btn_next_level');

out += nodeBox('btn_revive', [480, 95], [320, 44], [0.16, 0.68, 0.38], 1.0, 'game/box', [4, 4, 4, 4]);
out += nodeText('txt_revive', [0, 0], [320, 30], [0.56, 0.56], [1.0, 1.0, 1.0], 'ВОСКРЕСИТЬСЯ (+50 HP)', 'btn_revive');

out += nodeBox('btn_rematch', [310, 42], [190, 38], [0.78, 0.28, 0.24], 1.0, 'game/box', [4, 4, 4, 4]);
out += nodeText('txt_rematch', [0, 0], [220, 28], [0.46, 0.46], [1.0, 1.0, 1.0], 'ПЕРЕИГРАТЬ 🔄', 'btn_rematch');

out += nodeBox('btn_shop', [510, 42], [170, 38], [0.88, 0.65, 0.15], 1.0, 'game/box', [4, 4, 4, 4]);
out += nodeText('txt_shop', [0, 0], [200, 28], [0.46, 0.46], [1.0, 1.0, 1.0], 'МАГАЗИН 🛒', 'btn_shop');

out += nodeBox('btn_menu', [685, 42], [150, 38], [0.32, 0.36, 0.44], 1.0, 'game/box', [4, 4, 4, 4]);
out += nodeText('txt_menu', [0, 0], [180, 28], [0.46, 0.46], [1.0, 1.0, 1.0], 'В МЕНЮ 🏠', 'btn_menu');

out += 'material: "/builtins/materials/gui.material"\n';

fs.writeFileSync('gui/game_over/game_over.gui', out, 'utf8');
console.log('Successfully written gui/game_over/game_over.gui');
