extends Area2D
# Skrypt przypięty do jajka
# Area2D = obiekt z kolizją, który reaguje na gracza

signal collected
# Własny sygnał – wysyłamy go, gdy gracz zbierze jajko

@export var fall_speed: float = 120.0
# Prędkość spadania jajka (piksele na sekundę)

@export var start_delay: float = 0.4
# Opóźnienie po spawnie (żeby jajko nie leciało od razu)

@export var side_speed_range := Vector2(-60.0, 60.0)
# Losowy „dryf” w bok: od -60 do +60 px/s

@export var despawn_margin: float = 200.0
# O ile jajko może zejść poniżej dołu ekranu zanim je usuniemy

var _side_speed: float = 0.0
# Wylosowana prędkość w bok

var _collected := false
# Flaga – zabezpiecza przed zebraniem 2 razy

var _delay_left := 0.0
# Ile czasu zostało do startu spadania

func _ready() -> void:
	# Startowy setup po pojawieniu się jajka
	_delay_left = start_delay
	# Losujemy prędkość w bok
	_side_speed = randf_range(side_speed_range.x, side_speed_range.y)

func _on_body_entered(body: Node2D) -> void:
	# Wywołuje się, gdy coś wejdzie w kolizję jajka

	# Jeśli już zebrane – nic nie rób
	if _collected:
		return

	# Jeśli to gracz (musi być w grupie "player")
	if body.is_in_group("player"):
		_collected = true
		# Wyłączamy monitoring bezpiecznie (w trakcie fizyki)
		set_deferred("monitoring", false)
		# Zbieranie robimy odroczone
		call_deferred("_collect_deferred")

func _process(delta: float) -> void:
	# Wywołuje się co klatkę

	# Jeśli trwa jeszcze opóźnienie – odliczamy i kończymy klatkę
	if _delay_left > 0.0:
		_delay_left -= delta
		return

	# Ruch: w dół + lekko w bok
	global_position += Vector2(_side_speed, fall_speed) * delta

	# Despawn: jeśli jesteśmy sporo poniżej dołu ekranu (wg aktywnej kamery)
	var cam := get_viewport().get_camera_2d()
	# Jeśli nie ma kamery (awaryjnie) – nie kasujemy tutaj
	if cam == null:
		return

	# Wysokość widoku w pikselach
	var view_h := get_viewport_rect().size.y
	# Dół ekranu w świecie: środek kamery + połowa wysokości
	var bottom_y := cam.global_position.y + (view_h * 0.5)

	# Jeśli jajko jest poniżej dołu + margines → usuń
	if global_position.y > bottom_y + despawn_margin:
		queue_free()

func _collect_deferred() -> void:
	# Wysyłamy sygnał do Main: „zebrane”
	emit_signal("collected")
	# Usuwamy jajko ze sceny
	queue_free()
