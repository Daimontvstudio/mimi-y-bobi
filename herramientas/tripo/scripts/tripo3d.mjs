// Tripo 3D en GitHub Actions: crea un modelo (con texturas PBR), opcionalmente con esqueleto y animaciones,
// y guarda los GLB en la carpeta de salida. Sin dependencias (Node 20). La clave llega por TRIPO_API_KEY.
//   node herramientas/tripo/scripts/tripo3d.mjs --prompt "guerrero con alas" --name guerrero --out arte/tripo/guerrero --rig true --anims "reposo,caminar,ataque"
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const BASE = 'https://api.tripo3d.ai/v2/openapi';
const ANIMS = { reposo: 'preset:idle', caminar: 'preset:walk', correr: 'preset:run', saltar: 'preset:jump', ataque: 'preset:slash', disparo: 'preset:shoot', golpeado: 'preset:hurt', caida: 'preset:fall' };
const DONE = new Set(['success']);
const FAILED = new Set(['failed', 'cancelled', 'banned', 'expired', 'unknown']);

export function parseArgs(argv) {
  const a = {};
  for (let i = 0; i < argv.length; i++) if (argv[i].startsWith('--')) a[argv[i].slice(2)] = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : 'true';
  const name = String(a.name || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9_-]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 40);
  const prompt = String(a.prompt || '').trim();
  if (prompt.length < 3) throw new Error('Falta --prompt (descripción del modelo).');
  if (!name) throw new Error('Falta --name (nombre del modelo).');
  const anims = String(a.anims || '').split(/[,\s]+/).map((x) => x.trim().toLowerCase()).filter(Boolean);
  const bad = anims.filter((x) => !ANIMS[x]);
  if (bad.length) throw new Error(`Animaciones desconocidas: ${bad.join(', ')}. Válidas: ${Object.keys(ANIMS).join(', ')}.`);
  return { prompt: prompt.slice(0, 1000), name, out: a.out || join('tripo', name), rig: a.rig !== 'false' || anims.length > 0, anims: [...new Set(anims)].slice(0, 6), version: a.version || '' };
}

export function modelUrl(o = {}) {
  const pick = (v) => (typeof v === 'string' ? v : v && typeof v.url === 'string' ? v.url : '');
  return pick(o.pbr_model) || pick(o.model) || pick(o.base_model) || (typeof o.rigged_model === 'string' ? o.rigged_model : '');
}

export function createTripo({ apiKey, fetchImpl = globalThis.fetch, pollMs = Number(process.env.TRIPO_POLL_MS) || 4000, maxPolls = 225 }) {
  if (!apiKey) throw new Error('Falta el secreto TRIPO_API_KEY en el repositorio (Settings → Secrets and variables → Actions).');
  async function call(path, init = {}) {
    const r = await fetchImpl(`${BASE}${path}`, { ...init, headers: { Authorization: `Bearer ${apiKey}`, ...(init.headers || {}) } });
    const d = await r.json().catch(() => ({}));
    if (!r.ok || (d.code !== undefined && d.code !== 0)) throw new Error(`Tripo: ${String(d.message || d.suggestion || `respondió ${r.status}`).slice(0, 300)}`);
    return d.data || {};
  }
  const task = async (body) => {
    const { task_id: id } = await call('/task', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    if (!id) throw new Error('Tripo no creó la tarea.');
    return id;
  };
  async function wait(id, what) {
    for (let i = 0; i < maxPolls; i++) {
      await new Promise((r) => setTimeout(r, pollMs));
      const t = await call(`/task/${encodeURIComponent(id)}`);
      const s = String(t.status || '').toLowerCase();
      if (FAILED.has(s)) throw new Error(`Tripo no pudo crear ${what} (${s}).`);
      if (DONE.has(s)) return t.output || {};
      if (i % 5 === 0) console.log(`  ${what}: ${s || 'en cola'} ${Number.isFinite(Number(t.progress)) ? `${t.progress} %` : ''}`);
    }
    throw new Error(`Tripo tardó demasiado con ${what}.`);
  }
  async function download(url, what) {
    if (!url) throw new Error(`Tripo terminó pero no devolvió ${what}.`);
    const r = await fetchImpl(url);
    if (!r.ok) throw new Error(`No se pudo descargar ${what} (${r.status}).`);
    return Buffer.from(await r.arrayBuffer());
  }
  return { task, wait, download };
}

export async function run(opts, { apiKey = process.env.TRIPO_API_KEY, fetchImpl } = {}) {
  const t = createTripo({ apiKey, fetchImpl });
  await mkdir(opts.out, { recursive: true });
  const files = [];
  const save = async (file, bytes) => { await writeFile(join(opts.out, file), bytes); files.push(file); console.log(`✔ ${join(opts.out, file)} (${Math.round(bytes.length / 1024)} KB)`); };
  console.log(`Tripo: creando «${opts.prompt}»…`);
  const modelTask = await t.task({ type: 'text_to_model', prompt: opts.prompt, texture: true, pbr: true, ...(opts.version ? { model_version: opts.version } : {}) });
  await save('modelo.glb', await t.download(modelUrl(await t.wait(modelTask, 'el modelo')), 'el modelo'));
  let rigTask = null;
  if (opts.rig) {
    const check = await t.wait(await t.task({ type: 'animate_prerigcheck', original_model_task_id: modelTask }), 'la revisión del esqueleto');
    if (check.riggable === false) console.log('⚠ Tripo dice que este modelo no se puede riggear (no es personaje ni criatura): se guarda sin esqueleto.');
    else {
      rigTask = await t.task({ type: 'animate_rig', original_model_task_id: modelTask, out_format: 'glb', ...(check.rig_type ? { rig_type: check.rig_type } : {}) });
      await save('esqueleto.glb', await t.download(modelUrl(await t.wait(rigTask, 'el esqueleto')), 'el esqueleto'));
      for (const a of opts.anims) {
        const id = await t.task({ type: 'animate_retarget', original_model_task_id: rigTask, animation: ANIMS[a], out_format: 'glb', bake_animation: true });
        await save(`anim_${a}.glb`, await t.download(modelUrl(await t.wait(id, `la animación ${a}`)), `la animación ${a}`));
      }
    }
  }
  const info = { nombre: opts.name, descripcion: opts.prompt, archivos: files, esqueleto: Boolean(rigTask), animaciones: rigTask ? opts.anims : [], creado: new Date().toISOString(), motor: 'Tripo 3D (GitHub Actions)' };
  await writeFile(join(opts.out, 'info.json'), JSON.stringify(info, null, 2));
  return info;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run(parseArgs(process.argv.slice(2))).catch((err) => { console.error(`✖ ${err.message}`); process.exit(1); });
}
