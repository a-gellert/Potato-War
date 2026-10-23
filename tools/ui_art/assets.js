// Interface art for the "military midcore" look: dark navy steel panels, gold accents,
// bevelled buttons, rarity card frames, icons, supply crates and rank insignia.
// Rendered by render.js into main/assets/ui/*.png (atlas: main/assets/ui.atlas).
// Panels, buttons, frames and bars are drawn for slice-9 scaling: keep their corners within
// the slice margins used by lua_modules/ui_kit.lua.

const OUT = '#050a12'; // outline / darkest navy
const INK = '#0d1726'; // icon outline

const RARITY = {
	common: { light: '#c3ccd6', mid: '#8b98a8', dark: '#4f5b6b' },
	rare: { light: '#8cc8ff', mid: '#3d93f2', dark: '#1a4f95' },
	epic: { light: '#d8a8ff', mid: '#a45cf0', dark: '#5c2a9e' },
	legendary: { light: '#ffe48a', mid: '#f4b52e', dark: '#a8630b' },
};

let uid = 0;
const id = p => `${p}${++uid}`;

function rr(x, y, w, h, r) {
	r = Math.min(r, w / 2, h / 2);
	return `M${x + r},${y} H${x + w - r} Q${x + w},${y} ${x + w},${y + r} V${y + h - r} Q${x + w},${y + h} ${x + w - r},${y + h} H${x + r} Q${x},${y + h} ${x},${y + h - r} V${y + r} Q${x},${y} ${x + r},${y} Z`;
}

function vgrad(gid, stops) {
	return `<linearGradient id="${gid}" x1="0" y1="0" x2="0" y2="1">${stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('')}</linearGradient>`;
}

function rgrad(gid, stops) {
	return `<radialGradient id="${gid}" cx="0.5" cy="0.5" r="0.5">${stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('')}</radialGradient>`;
}

// Polygon star path
function star(cx, cy, ro, ri, n = 5, rot = -90) {
	let d = '';
	for (let i = 0; i < n * 2; i++) {
		const r = i % 2 === 0 ? ro : ri;
		const a = (rot + i * 180 / n) * Math.PI / 180;
		d += (i === 0 ? 'M' : 'L') + (cx + Math.cos(a) * r).toFixed(2) + ',' + (cy + Math.sin(a) * r).toFixed(2);
	}
	return d + 'Z';
}

// Path drawn twice: thick dark outline under the coloured fill
function outlined(d, fill, sw = 3, extra = '') {
	return `<path d="${d}" fill="${INK}" stroke="${INK}" stroke-width="${sw * 2}" stroke-linejoin="round"/><path d="${d}" fill="${fill}" ${extra}/>`;
}

const assets = [];
const add = (name, w, h, svg) => assets.push({ name, w, h, svg });

// ---------- panels ----------

