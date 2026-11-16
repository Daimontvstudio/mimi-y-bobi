# Aventuras Mágicas con Mimí y Bobi

Videojuego educativo y de exploración para niños de **2 a 3 años** (Android / iOS), hecho con **Godot 4**.
Estética de juguete de arcilla con colores fluorescentes. **Cero frustración**: sin temporizadores, sin castigos y sin "Game Over".

![Menú, Jardín de Lumen y Construcción de Kubo](docs/vista_previa.jpg)

## Probar el juego en el móvil
| Forma | Cómo |
|---|---|
| **Navegador** | Abre la página de GitHub Pages del repositorio: `https://<tu-usuario>.github.io/<repositorio>/` |
| **APK** | Pestaña **Releases** → *Versión de prueba* → descarga `MimiYBobi.apk` e instálalo |
| **Editor Godot (Android)** | Clona o descarga el repositorio → Godot → **Importar** → `project.godot` → ▶ |

Ambas versiones se generan solas con GitHub Actions (`.github/workflows/exportar.yml`) cada vez que se sube un cambio a `main`.

### Activar GitHub Pages (una sola vez)
**Settings → Pages → Build and deployment → Source: GitHub Actions**.

## Contenido actual
| Escena | Descripción |
|---|---|
| `escenas/menu_principal.tscn` | Menú con cuatro botones gigantes (Mimí, Bobi, Lumen, Kubo) y Nubi flotando como guía |
| `escenas/jardin_nivel1.tscn` | **Nivel 1 · El Jardín de las Sorpresas Musicales**: tres zonas gigantes con notas pentatónicas y partículas |
| `escenas/taller_nivel2.tscn` | **Nivel 2 · El Taller de Bobi**: arrastrar engranajes a una máquina con imanes táctiles |
| `escenas/lumen_nivel3.tscn` | **Nivel 3 · El Jardín de Lumen**: memoria de destellos musicales, con reintentos dulces |
| `escenas/kubo_nivel4.tscn` | **Nivel 4 · La Construcción de Kubo**: encajar bloques grandes en siluetas con imanes |

### Personajes y su nota
| Personaje | Nota | Papel |
|---|---|---|
| Mimí | Do | Ritmo y música |
| Bobi | Re | Causa-efecto |
| Lumen | Mi | Memoria y luces |
| Kubo | Sol | Formas y espacio |
| Nubi | La | Guía de sombras y siluetas |

Al tocar a cualquier personaje suena su nota con partículas de sus colores.

## Estructura
```
escenas/   Escenas (.tscn)
scripts/   GDScript (un sistema por archivo, documentado)
arte/      Imágenes provisionales (PNG)
audio/     Sonidos (una campanita en Do; las demás notas se generan cambiando el tono)
docs/      Documento de diseño y vista previa
```

## Sistemas reutilizables
| Script | Qué hace |
|---|---|
| `zona_toque_gigante.gd` | Hitbox gigante (Control) que se coloca sola; multitáctil y con anti-palmadas |
| `vigilante_inactividad.gd` | Tras 4 s sin toques, invita a jugar en 3 niveles suaves |
| `retroalimentacion.gd` | Notas pentatónicas, partículas, fiesta rítmica (~83 ppm) y nota propia de cada personaje |
| `personaje_principal.gd` | Rebote de plastilina y llamadas de atención (Tween o AnimationPlayer) |
| `gestor_arrastre.gd` · `pieza_arrastrable.gd` · `zona_iman.gd` | Arrastrar y soltar con imán, formas opcionales, encaje automático, regreso suave y pistas |
| `orbe_luz.gd` | Flor-orbe que se enciende con halo (Nivel 3) |
| `herramientas/verificar.gd` | Prueba automática: GitHub Actions carga todas las escenas y publica `verificacion.txt` |
| `boton_casa.gd` · `transicion.gd` | Volver al menú manteniendo pulsado 1,2 s · fundidos entre escenas |

Más detalles en [`docs/DISENO.md`](docs/DISENO.md).

## Derechos
Proyecto original, de autoría propia. © 2026 — Todos los derechos reservados.
