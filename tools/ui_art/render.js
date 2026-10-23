// Renders the interface art in assets.js to PNG files inside the Defold project.
//
//   node tools/ui_art/render.js            render everything
//   node tools/ui_art/render.js btn_       render only assets whose name contains "btn_"
//
// Needs Node 22+ (built-in WebSocket) and Microsoft Edge or Google Chrome; set BROWSER to override.
// Every asset is { name, w, h, svg } where svg is the inner markup of a w x h SVG.
// Output: main/assets/ui/<name>.png (transparent background).

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT_DIR = path.join(ROOT, 'main', 'assets', 'ui');
const FONT = path.join(ROOT, 'main', 'assets', 'fonts', 'Rubik-Black.ttf');
const PORT = 9341;

const BROWSERS = [
	process.env.BROWSER,
	'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
	'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
	'C:/Program Files/Google/Chrome/Application/chrome.exe',
	'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
	'/usr/bin/google-chrome',
	'/usr/bin/chromium',
].filter(Boolean);

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function main() {
	const filter = process.argv[2] || '';
	const assets = require('./assets.js').filter(a => a.name.includes(filter));
	const browser = BROWSERS.find(p => fs.existsSync(p));
	if (!browser) throw new Error('No Edge/Chrome found; set BROWSER=/path/to/browser');
	fs.mkdirSync(OUT_DIR, { recursive: true });

	const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'ui-art-'));
	const proc = spawn(browser, [
		'--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
		'--no-first-run', '--no-default-browser-check', '--force-device-scale-factor=1', 'about:blank',
	], { stdio: 'ignore' });

	let page;
	for (let i = 0; i < 60 && !page; i++) {
		try {
			const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
			page = list.find(t => t.type === 'page');
		} catch (e) { /* browser still starting */ }
		if (!page) await sleep(200);
	}
	const ws = new WebSocket(page.webSocketDebuggerUrl);
	await new Promise(r => ws.addEventListener('open', r));
	let id = 0;
	const pending = new Map();
	ws.addEventListener('message', ev => {
		const m = JSON.parse(ev.data);
		if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
	});
	const send = (method, params = {}) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });

	const font = fs.readFileSync(FONT).toString('base64');
	const html = `<html><head><style>@font-face{font-family:'Rubik';src:url(data:font/ttf;base64,${font});}
		html,body{margin:0;padding:0;background:transparent;} svg{display:block;}</style></head><body><div id="c"></div></body></html>`;
	await send('Page.enable');
	await send('Page.navigate', { url: 'data:text/html;base64,' + Buffer.from(html).toString('base64') });
	await sleep(600);
	await send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } });

	for (const a of assets) {
		const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${a.w}" height="${a.h}" viewBox="0 0 ${a.w} ${a.h}" style="font-family:Rubik">${a.svg}</svg>`;
		await send('Runtime.evaluate', { expression: `document.getElementById('c').innerHTML = ${JSON.stringify(svg)}; document.fonts.ready.then(() => 1)`, awaitPromise: true });
		const r = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: a.w, height: a.h, scale: 1 }, captureBeyondViewport: true });
		fs.writeFileSync(path.join(OUT_DIR, a.name + '.png'), Buffer.from(r.result.data, 'base64'));
	}
	console.log(`rendered ${assets.length} assets into ${path.relative(ROOT, OUT_DIR)}`);
	ws.close();
	proc.kill();
	process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
