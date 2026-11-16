## ============================================================================
## ConciertoEstrellas — Mimí · "El Concierto de las Estrellas" (Godot 4.x)
## ----------------------------------------------------------------------------
## Estrellas fugaces cruzan el cielo despacio. Cada estrella tocada suena con
## la SIGUIENTE nota de una melodía pentatónica y vuela a formar una
## constelación arriba: el niño "toca" la canción a su ritmo.
## Al completar la melodía, la constelación la canta entera y hay fiesta.
##
## Cero frustración: las estrellas que nadie toca se van y llegan otras;
## no hay fallos ni prisa. Basta con tocar CERCA de una estrella.
## ============================================================================
extends Node2D

## Melodías originales (índices de la escala pentatónica de Do).
const MELODIAS := [
	[0, 2, 4, 4, 3, 2, 0, 2, 4, 5, 4, 3, 2, 1, 0, 0],
	[4, 3, 2, 0, 2, 3, 4, 4, 5, 4, 2, 3, 1, 2, 0, 0],
	[0, 0, 2, 3, 4, 3, 2, 0, 1, 2, 3, 4, 5, 4, 2, 0],
]
const COLORES := [Color("ff4fb8"), Color("ffd23f"), Color("3fc4ff"), Color("b45cff"), Color("9dff3a")]

@export var textura_estrella: Texture2D
@export var textura_halo: Texture2D
@export var max_estrellas: int = 4
@export var segundos_entre_estrellas: float = 1.4
## Velocidad de las estrellas (px/s): lentas para que dé tiempo.
@export var velocidad: float = 190.0
## Distancia máxima a la que un toque "atrapa" una estrella.
@export var radio_toque: float = 250.0

@onready var mimi: PersonajePrincipal = $Mimi
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var cielo: Node2D = $Cielo

var _estrellas: Array[Node2D] = []
var _constelacion: Array[Node2D] = []
var _melodia: int = 0
var _nota: int = 0
var _espera: float = 0.6
var _fiesta: bool = false
var _material_luz := CanvasItemMaterial.new()


func _ready() -> void:
	_material_luz.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(mimi.cancelar_llamada)
	mimi.saludar_entrada()


func _process(delta: float) -> void:
	var vista: Vector2 = get_viewport().get_visible_rect().size
	_espera -= delta
	if _espera <= 0.0 and not _fiesta and _estrellas.size() < max_estrellas:
		_crear_estrella(vista)
		_espera = segundos_entre_estrellas * randf_range(0.8, 1.3)
	for e in _estrellas.duplicate():
		e.position += e.get_meta("velocidad") * delta
		e.rotation += delta * 0.6
		if e.position.x < -250.0 or e.position.y > vista.y + 250.0:
			_estrellas.erase(e)
			e.queue_free()


func _crear_estrella(vista: Vector2) -> void:
	var color: Color = COLORES[randi() % COLORES.size()]
	var e := Node2D.new()
	var estela := CPUParticles2D.new()  # rastro de polvo de estrellas
	estela.texture = textura_estrella
	estela.amount = 18
	estela.lifetime = 0.9
	estela.local_coords = false
	estela.gravity = Vector2.ZERO
	estela.spread = 180.0
	estela.initial_velocity_min = 5.0
	estela.initial_velocity_max = 25.0
	estela.scale_amount_min = 0.15
	estela.scale_amount_max = 0.3
	var degradado := Gradient.new()
	degradado.set_color(0, Color(color, 0.8))
	degradado.set_color(1, Color(color, 0.0))
	estela.color_ramp = degradado
	var halo := Sprite2D.new()
	halo.texture = textura_halo
	halo.material = _material_luz
	halo.modulate = Color(color, 0.8)
	halo.scale = Vector2.ONE * 0.75
	var cuerpo := Sprite2D.new()
	cuerpo.texture = textura_estrella
	cuerpo.modulate = color.lightened(0.25)
	cuerpo.scale = Vector2.ONE * 2.2
	e.add_child(estela)
	e.add_child(halo)
	e.add_child(cuerpo)
	e.position = Vector2(vista.x + 200.0, randf_range(260.0, vista.y * 0.62))
	e.set_meta("velocidad", Vector2(-velocidad, velocidad * randf_range(0.15, 0.4)))
	e.set_meta("color", color)
	cielo.add_child(e)
	_estrellas.append(e)


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch and event.pressed):
		return
	if mimi.contiene(event.position):
		return  # Mimí responde con su propia nota
	var punto: Vector2 = get_canvas_transform().affine_inverse() * event.position
	var mejor: Node2D = null
	var mejor_distancia: float = radio_toque
	for e in _estrellas:
		var d: float = e.global_position.distance_to(punto)
		if d < mejor_distancia:
			mejor = e
			mejor_distancia = d
	if mejor:
		_tocar_estrella(mejor)
	else:
		retro.lanzar_particulas(event.position, Color("fff6c9"), Color.WHITE, 4)
		retro.tocar_nota(randi() % 6, -18.0)


