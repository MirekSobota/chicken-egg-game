extends CharacterBody2D
# Kura jako CharacterBody2D -> porusza się z kolizją (nie duch)

signal lay_egg(world_pos: Vector2)
# Sygnał: kura złożyła jajko w danym miejscu (w świecie)

@export var chicken_texture: Texture2D
# Tekstura tej konkretnej kury (ustawiasz per instancja w Inspectorze)

@export var zone_path: NodePath
# Ścieżka do ChickenZone (Area2D) w Main

@export var move_speed: float = 80.0
# Prędkość ruchu

@export var arrive_distance: float = 10.0
# Jak blisko celu uznajemy "doszliśmy"

@export var lay_interval_min: float = 1.8
@export var lay_interval_max: float = 3.5
# Losowy czas między jajkami

@export var lay_pause_time: float = 0.6
# Ile kura stoi podczas składania

@export var think_time_min: float = 0.4
@export var think_time_max: float = 1.2
# Co ile kura wybiera nowy cel chodzenia

var _zone: Area2D
# Referencja do ChickenZone

var _target: Vector2
# Aktualny cel w świecie

var _think_left: float = 0.0
# Odliczanie do kolejnego losowania celu

var _lay_left: float = 0.0
# Odliczanie "stoję i składam"

var _time_to_lay: float = 0.0
# Odliczanie do kolejnego jajka

func _ready() -> void:
	# Pobieramy strefę chodzenia
	_zone = get_node_or_null(zone_path) as Area2D

	# Jeśli nie ustawiono zone_path, kończymy
	if _zone == null:
		push_error("Chicken: nie ustawiono zone_path (ChickenZone) w Inspectorze.")
		return

	# Ustawiamy sprite jeśli podano teksturę
	var sprite := $Sprite2D
	if chicken_texture != null:
		sprite.texture = chicken_texture

	# Losujemy czasy startowe
	_think_left = randf_range(think_time_min, think_time_max)
	_time_to_lay = randf_range(lay_interval_min, lay_interval_max)

	# Losujemy STARTOWĄ pozycję (żeby nie startowały w jednym miejscu)
	global_position = _random_point_in_zone()

	# Losujemy pierwszy cel
	_target = _random_point_in_zone()

func _physics_process(delta: float) -> void:
	# Jeśli nie ma strefy, nic nie rób
	if _zone == null:
		return

	# Odliczamy do jajka
	_time_to_lay -= delta

	# Jeśli czas na jajko i nie składamy -> zacznij składanie
	if _time_to_lay <= 0.0 and _lay_left <= 0.0:
		_lay_left = lay_pause_time
		_time_to_lay = randf_range(lay_interval_min, lay_interval_max)

		# Zatrzymujemy ruch podczas składania
		velocity = Vector2.ZERO
		move_and_slide()

		# Wysyłamy sygnał do Main
		emit_signal("lay_egg", global_position)
		return

	# Jeśli składamy -> stoimy
	if _lay_left > 0.0:
		_lay_left -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Losowanie nowego celu co jakiś czas
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = randf_range(think_time_min, think_time_max)
		_target = _random_point_in_zone()

	# Wektor do celu
	var to_target: Vector2 = _target - global_position
	var dist: float = to_target.length()

	# Jeśli blisko celu -> stop
	if dist <= arrive_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Kierunek do celu
	var dir: Vector2 = to_target / dist

	# Ustawiamy prędkość
	velocity = dir * move_speed

	# RUCH Z KOLIZJĄ (TO JEST KLUCZ)
	move_and_slide()

func _random_point_in_zone() -> Vector2:
	# Bierzemy CollisionPolygon2D ze strefy
	var poly := _zone.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null:
		return global_position

	# Punktów polygonu
	var pts: PackedVector2Array = poly.polygon
	if pts.is_empty():
		return global_position

	# Bounding box polygonu (lokalnie)
	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var min_y: float = pts[0].y
	var max_y: float = pts[0].y

	for p in pts:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	# Kilka prób trafienia w polygon
	for i in range(25):
		var local := Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		if Geometry2D.is_point_in_polygon(local, pts):
			return poly.to_global(local)

	# Awaryjnie środek
	var fallback_local := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	return poly.to_global(fallback_local)
