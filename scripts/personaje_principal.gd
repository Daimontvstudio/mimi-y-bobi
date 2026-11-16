## ============================================================================
## PersonajePrincipal — Reacciones y llamadas de atención (Godot 4.x)
## ----------------------------------------------------------------------------
## Para Mimí (o cualquier personaje). Dos modos:
##   1) Si le asignas un AnimationPlayer con animaciones llamadas como en
##      `anims_atencion`, usa esas animaciones (ideal con modelos de Tripo AI).
##   2) Si no, usa animaciones por código (Tween) con efecto plastilina.
## ============================================================================
class_name PersonajePrincipal
extends Node2D

## Opcional. Si está vacío, se usan animaciones por código.
@export var animador: AnimationPlayer
@export var anim_reposo: StringName = &"reposo"
## Una animación por nivel de inactividad (1, 2, 3).
@export var anims_atencion: Array[StringName] = [&"respirar", &"saltito", &"saludar"]

var _escala_base: Vector2
var _posicion_base: Vector2
var _tween: Tween


func _ready() -> void:
	_escala_base = scale
	_posicion_base = position


## Rebote tipo plastilina cada vez que el niño toca la pantalla.
func reaccionar_toque() -> void:
	_detener_tween()
	scale = _escala_base * Vector2(1.2, 0.82)  # se aplasta...
	_tween = create_tween()
	_tween.tween_property(self, "scale", _escala_base, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)  # ...y rebota


## Invitación a jugar. Conectada a VigilanteInactividad.llamar_atencion.
func llamar_atencion(nivel: int) -> void:
	_detener_tween()

	# Modo 1: animaciones propias del AnimationPlayer.
	var i: int = clampi(nivel - 1, 0, anims_atencion.size() - 1)
	if animador and not anims_atencion.is_empty() and animador.has_animation(anims_atencion[i]):
		animador.play(anims_atencion[i])
		return

	# Modo 2: animaciones por código.
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match nivel:
		1:  # Respira: se infla un poquito dos veces.
			for k in 2:
				_tween.tween_property(self, "scale", _escala_base * 1.08, 0.35)
				_tween.tween_property(self, "scale", _escala_base, 0.35)
		2:  # Un saltito.
			_saltito(40.0)
		_:  # Dos saltitos y un balanceo, como diciendo "¡ven!".
			_saltito(50.0)
			_saltito(30.0)
			_tween.tween_property(self, "rotation_degrees", 8.0, 0.2)
			_tween.tween_property(self, "rotation_degrees", -8.0, 0.3)
			_tween.tween_property(self, "rotation_degrees", 0.0, 0.2)


## El niño volvió: se interrumpe la llamada y vuelve a su sitio.
func cancelar_llamada() -> void:
	_detener_tween()
	if animador and animador.has_animation(anim_reposo):
		animador.play(anim_reposo)


func _saltito(altura: float) -> void:
	_tween.tween_property(self, "position", _posicion_base + Vector2(0.0, -altura), 0.22)
	_tween.tween_property(self, "position", _posicion_base, 0.38) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _detener_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = _escala_base
	position = _posicion_base
	rotation_degrees = 0.0
