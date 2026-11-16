## ============================================================================
## Transicion — Autoload para cambiar de escena con un fundido suave (Godot 4.x)
## ----------------------------------------------------------------------------
## Registrado en project.godot como autoload "Transicion".
## Uso desde cualquier script:  Transicion.ir_a("res://escenas/menu_principal.tscn")
## Sin cortes bruscos ni pantallas negras largas: 0,35 s de fundido de salida
## y 0,45 s de entrada, con el color de fondo nocturno del juego.
## ============================================================================
extends CanvasLayer

const COLOR_VELO := Color(0.07, 0.04, 0.18, 1.0)

## true mientras se cambia de escena (evita dobles toques).
var ocupado: bool = false
var _velo: ColorRect


func _ready() -> void:
	layer = 128  # por encima de todo
	_velo = ColorRect.new()
	_velo.color = COLOR_VELO
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.modulate.a = 0.0
	add_child(_velo)


func ir_a(ruta_escena: String) -> void:
	if ocupado:
		return
	ocupado = true
	var salida := create_tween()
	salida.tween_property(_velo, "modulate:a", 1.0, 0.35)
	await salida.finished
	get_tree().change_scene_to_file(ruta_escena)
	await get_tree().process_frame
	await get_tree().process_frame
	var entrada := create_tween()
	entrada.tween_property(_velo, "modulate:a", 0.0, 0.45)
	await entrada.finished
	ocupado = false
