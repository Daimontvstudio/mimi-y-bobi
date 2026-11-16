## ============================================================================
## Catalogo — Autoload con los personajes y sus minijuegos (Godot 4.x)
## ----------------------------------------------------------------------------
## Para añadir un minijuego basta con añadir una entrada en "juegos".
## El menú y la pantalla de selección se construyen a partir de aquí.
## ============================================================================
extends Node

const MENU := "res://escenas/menu_principal.tscn"
const SELECTOR := "res://escenas/selector_juegos.tscn"

const PERSONAJES := [
	{"id": "Mimi", "textura": "res://arte/mimi.png", "nota": 0,
		"color": Color("ff4fb8"), "acento": Color("ffd23f"), "juegos": [
			{"escena": "res://escenas/jardin_nivel1.tscn", "icono": "res://arte/iconos/jardin.png"},
			{"escena": "res://escenas/concierto_estrellas.tscn", "icono": "res://arte/iconos/concierto.png"},
		]},
	{"id": "Bobi", "textura": "res://arte/bobi.png", "nota": 1,
		"color": Color("3fc4ff"), "acento": Color("9dff3a"), "juegos": [
			{"escena": "res://escenas/taller_nivel2.tscn", "icono": "res://arte/iconos/taller.png"},
			{"escena": "res://escenas/laboratorio_burbujas.tscn", "icono": "res://arte/iconos/burbujas.png"},
		]},
	{"id": "Lumen", "textura": "res://arte/lumen.png", "nota": 2,
		"color": Color("b45cff"), "acento": Color("ff9a1f"), "juegos": [
			{"escena": "res://escenas/lumen_nivel3.tscn", "icono": "res://arte/iconos/lumen.png"},
			{"escena": "res://escenas/camino_luciernagas.tscn", "icono": "res://arte/iconos/luciernagas.png"},
		]},
	{"id": "Kubo", "textura": "res://arte/kubo.png", "nota": 3,
		"color": Color("ff3b5c"), "acento": Color("f6f1fb"), "juegos": [
			{"escena": "res://escenas/kubo_nivel4.tscn", "icono": "res://arte/iconos/kubo.png"},
			{"escena": "res://escenas/torre_magica.tscn", "icono": "res://arte/iconos/torre.png"},
		]},
	{"id": "Nubi", "textura": "res://arte/nubi.png", "nota": 4,
		"color": Color("aee8ff"), "acento": Color("ffd27a"), "juegos": [
			{"escena": "res://escenas/espejo_nubes.tscn", "icono": "res://arte/iconos/espejo.png"},
		]},
]

## Personaje elegido en el menú (-1 = ninguno).
var personaje_elegido: int = -1


func datos_elegido() -> Dictionary:
	if personaje_elegido < 0 or personaje_elegido >= PERSONAJES.size():
		return {}
	return PERSONAJES[personaje_elegido]
