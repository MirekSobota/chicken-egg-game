extends Node2D

@export var egg_scene: PackedScene

@onready var spawns: Array = $Chickens/Spawns.get_children()
@onready var score_label: Label = $UI/HUD/ScoreLabel

var score: int = 0


func _ready() -> void:
	score_label.text = str(score)


func add_score(amount: int = 1) -> void:
	score += amount
	score_label.text = str(score)


func _on_egg_collected() -> void:
	# odroczone, bezpieczne dla fizyki
	call_deferred("add_score", 1)


func _on_egg_timer_timeout() -> void:
	if spawns.is_empty():
		return

	var spawn: Node2D = spawns[randi() % spawns.size()]

	var egg: Area2D = egg_scene.instantiate()
	$Eggs.add_child(egg)

	# konwersja global -> lokalne względem Eggs
	egg.position = $Eggs.to_local(spawn.global_position)

	egg.collected.connect(_on_egg_collected)
