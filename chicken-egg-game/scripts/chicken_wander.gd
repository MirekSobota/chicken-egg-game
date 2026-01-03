extends CharacterBody2D
# Kura jako CharacterBody2D -> porusza się z kolizją
# + dodane play_lay_animation() (Main tego potrzebuje)
# + opcja auto_lay (wyłączona domyślnie, żeby nie robić podwójnych jajek)

signal lay_egg(world_pos: Vector2)

@export var chicken_texture: Texture2D

@export var zone_path: NodePath
@export var move_speed: float = 80.0
@export var arrive_distance: float = 10.0

# ===== ZNOSZENIE (AUTO) =====
@export var auto_lay: bool = false
@export var lay_interval_min: float = 1.8
@export var lay_interval_max: float = 3.5
@export var lay_pause_time: float = 0.6

# ===== WYBÓR CELU =====
@export var think_time_min: float = 0.4
@export var think_time_max: float = 1.2

# ===== ANIMACJE =====
@export var idle_anim: StringName = "idle"
@export var walk_anim: StringName = "walk"
@export var lay_anim: StringName = "lay"
@export var walk_threshold: float = 0.5

# ===== "POP" PRZY ZNOSZENIU (dla Main) =====
@export var pop_scale: float = 1.12
@export var pop_time: float = 0.12
@export var return_time: float = 0.18

var _zone: Area2D
var _target: Vector2
var _think_left: float = 0.0
var _lay_left: float = 0.0
var _time_to_lay: float = 0.0

var _rng := RandomNumberGenerator.new()

@onready var _sprite2d: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var _anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var _base_scale: Vector2
var _tween: Tween
var _locked_to_lay: bool = false

func _ready() -> void:
	_rng.randomize()
	_base_scale = scale

	# zone jest opcjonalne: jak nie ustawisz, kura stoi w miejscu
	if zone_path != NodePath(""):
		_zone = get_node_or_null(zone_path) as Area2D
		if _zone == null:
			push_error("Chicken: zone_path ustawione, ale nie znaleziono ChickenZone.")
	else:
		_zone = null

	if _sprite2d != null and chicken_texture != null:
		_sprite2d.texture = chicken_texture

	_play_anim_if_exists(idle_anim)

	_think_left = _rng.randf_range(think_time_min, think_time_max)
	_time_to_lay = _rng.randf_range(lay_interval_min, lay_interval_max)

	if _zone != null:
		global_position = _random_point_in_zone()
		_target = _random_point_in_zone()
	else:
		_target = global_position

func _physics_process(delta: float) -> void:
	# Jeśli Main odpala "lay" -> blokujemy logikę chodzenia/animacji
	if _locked_to_lay:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# ===== AUTO LAY (opcjonalnie) =====
	if auto_lay:
		_time_to_lay -= delta

		if _time_to_lay <= 0.0 and _lay_left <= 0.0:
			_lay_left = lay_pause_time
			_time_to_lay = _rng.randf_range(lay_interval_min, lay_interval_max)

			velocity = Vector2.ZERO
			move_and_slide()
			_play_anim_if_exists(lay_anim)

			emit_signal("lay_egg", global_position)
			return

		if _lay_left > 0.0:
			_lay_left -= delta
			velocity = Vector2.ZERO
			move_and_slide()
			return

	# ===== CHODZENIE (tylko jeśli mamy zone) =====
	if _zone == null:
		_play_anim_if_exists(idle_anim)
		return

	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = _rng.randf_range(think_time_min, think_time_max)
		_target = _random_point_in_zone()

	var to_target: Vector2 = _target - global_position
	var dist: float = to_target.length()

	if dist <= arrive_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_anim_if_exists(idle_anim)
		return

	var dir: Vector2 = to_target / dist
	velocity = dir * move_speed
	move_and_slide()

	_update_anim_and_flip()

# === TO WOŁA Main.gd ===
func play_lay_animation() -> void:
	_locked_to_lay = true

	if _tween != null and _tween.is_running():
		_tween.kill()

	_play_anim_if_exists(lay_anim)

	_tween = create_tween()
	_tween.tween_property(self, "scale", _base_scale * pop_scale, pop_time)
	_tween.tween_property(self, "scale", _base_scale, return_time)
	_tween.finished.connect(func():
		_locked_to_lay = false
		_play_anim_if_exists(idle_anim)
	)

func _update_anim_and_flip() -> void:
	if _anim != null:
		if velocity.length() > walk_threshold:
			_play_anim_if_exists(walk_anim)
		else:
			_play_anim_if_exists(idle_anim)

		if abs(velocity.x) > 0.1:
			_anim.flip_h = velocity.x < 0.0
		return

	if _sprite2d != null and abs(velocity.x) > 0.1:
		_sprite2d.flip_h = velocity.x < 0.0

func _play_anim_if_exists(anim_name: StringName) -> void:
	if _anim == null:
		return
	if _anim.sprite_frames == null:
		return
	if not _anim.sprite_frames.has_animation(anim_name):
		# fallback: jak nie ma "lay", to chociaż idle
		if anim_name == lay_anim:
			if _anim.sprite_frames.has_animation(idle_anim):
				if _anim.animation != idle_anim:
					_anim.play(idle_anim)
		return

	if _anim.animation != anim_name:
		_anim.play(anim_name)

func _random_point_in_zone() -> Vector2:
	var poly := _zone.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null:
		return global_position

	var pts: PackedVector2Array = poly.polygon
	if pts.is_empty():
		return global_position

	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var min_y: float = pts[0].y
	var max_y: float = pts[0].y

	for p in pts:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	for i in range(25):
		var local := Vector2(_rng.randf_range(min_x, max_x), _rng.randf_range(min_y, max_y))
		if Geometry2D.is_point_in_polygon(local, pts):
			return poly.to_global(local)

	var fallback_local := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	return poly.to_global(fallback_local)
