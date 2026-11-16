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
## Forma que acepta ("circulo", "cuadrado"...). Vacío = acepta cualquier pieza.
@export var forma: StringName = &""

## Pieza que ocupa la zona (null = libre).
var ocupada_por: PiezaArrastrable = null

var _tiempo: float = 0.0
var _resalte: float = 0.0


## ¿Esta zona acepta la pieza? (misma forma, o zona sin forma)
func acepta(pieza: PiezaArrastrable) -> bool:
	return forma == &"" or pieza.forma == forma


## Brilla con fuerza un momento: "¡aquí va esa pieza!" (pista, nunca reproche).
func resaltar(segundos: float = 1.6) -> void:
	_resalte = segundos


func _process(delta: float) -> void:
	_tiempo += delta
	_resalte = maxf(_resalte - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if ocupada_por != null:
		return
	var pulso: float = 0.5 + 0.5 * sin(_tiempo * 3.0)
	if _resalte > 0.0:
		pulso = 0.5 + 0.5 * sin(_tiempo * 9.0)  # late más rápido mientras resalta
	var extra: float = clampf(_resalte, 0.0, 1.0)
	var r: float = radio_visual * (1.0 + 0.08 * pulso + 0.12 * extra)
	draw_circle(Vector2.ZERO, r, Color(color_guia, 0.10 + 0.10 * pulso))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(color_guia, minf(0.45 + 0.4 * pulso + 0.3 * extra, 1.0)),
			8.0 + 6.0 * extra, true)
