## ============================================================================
## CaminoLuciernagas — Lumen · "El Camino de Luciérnagas" (Godot 4.x)
## ----------------------------------------------------------------------------
## Memoria suave ("¿dónde se escondió?"):
##   1. Lumen manda luciérnagas a esconderse en frascos (1, 2 o 3 por ronda).
##   2. El niño toca los frascos para encontrarlas: salen brillando y se
##      posan en el camino de piedras de arriba.
##   3. Con todas encontradas, el camino canta una melodía y hay fiesta.
##
## Cero frustración:
##   - Tocar un frasco vacío solo hace un brillito suave y una nota bajita.
##   - Tras 2 frascos vacíos, los frascos con luciérnaga laten (pista).
##   - Sin tiempo: si el niño se distrae, los frascos correctos laten solos.
## Zonas de toque: 3 columnas gigantes (los frascos son OrbeLuz reutilizados).
## ============================================================================
extends Node2D

enum Estado { DEMO, TURNO, FIESTA }

const NOTAS_FRASCOS := [0, 2, 4]
const CAMINO_INICIO := Vector2(800, 200)
const CAMINO_FIN := Vector2(1860, 200)
const COLOR_LUZ := Color("ffe066")

@export var textura_luciernaga: Texture2D
@export var textura_halo: Texture2D

@onready var lumen: PersonajePrincipal = $Lumen
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque
@onready var contenedor: Node2D = $Luciernagas

var frascos: Array[OrbeLuz] = []
var _escondidas := {}                 # índice de frasco → luciérnaga
var _encontradas: Array[Node2D] = []
var _ronda: int = 0
var _vacios: int = 0
var _estado: Estado = Estado.DEMO
var _material_luz := CanvasItemMaterial.new()


func _ready() -> void:
	_material_luz.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for nodo in $Frascos.get_children():
		if nodo is OrbeLuz:
			frascos.append(nodo)
	for i in frascos.size():
		var zona := ZonaToqueGigante.new()
		zona.columna = i
		zona.total_columnas = frascos.size()
		zona.alto_fraccion = 0.62
		zona.color_principal = frascos[i].color
		zona.mostrar_debug = false
		capa_toque.add_child(zona)
		zona.tocada.connect(_al_tocar_zona)
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(lumen.cancelar_llamada)
	lumen.saludar_entrada()
	var inicio := create_tween()
	inicio.tween_interval(1.3)
	inicio.tween_callback(_nueva_ronda)


func _crear_luciernaga() -> Node2D:
	var l := Node2D.new()
	var halo := Sprite2D.new()
	halo.texture = textura_halo
	halo.material = _material_luz
	halo.modulate = Color(COLOR_LUZ, 0.9)
	halo.scale = Vector2.ONE * 0.38
	var cuerpo := Sprite2D.new()
	cuerpo.texture = textura_luciernaga
	l.add_child(halo)
	l.add_child(cuerpo)
	contenedor.add_child(l)
	return l


# ---------- Esconderse ----------

func _nueva_ronda() -> void:
	_estado = Estado.DEMO
	_vacios = 0
	var cantidad: int = 1 + _ronda % 3        # 1, 2, 3, 1, 2, 3...
	_ronda += 1
	var opciones := [0, 1, 2]
	opciones.shuffle()
	var t := create_tween()
	t.tween_interval(0.5)
	for i in cantidad:
		t.tween_callback(_esconder.bind(opciones[i]))
		t.tween_interval(1.5)
	t.tween_callback(_empezar_turno)


