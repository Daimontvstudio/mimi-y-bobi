## ============================================================================
## ZonaToqueGigante — Hitbox gigante para manos de 2-3 años (Godot 4.x)
## ----------------------------------------------------------------------------
## Un Control que se coloca y se dimensiona SOLO: ocupa una columna del tercio
## inferior de la pantalla (o más, si subes `alto_fraccion`).
##
## ¿Por qué Control y no Area2D?
##   - Area2D necesita "physics picking" y es delicado con varios dedos a la vez.
##   - Aquí detectamos el toque en _input() comparando con el rectángulo de la
##     zona: funciona con multitáctil, con palmadas y sin depender de físicas.
##
## Cero frustración: no hay toque "incorrecto". Cada zona solo dice
## "me tocaron aquí"; el nivel decide la recompensa.
## ============================================================================
class_name ZonaToqueGigante
extends Control

## Se emite con cada toque válido dentro de la zona.
signal tocada(zona: ZonaToqueGigante, posicion_pantalla: Vector2)

@export_group("Colocación automática")
## Columna que ocupa esta zona (0 = izquierda).
@export var columna: int = 0
## Cuántas columnas hay en total a lo ancho de la pantalla.
@export var total_columnas: int = 3
## Altura de la zona respecto a la pantalla, medida desde abajo.
## 0.34 = tercio inferior · 0.5 = mitad inferior · 1.0 = pantalla completa.
@export_range(0.2, 1.0, 0.01) var alto_fraccion: float = 0.34

@export_group("Retroalimentación")
## Índices de la escala pentatónica que suenan al tocar (se van alternando).
@export var notas: PackedInt32Array = PackedInt32Array([0, 1])
@export var color_principal: Color = Color("ff4fb8")
@export var color_acento: Color = Color("ffe14d")

@export_group("Ajustes")
## Tiempo mínimo entre toques en ESTA zona: una palmada con toda la mano
## no dispara 5 sonidos a la vez.
@export var pausa_entre_toques_seg: float = 0.12
## Dibuja la zona semitransparente para probar en el móvil. Desactivar al publicar.
@export var mostrar_debug: bool = true

var _ultimo_toque_ms: int = -100000
var _contador_notas: int = 0


func _ready() -> void:
	# IGNORE: la zona no "se come" el toque; así el vigilante de inactividad
	# y otros nodos también lo ven.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_ajustar_a_pantalla)
	_ajustar_a_pantalla()


## Recalcula posición y tamaño (al iniciar y si la pantalla gira o cambia).
func _ajustar_a_pantalla() -> void:
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var ancho: float = pantalla.x / total_columnas
	var alto: float = pantalla.y * alto_fraccion
	position = Vector2(ancho * columna, pantalla.y - alto)
	size = Vector2(ancho, alto)
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Solo nos interesa el momento en que el dedo BAJA (cada dedo cuenta aparte).
	if not (event is InputEventScreenTouch and event.pressed):
		return
	if not contiene(event.position):
		return
	var ahora: int = Time.get_ticks_msec()
	if ahora - _ultimo_toque_ms < int(pausa_entre_toques_seg * 1000.0):
		return
	_ultimo_toque_ms = ahora
	tocada.emit(self, event.position)


## ¿Este punto de la pantalla cae dentro de la zona?
func contiene(punto_pantalla: Vector2) -> bool:
	return get_global_rect().has_point(punto_pantalla)


## Devuelve la siguiente nota de esta zona (alterna para que no suene monótono).
func siguiente_nota() -> int:
	if notas.is_empty():
		return 0
	var nota: int = notas[_contador_notas % notas.size()]
	_contador_notas += 1
	return nota


func _draw() -> void:
	if not mostrar_debug:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(color_principal, 0.18))               # relleno suave
	draw_rect(rect.grow(-3.0), Color(color_principal, 0.6), false, 6.0)  # borde