{
	const g = id('pg');
	add('panel', 96, 96, `<defs>${vgrad(g, [[0, '#213656'], [1, '#101c30']])}</defs>
		<path d="${rr(0, 0, 96, 96, 14)}" fill="${OUT}"/>
		<path d="${rr(2, 2, 92, 92, 12)}" fill="url(#${g})"/>
		<path d="${rr(5.5, 5.5, 85, 85, 9)}" fill="none" stroke="#3d5f87" stroke-width="1.5" stroke-opacity="0.85"/>
		<path d="M14,3.5 H82" stroke="#ffffff" stroke-opacity="0.14" stroke-width="1"/>
		${[[11, 11], [85, 11], [11, 85], [85, 85]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="2.8" fill="#4f7099" stroke="${OUT}" stroke-width="1.2"/><circle cx="${x - 0.7}" cy="${y - 0.7}" r="0.9" fill="#a9c2de"/>`).join('')}`);
}
{
	const g = id('ig');
	add('panel_inset', 64, 64, `<defs>${vgrad(g, [[0, '#050b15'], [0.25, '#0b1524'], [1, '#0e1a2c']])}</defs>
		<path d="${rr(0, 0, 64, 64, 10)}" fill="#03070d"/>
		<path d="${rr(1.5, 1.5, 61, 61, 8.5)}" fill="url(#${g})"/>
		<path d="${rr(1.5, 1.5, 61, 61, 8.5)}" fill="none" stroke="#24405f" stroke-width="1"/>`);
}
{
	const g = id('hg');
	add('header', 128, 44, `<defs>${vgrad(g, [[0, '#33557f'], [1, '#1b2f4c']])}</defs>
		<path d="${rr(0, 0, 128, 44, 10)}" fill="${OUT}"/>
		<path d="${rr(2, 2, 124, 38, 8)}" fill="url(#${g})"/>
		<rect x="2" y="36" width="124" height="4" fill="#f0b53a"/>
		<rect x="2" y="39.5" width="124" height="1.5" fill="#8a5a12"/>
		<path d="M12,3.5 H116" stroke="#ffffff" stroke-opacity="0.18" stroke-width="1"/>`);
}
add('dim', 8, 8, `<rect width="8" height="8" fill="#03060c"/>`);
add('white', 8, 8, `<rect width="8" height="8" fill="#ffffff"/>`);

// ---------- buttons ----------

function button(name, top, bottom, lip, rim) {
	const w = 128, h = 56, g = id('bg');
	add(name, w, h, `<defs>${vgrad(g, [[0, top], [1, bottom]])}</defs>
		<path d="${rr(1, 1, w - 2, h - 2, 13)}" fill="${OUT}"/>
		<path d="${rr(3, 3, w - 6, h - 6, 11)}" fill="${lip}"/>
		<path d="${rr(3, 3, w - 6, h - 12, 11)}" fill="url(#${g})"/>
		<path d="${rr(8, 6, w - 16, (h - 12) * 0.42, 7)}" fill="#ffffff" opacity="0.2"/>
		<path d="${rr(3.5, 3.5, w - 7, h - 13, 10.5)}" fill="none" stroke="${rim}" stroke-opacity="0.75" stroke-width="1.2"/>`);
}
button('btn_gold', '#ffdb63', '#e48d18', '#8f5309', '#fff1b8');
button('btn_green', '#86dc55', '#3a9a2a', '#225c18', '#d6ffbf');
button('btn_blue', '#61aef4', '#2768c0', '#173f74', '#d2eaff');
button('btn_red', '#f4705f', '#c22f27', '#731a13', '#ffd3cc');
button('btn_steel', '#6f86a3', '#3f5470', '#253244', '#c9d8ea');
button('btn_dark', '#2a405f', '#16243a', '#0a121e', '#5f80a8');

{
	const g = id('rb');
	add('round', 64, 64, `<defs>${vgrad(g, [[0, '#7891b0'], [1, '#3a4e68']])}</defs>
		<circle cx="32" cy="32" r="31" fill="${OUT}"/>
		<circle cx="32" cy="33.5" r="28.5" fill="#222f40"/>
		<circle cx="32" cy="31" r="27.5" fill="url(#${g})"/>
		<ellipse cx="32" cy="20" rx="18" ry="9" fill="#ffffff" opacity="0.2"/>
		<circle cx="32" cy="31" r="27" fill="none" stroke="#d3e1f2" stroke-opacity="0.55" stroke-width="1.2"/>`);
}
{
	const g = id('rg');
	add('round_gold', 64, 64, `<defs>${vgrad(g, [[0, '#ffdb63'], [1, '#e48d18']])}</defs>
		<circle cx="32" cy="32" r="31" fill="${OUT}"/>
		<circle cx="32" cy="33.5" r="28.5" fill="#8f5309"/>
		<circle cx="32" cy="31" r="27.5" fill="url(#${g})"/>
		<ellipse cx="32" cy="20" rx="18" ry="9" fill="#ffffff" opacity="0.25"/>`);
}
add('badge', 28, 28, `<circle cx="14" cy="14" r="13" fill="${OUT}"/><circle cx="14" cy="14" r="11" fill="#ffffff"/><circle cx="14" cy="14" r="9" fill="#e5392b"/><ellipse cx="14" cy="10" rx="5" ry="2.5" fill="#fff" opacity="0.35"/>`);
{
	const g = id('pl');
	add('pill', 48, 28, `<defs>${vgrad(g, [[0, '#060d18'], [1, '#0f1b2d']])}</defs>
		<path d="${rr(0, 0, 48, 28, 14)}" fill="#02050a" opacity="0.9"/>
		<path d="${rr(1.5, 1.5, 45, 25, 12.5)}" fill="url(#${g})"/>
		<path d="${rr(1.5, 1.5, 45, 25, 12.5)}" fill="none" stroke="#2c4a70" stroke-width="1.2"/>`);
}

// ---------- bars ----------

{
	const g = id('bb');
	add('bar_bg', 40, 20, `<defs>${vgrad(g, [[0, '#03070d'], [1, '#0e1a2b']])}</defs>
		<path d="${rr(0, 0, 40, 20, 10)}" fill="${OUT}"/>
		<path d="${rr(1.5, 1.5, 37, 17, 8.5)}" fill="url(#${g})"/>`);
	const f = id('bf');
	add('bar_fill', 40, 20, `<defs>${vgrad(f, [[0, '#ffffff'], [1, '#bcc9d9']])}</defs>
		<path d="${rr(2, 2, 36, 16, 8)}" fill="url(#${f})"/>
		<path d="${rr(5, 4, 30, 5, 2.5)}" fill="#ffffff" opacity="0.6"/>`);
}
{
	const g = id('kn');
	add('knob', 40, 40, `<defs>${vgrad(g, [[0, '#ffe07a'], [1, '#e08f1c']])}</defs>
		<circle cx="20" cy="20" r="19" fill="${OUT}"/><circle cx="20" cy="20" r="16.5" fill="url(#${g})"/>
		<ellipse cx="20" cy="13" rx="10" ry="5" fill="#fff" opacity="0.35"/>`);
}

// ---------- rarity card frames ----------

for (const [r, c] of Object.entries(RARITY)) {
	const w = 96, h = 120, gb = id('cb'), gf = id('cf'), gs = id('cs');
	add(`card_${r}`, w, h, `<defs>${vgrad(gb, [[0, c.light], [1, c.dark]])}${vgrad(gf, [[0, '#1d3050'], [1, '#0d1829']])}${vgrad(gs, [[0, c.mid], [1, c.dark]])}</defs>
		<path d="${rr(0, 0, w, h, 12)}" fill="${OUT}"/>
		<path d="${rr(2, 2, w - 4, h - 4, 10)}" fill="url(#${gb})"/>
		<path d="${rr(5, 5, w - 10, h - 10, 8)}" fill="url(#${gf})"/>
		<path d="${rr(5, h - 29, w - 10, 24, 6)}" fill="url(#${gs})"/>
		<path d="M5,${h - 29.5} H${w - 5}" stroke="${OUT}" stroke-opacity="0.6" stroke-width="1"/>
		<path d="M5,13 V5 H13 Z" fill="${c.light}"/>
		<path d="M${w - 5},13 V5 H${w - 13} Z" fill="${c.light}"/>
		<path d="${rr(5.5, 5.5, w - 11, h - 11, 7.5)}" fill="none" stroke="#ffffff" stroke-opacity="0.12" stroke-width="1"/>`);
}
// Selection glow around a card
add('card_select', 96, 120, `<path d="${rr(1.5, 1.5, 93, 117, 12)}" fill="none" stroke="#ffe27a" stroke-width="3"/><path d="${rr(4, 4, 88, 112, 10)}" fill="none" stroke="#ffffff" stroke-opacity="0.6" stroke-width="1.2"/>`);

// ---------- light ----------

{
	const g = id('gl');
	add('glow', 128, 128, `<defs>${rgrad(g, [[0, '#ffffff', 1], [0.35, '#ffffff', 0.55], [1, '#ffffff', 0]])}</defs><circle cx="64" cy="64" r="64" fill="url(#${g})"/>`);
	const rg = id('ry');
	let rays = '';
	for (let i = 0; i < 14; i++) {
		const a = i * 360 / 14;
		rays += `<path d="M128,128 L${128 + 128 * Math.cos((a - 6) * Math.PI / 180)},${128 + 128 * Math.sin((a - 6) * Math.PI / 180)} L${128 + 128 * Math.cos((a + 6) * Math.PI / 180)},${128 + 128 * Math.sin((a + 6) * Math.PI / 180)} Z" fill="#ffffff"/>`;
	}
	add('rays', 256, 256, `<defs>${rgrad(rg, [[0, '#ffffff', 1], [0.25, '#ffffff', 1], [1, '#ffffff', 0]])}<mask id="${rg}m"><circle cx="128" cy="128" r="128" fill="url(#${rg})"/></mask></defs><g mask="url(#${rg}m)" opacity="0.8">${rays}</g>`);
	const vg = id('vg');
	add('vignette', 128, 128, `<defs>${rgrad(vg, [[0, '#03060c', 0], [0.55, '#03060c', 0.25], [1, '#03060c', 0.9]])}</defs><rect width="128" height="128" fill="url(#${vg})"/>`);
}

// ---------- icons (64 x 64) ----------

function icon(name, svg) {
	add(name, 64, 64, svg);
}

{
	const g = id('co');
	icon('ic_coin', `<defs>${vgrad(g, [[0, '#ffe58a'], [1, '#e19a1d']])}</defs>
		<circle cx="32" cy="32" r="26" fill="${INK}"/>
		<circle cx="32" cy="34" r="23" fill="#9b5f0c"/>
		<circle cx="32" cy="31" r="23" fill="url(#${g})"/>
		<circle cx="32" cy="31" r="16.5" fill="none" stroke="#b87414" stroke-width="2.5"/>
		<ellipse cx="32" cy="31" rx="8.5" ry="10.5" fill="#c98419" transform="rotate(-20 32 31)"/>
		<circle cx="29" cy="28" r="1.4" fill="#8a520b"/><circle cx="35" cy="33" r="1.4" fill="#8a520b"/><circle cx="30" cy="35" r="1.1" fill="#8a520b"/>
		<ellipse cx="25" cy="20" rx="8" ry="4" fill="#fff" opacity="0.55" transform="rotate(-30 25 20)"/>`);
}
{
	const g = id('st');
	icon('ic_star', `<defs>${vgrad(g, [[0, '#fff09a'], [1, '#f0a020']])}</defs>
		${outlined(star(32, 34, 27, 12), `url(#${g})`, 3)}
		<path d="${star(32, 34, 27, 12)}" fill="none" stroke="#fff6c8" stroke-opacity="0.6" stroke-width="1.5"/>
		<ellipse cx="25" cy="25" rx="5" ry="3" fill="#fff" opacity="0.6" transform="rotate(-35 25 25)"/>`);
}
{
	const g = id('lv');
	const hex = 'M32,5 L55,18 L55,45 L32,59 L9,45 L9,18 Z';
	icon('ic_level', `<defs>${vgrad(g, [[0, '#3f78bf'], [1, '#1d3f73']])}</defs>
		${outlined(hex, '#f4b52e', 3)}
		<path d="M32,10 L50.5,20.5 L50.5,42.5 L32,53.5 L13.5,42.5 L13.5,20.5 Z" fill="url(#${g})"/>
		<path d="M32,10 L50.5,20.5 L32,23 L13.5,20.5 Z" fill="#ffffff" opacity="0.18"/>`);
}
{
	icon('ic_blueprint', `
		${outlined('M10,16 H48 Q54,16 54,22 V48 H16 Q10,48 10,42 Z', '#2f7ad8', 3)}
		<path d="M14,20 H48 V44 H16 Z" fill="#3a8be8"/>
		${[24, 30, 36, 42].map(x => `<path d="M${x},20 V44" stroke="#9fd0ff" stroke-opacity="0.55" stroke-width="1"/>`).join('')}
		${[26, 32, 38].map(y => `<path d="M14,${y} H48" stroke="#9fd0ff" stroke-opacity="0.55" stroke-width="1"/>`).join('')}
		<path d="M22,40 L30,26 L38,40 Z" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linejoin="round"/>
		<circle cx="42" cy="28" r="3.5" fill="none" stroke="#ffffff" stroke-width="2"/>
		${outlined('M48,16 Q58,16 58,26 V44 Q58,50 52,50 Q48,50 48,46 Z', '#5aa8f6', 2.5)}
		<path d="M52,20 V44" stroke="#c8e6ff" stroke-width="1.5" stroke-opacity="0.8"/>`);
}
{
	let teeth = '';
	for (let i = 0; i < 8; i++) {
		const a = i * 45;
		teeth += `<rect x="27" y="4" width="10" height="14" rx="2" transform="rotate(${a} 32 32)"/>`;
	}
	icon('ic_gear', `<g fill="${INK}" stroke="${INK}" stroke-width="6" stroke-linejoin="round">${teeth}<circle cx="32" cy="32" r="18"/></g>
		<g fill="#a9bed6">${teeth}<circle cx="32" cy="32" r="18"/></g>
		<circle cx="32" cy="32" r="7.5" fill="${INK}"/><circle cx="32" cy="32" r="13" fill="none" stroke="#7d93ad" stroke-width="2"/>
		<ellipse cx="26" cy="22" rx="6" ry="3" fill="#fff" opacity="0.45" transform="rotate(-35 26 22)"/>`);
}
icon('ic_close', `<path d="M16,16 L48,48 M48,16 L16,48" stroke="${INK}" stroke-width="16" stroke-linecap="round"/><path d="M16,16 L48,48 M48,16 L16,48" stroke="#ffffff" stroke-width="8" stroke-linecap="round"/>`);
icon('ic_check', `<path d="M13,33 L26,46 L51,18" fill="none" stroke="${INK}" stroke-width="17" stroke-linecap="round" stroke-linejoin="round"/><path d="M13,33 L26,46 L51,18" fill="none" stroke="#6ee04a" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>`);
icon('ic_plus', `<path d="M32,13 V51 M13,32 H51" stroke="${INK}" stroke-width="17" stroke-linecap="round"/><path d="M32,13 V51 M13,32 H51" stroke="#ffffff" stroke-width="9" stroke-linecap="round"/>`);
icon('ic_minus', `<path d="M13,32 H51" stroke="${INK}" stroke-width="17" stroke-linecap="round"/><path d="M13,32 H51" stroke="#ffffff" stroke-width="9" stroke-linecap="round"/>`);
icon('ic_left', `<path d="M40,12 L20,32 L40,52" fill="none" stroke="${INK}" stroke-width="17" stroke-linecap="round" stroke-linejoin="round"/><path d="M40,12 L20,32 L40,52" fill="none" stroke="#ffffff" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>`);
icon('ic_right', `<path d="M24,12 L44,32 L24,52" fill="none" stroke="${INK}" stroke-width="17" stroke-linecap="round" stroke-linejoin="round"/><path d="M24,12 L44,32 L24,52" fill="none" stroke="#ffffff" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>`);
{
	const g = id('up');
	icon('ic_up', `<defs>${vgrad(g, [[0, '#9cf06a'], [1, '#2f9a24']])}</defs>${outlined('M32,6 L56,32 H42 V56 H22 V32 H8 Z', `url(#${g})`, 3)}<path d="M32,12 L48,29 H38 V50" fill="none" stroke="#ffffff" stroke-opacity="0.45" stroke-width="2"/>`);
}
{
	const g = id('lk');
	icon('ic_lock', `<defs>${vgrad(g, [[0, '#ffd45e'], [1, '#d6871a']])}</defs>
		<path d="M20,30 V22 Q20,9 32,9 Q44,9 44,22 V30" fill="none" stroke="${INK}" stroke-width="14"/>
		<path d="M20,30 V22 Q20,9 32,9 Q44,9 44,22 V30" fill="none" stroke="#a7b8cc" stroke-width="7"/>
		${outlined(rr(12, 28, 40, 28, 6), `url(#${g})`, 3)}
		<circle cx="32" cy="39" r="4.5" fill="${INK}"/><rect x="30" y="40" width="4" height="9" rx="2" fill="${INK}"/>`);
}
{
	icon('ic_map', `
		${outlined('M8,14 L24,8 L40,14 L56,8 V50 L40,56 L24,50 L8,56 Z', '#e9d6a4', 3)}
		<path d="M24,8 V50 M40,14 V56" stroke="#b49a63" stroke-width="2"/>
		<path d="M14,40 Q22,30 30,36 T44,24" fill="none" stroke="#7a5b2a" stroke-width="2" stroke-dasharray="3 3"/>
		<path d="M41,17 L51,27 M51,17 L41,27" stroke="#d6362a" stroke-width="5" stroke-linecap="round"/>`);
}
{
	const g = id('ar');
	icon('ic_arsenal', `<defs>${vgrad(g, [[0, '#ffd877'], [1, '#c98419']])}</defs>
		<circle cx="32" cy="32" r="24" fill="none" stroke="${INK}" stroke-width="9"/>
		<circle cx="32" cy="32" r="24" fill="none" stroke="#d6413a" stroke-width="4"/>
		<path d="M32,4 V16 M32,48 V60 M4,32 H16 M48,32 H60" stroke="${INK}" stroke-width="9" stroke-linecap="round"/>
		<path d="M32,4 V16 M32,48 V60 M4,32 H16 M48,32 H60" stroke="#d6413a" stroke-width="4" stroke-linecap="round"/>
		${outlined('M26,50 V30 Q26,18 32,12 Q38,18 38,30 V50 Z', `url(#${g})`, 3)}
		<rect x="25" y="44" width="14" height="7" fill="#a86414"/>
		<path d="M30,18 Q29,26 29,40" stroke="#fff" stroke-opacity="0.6" stroke-width="2"/>`);
}
{
	const g = id('hm');
	icon('ic_squad', `<defs>${vgrad(g, [[0, '#7fa35a'], [1, '#3f5e2a']])}</defs>
		${outlined('M8,42 Q8,14 32,12 Q56,14 56,42 Z', `url(#${g})`, 3)}
		${outlined(rr(4, 40, 56, 10, 5), '#4a6b32', 3)}
		<path d="${star(32, 29, 9, 4)}" fill="#f4c443" stroke="${INK}" stroke-width="1.5"/>
		<ellipse cx="22" cy="22" rx="8" ry="4" fill="#fff" opacity="0.3" transform="rotate(-30 22 22)"/>`);
}
{
	icon('ic_hat', `
		${outlined(rr(18, 10, 28, 34, 4), '#2b2f3a', 3)}
		${outlined('M6,46 Q32,38 58,46 Q58,52 32,52 Q6,52 6,46 Z', '#2b2f3a', 3)}
		<rect x="18" y="34" width="28" height="7" fill="#d6413a"/>
		<path d="M22,14 V32" stroke="#fff" stroke-opacity="0.25" stroke-width="3"/>`);
}
{
	icon('ic_battle', `
		<g stroke-linecap="round">
		<path d="M12,12 L44,44 M52,12 L20,44" stroke="${INK}" stroke-width="13"/>
		<path d="M12,12 L44,44 M52,12 L20,44" stroke="#d8e2ee" stroke-width="6"/>
		<path d="M38,50 L50,38 M14,38 L26,50" stroke="${INK}" stroke-width="12"/>
		<path d="M38,50 L50,38 M14,38 L26,50" stroke="#f4b52e" stroke-width="6"/>
		<path d="M46,46 L56,56 M18,46 L8,56" stroke="${INK}" stroke-width="10"/>
		<path d="M46,46 L56,56 M18,46 L8,56" stroke="#8a5a2a" stroke-width="5"/></g>`);
}
{
	const speaker = 'M8,24 H20 L34,12 V52 L20,40 H8 Z';
	icon('ic_sound', `${outlined(speaker, '#e6edf5', 3)}<path d="M41,22 Q47,32 41,42 M47,15 Q57,32 47,49" fill="none" stroke="${INK}" stroke-width="9" stroke-linecap="round"/><path d="M41,22 Q47,32 41,42 M47,15 Q57,32 47,49" fill="none" stroke="#e6edf5" stroke-width="4" stroke-linecap="round"/>`);
	icon('ic_mute', `${outlined(speaker, '#9aa7b8', 3)}<path d="M42,22 L56,42 M56,22 L42,42" stroke="${INK}" stroke-width="10" stroke-linecap="round"/><path d="M42,22 L56,42 M56,22 L42,42" stroke="#e5392b" stroke-width="5" stroke-linecap="round"/>`);
	icon('ic_music', `<path d="M24,46 V14 L52,8 V40" fill="none" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/><path d="M24,46 V14 L52,8 V40" fill="none" stroke="#e6edf5" stroke-width="5" stroke-linejoin="round"/>
		${outlined('M10,48 A9,7 0 1,0 28,48 A9,7 0 1,0 10,48 Z', '#e6edf5', 3)}${outlined('M38,42 A9,7 0 1,0 56,42 A9,7 0 1,0 38,42 Z', '#e6edf5', 3)}`);
}
{
	icon('ic_ad', `${outlined(rr(6, 12, 52, 40, 8), '#ffffff', 3)}<path d="${rr(10, 16, 44, 32, 5)}" fill="#3a8be8"/><path d="M27,22 L42,32 L27,42 Z" fill="#ffffff" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>`);
}
{
	const g = id('tr');
	icon('ic_trophy', `<defs>${vgrad(g, [[0, '#ffe48a'], [1, '#d98a17']])}</defs>
		<path d="M18,14 Q4,14 8,26 Q12,34 22,34 M46,14 Q60,14 56,26 Q52,34 42,34" fill="none" stroke="${INK}" stroke-width="9"/>
		<path d="M18,14 Q4,14 8,26 Q12,34 22,34 M46,14 Q60,14 56,26 Q52,34 42,34" fill="none" stroke="#e8a52a" stroke-width="4"/>
		${outlined('M16,8 H48 V22 Q48,40 32,42 Q16,40 16,22 Z', `url(#${g})`, 3)}
		${outlined(rr(26, 42, 12, 8, 2), '#c98419', 2.5)}${outlined(rr(18, 50, 28, 8, 3), '#8a5a2a', 3)}
		<path d="M22,12 Q21,26 26,34" stroke="#fff" stroke-opacity="0.5" stroke-width="3" fill="none"/>`);
}
icon('ic_skull', `${outlined('M32,6 Q54,6 54,28 Q54,38 46,42 V52 H18 V42 Q10,38 10,28 Q10,6 32,6 Z', '#f0f2f5', 3)}
	<ellipse cx="23" cy="28" rx="6" ry="7" fill="${INK}"/><ellipse cx="41" cy="28" rx="6" ry="7" fill="${INK}"/><path d="M32,36 L28,42 H36 Z" fill="${INK}"/>
	<path d="M26,46 V52 M32,46 V52 M38,46 V52" stroke="${INK}" stroke-width="2.5"/>`);
icon('ic_heart', `${outlined('M32,54 Q8,38 8,22 Q8,10 20,10 Q28,10 32,18 Q36,10 44,10 Q56,10 56,22 Q56,38 32,54 Z', '#e8433a', 3)}<ellipse cx="20" cy="20" rx="6" ry="4" fill="#fff" opacity="0.5" transform="rotate(-30 20 20)"/>`);
icon('ic_damage', `${outlined(star(32, 32, 28, 13, 8, -90), '#ff9a2e', 3)}<path d="${star(32, 32, 16, 8, 8, -70)}" fill="#ffe36a"/>`);
icon('ic_radius', `<circle cx="32" cy="32" r="25" fill="none" stroke="${INK}" stroke-width="8"/><circle cx="32" cy="32" r="25" fill="none" stroke="#ffb340" stroke-width="3.5" stroke-dasharray="7 4"/><circle cx="32" cy="32" r="12" fill="${INK}"/><circle cx="32" cy="32" r="8.5" fill="#ff7a2e"/>`);
{
	const g = id('am');
	icon('ic_ammo', `<defs>${vgrad(g, [[0, '#ffd877'], [1, '#c98419']])}</defs>
		${outlined('M14,54 V30 Q14,20 20,14 Q26,20 26,30 V54 Z', `url(#${g})`, 2.5)}
		${outlined('M38,54 V30 Q38,20 44,14 Q50,20 50,30 V54 Z', `url(#${g})`, 2.5)}
		<rect x="13" y="48" width="14" height="6" fill="#a86414"/><rect x="37" y="48" width="14" height="6" fill="#a86414"/>`);
}
icon('ic_globe', `<circle cx="32" cy="32" r="25" fill="${INK}"/><circle cx="32" cy="32" r="22" fill="#3a8be8"/>
	<path d="M18,20 Q26,16 30,22 Q28,30 20,30 Q14,28 18,20 Z M36,30 Q46,26 50,36 Q46,46 38,44 Q34,38 36,30 Z" fill="#6ee04a" stroke="${INK}" stroke-width="1.5"/>
	<ellipse cx="32" cy="32" rx="22" ry="9" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.5"/><path d="M32,10 V54" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.5"/>`);
icon('ic_home', `${outlined('M8,30 L32,8 L56,30 H48 V54 H16 V30 Z', '#e6edf5', 3)}<rect x="26" y="38" width="12" height="16" fill="#d6413a" stroke="${INK}" stroke-width="2"/>`);
icon('ic_retry', `<path d="M48,24 A18,18 0 1,0 50,38" fill="none" stroke="${INK}" stroke-width="13" stroke-linecap="round"/><path d="M48,24 A18,18 0 1,0 50,38" fill="none" stroke="#ffffff" stroke-width="7" stroke-linecap="round"/>${outlined('M40,10 L56,22 L38,28 Z', '#ffffff', 2.5)}`);
icon('ic_flag', `<path d="M14,8 V58" stroke="${INK}" stroke-width="9" stroke-linecap="round"/><path d="M14,8 V58" stroke="#c9d4e2" stroke-width="4" stroke-linecap="round"/>${outlined('M17,10 H52 L44,22 L52,34 H17 Z', '#3d93f2', 3)}<path d="${star(32, 22, 6, 2.6)}" fill="#ffffff"/>`);
icon('ic_xp', `${outlined('M8,40 L32,20 L56,40 L56,52 L32,32 L8,52 Z', '#4aa3ff', 3)}${outlined('M8,22 L32,4 L56,22 L56,32 L32,14 L8,32 Z', '#8cc8ff', 3)}`);

// ---------- supply crates ----------

function crate(tier, body, plank, metal, accent) {
	const gb = id('cr'), gm = id('cm');
	const defs = `<defs>${vgrad(gb, [[0, body[0]], [1, body[1]]])}${vgrad(gm, [[0, metal[0]], [1, metal[1]]])}</defs>`;
	let planks = '';
	for (let y = 28; y < 84; y += 14) planks += `<path d="M14,${y} H114" stroke="${plank}" stroke-width="2"/>`;
	add(`crate_${tier}`, 128, 96, `${defs}
		${outlined(rr(10, 8, 108, 80, 8), `url(#${gb})`, 3)}
		${planks}
		${outlined(rr(10, 8, 18, 80, 6), `url(#${gm})`, 2)}${outlined(rr(100, 8, 18, 80, 6), `url(#${gm})`, 2)}
		${[18, 74].map(y => `<circle cx="19" cy="${y}" r="2.5" fill="${metal[2]}"/><circle cx="109" cy="${y}" r="2.5" fill="${metal[2]}"/>`).join('')}
		${outlined(rr(46, 30, 36, 36, 8), accent, 2.5)}
		<path d="${star(64, 49, 13, 5.5)}" fill="#ffffff" opacity="0.92"/>
		<path d="M16,12 H112" stroke="#ffffff" stroke-opacity="0.25" stroke-width="2"/>`);
	add(`crate_${tier}_lid`, 136, 32, `${defs}
		${outlined(rr(6, 4, 124, 24, 7), `url(#${gb})`, 3)}
		${outlined(rr(6, 4, 22, 24, 6), `url(#${gm})`, 2)}${outlined(rr(108, 4, 22, 24, 6), `url(#${gm})`, 2)}
		<path d="M12,8 H124" stroke="#ffffff" stroke-opacity="0.3" stroke-width="2"/>`);
}
crate('wood', ['#c9894a', '#8a5528'], '#6e3f1a', ['#b9c6d4', '#6d7f94', '#3a4757'], '#7a4a1e');
crate('steel', ['#8fa3b8', '#4e6176'], '#3a4a5c', ['#ffd45e', '#d6871a', '#7a4a0a'], '#2c5f9e');
crate('gold', ['#ffe07a', '#d98c17'], '#a8650d', ['#fff3c4', '#e8b54a', '#8a5a0a'], '#c43a2c');

// ---------- rank insignia (48 x 48) ----------

const SHIELD = 'M7,5 H41 V24 Q41,38 24,44 Q7,38 7,24 Z';
function chevron(y, color) {
	return `<path d="M13,${y} L24,${y - 7} L35,${y} V${y + 5} L24,${y - 2} L13,${y + 5} Z" fill="${color}" stroke="${INK}" stroke-width="1.6" stroke-linejoin="round"/>`;
}
function rocker(y, color) {
	return `<path d="M13,${y} Q24,${y + 7} 35,${y} V${y + 4.5} Q24,${y + 11.5} 13,${y + 4.5} Z" fill="${color}" stroke="${INK}" stroke-width="1.6" stroke-linejoin="round"/>`;
}
function bar(y, color) {
	return `<rect x="15" y="${y}" width="18" height="6" rx="1.5" fill="${color}" stroke="${INK}" stroke-width="1.6"/>`;
}
function rank(n, inner, officer) {
	const g = id('rk');
	add(`rank_${n}`, 48, 48, `<defs>${vgrad(g, [[0, officer ? '#3a2a12' : '#22385a'], [1, officer ? '#1e150a' : '#111d30']])}</defs>
		<path d="${SHIELD}" fill="${INK}" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
		<path d="${SHIELD}" fill="url(#${g})" stroke="${officer ? '#f4b52e' : '#7f97b3'}" stroke-width="2" stroke-linejoin="round"/>
		${inner}`);
}
const SILVER = '#dbe5f0', GOLD = '#f6c443';
rank(1, chevron(22, SILVER));
rank(2, chevron(17, SILVER) + chevron(26, SILVER));
rank(3, chevron(13, SILVER) + chevron(21, SILVER) + chevron(29, SILVER));
rank(4, chevron(12, SILVER) + chevron(19, SILVER) + chevron(26, SILVER) + rocker(30, GOLD));
rank(5, chevron(11, SILVER) + chevron(17, SILVER) + chevron(23, SILVER) + rocker(27, GOLD) + rocker(33, GOLD));
rank(6, chevron(13, SILVER) + chevron(20, SILVER) + chevron(27, SILVER) + `<path d="${star(24, 34, 6, 2.6)}" fill="${GOLD}" stroke="${INK}" stroke-width="1.4"/>`);
rank(7, bar(19, GOLD), true);
rank(8, bar(14, GOLD) + bar(24, GOLD), true);
rank(9, `<path d="${star(24, 22, 11, 4.6)}" fill="${GOLD}" stroke="${INK}" stroke-width="1.8"/>`, true);
rank(10, `<path d="${star(16.5, 20, 7.5, 3.2)}" fill="${GOLD}" stroke="${INK}" stroke-width="1.6"/><path d="${star(31.5, 20, 7.5, 3.2)}" fill="${GOLD}" stroke="${INK}" stroke-width="1.6"/><path d="${star(24, 32, 6, 2.6)}" fill="${GOLD}" stroke="${INK}" stroke-width="1.4"/>`, true);

module.exports = assets;
