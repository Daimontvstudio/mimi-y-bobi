## ============================================================================
## ZonaIman — Zona de impacto con imán táctil (Godot 4.x)
## ----------------------------------------------------------------------------
## Atrae las piezas que se acercan dentro de `radio_iman`. No hace falta
## soltar la pieza justo encima: el imán ayuda (ver GestorArrastre).
## Mientras está libre, dibuja un aro que "respira" para invitar a usarla.
## ============================================================================
class_name ZonaIman
extends Node2D

## Distancia a la que el imán empieza a tirar de la pieza.
@export var radio_iman: float = 300.0
## Tamaño del aro guía.
@export var radio_visual: float = 125.0
@export var color_guia: Color = Color("a8ff3e")

## Pieza que ocupa la zona (null = libre).
var ocupada_por: PiezaArrastrable = null

var _tiempo: float = 0.0


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _draw() -> void:
	if ocupada_por != null:
		return
	var pulso: float = 0.5 + 0.5 * sin(_tiempo * 3.0)
	var r: float = radio_visual * (1.0 + 0.08 * pulso)
	draw_circle(Vector2.ZERO, r, Color(color_guia, 0.10 + 0.10 * pulso))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(color_guia, 0.45 + 0.4 * pulso), 8.0, true)
