## ============================================================================
## GestorArrastre — Arrastrar y soltar para dedos de 2-3 años (Godot 4.x)
## ----------------------------------------------------------------------------
## - Multitáctil: cada dedo puede llevar una pieza distinta.
## - Agarre generoso: se coge la pieza libre MÁS CERCANA dentro de su radio.
## - Imán táctil: al acercarse a una zona libre, la pieza es atraída hacia ella;
##   si llega muy cerca, encaja SOLA aunque el niño no levante el dedo.
## - Cero frustración: soltar lejos no es un fallo, la pieza vuelve flotando
##   a la bandeja.
## - Formas (opcional): si pieza y zona tienen `forma`, el imán solo atrae a la
##   pieza que coincide. Sin forma, cualquier pieza vale en cualquier zona.
## ============================================================================
class_name GestorArrastre
extends Node2D

signal pieza_levantada(pieza: PiezaArrastrable)
signal pieza_encajada(pieza: PiezaArrastrable, zona: ZonaIman)
signal pieza_regreso(pieza: PiezaArrastrable)
## Toque sobre una pieza que ya está encajada (efecto extra).
signal pieza_encajada_tocada(pieza: PiezaArrastrable)

## A esta distancia de una zona, la pieza encaja sola sin soltar el dedo.
@export var radio_captura_directa: float = 120.0
## Cuánto tira el imán de la pieza mientras se arrastra (0 = nada, 0.8 = mucho).
@export_range(0.0, 0.8) var fuerza_iman: float = 0.4
## Suavidad con la que la pieza sigue al dedo (más alto = más pegada).
@export var suavizado: float = 20.0

var piezas: Array[PiezaArrastrable] = []
var zonas: Array[ZonaIman] = []
## Bloquea agarrar piezas nuevas (p. ej. durante la celebración).
var bloqueado: bool = false

var _arrastres := {}  # índice de dedo → PiezaArrastrable
var _destinos := {}   # PiezaArrastrable → Vector2 (a dónde quiere ir)


func registrar(nuevas_piezas: Array[PiezaArrastrable], nuevas_zonas: Array[ZonaIman]) -> void:
	piezas = nuevas_piezas
	zonas = nuevas_zonas


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var punto: Vector2 = _a_mundo(event.position)
		if event.pressed:
			_al_presionar(event.index, punto)
		else:
			_al_soltar(event.index)
	elif event is InputEventScreenDrag and _arrastres.has(event.index):
		_al_arrastrar(event.index, _a_mundo(event.position))


func _process(delta: float) -> void:
	var k: float = 1.0 - exp(-suavizado * delta)
	for pieza in _destinos:
		pieza.global_position = pieza.global_position.lerp(_destinos[pieza], k)


# ---------------------------------------------------------------------------

func _al_presionar(dedo: int, punto: Vector2) -> void:
	# 1) ¿Tocó una pieza ya encajada? → efecto divertido.
	for pieza in piezas:
		if pieza.encajada and pieza.global_position.distance_to(punto) <= pieza.radio_agarre:
			pieza_encajada_tocada.emit(pieza)
			return
	if bloqueado:
		return
	# 2) Agarra la pieza libre más cercana dentro de su radio de agarre.
	var mejor: PiezaArrastrable = null
	var mejor_distancia: float = INF
	for pieza in piezas:
		if pieza.encajada or pieza.arrastrando:
			continue
		var d: float = pieza.global_position.distance_to(punto)
		if d <= pieza.radio_agarre and d < mejor_distancia:
			mejor = pieza
			mejor_distancia = d
	if mejor == null:
		return
	mejor.levantar()
	_arrastres[dedo] = mejor
	_destinos[mejor] = punto
	pieza_levantada.emit(mejor)


func _al_arrastrar(dedo: int, punto: Vector2) -> void:
	var pieza: PiezaArrastrable = _arrastres[dedo]
	var zona := _zona_libre_cercana(punto, pieza)
	if zona:
		var d: float = punto.distance_to(zona.global_position)
		if d <= radio_captura_directa:
			# Encaje automático: no hace falta soltar con precisión.
			_arrastres.erase(dedo)
			_destinos.erase(pieza)
			_encajar(pieza, zona)
			return
		# Imán: cuanto más cerca, más tira.
		var cercania: float = 1.0 - d / zona.radio_iman
		punto = punto.lerp(zona.global_position, fuerza_iman * cercania)
	_destinos[pieza] = punto


func _al_soltar(dedo: int) -> void:
	if not _arrastres.has(dedo):
		return
	var pieza: PiezaArrastrable = _arrastres[dedo]
	_arrastres.erase(dedo)
	_destinos.erase(pieza)
	var zona := _zona_libre_cercana(pieza.global_position, pieza)
	if zona:
		_encajar(pieza, zona)
	else:
		pieza.volver_a_origen()
		pieza_regreso.emit(pieza)


func _encajar(pieza: PiezaArrastrable, zona: ZonaIman) -> void:
	zona.ocupada_por = pieza
	pieza.encajar_en(zona.global_position)
	pieza_encajada.emit(pieza, zona)


func _zona_libre_cercana(punto: Vector2, pieza: PiezaArrastrable) -> ZonaIman:
	var mejor: ZonaIman = null
	var mejor_distancia: float = INF
	for zona in zonas:
		if zona.ocupada_por != null or not zona.acepta(pieza):
			continue
		var d: float = punto.distance_to(zona.global_position)
		if d <= zona.radio_iman and d < mejor_distancia:
			mejor = zona
			mejor_distancia = d
	return mejor


func _a_mundo(punto_pantalla: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * punto_pantalla


# ---------------------------------------------------------------------------

## Devuelve todas las piezas a la bandeja (para volver a jugar).
func liberar_todo() -> void:
	for zona in zonas:
		if zona.ocupada_por != null:
			zona.ocupada_por.volver_a_origen()
			zona.ocupada_por = null


## Pista visual: una pieza libre se asoma hacia una zona libre.
func pista() -> void:
	var zonas_libres: Array[ZonaIman] = []
	for zona in zonas:
		if zona.ocupada_por == null:
			zonas_libres.append(zona)
	var piezas_libres: Array[PiezaArrastrable] = []
	for pieza in piezas:
		if not pieza.encajada and not pieza.arrastrando:
			piezas_libres.append(pieza)
	piezas_libres.shuffle()
	for pieza in piezas_libres:
		for zona in zonas_libres:
			if zona.acepta(pieza):
				pieza.insinuar(zona.global_position)
				return


## Zonas libres que aceptarían esta pieza (para resaltarlas como pista).
func zonas_para(pieza: PiezaArrastrable) -> Array[ZonaIman]:
	var resultado: Array[ZonaIman] = []
	for zona in zonas:
		if zona.ocupada_por == null and zona.acepta(pieza):
			resultado.append(zona)
	return resultado


func todas_encajadas() -> bool:
	for zona in zonas:
		if zona.ocupada_por == null:
			return false
	return not zonas.is_empty()