func _esconder(indice: int) -> void:
	var l := _crear_luciernaga()
	l.global_position = lumen.centro_en_pantalla()
	var destino: Vector2 = frascos[indice].global_position + Vector2(0, -30)
	var medio: Vector2 = (l.global_position + destino) * 0.5 + Vector2(0, -220)
	retro.tocar_nota(mini(NOTAS_FRASCOS[indice] + 1, 5), -10.0)
	var t := l.create_tween()
	t.tween_property(l, "global_position", medio, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "global_position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(frascos[indice].encender.bind(0.5))
	t.tween_callback(retro.tocar_nota.bind(NOTAS_FRASCOS[indice], -6.0))
	t.tween_property(l, "modulate:a", 0.0, 0.5)  # se apaga dentro del frasco
	_escondidas[indice] = l


func _empezar_turno() -> void:
	_estado = Estado.TURNO
	vigilante.registrar_actividad()


# ---------- Buscar ----------

func _al_tocar_zona(zona: ZonaToqueGigante, _posicion_pantalla: Vector2) -> void:
	var i: int = zona.columna
	_bambolear(frascos[i])
	if _estado != Estado.TURNO:
		retro.tocar_nota(NOTAS_FRASCOS[i], -12.0)
		return
	if _escondidas.has(i):
		_liberar(i)
	else:
		retro.tocar_nota(NOTAS_FRASCOS[i], -12.0)
		retro.lanzar_particulas(_en_pantalla(frascos[i]), frascos[i].color, Color.WHITE, 5)
		_vacios += 1
		if _vacios >= 2:
			_vacios = 0
			_pista()


func _liberar(i: int) -> void:
	var l: Node2D = _escondidas[i]
	_escondidas.erase(i)
	frascos[i].encender(0.6)
	var n: int = _encontradas.size()
	var destino: Vector2 = CAMINO_INICIO.lerp(CAMINO_FIN, n / 2.0) + Vector2(0, -50.0 * sin(n * PI / 2.0))
	retro.tocar_nota(mini(NOTAS_FRASCOS[i] + 1, 5))
	retro.lanzar_particulas(_en_pantalla(frascos[i]), COLOR_LUZ, frascos[i].color, 14)
	lumen.reaccionar_toque()
	l.modulate.a = 1.0
	var t := l.create_tween()
	t.tween_property(l, "global_position", destino, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_flotar.bind(l))
	_encontradas.append(l)
	if _escondidas.is_empty():
		_estado = Estado.FIESTA
		var espera := create_tween()
		espera.tween_interval(1.1)
		espera.tween_callback(_camino_completo)


func _flotar(l: Node2D) -> void:
	var base: Vector2 = l.position
	var t := l.create_tween().set_loops()
	t.tween_property(l, "position", base + Vector2(0, -14), 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(l, "position", base, 0.8).set_trans(Tween.TRANS_SINE)
	l.set_meta("flote", t)


func _bambolear(frasco: Node2D) -> void:
	var t := frasco.create_tween()
	t.tween_property(frasco, "rotation", 0.08, 0.08)
	t.tween_property(frasco, "rotation", -0.08, 0.12)
	t.tween_property(frasco, "rotation", 0.0, 0.08)


func _pista() -> void:
	for indice in _escondidas.keys():
		frascos[indice].invitar()


# ---------- Camino completo ----------

func _camino_completo() -> void:
	lumen.llamar_atencion(3)
	var t := create_tween()
	for k in _encontradas.size():
		t.tween_callback(_destello_camino.bind(k))
		t.tween_interval(0.36)
	t.tween_callback(retro.fiesta.bind(Vector2(1330, 300),
			[COLOR_LUZ, Color("b45cff"), Color("ff9a1f")], [0, 2, 4, 5], 0.36, 420.0))
	t.tween_interval(2.0)
	t.tween_callback(_despedir)


func _destello_camino(k: int) -> void:
	var l: Node2D = _encontradas[k]
	retro.tocar_nota(mini(2 + k, 5))
	retro.lanzar_particulas(_en_pantalla(l), COLOR_LUZ, Color.WHITE, 8)
	l.scale = Vector2.ONE * 1.5
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _despedir() -> void:
	for l in _encontradas:
		if l.has_meta("flote"):
			var flote: Tween = l.get_meta("flote")
			if flote.is_valid():
				flote.kill()
		var t := l.create_tween().set_parallel(true)
		t.tween_property(l, "position", l.position + Vector2(randf_range(-200, 200), -400), 1.2)
		t.tween_property(l, "modulate:a", 0.0, 1.2)
		t.chain().tween_callback(l.queue_free)
	_encontradas.clear()
	lumen.cancelar_llamada()
	_nueva_ronda()


func _al_pedir_atencion(nivel: int) -> void:
	if _estado == Estado.FIESTA:
		return
	lumen.llamar_atencion(nivel)
	if _estado == Estado.TURNO and nivel >= 2:
		_pista()


func _en_pantalla(nodo: Node2D) -> Vector2:
	return nodo.get_global_transform_with_canvas().origin
