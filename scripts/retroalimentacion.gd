## ============================================================================
## Retroalimentacion — Sonido armónico + partículas (Godot 4.x)
## ----------------------------------------------------------------------------
## Función principal: celebrar_toque(). Suena una nota de la escala pentatónica
## y salen estrellas y corazones en el punto tocado, en el mismo frame.
## fiesta(): celebración RÍTMICA a tempo tranquilo (≈ 90 ppm): un estallido
## suave y una nota por pulso, alegre pero relajante.
## Además conecta solos a todos los personajes del grupo "personajes":
## al tocarlos suena su nota propia con partículas de sus colores.
##
## Escala pentatónica de Do (Do Re Mi Sol La Do'): no tiene notas que choquen,
## así que cualquier combinación de toques suena bonita.
## Solo necesitas UN sample suave en Do (campanita, marimba, xilófono):
## las demás notas se obtienen cambiando `pitch_scale`.
## ============================================================================
class_name Retroalimentacion
extends Node2D

const ESCALA_PENTATONICA := [
	1.0,     # 0 Do
	1.1225,  # 1 Re
	1.2599,  # 2 Mi
	1.4983,  # 3 Sol
	1.6818,  # 4 La
	2.0,     # 5 Do agudo
]

@export var nota_base: AudioStream
@export var textura_estrella: Texture2D
@export var textura_corazon: Texture2D
## Notas que pueden sonar a la vez (varios dedos rápidos).
@export var voces_simultaneas: int = 6
@export var volumen_db: float = -4.0

var _voces: Array[AudioStreamPlayer] = []
var _voz_siguiente: int = 0


func _ready() -> void:
	z_index = 10  # partículas por encima de los personajes
	# "Pool" de reproductores: se reutilizan, no se crean en cada toque.
	for i in voces_simultaneas:
		var voz := AudioStreamPlayer.new()
		voz.stream = nota_base
		add_child(voz)
		_voces.append(voz)
	# Diferido: así todos los personajes de la escena ya están listos.
	_conectar_personajes.call_deferred()


func _conectar_personajes() -> void:
	for nodo in get_tree().get_nodes_in_group("personajes"):
		if nodo is PersonajePrincipal and nodo.tocable:
			nodo.tocado.connect(_al_tocar_personaje)


## Cada personaje suena con SU nota y brilla con SUS colores.
func _al_tocar_personaje(p: PersonajePrincipal) -> void:
	tocar_nota(p.nota_propia)
	lanzar_particulas(p.centro_en_pantalla(), p.color_a, p.color_b, 10)
	p.reaccionar_toque()


## Retroalimentación completa de un toque válido.
func celebrar_toque(posicion_pantalla: Vector2, indice_nota: int,
		color_principal: Color, color_acento: Color) -> void:
	tocar_nota(indice_nota)
	lanzar_particulas(posicion_pantalla, color_principal, color_acento, 14)


## Reproduce una nota de la escala pentatónica (índice 0-5).
func tocar_nota(indice_nota: int, volumen: float = volumen_db) -> void:
	if nota_base == null or _voces.is_empty():
		return
	var voz: AudioStreamPlayer = _voces[_voz_siguiente]
	_voz_siguiente = (_voz_siguiente + 1) % _voces.size()
	var i: int = clampi(indice_nota, 0, ESCALA_PENTATONICA.size() - 1)
	voz.pitch_scale = ESCALA_PENTATONICA[i]
	voz.volume_db = volumen
	voz.play()


## Varias notas seguidas (fanfarrias y celebraciones).
func arpegio(indices_notas: Array, intervalo: float = 0.12, volumen: float = volumen_db) -> void:
	var t := create_tween()
	for n in indices_notas:
		t.tween_callback(tocar_nota.bind(n, volumen))
		t.tween_interval(intervalo)


## Celebración rítmica: un pulso cada `intervalo` segundos (0,36 s ≈ 83 ppm).
## En cada pulso suena una nota y florece un estallido suave alrededor del centro.
func fiesta(centro_pantalla: Vector2, colores: Array, notas: Array = [0, 2, 3, 4, 5],
		intervalo: float = 0.36, dispersion: float = 170.0) -> void:
	if colores.is_empty():
		colores = [Color.WHITE]
	var t := create_tween()
	for i in notas.size():
		t.tween_callback(_pulso_fiesta.bind(centro_pantalla, colores, notas[i], i, dispersion))
		t.tween_interval(intervalo)


func _pulso_fiesta(centro: Vector2, colores: Array, nota: int, i: int, dispersion: float) -> void:
	tocar_nota(nota, volumen_db - 2.0)
	var desfase := Vector2(randf_range(-dispersion, dispersion), randf_range(-dispersion, dispersion) * 0.5)
	lanzar_particulas(centro + desfase, colores[i % colores.size()],
			colores[(i + 1) % colores.size()], 10)


## Explosión de estrellas (color principal) y corazones (color acento).
func lanzar_particulas(posicion_pantalla: Vector2, color_principal: Color,
		color_acento: Color, cantidad: int = 14) -> void:
	# Convierte coordenadas de pantalla a coordenadas del mundo 2D.
	var pos_mundo: Vector2 = get_canvas_transform().affine_inverse() * posicion_pantalla
	var texturas := [textura_estrella, textura_corazon]
	var colores := [color_principal, color_acento]
	for k in 2:
		var p := CPUParticles2D.new()
		p.position = to_local(pos_mundo)
		p.texture = texturas[k]
		p.amount = maxi(cantidad / 2, 1)
		p.one_shot = true
		p.explosiveness = 1.0          # todas salen a la vez: "¡pop!"
		p.lifetime = 1.1
		p.direction = Vector2.UP
		p.spread = 180.0
		p.initial_velocity_min = 140.0
		p.initial_velocity_max = 270.0
		p.gravity = Vector2(0.0, 260.0)  # caen despacio, como confeti
		p.angular_velocity_min = -120.0
		p.angular_velocity_max = 120.0
		if p.texture == null:
			# Sin textura aún: cuadraditos de color grandes para poder probar.
			p.scale_amount_min = 10.0
			p.scale_amount_max = 18.0
		else:
			p.scale_amount_min = 0.5
			p.scale_amount_max = 1.0
		# Se desvanecen suavemente, nunca desaparecen de golpe.
		var c: Color = colores[k]
		var degradado := Gradient.new()
		degradado.set_color(0, c)
		degradado.set_color(1, Color(c, 0.0))
		p.color_ramp = degradado
		add_child(p)
		p.emitting = true
		# Se borra sola al terminar.
		get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)
