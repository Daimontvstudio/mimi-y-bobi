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
**Menú** con cinco personajes gigantes → **selector** con sus minijuegos (paneles de media pantalla).

| Personaje | Nota | Minijuego 1 | Minijuego 2 |
|---|---|---|---|
| Mimí (ritmo) | Do | Jardín de las Sorpresas Musicales | **El Concierto de las Estrellas**: atrapar estrellas fugaces que tocan una melodía |
| Bobi (causa-efecto) | Re | El Taller de Bobi | **El Laboratorio de Burbujas**: reventar burbujas y soplar el matraz |
| Lumen (memoria y luces) | Mi | El Jardín de Lumen | **El Camino de Luciérnagas**: encontrar luciérnagas escondidas en frascos |
| Kubo (formas y espacio) | Sol | La Construcción de Kubo | **La Torre Mágica**: apilar bloques con un imán suave |
| Nubi (sombras y siluetas) | La | **El Espejo de las Nubes**: llevar nubes a su silueta | — |

Al tocar a cualquier personaje suena su nota con partículas de sus colores.
Los minijuegos y sus iconos se definen en `scripts/catalogo.gd`.

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
| `orbe_luz.gd` | Objeto que se enciende con halo (orbes de Lumen, frascos de luciérnagas) |
| `catalogo.gd` · `selector_juegos.gd` | Autoload con personajes y juegos · pantalla de selección generada sola |
| `herramientas/verificar.gd` | Prueba automática: GitHub Actions carga todas las escenas y publica `verificacion.txt` |
| `boton_casa.gd` · `transicion.gd` | Volver al menú manteniendo pulsado 1,2 s · fundidos entre escenas |

Más detalles en [`docs/DISENO.md`](docs/DISENO.md).

## Derechos
Proyecto original, de autoría propia. © 2026 — Todos los derechos reservados.
