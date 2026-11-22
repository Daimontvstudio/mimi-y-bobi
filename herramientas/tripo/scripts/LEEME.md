# Tripo 3D en GitHub Actions

Crea modelos 3D con **Tripo** (texturas PBR, esqueleto y animaciones) y los convierte en **sprites isométricos** listos para el juego. Todo llega en un **PR** para revisarlo antes de usarlo.

## Una sola vez
1. **Settings → Secrets and variables → Actions → New repository secret**: `TRIPO_API_KEY` con tu clave de Tripo (platform.tripo3d.ai → API Keys).
2. **Settings → Actions → General → Workflow permissions**: marca «Allow GitHub Actions to create and approve pull requests» (para que abra el PR solo).

## Pedir un modelo
- **A mano:** Actions → **Tripo 3D** → *Run workflow* → descripción, nombre, animaciones.
- **Con un issue** (también lo puede crear Claude Code): título = qué modelo crear, etiqueta **`tripo`**. En el cuerpo, opcional:
  ```
  nombre: guerrero_alado
  animaciones: reposo, caminar, ataque
  esqueleto: no
  ```

Animaciones disponibles: `reposo`, `caminar`, `correr`, `saltar`, `ataque`, `disparo`, `golpeado`, `caida` (máx. 6).

## Qué se genera (carpeta del modelo)
| Archivo | Qué es |
|---|---|
| `modelo.glb` | El modelo con texturas PBR |
| `esqueleto.glb` | El modelo con esqueleto (si es personaje o criatura) |
| `anim_<nombre>.glb` | Una animación por archivo |
| `sprites_<archivo>.png` | Hoja isométrica: **filas = 8 direcciones** (0 = de frente, luego cada 45° en sentido horario), **columnas = fotogramas** de la animación; fondo transparente |
| `sprites.json` | Tamaño de celda, ángulo de cámara y fotogramas de cada hoja |
| `info.json` | Descripción, animaciones y fecha |

Scripts: `tripo3d.mjs` (Tripo, sin dependencias), `render.mjs` (three.js + Chromium), `datos.mjs` (lee el formulario o el issue).
