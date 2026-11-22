// Datos del encargo para el workflow «Tripo 3D»: del formulario (workflow_dispatch) o de un issue con la etiqueta
// «tripo». Formato del issue: título = qué modelo crear; en el cuerpo, líneas opcionales
//   nombre: guerrero_alado
//   animaciones: reposo, caminar, ataque
//   esqueleto: no
// Escribe pares clave=valor para $GITHUB_OUTPUT (sin ejecutar nada de lo que diga el issue).
const env = process.env;
const slug = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9_-]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 40);
const one = (s) => String(s || '').replace(/[\r\n]+/g, ' ').trim();
export function datos(e = env) {
  if (e.GITHUB_EVENT_NAME === 'issues') {
    const body = String(e.ISSUE_BODY || '');
    const field = (k) => { const m = body.match(new RegExp(`^\\s*${k}\\s*:\\s*(.+)$`, 'im')); return m ? m[1].trim() : ''; };
    const descripcion = one(field('descripcion') || field('descripción') || e.ISSUE_TITLE).replace(/^tripo\s*[:\-]\s*/i, '');
    return { descripcion, nombre: slug(field('nombre') || descripcion.split(/\s+/).slice(0, 3).join('_')), animaciones: one(field('animaciones') || 'reposo,caminar,ataque'), esqueleto: /^(no|false|sin)$/i.test(field('esqueleto')) ? 'false' : 'true', issue: e.ISSUE_NUMBER || '' };
  }
  return { descripcion: one(e.IN_DESCRIPCION), nombre: slug(e.IN_NOMBRE || e.IN_DESCRIPCION), animaciones: one(e.IN_ANIMACIONES), esqueleto: e.IN_ESQUELETO === 'false' ? 'false' : 'true', issue: '' };
}
if (import.meta.url === `file://${process.argv[1]}`) {
  const d = datos();
  if (d.descripcion.length < 3) { console.error('Falta la descripción del modelo.'); process.exit(1); }
  for (const [k, v] of Object.entries(d)) console.log(`${k}=${v}`);
}
