## ============================================================================
## MenuPrincipal — Elegir personaje (Godot 4.x)
## ----------------------------------------------------------------------------
## Cinco columnas GIGANTES, a toda altura: Mimí, Bobi, Lumen, Kubo y Nubi.
## Encima de cada personaje se ven los iconos de sus minijuegos.
## Al tocar: fanfarria con la nota del personaje y paso a la pantalla
## de selección de sus juegos (o directamente al juego si solo tiene uno).
## ============================================================================
extends Node2D

@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque

var _personajes: Array[PersonajePrincipal] = []
var _eligiendo: bool = false
var _turno: int = 0


func _ready() -> void:
	var lista: Array = Catalogo.PERSONAJES
	for i in lista.size():
		var datos: Dictionary = lista[i]
		_personajes.append(get_node(datos["id"]))
		var zona := ZonaToqueGigante.new()
		zona.name = "Boton%d" % i
		zona.columna = i
		zona.total_columnas = lista.size()
		zona.alto_fraccion = 1.0
		zona.notas = PackedInt32Array([datos["nota"]])
		zona.color_principal = datos["color"]
		zona.color_acento = datos["acento"]
		zona.mostrar_debug = false  # los paneles ya están dibujados en el fondo
		capa_toque.add_child(zona)
		zona.tocada.connect(_al_elegir)

	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(_cancelar_llamadas)

	for i in _personajes.size():
		_personajes[i].saludar_entrada(0.2 + 0.16 * i)
	retro.arpegio([0, 1, 2, 3, 4], 0.16, -10.0)


func _al_elegir(zona: ZonaToqueGigante, posicion_pantalla: Vector2) -> void:
	if _eligiendo or Transicion.ocupado:
		return
	_eligiendo = true
	_cancelar_llamadas()
	var datos: Dictionary = Catalogo.PERSONAJES[zona.columna]
	var personaje := _personajes[zona.columna]
	var nota: int = datos["nota"]
	Catalogo.personaje_elegido = zona.columna

	retro.arpegio([nota, mini(nota + 2, 5), 5], 0.13)
	retro.lanzar_particulas(posicion_pantalla, zona.color_principal, zona.color_acento, 16)
	retro.lanzar_particulas(personaje.centro_en_pantalla(), zona.color_principal, zona.color_acento, 24)
	personaje.reaccionar_toque()

	var juegos: Array = datos["juegos"]
	var destino: String = juegos[0]["escena"] if juegos.size() == 1 else Catalogo.SELECTOR
	var espera := create_tween()
	espera.tween_interval(0.7)
	espera.tween_callback(Transicion.ir_a.bind(destino))


func _al_pedir_atencion(nivel: int) -> void:
	if _eligiendo:
		return
	_cancelar_llamadas()
	_personajes[_turno % _personajes.size()].llamar_atencion(nivel)
	_turno += 1


func _cancelar_llamadas() -> void:
	for p in _personajes:
		p.cancelar_llamada()