func _tocar_estrella(e: Node2D) -> void:
	_estrellas.erase(e)
	var color: Color = e.get_meta("color")
	var en_pantalla: Vector2 = e.get_global_transform_with_canvas().origin
	if _fiesta:
		retro.tocar_nota(randi() % 6)
		retro.lanzar_particulas(en_pantalla, color, Color.WHITE, 12)
		e.queue_free()
		return

	var melodia: Array = MELODIAS[_melodia]
	retro.tocar_nota(melodia[_nota])
	retro.lanzar_particulas(en_pantalla, color, Color("ffd23f"), 14)
	mimi.reaccionar_toque()

	# Vuela a su sitio en la constelación de arriba.
	var vista: Vector2 = get_viewport().get_visible_rect().size
	var t_x: float = float(_nota) / float(melodia.size() - 1)
	var destino := Vector2(lerpf(vista.x * 0.22, vista.x * 0.88, t_x), 95.0 + 22.0 * sin(_nota * 0.9))
	for hijo in e.get_children():
		if hijo is CPUParticles2D:
			hijo.emitting = false
	var t := e.create_tween().set_parallel(true)
	t.tween_property(e, "position", destino, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(e, "scale", Vector2.ONE * 0.38, 0.6)
	t.tween_property(e, "rotation", 0.0, 0.6)
	_constelacion.append(e)

	_nota += 1
	if _nota >= melodia.size():
		_fin_melodia()


## La constelación canta toda la melodía que el niño ha "tocado".
func _fin_melodia() -> void:
	_fiesta = true
	mimi.llamar_atencion(3)
	var melodia: Array = MELODIAS[_melodia]
	var t := create_tween()
	t.tween_interval(0.8)
	for i in _constelacion.size():
		t.tween_callback(_brillar_constelacion.bind(i, melodia[i]))
		t.tween_interval(0.3)
	t.tween_callback(retro.fiesta.bind(Vector2(1170, 420), COLORES, [0, 2, 4, 5], 0.36, 500.0))
	t.tween_interval(2.0)
	t.tween_callback(_nueva_melodia)


func _brillar_constelacion(i: int, nota: int) -> void:
	var e: Node2D = _constelacion[i]
	retro.tocar_nota(nota)
	retro.lanzar_particulas(e.get_global_transform_with_canvas().origin, e.get_meta("color"), Color.WHITE, 5)
	var t := e.create_tween()
	t.tween_property(e, "scale", Vector2.ONE * 0.6, 0.12)
	t.tween_property(e, "scale", Vector2.ONE * 0.38, 0.2)


func _nueva_melodia() -> void:
	for e in _constelacion:
		var t := e.create_tween()
		t.tween_property(e, "modulate:a", 0.0, 0.6)
		t.tween_callback(e.queue_free)
	_constelacion.clear()
	_melodia = (_melodia + 1) % MELODIAS.size()
	_nota = 0
	_fiesta = false
	mimi.cancelar_llamada()


func _al_pedir_atencion(nivel: int) -> void:
	if _fiesta:
		return
	mimi.llamar_atencion(nivel)
	if nivel >= 2:
		_espera = 0.0  # que llegue otra estrella ya
		for e in _estrellas:
			var t := e.create_tween()
			t.tween_property(e, "scale", Vector2.ONE * 1.25, 0.25)
			t.tween_property(e, "scale", Vector2.ONE, 0.3)
