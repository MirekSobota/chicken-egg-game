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

var score: int = 0
var rng := RandomNumberGenerator.new()
var spawn_points: Array[Marker2D] = []

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
	if eggs_container == null:
		return

	# Jeśli nie mamy żadnych spawnów – nie robimy nic
	if spawn_points.is_empty():
		return

	# Losujemy indeks spawna z zakresu 0..(size-1)
	var idx: int = rng.randi_range(0, spawn_points.size() - 1)

	# Bierzemy konkretny spawn
	var spawn: Marker2D = spawn_points[idx]

	# Spróbujemy znaleźć kurę po nazwie: Spawn1 -> Chicken1 itd.
	var chicken_name: String = spawn.name.replace("Spawn", "Chicken")
	# Szukamy węzła kury pod $Chickens
	var chicken: Node = $Chickens.get_node_or_null(chicken_name)

	# Jeśli kura istnieje i ma metodę animacji – odpalamy “pop”
	if chicken != null and chicken.has_method("play_lay_animation"):
		chicken.play_lay_animation()

	# Tworzymy instancję jajka
	var egg: Area2D = egg_scene.instantiate()

	# Dodajemy jajko do kontenera
	eggs_container.add_child(egg)

	# Ustawiamy pozycję jajka na pozycji markera spawna
	# (konwersja na lokalne współrzędne kontenera jajek)
	egg.position = eggs_container.to_local(spawn.global_position)

	# Podpinamy sygnał zbierania jajka do funkcji w Main
	egg.collected.connect(_on_egg_collected)
