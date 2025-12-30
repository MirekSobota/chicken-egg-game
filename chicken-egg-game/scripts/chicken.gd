extends Node2D
# Skrypt kury – robi prostą animację „pop”, gdy kura znosi jajko

@export var pop_scale: float = 1.12
# Jak mocno kura się powiększa w animacji

@export var pop_time: float = 0.12
# Czas powiększenia (sekundy)

@export var return_time: float = 0.18
# Czas powrotu do normalnej skali (sekundy)

var _base_scale: Vector2
# Normalna (startowa) skala kury

var _tween: Tween
# Trzymamy referencję do aktualnego tweenu,
# żeby móc go przerwać, gdy animacja odpali kolejny raz

func _ready() -> void:
	# Zapamiętaj skalę startową kury
	_base_scale = scale

func play_lay_animation() -> void:
	# Wywoływane z Main, gdy kura ma „znieść” jajko

	# Jeśli wcześniej działała animacja, zatrzymaj ją
	if _tween != null and _tween.is_running():
		_tween.kill()

	# Tworzymy nowy tween (animację)
	_tween = create_tween()

	# 1) szybkie powiększenie („pop”)
	_tween.tween_property(self, "scale", _base_scale * pop_scale, pop_time)

	# 2) powrót do normalnej skali
	_tween.tween_property(self, "scale", _base_scale, return_time)
