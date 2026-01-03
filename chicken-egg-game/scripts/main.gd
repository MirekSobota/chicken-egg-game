extends Node2D

@export var egg_scene: PackedScene
@export var eggs_container_path: NodePath

@onready var eggs_container: Node2D = get_node_or_null(eggs_container_path) as Node2D
@onready var score_label: Label = get_node_or_null("UI/HUD/ScoreLabel") as Label
@onready var spawns_node: Node = get_node_or_null("Chickens/Spawns")
@onready var balance: Node = get_node_or_null("GameBalance")
@onready var egg_timer: Timer = get_node_or_null("EggTimer") as Timer
@onready var player: Node = get_node_or_null("Player")

var elapsed_time: float = 0.0
var score: int = 0
var rng := RandomNumberGenerator.new()
var spawn_points: Array[Marker2D] = []

func _process(delta: float) -> void:
	elapsed_time += delta

func _ready() -> void:
	if egg_scene == null:
		push_error("Main: nie ustawiono egg_scene w Inspectorze.")
		return

	if eggs_container == null:
		push_error("Main: nie ustawiono eggs_container_path w Inspectorze.")
		return

	if egg_timer == null:
		push_error("Main: brak węzła EggTimer w scenie.")
		return

	rng.randomize()

	_update_score_label()

	# Zbierz spawny
	spawn_points.clear()
	if spawns_node != null:
		for child in spawns_node.get_children():
			if child is Marker2D:
				spawn_points.append(child)

	spawn_points.sort_custom(func(a: Marker2D, b: Marker2D) -> bool:
		return a.name < b.name
	)

	# Podłącz timer (jeśli nie podłączony w edytorze)
	if not egg_timer.timeout.is_connected(_on_egg_timer_timeout):
		egg_timer.timeout.connect(_on_egg_timer_timeout)

	# Pierwszy interwał
	_set_next_spawn_interval()
	egg_timer.start()

func _update_score_label() -> void:
	if score_label != null:
		score_label.text = str(score)

func add_score(amount: int = 1) -> void:
	score += amount
	_update_score_label()

func _on_egg_collected() -> void:
	# +1 punkt
	call_deferred("add_score", 1)

	# Animacja pickup na graczu (jeśli masz ją w Player.gd)
	if player != null and player.has_method("play_pickup"):
		player.play_pickup()

func _set_next_spawn_interval() -> void:
	if balance != null and balance.has_method("get_current_spawn_interval"):
		egg_timer.wait_time = balance.get_current_spawn_interval(elapsed_time)

func _get_max_eggs_on_screen() -> int:
	if balance == null:
		return 0
	var v = balance.get("max_eggs_on_screen")
	return v if typeof(v) == TYPE_INT else 0

func _on_egg_timer_timeout() -> void:
	if eggs_container == null:
		return
	if spawn_points.is_empty():
		return

	# Limit jajek
	var max_eggs := _get_max_eggs_on_screen()
	if max_eggs > 0 and eggs_container.get_child_count() >= max_eggs:
		# mimo limitu odświeżaj czas (żeby gra nie "stawała" na jednym tempie)
		_set_next_spawn_interval()
		return

	# Dynamiczny interwał
	_set_next_spawn_interval()

	# Losuj spawn
	var idx: int = rng.randi_range(0, spawn_points.size() - 1)
	var spawn: Marker2D = spawn_points[idx]

	# Odpal animację kury: Spawn1 -> Chicken1
	var chicken_name: String = spawn.name.replace("Spawn", "Chicken")
	var chickens_root := get_node_or_null("Chickens")
	var chicken: Node = null
	if chickens_root != null:
		chicken = chickens_root.get_node_or_null(chicken_name)

	if chicken != null and chicken.has_method("play_lay_animation"):
		chicken.play_lay_animation()

	# Spawn jajka
	var egg := egg_scene.instantiate()
	if egg == null:
		return

	eggs_container.add_child(egg)

	# Pozycja w świecie (bezpiecznie)
	if egg is Node2D:
		(egg as Node2D).global_position = spawn.global_position

	# Podłącz sygnał "collected" jeśli jest
	if egg.has_signal("collected"):
		egg.collected.connect(_on_egg_collected)

	# Prędkość spadania jeśli egg ma zmienną fall_speed
	if balance != null and balance.has_method("get_current_fall_speed"):
		var fs: float = balance.get_current_fall_speed(elapsed_time)
		if egg is Node and (egg as Node).get("fall_speed") != null:
			egg.fall_speed = fs
