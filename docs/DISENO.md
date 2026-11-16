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
### Menú principal y selector
- Menú: cinco columnas gigantes a toda altura (Mimí, Bobi, Lumen, Kubo, Nubi), con los iconos de sus minijuegos encima.
- Selector: un panel de media pantalla por minijuego, con su icono grande; el personaje saluda arriba.
- Personajes con un solo juego (Nubi) van directos al juego.
- La casita (mantener 1,2 s) vuelve del juego al selector, y del selector al menú.

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

### Mimí · El Concierto de las Estrellas
Estrellas fugaces lentas cruzan el cielo. Cada estrella atrapada (basta tocar cerca) suena con la siguiente nota de una melodía pentatónica y vuela a una constelación arriba. Al completar la melodía, la constelación la canta entera y hay fiesta. Las estrellas que nadie toca se van sin más.

### Bobi · El Laboratorio de Burbujas
Burbujas de colores suben del matraz. Tocar una: "¡plop!" + nota (grandes graves, pequeñas agudas); algunas guardan una sorpresa. Tocar el matraz: "¡boing!" y un chorro de burbujas. Cada 12 burbujas, mini fiesta. Las burbujas que llegan arriba se desvanecen sin sonido.

### Lumen · El Camino de Luciérnagas
Lumen esconde 1, 2 o 3 luciérnagas en frascos. Al encontrarlas, salen brillando y se posan en un camino de piedras; con todas, el camino canta una melodía. Un frasco vacío solo da un brillito suave; tras 2 vacíos (o al distraerse), los frascos correctos laten.

### Kubo · La Torre Mágica
Un imán suave marca el siguiente piso; cualquier bloque vale. Cada piso suena más agudo. Con 5 pisos, la torre se vuelve mágica (cada piso canta, fiesta) y los bloques suben flotando al cielo. La bandeja siempre se rellena; la torre nunca se cae.

### Nubi · El Espejo de las Nubes
En un espejo dorado aparecen 3 siluetas (corazón, estrella, luna, gota, flor). Las nubes con esas formas se deslizan hasta su silueta; el imán solo atrae a la forma correcta. Encajar: lluvia de destellos dorados. Las tres: fiesta y nuevas formas.

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
- Segundo minijuego de Nubi (sombras de objetos reales).
- Sustituir el arte provisional por modelos/renders definitivos (p. ej. Tripo AI).
- Música de fondo suave y voces grabadas.
