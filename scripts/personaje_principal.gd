## ============================================================================
## PersonajePrincipal — Personajes y guías: Mimí, Bobi, Lumen, Kubo, Nubi (Godot 4.x)
## ----------------------------------------------------------------------------
## - Nota propia: al tocar al personaje suena SU nota pentatónica
##   (Mimí Do · Bobi Re · Lumen Mi · Kubo Sol · Nubi La) con partículas
##   de sus colores. La conexión la hace Retroalimentacion automáticamente
##   con todos los nodos del grupo "personajes".
## - Animaciones: rebote de plastilina, llamadas de atención (3 niveles),
##   entrada de saludo al empezar un nivel y flotación suave (Nubi).
## - Si le asignas un AnimationPlayer con animaciones con los nombres de
##   `anims_atencion`, las usa en vez de las animaciones por código.
## ============================================================================
class_name PersonajePrincipal
extends Node2D

## Se emite cuando el niño toca al personaje.
signal tocado(personaje: PersonajePrincipal)

@export_group("Identidad musical")
## Índice de la escala pentatónica (0 Do · 1 Re · 2 Mi · 3 Sol · 4 La · 5 Do').
@export_range(0, 5) var nota_propia: int = 0
@export var color_a: Color = Color.WHITE
@export var color_b: Color = Color.WHITE

@export_group("Toque")
## false en el menú: allí el toque lo gestiona el botón gigante.
@export var tocable: bool = true
## Radio de toque (en píxeles del dibujo, antes de escalar).
@export var radio_toque: float = 210.0
## Centro del cuerpo respecto a los pies (el nodo está en los pies).
@export var centro_toque: Vector2 = Vector2(0, -242)

@export_group("Animación")
@export var animador: AnimationPlayer
@export var anim_reposo: StringName = &"reposo"
@export var anims_atencion: Array[StringName] = [&"respirar", &"saltito", &"saludar"]
## Nodo que flota arriba y abajo (p. ej. el Sprite2D de Nubi). Vacío = no flota.
@export var nodo_flotante: Node2D
@export var amplitud_flotar: float = 12.0

var _escala_base: Vector2
var _posicion_base: Vector2
var _tween: Tween
var _tiempo: float = 0.0
var _flotante_base: Vector2


func _ready() -> void:
	_escala_base = scale
	_posicion_base = position
	if nodo_flotante:
		_flotante_base = nodo_flotante.position


func _process(delta: float) -> void:
	if nodo_flotante and amplitud_flotar > 0.0:
		_tiempo += delta
		nodo_flotante.position = _flotante_base + Vector2(
				sin(_tiempo * 0.7) * amplitud_flotar * 0.6, sin(_tiempo * 1.6) * amplitud_flotar)


func _input(event: InputEvent) -> void:
	if tocable and event is InputEventScreenTouch and event.pressed and contiene(event.position):
		tocado.emit(self)


## ¿El punto de pantalla toca al personaje?
func contiene(punto_pantalla: Vector2) -> bool:
	var punto: Vector2 = get_canvas_transform().affine_inverse() * punto_pantalla
	return to_local(punto).distance_to(centro_toque) <= radio_toque


## Centro del personaje en coordenadas de pantalla (para partículas).
func centro_en_pantalla() -> Vector2:
	return get_global_transform_with_canvas() * centro_toque


## Rebote tipo plastilina.
func reaccionar_toque() -> void:
	_detener_tween()
	scale = _escala_base * Vector2(1.2, 0.82)  # se aplasta...
	_tween = create_tween()
	_tween.tween_property(self, "scale", _escala_base, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)  # ...y rebota


## Entrada al empezar un nivel: aparece "inflándose" con rebote.
func saludar_entrada(retraso: float = 0.3) -> void:
	_detener_tween()
	scale = _escala_base * 0.05
	_tween = create_tween()
	_tween.tween_interval(retraso)
	_tween.tween_property(self, "scale", _escala_base, 0.7) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Invitación a jugar (nivel 1 sutil · 2 juguetón · 3 claro).
func llamar_atencion(nivel: int) -> void:
	_detener_tween()
	var i: int = clampi(nivel - 1, 0, anims_atencion.size() - 1)
	if animador and not anims_atencion.is_empty() and animador.has_animation(anims_atencion[i]):
		animador.play(anims_atencion[i])
		return

	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match nivel:
		1:  # Respira
			for k in 2:
				_tween.tween_property(self, "scale", _escala_base * 1.08, 0.35)
				_tween.tween_property(self, "scale", _escala_base, 0.35)
		2:  # Saltito
			_saltito(40.0)
		_:  # Dos saltitos y balanceo: "¡ven!"
			_saltito(50.0)
			_saltito(30.0)
			_tween.tween_property(self, "rotation_degrees", 8.0, 0.2)
			_tween.tween_property(self, "rotation_degrees", -8.0, 0.3)
			_tween.tween_property(self, "rotation_degrees", 0.0, 0.2)


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
