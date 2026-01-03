extends Node2D
# Skrypt kury:
# - przełącza animację idle/walk zależnie od ruchu
# - ma metodę play_lay_animation() do efektu przy znoszeniu jajka
# - robi "pop" (krótki tween skali)

# === PARAMETRY FEELINGU ===

@export var pop_scale: float = 1.12
# Jak mocno kura się powiększa podczas "pop"

@export var pop_time: float = 0.12
# Czas powiększenia

@export var return_time: float = 0.18
# Czas powrotu do normalnej skali

@export var walk_threshold: float = 2.0
# Minimalny ruch (w pikselach na klatkę), żeby uznać że kura "idzie"
# Jeśli Twoje kury stoją w miejscu, animacja będzie idle

# === REFERENCJE ===

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# AnimatedSprite2D z animacjami: "idle", "walk" (opcjonalnie "lay")

var _base_scale: Vector2
# Startowa skala kury

var _tween: Tween
# Tween do "pop" animacji (żeby można było przerwać)

var _prev_pos: Vector2
# Poprzednia pozycja (do wykrywania ruchu)

var _locked_to_lay: bool = false
# Gdy kura odtwarza "lay", blokujemy przełączanie idle/walk na chwilę

# === START ===

func _ready() -> void:
	# Zapamiętaj normalną skalę
	_base_scale = scale
	
	# Zapamiętaj pozycję startową
	_prev_pos = global_position
	
	# Na start odpal idle (jeśli istnieje)
	_play_if_exists("idle")

# === LOGIKA: IDLE / WALK ===

func _process(_delta: float) -> void:
	# Jeżeli kura jest w trakcie "lay", nie zmieniamy animacji
	if _locked_to_lay:
		return

	# Obliczamy ile kura się przesunęła od poprzedniej klatki
	var moved: float = global_position.distance_to(_prev_pos)
	_prev_pos = global_position

	# Jeśli przesunęła się wyraźnie -> walk, inaczej -> idle
	if moved > walk_threshold:
		_play_if_exists("walk")
	else:
		_play_if_exists("idle")

# === ZNOSZENIE JAJKA (WYWOŁUJESZ Z MAIN.GD) ===

func play_lay_animation() -> void:
	# To wywołuj w main.gd w momencie spawnu jajka z tej kury:
	# chicken.play_lay_animation()

	# Zablokuj automatyczne przełączanie idle/walk na czas "lay"
	_locked_to_lay = true

	# Jeśli masz animację "lay" w SpriteFrames, odtwórz ją,
	# jeśli nie masz, to chociaż "pop" i zostanie idle
	if anim.sprite_frames.has_animation("lay"):
		anim.play("lay")
	else:
		_play_if_exists("idle")

	# Przerwij poprzedni tween (żeby nie nakładać animacji)
	if _tween != null and _tween.is_running():
		_tween.kill()

	# Nowy tween = "pop" (powiększenie i powrót)
	_tween = create_tween()
	_tween.tween_property(self, "scale", _base_scale * pop_scale, pop_time)
	_tween.tween_property(self, "scale", _base_scale, return_time)

	# Po zakończeniu odblokuj i wróć do idle
	_tween.finished.connect(_on_lay_finished)

func _on_lay_finished() -> void:
	# Koniec "lay"
	_locked_to_lay = false
	_play_if_exists("idle")

# === POMOCNICZA FUNKCJA ===

func _play_if_exists(name: String) -> void:
	# Bezpieczne odtwarzanie animacji tylko jeśli istnieje
	if anim.sprite_frames.has_animation(name):
		# Nie restartujemy tej samej animacji w kółko (żeby nie "mrugała")
		if anim.animation != name:
			anim.play(name)
