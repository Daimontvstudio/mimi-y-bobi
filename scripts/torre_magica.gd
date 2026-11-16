## ============================================================================
## TorreMagica — Kubo · "La Torre Mágica" (Godot 4.x)
## ----------------------------------------------------------------------------
## Arrastrar bloques geométricos para apilar una torre de 5 pisos.
##   - Un solo imán suave marca el SIGUIENTE piso: cualquier bloque vale.
##   - Cada piso suena una nota más aguda (Do → La) y Kubo rebota.
##   - La bandeja siempre se rellena: nunca faltan bloques.
##   - Con 5 pisos la torre "se vuelve mágica": cada piso brilla y canta,
##     fiesta rítmica, y los bloques suben flotando al cielo para empezar otra.
## Cero frustración: la torre nunca se cae; un bloque soltado lejos vuelve
## flotando a la bandeja y el imán del siguiente piso brilla como pista.
## ============================================================================
extends Node2D

const FORMAS := ["circulo", "cuadrado", "triangulo"]
const COLORES := [Color("ff3b5c"), Color("ffd23f"), Color("3fc4ff"), Color("9dff3a"), Color("b45cff")]
const BANDEJA := [Vector2(600, 905), Vector2(860, 905), Vector2(1120, 905)]
const BASE_TORRE := Vector2(1760, 905)
const ALTURA_BLOQUE := 186.0
const PISOS := 5
const NOTAS_PISOS := [0, 1, 2, 3, 4]

## Texturas de los bloques, en el mismo orden que FORMAS.
@export var texturas: Array[Texture2D] = []

@onready var kubo: PersonajePrincipal = $Kubo
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var gestor: GestorArrastre = $GestorArrastre
@onready var zona: ZonaIman = $ZonaSiguiente
@onready var bloques: Node2D = $Bloques

var _torre: Array[PiezaArrastrable] = []
var _celebrando: bool = false


func _ready() -> void:
	var piezas: Array[PiezaArrastrable] = []
	var zonas: Array[ZonaIman] = [zona]
	gestor.registrar(piezas, zonas)
	zona.position = BASE_TORRE
	for i in BANDEJA.size():
		_nuevo_bloque(i, 0.4 + 0.15 * i)

	gestor.pieza_levantada.connect(_al_levantar)
	gestor.pieza_encajada.connect(_al_encajar)
	gestor.pieza_regreso.connect(_al_regresar)
	gestor.pieza_encajada_tocada.connect(_al_tocar_encajada)
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(kubo.cancelar_llamada)
	kubo.saludar_entrada()


## Crea un bloque al azar en un hueco de la bandeja, con un "pop".
func _nuevo_bloque(hueco: int, retraso: float = 0.0) -> void:
	var k: int = randi() % FORMAS.size()
	var p := PiezaArrastrable.new()
	p.color = COLORES[randi() % COLORES.size()]
	p.forma = StringName(FORMAS[k])
	p.puede_girar = false
	p.radio_agarre = 165.0
	p.position = BANDEJA[hueco]
	p.set_meta("hueco", hueco)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	if k < texturas.size():
		visual.texture = texturas[k]
	visual.scale = Vector2.ONE * 0.8
	p.add_child(visual)
	bloques.add_child(p)
	gestor.piezas.append(p)
	p.scale = Vector2.ONE * 0.01
	var t := p.create_tween()
	t.tween_interval(retraso)
	t.tween_property(p, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------- Reacciones ----------

func _al_levantar(_pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(0, -12.0)


func _al_encajar(pieza: PiezaArrastrable, z: ZonaIman) -> void:
	z.ocupada_por = null  # el imán sube al piso siguiente
	_torre.append(pieza)
	var piso: int = _torre.size()
	retro.tocar_nota(NOTAS_PISOS[mini(piso - 1, NOTAS_PISOS.size() - 1)])
	retro.lanzar_particulas(_en_pantalla(z), pieza.color, Color.WHITE, 14)
	kubo.reaccionar_toque()
	z.position = BASE_TORRE + Vector2(0, -ALTURA_BLOQUE * piso)
	var reponer := create_tween()
	reponer.tween_interval(0.45)
	reponer.tween_callback(_nuevo_bloque.bind(int(pieza.get_meta("hueco"))))
	if piso >= PISOS:
		_torre_magica()


func _al_regresar(_pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(0, -16.0)
	zona.resaltar()


func _al_tocar_encajada(pieza: PiezaArrastrable) -> void:
	pieza.impulso_giro()
	retro.tocar_nota(randi() % 6, -8.0)
	retro.lanzar_particulas(_en_pantalla(pieza), pieza.color, Color.WHITE, 6)


# ---------- ¡Torre mágica! ----------

func _torre_magica() -> void:
	_celebrando = true
	gestor.bloqueado = true
	zona.visible = false
	kubo.llamar_atencion(3)
	var t := create_tween()
	t.tween_interval(0.4)
	for i in _torre.size():
		t.tween_callback(_brillar_piso.bind(i))
		t.tween_interval(0.36)
	t.tween_callback(retro.fiesta.bind(Vector2(1760, 450), COLORES, [5, 4, 3, 4, 5], 0.36, 260.0))
	t.tween_interval(2.0)
	t.tween_callback(_desmontar)


func _brillar_piso(i: int) -> void:
	var p := _torre[i]
	retro.tocar_nota(NOTAS_PISOS[i])
	retro.lanzar_particulas(_en_pantalla(p), p.color, Color("ffd23f"), 8)
	p.impulso_giro()


## Los bloques suben flotando al cielo y la torre empieza de nuevo.
func _desmontar() -> void:
	for i in _torre.size():
		var p := _torre[i]
		gestor.piezas.erase(p)
		var t := p.create_tween().set_parallel(true)
		t.tween_property(p, "position", p.position + Vector2(randf_range(-260, 260), -1100), 1.4) \
			.set_delay(i * 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(p, "modulate:a", 0.0, 1.4).set_delay(i * 0.08)
		t.chain().tween_callback(p.queue_free)
	_torre.clear()
	zona.position = BASE_TORRE
	zona.visible = true
	gestor.bloqueado = false
	_celebrando = false
	kubo.cancelar_llamada()


func _al_pedir_atencion(nivel: int) -> void:
	if _celebrando:
		return
	kubo.llamar_atencion(nivel)
	if nivel >= 2:
		zona.resaltar()
		gestor.pista()


func _en_pantalla(nodo: Node2D) -> Vector2:
	return nodo.get_global_transform_with_canvas().origin
