extends Node
# Prosty balans w 1 miejscu

enum Difficulty { EASY, NORMAL, HARD }
# 3 tryby trudności

@export var difficulty: Difficulty = Difficulty.NORMAL
# Wybór trudności w Inspectorze

@export var spawn_interval: float = 1.2
# Bazowy spawn (dla NORMAL)

@export var max_eggs_on_screen: int = 8
# Limit jajek na ekranie

@export var egg_fall_speed: float = 160.0
# Bazowa prędkość spadania (dla NORMAL)

@export var difficulty_ramp_per_minute: float = 0.15
# Jak szybko rośnie trudność z czasem

func _difficulty_mult() -> float:
	# Zwraca mnożnik zależnie od trybu
	match difficulty:
		Difficulty.EASY:
			return 0.85
		Difficulty.NORMAL:
			return 1.0
		Difficulty.HARD:
			return 1.15
	return 1.0

func get_current_fall_speed(elapsed_seconds: float) -> float:
	# Prędkość spadania rośnie z czasem + zależy od trudności
	var minutes: float = elapsed_seconds / 60.0
	var mult_time: float = 1.0 + (minutes * difficulty_ramp_per_minute)
	var mult_diff: float = _difficulty_mult()
	return egg_fall_speed * mult_time * mult_diff

func get_current_spawn_interval(elapsed_seconds: float) -> float:
	# Spawn robi się częstszy z czasem + zależy od trudności
	var minutes: float = elapsed_seconds / 60.0

	# Z czasem skracamy interwał (ale z limitem)
	var mult_time: float = 1.0 - (minutes * (difficulty_ramp_per_minute * 0.5))
	mult_time = max(mult_time, 0.55)

	# Trudność wpływa na interwał (HARD = częściej, EASY = rzadziej)
	var mult_diff: float = _difficulty_mult()
	var diff_spawn_factor: float = 1.0 / mult_diff

	var value: float = spawn_interval * mult_time * diff_spawn_factor
	return max(value, 0.35)
