extends Area2D
signal collected

@export var fall_speed: float = 120.0
@export var max_y: float = 900.0
@export var start_delay: float = 0.4

var _collected := false
var _delay_left := 0.0

func _ready() -> void:
	_delay_left = start_delay

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		set_deferred("monitoring", false)
		call_deferred("_collect_deferred")

func _process(delta: float) -> void:
	if _delay_left > 0.0:
		_delay_left -= delta
		return
	global_position.y += fall_speed * delta
	if global_position.y > max_y:
		queue_free()

func _collect_deferred() -> void:
	emit_signal("collected")
	queue_free()
