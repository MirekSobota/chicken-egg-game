extends Area2D
# Skrypt przypięty do jajka
# Area2D = obiekt z kolizją, który reaguje na gracza


signal collected
# Własny sygnał
# Będzie wysyłany w momencie zebrania jajka


@export var fall_speed: float = 120.0
# Prędkość spadania jajka (piksele na sekundę)


@export var max_y: float = 900.0
# Y poniżej którego jajko zostanie usunięte
# (żeby nie leciało w nieskończoność poza ekranem)


@export var start_delay: float = 0.4
# Opóźnienie po spawnie
# Dzięki temu jajko nie zaczyna spadać natychmiast

@export var side_speed_range := Vector2(-60.0, 60.0)

var _side_speed: float = 0.0


var _collected := false
# Flaga zabezpieczająca
# Dzięki niej jajko może zostać zebrane tylko RAZ


var _delay_left := 0.0
# Ile czasu zostało do rozpoczęcia spadania


func _ready() -> void:
	# Ta funkcja uruchamia się, gdy jajko pojawi się na scenie
	# Ustawiamy licznik opóźnienia
	_delay_left = start_delay
	_side_speed = randf_range(side_speed_range.x, side_speed_range.y)



func _on_body_entered(body: Node2D) -> void:
	# Wywoływane, gdy coś wejdzie w obszar kolizji jajka

	# Jeśli jajko już zostało zebrane – nic nie rób
	if _collected:
		return

	# Sprawdzamy, czy to gracz
	# (gracz MUSI być w grupie "player")
	if body.is_in_group("player"):
		_collected = true
		# Wyłączamy kolizję w bezpieczny sposób
		# (Godot 4 nie lubi zmian w trakcie fizyki)
		set_deferred("monitoring", false)

		# Zbieranie robimy "odroczone"
		call_deferred("_collect_deferred")


func _process(delta: float) -> void:
	# _process wywołuje się CO KLATKĘ

	# Jeśli trwa jeszcze opóźnienie po spawnie
	if _delay_left > 0.0:
		_delay_left -= delta
		return

	# Po opóźnieniu jajko zaczyna spadać w dół
	global_position += Vector2(_side_speed, fall_speed) * delta


	# Jeśli jajko spadnie za nisko – usuń je
	if global_position.y > max_y:
		queue_free()


func _collect_deferred() -> void:
	# Wysyłamy sygnał do Main (że jajko zebrane)
	emit_signal("collected")

	# Usuwamy jajko ze sceny
	queue_free()
