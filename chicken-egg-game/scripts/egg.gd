extends Area2D

signal collected

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("collected")
		queue_free()
