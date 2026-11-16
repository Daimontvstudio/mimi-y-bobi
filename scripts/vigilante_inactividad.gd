## ============================================================================
## VigilanteInactividad — Sistema anti-frustración (Godot 4.x)
## ----------------------------------------------------------------------------
## Si nadie toca la pantalla durante `segundos_espera` (4 s), emite
## `llamar_atencion(nivel)` para que la personaje principal invite a jugar.
##
##   Nivel 1 = sutil (respira) · Nivel 2 = juguetón (saltito)
##   Nivel 3 = invitación clara (saluda) → tope: se repite cada 4 s, nunca sube más.
##
## Nunca castiga, nunca muestra textos ni sonidos fuertes.
## Cualquier toque o arrastre reinicia la cuenta a cero.
## ============================================================================
class_name VigilanteInactividad
extends Node

## Pide una llamada de atención suave.
signal llamar_atencion(nivel: int)
## El niño volvió a tocar DESPUÉS de una llamada de atención (para cancelarla).
signal nino_volvio

@export var segundos_espera: float = 4.0
@export_range(1, 5) var nivel_maximo: int = 3

var nivel_actual: int = 0
var _reloj: Timer


func _ready() -> void:
	_reloj = Timer.new()
	_reloj.wait_time = segundos_espera
	_reloj.one_shot = false  # vuelve a sonar cada 4 s mientras no haya toques
	_reloj.timeout.connect(_al_cumplirse_espera)
	add_child(_reloj)
	_reloj.start()


func _input(event: InputEvent) -> void:
	# _input ve TODOS los toques, aunque otro nodo los procese.
	if (event is InputEventScreenTouch and event.pressed) or event is InputEventScreenDrag:
		registrar_actividad()


## Llamar también desde código si hay otra forma de interacción (p. ej. inclinar el móvil).
func registrar_actividad() -> void:
	if nivel_actual > 0:
		nino_volvio.emit()
	nivel_actual = 0
	_reloj.start()  # reinicia la cuenta desde cero


## Útil para escenas de transición o vídeos cortos.
func pausar(pausado: bool) -> void:
	_reloj.paused = pausado
	if not pausado:
		nivel_actual = 0
		_reloj.start()


func _al_cumplirse_espera() -> void:
	nivel_actual = mini(nivel_actual + 1, nivel_maximo)
	llamar_atencion.emit(nivel_actual)


# Si la app pasa a segundo plano, el reloj se congela.
func _notification(what: int) -> void:
	if _reloj == null:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_reloj.paused = true
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			pausar(false)
