## ============================================================================
## OrbeLuz — Flor-orbe de luz del Jardín de Lumen (Godot 4.x)
## ----------------------------------------------------------------------------
## Estructura:
##   OrbeLuz (Node2D)      ← este script
##   ├─ Halo (Sprite2D)    ← resplandor (material aditivo)
##   └─ Bola (Sprite2D)    ← esfera de arcilla blanca (se tiñe con `color`)
## Apagada: color suave. Encendida: brillo + halo + pequeño rebote.
## ============================================================================
class_name OrbeLuz
extends Node2D

@export var color: Color = Color("b45cff")

@onready var bola: Sprite2D = $Bola
@onready var halo: Sprite2D = $Halo

var _tween: Tween


func _ready() -> void:
	_apagar()


func color_apagado() -> Color:
	return color.lerp(Color(0.16, 0.1, 0.3), 0.4)


## Destello con luz y rebote. `duracion` = tiempo que permanece encendida.
func encender(duracion: float = 0.45) -> void:
	_detener()
	bola.modulate = color.lightened(0.2)
	halo.modulate = Color(color, 1.0)
	scale = Vector2.ONE * 1.12
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(halo, "modulate:a", 0.0, 0.4).set_delay(duracion)
	_tween.parallel().tween_property(bola, "modulate", color_apagado(), 0.4).set_delay(duracion)


## Pista suave: el halo late dos veces ("¡tócame a mí!").
func invitar() -> void:
	_detener()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for k in 2:
		_tween.tween_property(halo, "modulate:a", 0.5, 0.35)
		_tween.tween_property(halo, "modulate:a", 0.0, 0.35)


func _apagar() -> void:
	bola.modulate = color_apagado()
	halo.modulate = Color(color, 0.0)
	scale = Vector2.ONE


func _detener() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_apagar()
