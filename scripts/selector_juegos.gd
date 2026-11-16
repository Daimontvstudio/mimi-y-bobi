## ============================================================================
## SelectorJuegos — Los minijuegos del personaje elegido (Godot 4.x)
## ----------------------------------------------------------------------------
## Se construye solo a partir de Catalogo: un panel GIGANTE por juego (mitad de
## pantalla cada uno), con un icono grande. El personaje saluda arriba y
## canta su nota si lo tocas. Casita (mantener 1,2 s) → menú de personajes.
## ============================================================================
extends Node2D

const ALTO_ZONAS := 0.74   # la franja de arriba es del personaje

@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var capa_toque: CanvasLayer = $CapaToque

var _datos: Dictionary = {}
var _personaje: PersonajePrincipal
var _paneles: Node2D
var _iconos: Array[Sprite2D] = []
var _eligiendo: bool = false
var _turno: int = 0


func _ready() -> void:
	_datos = Catalogo.datos_elegido()
	if _datos.is_empty():
		Transicion.ir_a.call_deferred(Catalogo.MENU)
		return
	var juegos: Array = _datos["juegos"]
	var vista: Vector2 = get_viewport().get_visible_rect().size

	# Paneles de colores (se dibujan con la señal draw).
	_paneles = Node2D.new()
	_paneles.draw.connect(_dibujar_paneles)
	add_child(_paneles)
	move_child(_paneles, 1)  # justo encima del fondo

	for i in juegos.size():
		var juego: Dictionary = juegos[i]
		var zona := ZonaToqueGigante.new()
		zona.columna = i
		zona.total_columnas = juegos.size()
		zona.alto_fraccion = ALTO_ZONAS
		zona.notas = PackedInt32Array([mini(_datos["nota"] + i * 2, 5)])
		zona.color_principal = _datos["color"]
		zona.color_acento = _datos["acento"]
		zona.mostrar_debug = false
		capa_toque.add_child(zona)
		zona.tocada.connect(_al_elegir)

		var icono := Sprite2D.new()
		icono.texture = load(juego["icono"])
		icono.position = Vector2(vista.x * (i + 0.5) / juegos.size(), vista.y * (1.0 - ALTO_ZONAS * 0.5))
		icono.scale = Vector2.ONE * 1.5
		add_child(icono)
		_iconos.append(icono)
		_respirar_icono(icono, i * 0.4)

	_personaje = _crear_personaje(vista)
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(_personaje.cancelar_llamada)
	_personaje.saludar_entrada()


func _crear_personaje(vista: Vector2) -> PersonajePrincipal:
	var p := PersonajePrincipal.new()
	p.name = _datos["id"]
	p.nota_propia = _datos["nota"]
	p.color_a = _datos["color"]
	p.color_b = _datos["acento"]
	p.position = Vector2(vista.x * 0.5, vista.y * (1.0 - ALTO_ZONAS) - 12.0)
	p.scale = Vector2.ONE * 0.52
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load(_datos["textura"])
	sprite.position = Vector2(0, -242)
	p.add_child(sprite)
	p.add_to_group("personajes")
	add_child(p)
	return p


func _dibujar_paneles() -> void:
	var vista: Vector2 = get_viewport().get_visible_rect().size
	var n: int = _iconos.size()
	var c: Color = _datos["color"]
	for i in n:
		var ancho: float = vista.x / n
		var rect := Rect2(ancho * i + 30.0, vista.y * (1.0 - ALTO_ZONAS) + 20.0,
				ancho - 60.0, vista.y * ALTO_ZONAS - 50.0)
		_paneles.draw_rect(rect, Color(c, 0.16))
		_paneles.draw_rect(rect, Color(c, 0.85), false, 10.0)


func _respirar_icono(icono: Sprite2D, retraso: float) -> void:
	var t := icono.create_tween().set_loops()
	t.tween_interval(retraso)
	t.tween_property(icono, "scale", Vector2.ONE * 1.6, 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(icono, "scale", Vector2.ONE * 1.5, 0.9).set_trans(Tween.TRANS_SINE)


func _al_elegir(zona: ZonaToqueGigante, posicion_pantalla: Vector2) -> void:
	if _eligiendo or Transicion.ocupado:
		return
	_eligiendo = true
	var juego: Dictionary = _datos["juegos"][zona.columna]
	retro.arpegio([zona.notas[0], mini(zona.notas[0] + 2, 5), 5], 0.13)
	retro.lanzar_particulas(posicion_pantalla, zona.color_principal, zona.color_acento, 18)
	retro.lanzar_particulas(_iconos[zona.columna].get_global_transform_with_canvas().origin,
			zona.color_principal, Color.WHITE, 24)
	_personaje.reaccionar_toque()
	var espera := create_tween()
	espera.tween_interval(0.7)
	espera.tween_callback(Transicion.ir_a.bind(juego["escena"]))


func _al_pedir_atencion(nivel: int) -> void:
	if _eligiendo:
		return
	_personaje.llamar_atencion(nivel)
	if nivel >= 2 and not _iconos.is_empty():
		var icono := _iconos[_turno % _iconos.size()]
		_turno += 1
		retro.lanzar_particulas(icono.get_global_transform_with_canvas().origin,
				_datos["color"], _datos["acento"], 8)
