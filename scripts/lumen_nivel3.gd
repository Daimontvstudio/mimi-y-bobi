## ============================================================================
## LumenNivel3 — "El Jardín de Lumen" · Memoria y secuencias (Godot 4.x)
## ----------------------------------------------------------------------------
## Lumen enciende las flores-orbe en orden, cada una con su nota.
## Después es el turno del niño: tocar las flores en el mismo orden.
##
## Cero frustración:
##   - TODA flor tocada brilla y suena, sea o no la "correcta".
##   - Equivocarse no resta nada: Lumen respira y repite la secuencia con calma.
##   - Si cuesta (2 reintentos), la secuencia se hace MÁS CORTA.
##   - Al acertar: fiesta rítmica y la secuencia crece (máximo 4 destellos).
##   - Sin tiempo límite. Si el niño se distrae, la flor siguiente late (pista)
##     y después Lumen vuelve a enseñar la secuencia.
##
## Zonas de toque: 3 columnas gigantes (dos tercios inferiores de la pantalla).
## ============================================================================
extends Node2D

enum Estado { DEMO, TURNO, FIESTA }

const NOTAS_ORBES := [0, 2, 4]   # Do · Mi · La
const LONGITUD_MAXIMA := 4
const COLORES_FIESTA := [Color("b45cff"), Color("ff9a1f"), Color("ffd23f"), Color("ffb347")]

@export var pausa_entre_destellos: float = 0.8

@onready var lumen: PersonajePrincipal = $Lumen
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque

var orbes: Array[OrbeLuz] = []
var _estado: Estado = Estado.DEMO
var _secuencia: Array[int] = []
var _longitud: int = 1
var _posicion: int = 0
var _reintentos: int = 0
var _tween_demo: Tween


func _ready() -> void:
	for nodo in $Orbes.get_children():
		if nodo is OrbeLuz:
			orbes.append(nodo)

	for i in orbes.size():
		var zona := ZonaToqueGigante.new()
		zona.name = "Zona%d" % i
		zona.columna = i
		zona.total_columnas = orbes.size()
		zona.alto_fraccion = 0.66
		zona.notas = PackedInt32Array([NOTAS_ORBES[i]])
		zona.color_principal = orbes[i].color
		zona.mostrar_debug = false  # las flores ya marcan cada zona
		capa_toque.add_child(zona)
		zona.tocada.connect(_al_tocar_zona)

	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(lumen.cancelar_llamada)

	lumen.saludar_entrada()
	var inicio := create_tween()
	inicio.tween_interval(1.4)
	inicio.tween_callback(_nueva_ronda)


# ---------- Rondas ----------

func _nueva_ronda() -> void:
	_secuencia.clear()
	var anterior: int = -1
	for i in _longitud:
		var n: int = randi() % orbes.size()
		if n == anterior:  # sin repetir la misma flor dos veces seguidas
			n = (n + 1 + randi() % (orbes.size() - 1)) % orbes.size()
		_secuencia.append(n)
		anterior = n
	_mostrar_secuencia()


## Lumen enseña la secuencia: destello + nota, con calma.
func _mostrar_secuencia() -> void:
	_estado = Estado.DEMO
	_posicion = 0
	if _tween_demo and _tween_demo.is_valid():
		_tween_demo.kill()
	lumen.reaccionar_toque()
	_tween_demo = create_tween()
	_tween_demo.tween_interval(0.7)
	for i in _secuencia:
		_tween_demo.tween_callback(_destello.bind(i, false))
		_tween_demo.tween_interval(pausa_entre_destellos)
	_tween_demo.tween_callback(_empezar_turno)


func _empezar_turno() -> void:
	_estado = Estado.TURNO
	vigilante.registrar_actividad()  # los 4 s de espera cuentan desde aquí


func _destello(i: int, con_particulas: bool) -> void:
	orbes[i].encender()
	retro.tocar_nota(NOTAS_ORBES[i])
	if con_particulas:
		retro.lanzar_particulas(_en_pantalla(orbes[i]), orbes[i].color, Color("ffd23f"), 10)


# ---------- Turno del niño ----------

func _al_tocar_zona(zona: ZonaToqueGigante, _posicion_pantalla: Vector2) -> void:
	var i: int = zona.columna
	_destello(i, true)  # siempre hay luz y música
	if _estado != Estado.TURNO:
		return
	if i == _secuencia[_posicion]:
		_posicion += 1
		if _posicion >= _secuencia.size():
			_acierto()
	else:
		_reintento_dulce()


func _acierto() -> void:
	_estado = Estado.FIESTA
	_reintentos = 0
	lumen.llamar_atencion(3)  # saltitos de alegría
	for orbe in orbes:
		orbe.encender(1.4)
	retro.fiesta(Vector2(1170, 560), COLORES_FIESTA, [0, 2, 3, 4, 5, 4], 0.36, 420.0)
	_longitud = mini(_longitud + 1, LONGITUD_MAXIMA)
	var espera := create_tween()
	espera.tween_interval(3.0)
	espera.tween_callback(_tras_fiesta)


func _tras_fiesta() -> void:
	lumen.cancelar_llamada()
	_nueva_ronda()


## Sin castigo: Lumen respira ("mira otra vez") y repite; si cuesta, acorta.
func _reintento_dulce() -> void:
	_estado = Estado.DEMO
	_reintentos += 1
	lumen.llamar_atencion(1)
	var espera := create_tween()
	espera.tween_interval(1.3)
	if _reintentos >= 2 and _longitud > 1:
		_longitud -= 1
		_reintentos = 0
		espera.tween_callback(_nueva_ronda)
	else:
		espera.tween_callback(_mostrar_secuencia)


# ---------- Inactividad ----------

func _al_pedir_atencion(nivel: int) -> void:
	if _estado == Estado.FIESTA:
		return
	lumen.llamar_atencion(nivel)
	if _estado != Estado.TURNO:
		return
	if nivel == 2:
		orbes[_secuencia[_posicion]].invitar()  # la flor que toca, late
	elif nivel >= 3:
		_mostrar_secuencia()  # Lumen la enseña otra vez


func _en_pantalla(nodo: Node2D) -> Vector2:
	return nodo.get_global_transform_with_canvas().origin
