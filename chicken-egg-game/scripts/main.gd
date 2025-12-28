extends Node2D

var score: int = 0

@onready var score_label = $UI/HUD/ScoreLabel

func add_score(amount: int = 1) -> void:
	score += amount
	score_label.text = str(score)


func _on_egg_collected() -> void:
	add_score(1)
