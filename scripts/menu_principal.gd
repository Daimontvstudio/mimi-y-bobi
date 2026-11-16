## ============================================================================
## MenuPrincipal — Pantalla de inicio (Godot 4.x)
## ----------------------------------------------------------------------------
## Cuatro botones GIGANTES (una columna cada uno, casi toda la altura):
##   Mimí  (ritmo)            → Nivel 1 · El Jardín de las Sorpresas Musicales
##   Bobi  (causa-efecto)     → Nivel 2 · El Taller de Bobi
##   Lumen (memoria y luces)  → Nivel 3 · El Jardín de Lumen
##   Kubo  (formas y espacio) → Nivel 4 · La Construcción de Kubo
## Nubi, la guía de sombras y siluetas, flota arriba: al tocarla canta su nota.
## Si nadie toca en 4 s, los personajes se turnan para invitar a jugar.
## ============================================================================
extends Node2D

const BOTONES := [
	{"personaje": "Mimi", "notas": [0, 2], "color": Color("ff4fb8"), "acento": Color("ffe14d"),
		"fanfarria": [0, 2, 4], "escena": "res://escenas/jardin_nivel1.tscn"},
	{"personaje": "Bobi", "notas": [1, 3], "color": Color("3fc4ff"), "acento": Color("a8ff3e"),
		"fanfarria": [1, 3, 5], "escena": "res://escenas/taller_nivel2.tscn"},
	{"personaje": "Lumen", "notas": [2, 4], "color": Color("b45cff"), "acento": Color("ff9a1f"),
		"fanfarria": [2, 4, 5], "escena": "res://escenas/lumen_nivel3.tscn"},
	{"personaje": "Kubo", "notas": [3, 5], "color": Color("ff3b5c"), "acento": Color("ffffff"),
		"fanfarria": [3, 4, 5], "escena": "res://escenas/kubo_nivel4.tscn"},
]

@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque
@onready var nubi: PersonajePrincipal = $Nubi

var _personajes: Array[PersonajePrincipal] = []
var _eligiendo: bool = false
var _turno: int = 0


func _ready() -> void:
	for i in BOTONES.size():
		var datos: Dictionary = BOTONES[i]
		_personajes.append(get_node(datos["personaje"]))
		var zona := ZonaToqueGigante.new()
		zona.name = "Boton%d" % i
		zona.columna = i
		zona.total_columnas = BOTONES.size()
		zona.alto_fraccion = 0.78      # la franja de arriba es de Nubi
		zona.notas = PackedInt32Array(datos["notas"])
		zona.color_principal = datos["color"]
		zona.color_acento = datos["acento"]
		zona.mostrar_debug = false     # los paneles ya están dibujados en el fondo
		capa_toque.add_child(zona)
		zona.tocada.connect(_al_elegir)

	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(_cancelar_llamadas)

	# Entrada escalonada: cada personaje aparece con un "pop" y su nota.
	for i in _personajes.size():
		_personajes[i].saludar_entrada(0.2 + 0.18 * i)
	nubi.saludar_entrada(0.2 + 0.18 * _personajes.size())
	retro.arpegio([0, 1, 2, 3, 4], 0.18, -10.0)


func _al_elegir(zona: ZonaToqueGigante, posicion_pantalla: Vector2) -> void:
	if _eligiendo or Transicion.ocupado:
		return
	_eligiendo = true
	_cancelar_llamadas()
	var datos: Dictionary = BOTONES[zona.columna]
	var personaje: PersonajePrincipal = _personajes[zona.columna]

	retro.arpegio(datos["fanfarria"], 0.13)
	retro.lanzar_particulas(posicion_pantalla, zona.color_principal, zona.color_acento, 16)
	retro.lanzar_particulas(personaje.centro_en_pantalla(), zona.color_principal, zona.color_acento, 24)
	personaje.reaccionar_toque()

	var espera := create_tween()
	espera.tween_interval(0.7)
	espera.tween_callback(Transicion.ir_a.bind(datos["escena"]))


func _al_pedir_atencion(nivel: int) -> void:
	if _eligiendo:
		return
	_cancelar_llamadas()
	# Se turnan los cuatro protagonistas y Nubi.
	var todos: Array[PersonajePrincipal] = []
	todos.append_array(_personajes)
	todos.append(nubi)
	todos[_turno % todos.size()].llamar_atencion(nivel)
	_turno += 1


func _cancelar_llamadas() -> void:
	for p in _personajes:
		p.cancelar_llamada()
	nubi.cancelar_llamada()
