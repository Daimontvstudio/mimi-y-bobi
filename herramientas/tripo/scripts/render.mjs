// GLB de Tripo → hojas de sprites isométricas (8 direcciones × fotogramas de la animación), fondo transparente.
// Para juegos 2D (canvas, Godot 2D): el 3D se ilumina una vez y el juego solo dibuja imágenes.
//   node herramientas/tripo/scripts/render.mjs --dir arte/tripo/guerrero --elev 30 --size 256 --frames 8
// Necesita: npm i three@0.170.0 playwright@1 (lo instala el workflow) y Chromium de Playwright.
import { createServer } from 'node:http';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import { join, resolve, extname } from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const args = Object.fromEntries(process.argv.slice(2).reduce((acc, v, i, a) => (v.startsWith('--') ? [...acc, [v.slice(2), a[i + 1]]] : acc), []));
const DIR = resolve(args.dir || '.');
const ELEV = Math.min(80, Math.max(0, Number(args.elev) || 30)); // grados sobre el horizonte (30 ≈ isométrica 2:1)
const SIZE = Math.min(1024, Math.max(64, Number(args.size) || 256)); // celda cuadrada en px
const FRAMES = Math.min(24, Math.max(1, Number(args.frames) || 8));
const THREE_DIR = resolve(args.three || join(process.cwd(), 'node_modules', 'three'));

const PAGE = `<!doctype html><html><body style="margin:0;background:transparent">
<script type="importmap">{"imports":{"three":"/three/build/three.module.js","three/addons/":"/three/examples/jsm/"}}</script>
<script type="module">
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
window.renderSheet = async ({ url, elev, size, frames }) => {
  const gltf = await new GLTFLoader().loadAsync(url);
  const scene = new THREE.Scene();
  const root = gltf.scene;
  scene.add(root);
  scene.add(new THREE.HemisphereLight(0xdde6ff, 0x2a1f1a, 1.1));
  const key = new THREE.DirectionalLight(0xffffff, 2.2); key.position.set(-3, 6, 4); scene.add(key);
  const rim = new THREE.DirectionalLight(0xffb070, 0.9); rim.position.set(3, 2, -4); scene.add(rim);
  // Encaje: pies en el suelo y centrado; la escala se fija con la pose de reposo para todos los fotogramas.
  const box = new THREE.Box3().setFromObject(root);
  const c = box.getCenter(new THREE.Vector3()), sz = box.getSize(new THREE.Vector3());
  root.position.sub(new THREE.Vector3(c.x, box.min.y, c.z));
  const r = Math.max(sz.x, sz.y, sz.z) * 0.62;
  const cam = new THREE.OrthographicCamera(-r, r, r * 1.05, -r * 0.95, 0.01, 1000);
  const e = elev * Math.PI / 180, d = 50;
  cam.position.set(d * Math.cos(e) * Math.SQRT1_2, d * Math.sin(e) + sz.y * 0.45, d * Math.cos(e) * Math.SQRT1_2);
  cam.lookAt(0, sz.y * 0.45, 0);
  const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(1); renderer.setSize(size, size); renderer.setClearColor(0x000000, 0);
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  const clip = gltf.animations[0] || null;
  const mixer = clip ? new THREE.AnimationMixer(root) : null;
  if (mixer) mixer.clipAction(clip).play();
  const n = clip ? frames : 1;
  const sheet = document.createElement('canvas'); sheet.width = size * n; sheet.height = size * 8;
  const g = sheet.getContext('2d');
  for (let dir = 0; dir < 8; dir++) {
    root.rotation.y = Math.PI / 4 - dir * Math.PI / 4; // 0 = de frente a la cámara, luego cada 45° en sentido horario
    for (let f = 0; f < n; f++) {
      if (mixer) mixer.setTime((clip.duration * f) / n);
      renderer.render(scene, cam);
      g.drawImage(renderer.domElement, f * size, dir * size);
    }
  }
  renderer.dispose();
  return { png: sheet.toDataURL('image/png'), frames: n, clip: clip ? clip.name || 'clip' : null, duration: clip ? clip.duration : 0 };
};
window.ready = true;
</script></body></html>`;

const TYPES = { '.js': 'text/javascript', '.glb': 'model/gltf-binary', '.html': 'text/html' };
const server = createServer(async (req, res) => {
  try {
    const u = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (u === '/') { res.writeHead(200, { 'Content-Type': 'text/html' }); return res.end(PAGE); }
    const base = u.startsWith('/three/') ? THREE_DIR : u.startsWith('/model/') ? DIR : null;
    const file = base && resolve(base, '.' + u.replace(/^\/(three|model)/, ''));
    if (!file || !file.startsWith(base)) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'Content-Type': TYPES[extname(file)] || 'application/octet-stream' });
    res.end(await readFile(file));
  } catch { res.writeHead(404); res.end(); }
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const port = server.address().port;
const { chromium } = require('playwright');
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage();
page.on('pageerror', (e) => console.error('página:', e.message));
await page.goto(`http://127.0.0.1:${port}/`);
await page.waitForFunction(() => window.ready === true);
const glbs = (await readdir(DIR)).filter((f) => f.endsWith('.glb')).sort();
const index = { celda: SIZE, filas: 'direcciones (0 = de frente, luego cada 45° en sentido horario)', elevacion: ELEV, hojas: {} };
for (const f of glbs) {
  const r = await page.evaluate((o) => window.renderSheet(o), { url: `/model/${f}`, elev: ELEV, size: SIZE, frames: FRAMES });
  const out = `sprites_${f.replace(/\.glb$/, '')}.png`;
  await writeFile(join(DIR, out), Buffer.from(r.png.split(',')[1], 'base64'));
  index.hojas[out] = { glb: f, columnas: r.frames, animacion: r.clip, duracion: r.duration };
  console.log(`✔ ${out}: 8 direcciones × ${r.frames} fotograma(s)`);
}
await writeFile(join(DIR, 'sprites.json'), JSON.stringify(index, null, 2));
await browser.close();
server.close();
