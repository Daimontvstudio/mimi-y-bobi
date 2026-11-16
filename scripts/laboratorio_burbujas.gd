## ============================================================================
## LaboratorioBurbujas — Bobi · "El Laboratorio de Burbujas" (Godot 4.x)
## ----------------------------------------------------------------------------
## Causa → efecto:
##   - Del matraz salen burbujas de colores que suben bamboleándose.
##   - Tocar una burbuja: "¡plop!" + nota (grandes suenan graves, pequeñas
##     agudas) + partículas. Algunas guardan una sorpresa (más brillo).
##   - Tocar el matraz: "¡boing!" y sopla un chorro de burbujas.
##   - Cada 12 burbujas: mini fiesta rítmica.
## Cero frustración: las burbujas que llegan arriba se desvanecen solas,
## sin sonido ni castigo. Basta con tocar cerca.
## ============================================================================
extends Node2D

const COLORES := [Color("3fc4ff"), Color("9dff3a"), Color("ff4fb8"), Color("ffd23f"), Color("b45cff")]

@export var textura_burbuja: Texture2D
@export var sonido_pop: AudioStream
@export var sonido_boing: AudioStream
@export var max_burbujas: int = 12
@export var segundos_entre_burbujas: float = 1.5
## Radio del matraz como botón gigante.
@export var radio_matraz: float = 270.0

@onready var bobi: PersonajePrincipal = $Bobi
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var matraz: Sprite2D = $Matraz
@onready var burbujas: Node2D = $Burbujas

var _lista: Array[Sprite2D] = []
var _espera: float = 0.3
var _reventadas: int = 0
var _tiempo: float = 0.0
var _efectos: Array[AudioStreamPlayer] = []
var _efecto_siguiente: int = 0
var _escala_matraz: Vector2
var _tween_matraz: Tween


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_efectos.append(p)
	_escala_matraz = matraz.scale
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(bobi.cancelar_llamada)
	bobi.saludar_entrada()


func _process(delta: float) -> void:
	_tiempo += delta
	_espera -= delta
	if _espera <= 0.0 and _lista.size() < max_burbujas:
		_crear_burbuja(false)
		_espera = segundos_entre_burbujas * randf_range(0.7, 1.3)
	for b in _lista.duplicate():
		var fase: float = b.get_meta("fase")
		b.position.y -= float(b.get_meta("subida")) * delta
		b.position.x += (sin(_tiempo * 1.5 + fase) * 40.0 + float(b.get_meta("deriva"))) * delta
		if b.position.y < 150.0:
			_desvanecer(b)


func _boca_matraz() -> Vector2:
	return matraz.position + Vector2(0, -200.0 * _escala_matraz.y)


func _crear_burbuja(soplada: bool) -> void:
	var b := Sprite2D.new()
	b.texture = textura_burbuja
	var tam: float = randf_range(0.55, 1.25)
	b.modulate = COLORES[randi() % COLORES.size()]
	b.position = _boca_matraz() + Vector2(randf_range(-40.0, 40.0), 0.0)
	b.scale = Vector2.ONE * tam * 0.2
	b.set_meta("tam", tam)
	b.set_meta("subida", randf_range(85.0, 140.0) * (1.25 - tam * 0.3))
	b.set_meta("fase", randf() * TAU)
	b.set_meta("deriva", randf_range(-170.0, 170.0) if soplada else randf_range(-60.0, 60.0))
	b.set_meta("sorpresa", randi() % 4 == 0)
	burbujas.add_child(b)
	_lista.append(b)
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2.ONE * tam, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch and event.pressed):
		return
	if bobi.contiene(event.position):
		return  # Bobi responde con su propia nota
	var punto: Vector2 = get_canvas_transform().affine_inverse() * event.position
	var mejor: Sprite2D = null
	var mejor_distancia: float = INF
	for b in _lista:
		var radio: float = 128.0 * float(b.get_meta("tam")) + 90.0  # mucho margen
		var d: float = b.position.distance_to(punto)
		if d <= radio and d < mejor_distancia:
			mejor = b
			mejor_distancia = d
	if mejor:
		_reventar(mejor)
	elif punto.distance_to(matraz.position) <= radio_matraz:
		_soplar_matraz()
	else:
		retro.lanzar_particulas(event.position, Color("fff6c9"), Color.WHITE, 4)


func _reventar(b: Sprite2D) -> void:
	_lista.erase(b)
	var tam: float = b.get_meta("tam")
	var nota: int = clampi(int(round(remap(tam, 0.55, 1.25, 5.0, 0.0))), 0, 5)  # grande = grave
	_efecto(sonido_pop, clampf(1.15 / tam, 0.85, 1.7), -6.0)
	retro.tocar_nota(nota, -6.0)
	var en_pantalla: Vector2 = b.get_global_transform_with_canvas().origin
	var color := Color(b.modulate, 1.0)
	if b.get_meta("sorpresa"):
		retro.lanzar_particulas(en_pantalla, color, Color("ffd23f"), 24)
		bobi.reaccionar_toque()
	else:
		retro.lanzar_particulas(en_pantalla, color, Color.WHITE, 10)
	var t := b.create_tween().set_parallel(true)
	t.tween_property(b, "scale", b.scale * 1.4, 0.12)
	t.tween_property(b, "modulate:a", 0.0, 0.12)
	t.chain().tween_callback(b.queue_free)
	_reventadas += 1
	if _reventadas % 12 == 0:
		_mini_fiesta()


func _desvanecer(b: Sprite2D) -> void:
	_lista.erase(b)
	var t := b.create_tween().set_parallel(true)
	t.tween_property(b, "modulate:a", 0.0, 0.5)
	t.tween_property(b, "scale", b.scale * 1.2, 0.5)
	t.chain().tween_callback(b.queue_free)


func _soplar_matraz() -> void:
	_efecto(sonido_boing, 1.0, -6.0)
	retro.arpegio([0, 1, 2], 0.08, -10.0)
	bobi.reaccionar_toque()
	if _tween_matraz and _tween_matraz.is_valid():
		_tween_matraz.kill()
	matraz.scale = _escala_matraz * Vector2(1.15, 0.85)
	_tween_matraz = create_tween()
	_tween_matraz.tween_property(matraz, "scale", _escala_matraz, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for i in 5:
		if _lista.size() < max_burbujas + 6:
			_crear_burbuja(true)


func _mini_fiesta() -> void:
	retro.fiesta(Vector2(1170, 450), COLORES, [1, 3, 5, 3, 1], 0.36, 500.0)
	bobi.llamar_atencion(3)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(bobi.cancelar_llamada)


func _efecto(stream: AudioStream, tono: float, volumen: float) -> void:
	if stream == null:
		return
	var p := _efectos[_efecto_siguiente]
	_efecto_siguiente = (_efecto_siguiente + 1) % _efectos.size()
	p.stream = stream
	p.pitch_scale = tono
	p.volume_db = volumen
	p.play()


func _al_pedir_atencion(nivel: int) -> void:
	bobi.llamar_atencion(nivel)
	if nivel >= 2:
		# El matraz burbujea solo para invitar a tocarlo.
		if _tween_matraz and _tween_matraz.is_valid():
			_tween_matraz.kill()
		_tween_matraz = create_tween()
		_tween_matraz.tween_property(matraz, "rotation", 0.08, 0.15)
		_tween_matraz.tween_property(matraz, "rotation", -0.08, 0.2)
		_tween_matraz.tween_property(matraz, "rotation", 0.0, 0.15)
		_crear_burbuja(true)
		_crear_burbuja(true)
