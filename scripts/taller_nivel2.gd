## ============================================================================
## TallerNivel2 — "El Taller de Bobi" · minijuego de causa-efecto (Godot 4.x)
## ----------------------------------------------------------------------------
## El niño arrastra engranajes de la bandeja a la máquina.
##   Causa → efecto:
##   - Cada engranaje encajado: gira, la bombilla se enciende de su color,
##     suena una nota más aguda y Bobi rebota.
##   - Tocar un engranaje encajado: gira rapidísimo con un destello.
##   - Los 3 encajados: ¡la máquina celebra! (arpegio, bombilla arcoíris,
##     estrellas y corazones por la chimenea). Luego las piezas vuelven solas
##     a la bandeja para jugar otra vez. No hay final ni puntuación.
##
## Árbol de escena:
##   TallerNivel2 (Node2D)               ← este script
##   ├─ Fondo (Sprite2D)
##   ├─ Maquina (Sprite2D)
##   │   ├─ Bombilla (Sprite2D)
##   │   ├─ Chimenea (Marker2D)
##   │   └─ Enchufes (Node2D) → Enchufe1..3 (ZonaIman)
##   ├─ Bobi (PersonajePrincipal)
##   ├─ Piezas (Node2D) → Engranaje1..3 (PiezaArrastrable + Visual)
##   ├─ Retroalimentacion · VigilanteInactividad · GestorArrastre
##   └─ CapaUI (CanvasLayer) → BotonCasa
## ============================================================================
extends Node2D

const NOTAS_ENCAJE := [1, 3, 5]          # Re, Sol, Do agudo: sube con cada pieza
const ARPEGIO_FIESTA := [0, 1, 2, 3, 4, 5, 4, 5]
const COLOR_BOMBILLA_APAGADA := Color(0.5, 0.5, 0.62)
const ARCOIRIS := [Color("ff4fb8"), Color("ffd23f"), Color("9dff3a"), Color("3fc4ff"), Color("b45cff")]

@export var segundos_celebracion: float = 3.5

@onready var bobi: PersonajePrincipal = $Bobi
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var gestor: GestorArrastre = $GestorArrastre
@onready var bombilla: Sprite2D = $Maquina/Bombilla
@onready var chimenea: Marker2D = $Maquina/Chimenea

var _encajadas: int = 0
var _celebrando: bool = false
var _tween_bombilla: Tween


func _ready() -> void:
	var piezas: Array[PiezaArrastrable] = []
	for nodo in $Piezas.get_children():
		if nodo is PiezaArrastrable:
			piezas.append(nodo)
	var zonas: Array[ZonaIman] = []
	for nodo in $Maquina/Enchufes.get_children():
		if nodo is ZonaIman:
			zonas.append(nodo)
	gestor.registrar(piezas, zonas)

	gestor.pieza_levantada.connect(_al_levantar)
	gestor.pieza_encajada.connect(_al_encajar)
	gestor.pieza_regreso.connect(_al_regresar)
	gestor.pieza_encajada_tocada.connect(_al_tocar_encajada)
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(bobi.cancelar_llamada)

	bombilla.modulate = COLOR_BOMBILLA_APAGADA


# ---------- Reacciones (causa → efecto) ----------

func _al_levantar(_pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(0, -12.0)  # "pop" suave al agarrar


func _al_encajar(pieza: PiezaArrastrable, zona: ZonaIman) -> void:
	_encajadas += 1
	retro.tocar_nota(NOTAS_ENCAJE[mini(_encajadas - 1, NOTAS_ENCAJE.size() - 1)])
	retro.lanzar_particulas(_en_pantalla(zona), pieza.color, Color.WHITE, 16)
	bobi.reaccionar_toque()
	_encender_bombilla(pieza.color)
	if gestor.todas_encajadas():
		_celebrar()


func _al_regresar(_pieza: PiezaArrastrable) -> void:
	# Sin sonido de "error": solo una nota grave y bajita, como un "boing".
	retro.tocar_nota(0, -16.0)


func _al_tocar_encajada(pieza: PiezaArrastrable) -> void:
	pieza.impulso_giro()
	retro.tocar_nota(randi() % 6, -8.0)
	retro.lanzar_particulas(_en_pantalla(pieza), pieza.color, Color.WHITE, 6)


func _encender_bombilla(c: Color) -> void:
	if _tween_bombilla and _tween_bombilla.is_valid():
		_tween_bombilla.kill()
	bombilla.modulate = c
	bombilla.scale = Vector2.ONE * 1.3
	_tween_bombilla = create_tween()
	_tween_bombilla.tween_property(bombilla, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# ---------- Gran final (y vuelta a empezar) ----------

func _celebrar() -> void:
	_celebrando = true
	gestor.bloqueado = true
	retro.arpegio(ARPEGIO_FIESTA, 0.14)
	for pieza in gestor.piezas:
		pieza.impulso_giro(25.0)
	bobi.llamar_atencion(3)  # saltitos de alegría

	# Bombilla arcoíris + 4 explosiones por la chimenea.
	if _tween_bombilla and _tween_bombilla.is_valid():
		_tween_bombilla.kill()
	_tween_bombilla = create_tween()
	for i in 10:
		_tween_bombilla.tween_property(bombilla, "modulate", ARCOIRIS[i % ARCOIRIS.size()], 0.25)
	var fiesta := create_tween()
	for i in 4:
		fiesta.tween_callback(_soplido_chimenea)
		fiesta.tween_interval(0.5)

	# Tween ligado a este nodo: si se sale al menú a mitad, se cancela solo.
	var espera := create_tween()
	espera.tween_interval(segundos_celebracion)
	espera.tween_callback(_terminar_celebracion)


func _soplido_chimenea() -> void:
	retro.lanzar_particulas(_en_pantalla(chimenea), ARCOIRIS[randi() % ARCOIRIS.size()],
			Color("ffd23f"), 20)


func _terminar_celebracion() -> void:
	bobi.cancelar_llamada()
	gestor.liberar_todo()
	_encajadas = 0
	bombilla.modulate = COLOR_BOMBILLA_APAGADA
	gestor.bloqueado = false
	_celebrando = false


# ---------- Inactividad: Bobi invita y una pieza da una pista ----------

func _al_pedir_atencion(nivel: int) -> void:
	if _celebrando:
		return
	bobi.llamar_atencion(nivel)
	if nivel >= 2:
		gestor.pista()


func _en_pantalla(nodo: Node2D) -> Vector2:
	return nodo.get_global_transform_with_canvas().origin
