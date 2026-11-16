## ============================================================================
## MenuPrincipal — Pantalla de inicio (Godot 4.x)
## ----------------------------------------------------------------------------
## Dos botones GIGANTES: cada uno es media pantalla completa.
##   Izquierda → Mimí (ritmo)    → Nivel 1, El Jardín de las Sorpresas Musicales
##   Derecha   → Bobi (lógica)   → Nivel 2, El Taller de Bobi
## Reutiliza ZonaToqueGigante (2 columnas, altura 100 %).
## Al tocar: fanfarria pentatónica + partículas + rebote, y fundido al nivel.
## Si nadie toca en 4 s, Mimí y Bobi se turnan para invitar a jugar.
## ============================================================================
extends Node2D

const ESCENA_MIMI := "res://escenas/jardin_nivel1.tscn"
const ESCENA_BOBI := "res://escenas/taller_nivel2.tscn"

const BOTONES := [
	{"notas": [0, 2], "color": Color("ff4fb8"), "acento": Color("ffe14d"),
		"fanfarria": [0, 2, 4], "escena": ESCENA_MIMI},
	{"notas": [3, 5], "color": Color("3fc4ff"), "acento": Color("a8ff3e"),
		"fanfarria": [1, 3, 5], "escena": ESCENA_BOBI},
]

@onready var mimi: PersonajePrincipal = $Mimi
@onready var bobi: PersonajePrincipal = $Bobi
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque

var _eligiendo: bool = false
var _turno: int = 0


func _ready() -> void:
	for i in BOTONES.size():
		var datos: Dictionary = BOTONES[i]
		var zona := ZonaToqueGigante.new()
		zona.name = "Boton%d" % i
		zona.columna = i
		zona.total_columnas = BOTONES.size()
		zona.alto_fraccion = 1.0          # pantalla completa de alto
		zona.notas = PackedInt32Array(datos["notas"])
		zona.color_principal = datos["color"]
		zona.color_acento = datos["acento"]
		zona.mostrar_debug = false        # los paneles ya están dibujados en el fondo
		capa_toque.add_child(zona)
		zona.tocada.connect(_al_elegir)

	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(_cancelar_llamadas)


func _al_elegir(zona: ZonaToqueGigante, posicion_pantalla: Vector2) -> void:
	if _eligiendo or Transicion.ocupado:
		return
	_eligiendo = true
	_cancelar_llamadas()
	var datos: Dictionary = BOTONES[zona.columna]
	var personaje: PersonajePrincipal = mimi if zona.columna == 0 else bobi

	retro.arpegio(datos["fanfarria"], 0.13)
	retro.lanzar_particulas(posicion_pantalla, zona.color_principal, zona.color_acento, 16)
	retro.lanzar_particulas(personaje.get_global_transform_with_canvas().origin + Vector2(0, -250),
			zona.color_principal, zona.color_acento, 24)
	personaje.reaccionar_toque()

	# Pequeña pausa para disfrutar la fanfarria, y fundido al nivel elegido.
	var espera := create_tween()
	espera.tween_interval(0.7)
	espera.tween_callback(Transicion.ir_a.bind(datos["escena"]))


func _al_pedir_atencion(nivel: int) -> void:
	if _eligiendo:
		return
	_cancelar_llamadas()
	var personaje: PersonajePrincipal = mimi if _turno % 2 == 0 else bobi
	_turno += 1
	personaje.llamar_atencion(nivel)


func _cancelar_llamadas() -> void:
	mimi.cancelar_llamada()
	bobi.cancelar_llamada()
