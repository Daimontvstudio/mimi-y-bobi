## ============================================================================
## KuboNivel4 — "La Construcción de Kubo" · Formas y espacio (Godot 4.x)
## ----------------------------------------------------------------------------
## Bloques grandes (círculo, cuadrado, triángulo) se arrastran a sus siluetas
## en el tablero. Al completar el dibujo (una casita con sol, un robot...)
## llega una fiesta rítmica y el tablero cambia de diseño.
##
## Cero frustración:
##   - El imán solo atrae a la forma correcta, así que nunca encaja "mal".
##   - Si un bloque se suelta lejos o junto a otra silueta, vuelve flotando
##     a la bandeja y SU silueta correcta brilla como pista (nunca reproche).
##   - Sin tiempo ni puntos. Nubi, la exploradora de sombras, acompaña.
## ============================================================================
extends Node2D

## Diseños del tablero: posición de cada silueta según su forma.
const DISENOS := [
	{"cuadrado": Vector2(1700, 740), "triangulo": Vector2(1700, 498), "circulo": Vector2(2040, 290)},  # casita con sol
	{"cuadrado": Vector2(1770, 760), "circulo": Vector2(1770, 520), "triangulo": Vector2(1770, 300)},  # robot con gorro
	{"circulo": Vector2(1530, 720), "cuadrado": Vector2(1790, 720), "triangulo": Vector2(2040, 690)},  # tren de formas
]
const NOTAS_ENCAJE := [3, 4, 5]  # Sol, La, Do agudo (Sol es la nota de Kubo)
const COLORES_FIESTA := [Color("ff3b5c"), Color("ffd23f"), Color("3fc4ff"), Color("ffffff")]
const CENTRO_TABLERO := Vector2(1770, 520)

@export var segundos_celebracion: float = 3.4

@onready var kubo: PersonajePrincipal = $Kubo
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var gestor: GestorArrastre = $GestorArrastre
@onready var tablero: Node2D = $Tablero

var _diseno: int = 0
var _encajadas: int = 0
var _celebrando: bool = false


func _ready() -> void:
	var piezas: Array[PiezaArrastrable] = []
	for nodo in $Bloques.get_children():
		if nodo is PiezaArrastrable:
			piezas.append(nodo)
	var zonas: Array[ZonaIman] = []
	for nodo in tablero.get_children():
		if nodo is ZonaIman:
			zonas.append(nodo)
	gestor.registrar(piezas, zonas)

	gestor.pieza_levantada.connect(_al_levantar)
	gestor.pieza_encajada.connect(_al_encajar)
	gestor.pieza_regreso.connect(_al_regresar)
	gestor.pieza_encajada_tocada.connect(_al_tocar_encajada)
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(kubo.cancelar_llamada)

	_aplicar_diseno(0, false)
	kubo.saludar_entrada()


func _aplicar_diseno(indice: int, animado: bool) -> void:
	var diseno: Dictionary = DISENOS[indice]
	for zona in gestor.zonas:
		zona.position = diseno[String(zona.forma)]
	if animado:
		tablero.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(tablero, "modulate:a", 1.0, 0.6)


# ---------- Reacciones ----------

func _al_levantar(_pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(0, -12.0)


func _al_encajar(pieza: PiezaArrastrable, zona: ZonaIman) -> void:
	_encajadas += 1
	retro.tocar_nota(NOTAS_ENCAJE[mini(_encajadas - 1, NOTAS_ENCAJE.size() - 1)])
	retro.lanzar_particulas(_en_pantalla(zona), pieza.color, Color.WHITE, 14)
	kubo.reaccionar_toque()
	if gestor.todas_encajadas():
		_celebrar()


## Vuelve a la bandeja: nota suave y su silueta brilla para ayudar.
func _al_regresar(pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(0, -16.0)
	for zona in gestor.zonas_para(pieza):
		zona.resaltar()


func _al_tocar_encajada(pieza: PiezaArrastrable) -> void:
	pieza.impulso_giro()  # los bloques no giran: dan un saltito
	retro.tocar_nota(randi() % 6, -8.0)
	retro.lanzar_particulas(_en_pantalla(pieza), pieza.color, Color.WHITE, 6)


# ---------- Dibujo completado ----------

func _celebrar() -> void:
	_celebrando = true
	gestor.bloqueado = true
	kubo.llamar_atencion(3)
	for pieza in gestor.piezas:
		pieza.impulso_giro()
	retro.fiesta(CENTRO_TABLERO, COLORES_FIESTA, [3, 4, 5, 4, 3, 5], 0.36, 300.0)
	var espera := create_tween()
	espera.tween_interval(segundos_celebracion)
	espera.tween_callback(_terminar_celebracion)


func _terminar_celebracion() -> void:
	kubo.cancelar_llamada()
	gestor.liberar_todo()
	_encajadas = 0
	_diseno = (_diseno + 1) % DISENOS.size()
	_aplicar_diseno(_diseno, true)
	gestor.bloqueado = false
	_celebrando = false


# ---------- Inactividad ----------

func _al_pedir_atencion(nivel: int) -> void:
	if _celebrando:
		return
	kubo.llamar_atencion(nivel)
	if nivel >= 2:
		gestor.pista()


func _en_pantalla(nodo: Node2D) -> Vector2:
	return nodo.get_global_transform_with_canvas().origin
