extends Node2D
# Główny skrypt gry

@export var egg_scene: PackedScene
# Scena jajka

@export var eggs_container_path: NodePath
# TU w Inspectorze wskażesz kontener na jajka (kliknięciem)

@onready var eggs_container: Node2D = get_node_or_null(eggs_container_path)
# Pobieramy kontener po ścieżce (bez crasha)

@onready var score_label: Label = $UI/HUD/ScoreLabel
# HUD

@onready var spawns_node: Node = $Chickens/Spawns
# Spawny
@onready var balance: Node = $GameBalance
# Referencja do ustawień balansu

var elapsed_time: float = 0.0
# Ile czasu trwa rozgrywka
var score: int = 0
var rng := RandomNumberGenerator.new()
var spawn_points: Array[Marker2D] = []

func _process(delta: float) -> void:
	# Zliczamy czas gry
	elapsed_time += delta

func _ready() -> void:
	
	# Jeśli nie ustawiono kontenera jajek – pokaż błąd i zatrzymaj spawnowanie
	if eggs_container == null:
		push_error("Nie ustawiono eggs_container_path w Inspectorze (Main).")
		return
	# Ustawiamy losowe ziarno (żeby losowania były “prawdziwie” losowe)
	rng.randomize()

	# Ustawiamy wynik na starcie
	score_label.text = str(score)

	# Zbieramy wszystkie spawny do tablicy
	spawn_points = []
	for child in spawns_node.get_children():
		# Sprawdzamy czy dziecko jest Marker2D
		if child is Marker2D:
			# Dodajemy do tablicy
			spawn_points.append(child)

	# Sortujemy spawny po nazwie: Spawn1, Spawn2, Spawn3...
	spawn_points.sort_custom(func(a: Marker2D, b: Marker2D) -> bool:
		# Porównujemy nazwy jako tekst
		return a.name < b.name
	)

func add_score(amount: int = 1) -> void:
	# Dodaje punkty
	score += amount
	# Odświeża HUD
	score_label.text = str(score)

func _on_egg_collected() -> void:
	# Bezpiecznie dodaj punkt (poza krokiem fizyki)
	call_deferred("add_score", 1)

func _on_egg_timer_timeout() -> void:
	# Timer odpala się co X sekund i tworzy nowe jajko

	# Jeśli nie mamy kontenera jajek – nie robimy nic
	if eggs_container == null:
		return

	# Jeśli nie mamy spawnów – nie robimy nic
	if spawn_points.is_empty():
		return

	# LIMIT: jeśli już jest za dużo jajek, pomijamy spawn
	if eggs_container.get_child_count() >= balance.max_eggs_on_screen:
		return

	# Ustawiamy timer dynamicznie (tempo rośnie z czasem)
	$EggTimer.wait_time = balance.get_current_spawn_interval(elapsed_time)

	# Losujemy spawn
	var idx: int = rng.randi_range(0, spawn_points.size() - 1)
	var spawn: Marker2D = spawn_points[idx]

	# Kura (Spawn1 -> Chicken1)
	var chicken_name: String = spawn.name.replace("Spawn", "Chicken")
	var chicken: Node = $Chickens.get_node_or_null(chicken_name)
	if chicken != null and chicken.has_method("play_lay_animation"):
		chicken.play_lay_animation()

	# Tworzymy jajko
	var egg: Area2D = egg_scene.instantiate()
	eggs_container.add_child(egg)

	# Pozycja na spawnie
	egg.position = eggs_container.to_local(spawn.global_position)

	# Podpinamy punkt
	egg.collected.connect(_on_egg_collected)

	# Ustawiamy prędkość spadania z balansu (zależnie od czasu gry)
	# (Egg ma mieć zmienną fall_speed)
	egg.fall_speed = balance.get_current_fall_speed(elapsed_time)
