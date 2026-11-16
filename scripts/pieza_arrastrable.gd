## ============================================================================
## PiezaArrastrable — Objeto que el niño arrastra (Godot 4.x)
## ----------------------------------------------------------------------------
## Engranaje, ingrediente, bloque... Solo gestiona su ASPECTO y sus animaciones.
## El arrastre real (dedos, imanes) lo hace GestorArrastre.
##
## Estructura del nodo:
##   PiezaArrastrable (Node2D)   ← este script
##   └─ Visual (Sprite2D)        ← la imagen; gira cuando la pieza está encajada
##
## Usa una textura BLANCA de arcilla: el color se aplica con `color`.
## ============================================================================
class_name PiezaArrastrable
extends Node2D

@export var color: Color = Color.WHITE
## Radio para agarrarla: mayor que la pieza, para dedos poco precisos.
@export var radio_agarre: float = 170.0
## Velocidad de giro (radianes/s) cuando está encajada.
@export var velocidad_giro: float = 2.5

var origen: Vector2          # posición inicial (a donde vuelve flotando)
var encajada: bool = false
var arrastrando: bool = false

var _girando: bool = false
var _giro_extra: float = 0.0
var _tween: Tween
var _tween_pop: Tween

@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	origen = global_position
	if visual:
		visual.modulate = color


func _process(delta: float) -> void:
	if visual == null:
		return
	var velocidad: float = (velocidad_giro if _girando else 0.0) + _giro_extra
	if velocidad != 0.0:
		visual.rotation += velocidad * delta
	_giro_extra = move_toward(_giro_extra, 0.0, 8.0 * delta)


## El dedo la agarra: crece un poco y se pone por encima.
func levantar() -> void:
	_detener()
	arrastrando = true
	encajada = false
	z_index = 20
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.12)


## Encaja con un pequeño rebote y empieza a girar (causa → efecto).
func encajar_en(destino: Vector2) -> void:
	_detener()
	arrastrando = false
	encajada = true
	z_index = 5
	_girando = true
	_giro_extra = 10.0  # arranque con "¡brrrum!"
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "global_position", destino, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.28)


## Vuelve flotando a la bandeja. NO es un error: es "otra vez".
func volver_a_origen() -> void:
	_detener()
	arrastrando = false
	encajada = false
	_girando = false
	z_index = 10
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "global_position", origen, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	_tween.chain().tween_property(self, "z_index", 0, 0.0)


## Toque sobre una pieza ya encajada: gira rapidísimo un momento.
func impulso_giro(fuerza: float = 12.0) -> void:
	_giro_extra = maxf(_giro_extra, fuerza)
	if _tween_pop and _tween_pop.is_valid():
		_tween_pop.kill()
	scale = Vector2.ONE * 1.12
	_tween_pop = create_tween()
	_tween_pop.tween_property(self, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Pista sin palabras: se asoma un poco hacia el destino y vuelve.
func insinuar(destino: Vector2) -> void:
	if arrastrando or encajada:
		return
	_detener()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "global_position", origen.lerp(destino, 0.22), 0.45)
	_tween.tween_property(self, "global_position", origen, 0.5)


func _detener() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
