extends Node2D
# Główny skrypt gry – spawnuje jajka i zarządza punktami

@export var egg_scene: PackedScene
# Scena jajka (egg.tscn) ustawiona w Inspectorze

@onready var spawns: Array = $Chickens/Spawns.get_children()
# Lista markerów Spawn1/Spawn2/Spawn3

@onready var score_label: Label = $UI/HUD/ScoreLabel
# Etykieta wyniku na HUD

# Lista kur, kolejność ma odpowiadać spawn’om:
# Chicken1 pasuje do Spawn1 itd.
@onready var chickens: Array = [
	$Chickens/Chicken1,
	$Chickens/Chicken2,
	$Chickens/Chicken3
]

var score: int = 0
# Aktualny wynik


func _ready() -> void:
	# Start gry – ustaw wynik na ekranie
	score_label.text = str(score)


func add_score(amount: int = 1) -> void:
	# Dodaje punkty i odświeża HUD
	score += amount
	score_label.text = str(score)


func _on_egg_collected() -> void:
	# Wywoływane, gdy jajko wyśle sygnał "collected"
	# call_deferred – bezpieczne dla fizyki
	call_deferred("add_score", 1)


func _on_egg_timer_timeout() -> void:
	# Timer odpala się co X sekund i tworzy nowe jajko

	if spawns.is_empty():
		# Jeśli nie ma markerów spawn – nic nie rób
		return

	# Losujemy indeks spawna (0..n-1)
	var idx: int = randi() % spawns.size()

	# Wybieramy konkretnego spawna i kurę o tym samym indeksie
	var spawn: Node2D = spawns[idx]
	var chicken: Node = chickens[min(idx, chickens.size() - 1)]
	# min(...) zabezpiecza, gdybyś miał więcej spawnów niż kur

	# 1) Animacja kury (znoszenie jajka)
	if chicken.has_method("play_lay_animation"):
		chicken.play_lay_animation()

	# 2) Tworzymy jajko
	var egg: Area2D = egg_scene.instantiate()

	# Dla porządku trzymamy jajka pod węzłem "Eggs"
	$Eggs.add_child(egg)

	# Ustawiamy jajko dokładnie na markerze spawna
	egg.position = $Eggs.to_local(spawn.global_position)

	# Podpinamy sygnał zbierania jajka do funkcji w Main
	egg.collected.connect(_on_egg_collected)
