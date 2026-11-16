# Documento de diseño — Aventuras Mágicas con Mimí y Bobi

## Visión
Juego educativo y de exploración interactiva para móviles (Android / iOS), pensado para niños de **2 a 3 años**. Proyecto 100 % original y de autoría propia.

## Estilo visual
- Juguete suave tipo **arcilla (clay)**: formas redondeadas, brillo suave y sombras amables.
- **Colores fluorescentes y vibrantes** sobre fondos nocturnos o pasteles limpios.

## Filosofía: cero frustración
- Sin temporizadores de estrés, sin castigos, sin pantallas de "Game Over".
- No existen respuestas "incorrectas": cada acción produce algo bonito.
- Si el niño se queda quieto, un personaje le invita a jugar con una animación sutil (nunca un aviso negativo).

## Reglas de interacción
| Regla | Valor actual |
|---|---|
| Hitboxes | Gigantes: tercios de pantalla o mitades completas |
| Anti-palmadas | 0,12 s entre toques en la misma zona |
| Inactividad | 4 s → 3 niveles: respirar, saltito, saludo (tope, se repite) |
| Sonido | Escala pentatónica de Do (Do Re Mi Sol La Do'), siempre armónica |
| Partículas | Estrellas y corazones del color del personaje o la zona |
| Salida al menú | Mantener pulsada la casa 1,2 s (a prueba de toques accidentales) |
| Arrastre | Agarre con radio amplio, imán a 300 px, encaje automático a 120 px, regreso suave |

## Personajes
| Personaje | Colores | Rol |
|---|---|---|
| **Mimí** (niña, 2-3 años) | Rosa chicle y amarillo sol | Ritmo y exploración musical |
| **Bobi** (niño, 2-3 años) | Azul cielo y verde lima | Lógica y causa-efecto |
| **Lumen** (ayudante) | Morado uva y naranja brillante | Memoria y secuencias de luces |
| **Kubo** (ayudante) | Rojo cereza y blanco perla | Robot de formas redondeadas; encajar piezas |
| **Nubi** (ayudante) | Celeste pastel y dorado suave | Esponjita etérea; formas y sombras |

## Niveles
### Menú principal
Cuatro botones gigantes (una columna cada uno): Mimí (nota musical), Bobi (engranaje), Lumen (estrella de luz) y Kubo (bloques). Nubi flota arriba como guía y canta su nota al tocarla. Los personajes entran con un "pop" escalonado; al elegir, fanfarria de 3 notas y fundido al nivel.

### Nivel 1 · El Jardín de las Sorpresas Musicales (Mimí)
Tres zonas gigantes en el tercio inferior, cada una con una flor brillante. Cada toque: nota pentatónica (grave → aguda de izquierda a derecha), partículas y rebote de Mimí.

### Nivel 2 · El Taller de Bobi (Bobi)
Tres engranajes en una bandeja y una máquina con tres huecos. Cualquier engranaje vale en cualquier hueco.
- Al encajar: gira, la bombilla toma su color, suena una nota más aguda y Bobi rebota.
- Tocar un engranaje encajado: gira rapidísimo.
- Con los tres: celebración (arpegio, bombilla arcoíris, partículas por la chimenea) y las piezas vuelven solas para repetir.

### Nivel 3 · El Jardín de Lumen (Lumen)
Tres flores-orbe (morado, naranja, amarillo; notas Do, Mi, La). Lumen enciende una secuencia y el niño la repite.
- Toda flor tocada brilla y suena siempre.
- Acierto: fiesta rítmica y la secuencia crece (de 1 hasta 4 destellos).
- Error: sin castigo; Lumen respira y repite la secuencia. Tras 2 reintentos, la secuencia se acorta.
- Inactividad: la flor siguiente late (pista) y después Lumen vuelve a enseñar la secuencia.

### Nivel 4 · La Construcción de Kubo (Kubo + Nubi)
Bloques grandes (círculo rojo, cuadrado amarillo, triángulo azul) y siluetas en un tablero (casita con sol, robot, tren).
- El imán solo atrae a la forma correcta: nunca encaja "mal".
- Si un bloque se suelta lejos, vuelve flotando y su silueta correcta brilla como pista.
- Dibujo completo: fiesta rítmica y el tablero cambia de diseño.

## Sonido y celebración
- Cada personaje tiene su nota: Mimí Do · Bobi Re · Lumen Mi · Kubo Sol · Nubi La.
- Celebraciones rítmicas a tempo tranquilo (un pulso cada 0,36 s): nota + estallido suave por pulso.
- Partículas lentas que caen como confeti (gravedad baja, 1,1 s de vida), siempre con fundido.

## Arquitectura técnica
- Motor: **Godot 4** · renderizador *Compatibilidad* (máxima compatibilidad Android y Web).
- Resolución base 2340×1080 (Samsung S24 Ultra), horizontal, `stretch canvas_items` + `expand`.
- Autoload `Transicion` para cambiar de escena con fundidos.
- Entrada por `InputEventScreenTouch` / `InputEventScreenDrag` (multitáctil). En PC, el ratón emula el toque.

## Próximos pasos posibles
- Nivel propio de Nubi (formas y sombras: emparejar objetos con su sombra).
- Sustituir el arte provisional por modelos/renders definitivos (p. ej. Tripo AI).
- Música de fondo suave y voces grabadas.
