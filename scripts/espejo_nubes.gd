## ============================================================================
## EspejoNubes — Nubi · "El Espejo de las Nubes" (Godot 4.x)
## ----------------------------------------------------------------------------
## En el espejo mágico aparecen tres siluetas (corazón, estrella, luna, gota,
## flor...). Abajo flotan nubes con esas formas: hay que deslizarlas hasta
## su sombra en el espejo.
##   - El imán solo atrae la nube con la MISMA forma: nunca encaja mal.
##   - Al encajar: lluvia de destellos dorados, nota y Nubi rebota.
##   - Las tres colocadas: fiesta rítmica y el espejo cambia de formas.
## Cero frustración: una nube soltada lejos vuelve flotando y su silueta
## brilla como pista. Sin tiempo ni puntos.
## ============================================================================
extends Node2D

const FORMAS := ["corazon", "estrella", "luna", "gota", "flor"]
const COLORES := {
	"corazon": Color("ffb3d1"), "estrella": Color("fff1a8"), "luna": Color("c9b8ff"),
	"gota": Color("a8e8ff"), "flor": Color("b8ffd0"),
}
const NOTAS_ENCAJE := [2, 3, 4]   # Mi, Sol, La (La es la nota de Nubi)
const DORADO := Color("ffd27a")
const CENTRO_ESPEJO := Vector2(1650, 430)

## Texturas de nube, en el mismo orden que FORMAS.
@export var texturas: Array[Texture2D] = []
@export var segundos_celebracion: float = 3.2

@onready var nubi: PersonajePrincipal = $Nubi
@onready var retro: Retroalimentacion = $Retroalimentacion
@onready var vigilante: VigilanteInactividad = $VigilanteInactividad
@onready var gestor: GestorArrastre = $GestorArrastre
@onready var espejo: Node2D = $Espejo

var _encajadas: int = 0
var _celebrando: bool = false


func _ready() -> void:
	var piezas: Array[PiezaArrastrable] = []
	for nodo in $Nubes.get_children():
		if nodo is PiezaArrastrable:
			piezas.append(nodo)
	var zonas: Array[ZonaIman] = []
	for nodo in espejo.get_children():
		if nodo is ZonaIman:
			zonas.append(nodo)
	gestor.registrar(piezas, zonas)

	gestor.pieza_levantada.connect(_al_levantar)
	gestor.pieza_encajada.connect(_al_encajar)
	gestor.pieza_regreso.connect(_al_regresar)
	gestor.pieza_encajada_tocada.connect(_al_tocar_encajada)
	vigilante.llamar_atencion.connect(_al_pedir_atencion)
	vigilante.nino_volvio.connect(nubi.cancelar_llamada)

	_nueva_ronda(false)
	nubi.saludar_entrada()


func _textura(forma: String) -> Texture2D:
	var i: int = FORMAS.find(forma)
	return texturas[i] if i >= 0 and i < texturas.size() else null


## Elige 3 formas al azar; las siluetas del espejo salen en otro orden.
func _nueva_ronda(animado: bool) -> void:
	var formas: Array = FORMAS.duplicate()
	formas.shuffle()
	var elegidas: Array = formas.slice(0, 3)
	var siluetas: Array = elegidas.duplicate()
	siluetas.shuffle()
	for i in mini(3, gestor.piezas.size()):
		var nube := gestor.piezas[i]
		var forma: String = elegidas[i]
		nube.forma = StringName(forma)
		nube.color = COLORES[forma]
		if nube.visual:
			var sprite := nube.visual as Sprite2D
			sprite.texture = _textura(forma)
			sprite.modulate = nube.color
	for i in mini(3, gestor.zonas.size()):
		var z := gestor.zonas[i]
		var forma: String = siluetas[i]
		z.forma = StringName(forma)
		var silueta := z.get_node_or_null("Silueta") as Sprite2D
		if silueta:
			silueta.texture = _textura(forma)
	if animado:
		espejo.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(espejo, "modulate:a", 1.0, 0.6)


# ---------- Reacciones ----------

func _al_levantar(_pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(4, -12.0)


func _al_encajar(pieza: PiezaArrastrable, zona: ZonaIman) -> void:
	_encajadas += 1
	retro.tocar_nota(NOTAS_ENCAJE[mini(_encajadas - 1, NOTAS_ENCAJE.size() - 1)])
	retro.lanzar_particulas(_en_pantalla(zona), DORADO, pieza.color, 16)  # lluvia dorada
	nubi.reaccionar_toque()
	if gestor.todas_encajadas():
		_celebrar()


func _al_regresar(pieza: PiezaArrastrable) -> void:
	retro.tocar_nota(4, -16.0)
	for z in gestor.zonas_para(pieza):
		z.resaltar()


func _al_tocar_encajada(pieza: PiezaArrastrable) -> void:
	pieza.impulso_giro()
	retro.tocar_nota(randi() % 6, -8.0)
	retro.lanzar_particulas(_en_pantalla(pieza), DORADO, Color.WHITE, 6)


# ---------- Espejo completo ----------

func _celebrar() -> void:
	_celebrando = true
	gestor.bloqueado = true
	nubi.llamar_atencion(3)
	for pieza in gestor.piezas:
		pieza.impulso_giro()
	var colores: Array = [DORADO]
	for pieza in gestor.piezas:
		colores.append(pieza.color)
	retro.fiesta(CENTRO_ESPEJO, colores, [4, 5, 4, 2, 3, 4], 0.36, 380.0)
	var espera := create_tween()
	espera.tween_interval(segundos_celebracion)
	espera.tween_callback(_terminar_celebracion)


func _terminar_celebracion() -> void:
	nubi.cancelar_llamada()
	gestor.liberar_todo()
	_encajadas = 0
	_nueva_ronda(true)
	gestor.bloqueado = false
	_celebrando = false


func _al_pedir_atencion(nivel: int) -> void:
	if _celebrando:
		return
	nubi.llamar_atencion(nivel)
	if nivel >= 2:
		gestor.pista()


func _en_pantalla(nodo: Node2D) -> Vector2:
	return nodo.get_global_transform_with_canvas().origin
