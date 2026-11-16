## ============================================================================
## BotonCasa — Volver al menú de forma segura (Godot 4.x)
## ----------------------------------------------------------------------------
## Pensado para los PADRES: hay que MANTENER pulsado 1,2 s (se llena un aro
## amarillo). Un toque accidental del bebé no le saca del juego.
## Si se suelta antes, el aro se vacía suavemente: nada pasa.
## Colócalo dentro de un CanvasLayer, en una esquina.
## ============================================================================
class_name BotonCasa
extends Node2D

@export_file("*.tscn") var escena_destino: String = "res://escenas/menu_principal.tscn"
@export var icono: Texture2D
@export var radio: float = 80.0
@export var segundos_mantener: float = 1.2

var _dedo: int = -1
var _progreso: float = 0.0


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch):
		return
	var punto: Vector2 = get_canvas_transform().affine_inverse() * event.position
	if event.pressed and _dedo == -1 and to_local(punto).length() <= radio * 1.25:
		_dedo = event.index
	elif not event.pressed and event.index == _dedo:
		_dedo = -1


func _process(delta: float) -> void:
	if _dedo != -1:
		_progreso += delta / segundos_mantener
	else:
		_progreso = move_toward(_progreso, 0.0, delta * 3.0)
	if _progreso >= 1.0:
		_progreso = 0.0
		_dedo = -1
		Transicion.ir_a(escena_destino)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radio, Color(1, 1, 1, 0.12))
	if icono:
		var escala: float = 1.0 + 0.12 * _progreso
		var tam: Vector2 = icono.get_size() * escala
		draw_texture_rect(icono, Rect2(-tam / 2.0, tam), false)
	if _progreso > 0.0:
		draw_arc(Vector2.ZERO, radio - 6.0, -PI / 2.0, -PI / 2.0 + TAU * _progreso,
				48, Color("ffd23f"), 12.0, true)
