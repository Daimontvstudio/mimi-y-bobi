## ============================================================================
## JardinNivel1 — "El Jardín de las Sorpresas Musicales" (Godot 4.x)
## ----------------------------------------------------------------------------
## Script del nodo raíz. Conecta: zonas gigantes → retroalimentación + Mimí,
## y vigilante de inactividad → llamadas de atención de Mimí.
##
## Árbol de escena:
##   JardinNivel1 (Node2D)                 ← jardin_nivel1.gd
##   ├─ Fondo (Sprite2D)
##   ├─ Mimi (Node2D)                      ← personaje_principal.gd
##   │   └─ Sprite2D (o el modelo/animaciones)
##   ├─ Retroalimentacion (Node2D)         ← retroalimentacion.gd
##   ├─ VigilanteInactividad (Node)        ← vigilante_inactividad.gd
##   └─ CapaToque (CanvasLayer)            ← déjala vacía: las 3 zonas se crean solas
##                                           (o añade tú nodos ZonaToqueGigante)
## ============================================================================
extends Node2D

# Zonas por defecto (izquierda → derecha): notas graves → agudas.
const ZONAS_POR_DEFECTO := [
	{"notas": [0, 1], "color": Color("ff4fb8"), "acento": Color("ffe14d")},  # Mimí: rosa / amarillo
	{"notas": [2, 3], "color": Color("3fd0ff"), "acento": Color("a8ff3e")},  # Bobi: azul / lima
	{"notas": [4, 5], "color": Color("b45cff"), "acento": Color("ff9a1f")},  # Lumen: morado / naranja
]

@onready var mimi: PersonajePrincipal = $Mimi
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque

var _zonas: Array[ZonaToqueGigante] = []


func _ready() -> void:
	# Usa las zonas que pusiste a mano; si no hay ninguna, crea las 3 por defecto.
	for hijo in capa_toque.get_children():
		if hijo is ZonaToqueGigante:
			_zonas.append(hijo)
	if _zonas.is_empty():
		_crear_zonas_por_defecto()

	for zona in _zonas:
		zona.tocada.connect(_al_tocar_zona)

	vigilante.llamar_atencion.connect(mimi.llamar_atencion)
	vigilante.nino_volvio.connect(mimi.cancelar_llamada)


func _crear_zonas_por_defecto() -> void:
	for i in ZONAS_POR_DEFECTO.size():
		var datos: Dictionary = ZONAS_POR_DEFECTO[i]
		var zona := ZonaToqueGigante.new()
		zona.name = "Zona%d" % i
		zona.columna = i
		zona.total_columnas = ZONAS_POR_DEFECTO.size()
		zona.notas = PackedInt32Array(datos["notas"])
		zona.color_principal = datos["color"]
		zona.color_acento = datos["acento"]
		capa_toque.add_child(zona)
		_zonas.append(zona)


## Toque válido en una zona: sonido + partículas + rebote de Mimí.
func _al_tocar_zona(zona: ZonaToqueGigante, posicion_pantalla: Vector2) -> void:
	retro.celebrar_toque(posicion_pantalla, zona.siguiente_nota(),
			zona.color_principal, zona.color_acento)
	mimi.reaccionar_toque()


## Cero frustración: un toque FUERA de las zonas tampoco "falla".
## Recibe un destello pequeño y silencioso para que la pantalla nunca parezca muerta.
func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch and event.pressed):
		return
	for zona in _zonas:
		if zona.contiene(event.position):
			return
	retro.lanzar_particulas(event.position, Color("fff6c9"), Color("ffffff"), 4)
