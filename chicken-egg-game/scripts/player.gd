extends CharacterBody2D

@export var speed: float = 350.0
@export var polygon_path: NodePath = NodePath("../ChickenZone/CollisionPolygon2D")

@export var use_custom_input: bool = true
@export var auto_recenter_children: bool = true

@export var idle_anim: StringName = "idle"
@export var walk_anim: StringName = "walk"

# jak dalej minimalnie drży, podnieś na 6-10
@export var wall_margin: float = 6.0

@onready var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var anim_alt: AnimatedSprite2D = get_node_or_null("Sprite2D") as AnimatedSprite2D
@onready var poly_node: CollisionPolygon2D = get_node_or_null(polygon_path) as CollisionPolygon2D

var _half_extents: Vector2 = Vector2.ZERO

func _ready() -> void:
	if anim == null:
		anim = anim_alt

	if auto_recenter_children and col != null and col.position != Vector2.ZERO:
		var delta: Vector2 = col.position
		global_position += delta
		col.position = Vector2.ZERO
		for child in get_children():
			if child is Node2D and child != col:
				(child as Node2D).position -= delta

	_cache_half_extents()

	if poly_node == null:
		push_error("Player: nie znaleziono CollisionPolygon2D. Sprawdź polygon_path w Inspectorze!")

func _physics_process(_delta: float) -> void:
	var dir: Vector2 = _get_input_dir()

	# 1) zaplanuj ruch
	var desired_vel: Vector2 = dir * speed

	# 2) Zablokuj składową, która pcha poza polygon (PRZED ruchem)
	desired_vel = _clip_velocity_to_polygon(desired_vel)

	velocity = desired_vel
	move_and_slide()

	# 3) po ruchu tylko miękko dociśnij (bez teleportowania daleko)
	_soft_push_inside()

	_update_anim(dir)

func _get_input_dir() -> Vector2:
	if use_custom_input:
		return Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _update_anim(dir: Vector2) -> void:
	if anim == null:
		return

	if dir.length() > 0.01:
		if anim.sprite_frames != null and anim.sprite_frames.has_animation(walk_anim):
			if anim.animation != walk_anim:
				anim.play(walk_anim)
		if abs(dir.x) > 0.1:
			anim.flip_h = dir.x < 0.0
	else:
		if anim.sprite_frames != null and anim.sprite_frames.has_animation(idle_anim):
			if anim.animation != idle_anim:
				anim.play(idle_anim)

func _cache_half_extents() -> void:
	_half_extents = Vector2.ZERO
	if col == null or col.shape == null:
		return
	var r: Rect2 = col.shape.get_rect()
	_half_extents = r.size * 0.5

# --- klucz: przycinamy prędkość zanim wejdziemy w ścianę ---
func _clip_velocity_to_polygon(v: Vector2) -> Vector2:
	if poly_node == null:
		return v

	var poly_local: PackedVector2Array = poly_node.polygon
	if poly_local.is_empty():
		return v

	var inv: Transform2D = poly_node.global_transform.affine_inverse()
	var p_local: Vector2 = inv * global_position

	# jeśli jesteśmy wewnątrz, ale następny krok wyjdzie - przytnij
	if Geometry2D.is_point_in_polygon(p_local, poly_local):
		# sprawdź "punkt po kroku" (mały krok w kierunku v)
		var step: float = 1.0
		if v.length() > 0.001:
			step = 6.0  # patrzymy kawałek do przodu
		var p2_local: Vector2 = inv * (global_position + v.normalized() * step)

		if Geometry2D.is_point_in_polygon(p2_local, poly_local):
			return v

		# jesteśmy blisko krawędzi: usuń składową w kierunku normalnej
		var res: Dictionary = _closest_point_and_normal(p_local, poly_local)
		var normal_local: Vector2 = res["normal"] as Vector2
		var normal_global: Vector2 = (poly_node.global_transform.basis_xform(normal_local)).normalized()

		var d: float = v.dot(normal_global)
		if d < 0.0:
			v -= normal_global * d
		return v

	return v

# --- miękki docisk do środka, bez "snapowania" ---
func _soft_push_inside() -> void:
	if poly_node == null:
		return

	var poly_local: PackedVector2Array = poly_node.polygon
	if poly_local.is_empty():
		return

	var inv: Transform2D = poly_node.global_transform.affine_inverse()
	var p_local: Vector2 = inv * global_position

	if Geometry2D.is_point_in_polygon(p_local, poly_local):
		# jeśli jesteśmy bardzo blisko krawędzi, dociśnij minimalnie do środka
		var res: Dictionary = _closest_point_and_normal(p_local, poly_local)
		var closest_local: Vector2 = res["point"] as Vector2
		var normal_local: Vector2 = res["normal"] as Vector2

		var dist: float = p_local.distance_to(closest_local)
		if dist < wall_margin:
			var corrected_local: Vector2 = closest_local + normal_local * wall_margin
			global_position = poly_node.global_transform * corrected_local
		return

	# jeśli jednak wyszliśmy poza - dociśnij
	var res2: Dictionary = _closest_point_and_normal(p_local, poly_local)
	var closest2: Vector2 = res2["point"] as Vector2
	var normal2: Vector2 = res2["normal"] as Vector2
	var corrected2: Vector2 = closest2 + normal2 * wall_margin
	global_position = poly_node.global_transform * corrected2

func _closest_point_and_normal(p: Vector2, poly: PackedVector2Array) -> Dictionary:
	var best_point: Vector2 = poly[0]
	var best_normal: Vector2 = Vector2.UP
	var best_d2: float = INF

	var centroid: Vector2 = Vector2.ZERO
	for v in poly:
		centroid += v
	centroid /= float(poly.size())

	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]

		var q: Vector2 = _closest_point_on_segment(p, a, b)
		var d2: float = p.distance_squared_to(q)
		if d2 < best_d2:
			best_d2 = d2
			best_point = q

			var edge: Vector2 = (b - a)
			var n: Vector2 = Vector2(-edge.y, edge.x)
			if n.length() > 0.0001:
				n = n.normalized()
			if (centroid - q).dot(n) < 0.0:
				n = -n
			best_normal = n

	return {"point": best_point, "normal": best_normal}

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var ab_len2: float = ab.length_squared()
	if ab_len2 <= 0.000001:
		return a
	var t: float = (p - a).dot(ab) / ab_len2
	t = clamp(t, 0.0, 1.0)
	return a + ab * t
