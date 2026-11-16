## ============================================================================
## verificar.gd — Prueba automática (la ejecuta GitHub Actions)
## ----------------------------------------------------------------------------
## Carga e instancia cada escena de res://escenas, la deja correr 45 frames
## y la cierra. Los errores de script aparecen en el registro, que se publica
## como verificacion.txt junto al APK.
## Uso local:  godot --headless -s res://herramientas/verificar.gd
## ============================================================================
extends SceneTree

var _escenas: PackedStringArray = []
var _indice: int = 0
var _frames: int = 0
var _actual: Node = null


func _initialize() -> void:
	for archivo in DirAccess.get_files_at("res://escenas"):
		if archivo.ends_with(".tscn"):
			_escenas.append("res://escenas/" + archivo)
	print("VERIF_INICIO escenas=", _escenas.size())


func _process(_delta: float) -> bool:
	if _actual == null:
		if _indice >= _escenas.size():
			print("VERIF_FIN")
			return true
		var ruta: String = _escenas[_indice]
		_indice += 1
		var paquete := load(ruta) as PackedScene
		if paquete == null:
			print("VERIF_FALLO no se pudo cargar ", ruta)
			return false
		_actual = paquete.instantiate()
		if _actual == null:
			print("VERIF_FALLO no se pudo instanciar ", ruta)
			return false
		root.add_child(_actual)
		_frames = 0
		print("VERIF_OK ", ruta)
	else:
		_frames += 1
		if _frames > 45:
			_actual.queue_free()
			_actual = null
	return false
