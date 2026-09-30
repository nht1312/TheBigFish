class_name FishBiteAI
extends RefCounted
## Fish behaviour before the hook: SEARCHING → APPROACHING → INSPECTING → BITING (docs/08 §3–9).
## Nibbles are the "fake bites" of docs/07 §8: striking on one spooks the fish.

enum Stage { APPROACHING, INSPECTING, BITING, GONE }

var fish: Dictionary
var rng: RandomNumberGenerator
var stage: Stage = Stage.APPROACHING
var bite_strength: String = "NORMAL"  # LIGHT / NORMAL / STRONG

var _timer: float = 0.0
var _nibbles_left: int = 0
var _speed: float = 1.0  # activity × bait attraction


## activity: time/weather multiplier. attraction: bait attraction × preference match.
func _init(fish_def: Dictionary, p_rng: RandomNumberGenerator, activity: float, attraction: float, close_cast: bool) -> void:
	fish = fish_def
	rng = p_rng
	_speed = maxf(0.1, activity * attraction)
	_start_approach(close_cast)


## Advances the AI. Returns "" or one of: "nibble", "bite", "shadow".
func tick(delta: float) -> String:
	if stage in [Stage.BITING, Stage.GONE]:
		return ""
	_timer -= delta
	if _timer > 0.0:
		return ""
	match stage:
		Stage.APPROACHING:
			stage = Stage.INSPECTING
			_nibbles_left = _roll_nibbles()
			_timer = rng.randf_range(0.6, 1.6)
			return "shadow" if fish.get("giant", false) else ""
		Stage.INSPECTING:
			if _nibbles_left > 0:
				_nibbles_left -= 1
				_timer = rng.randf_range(0.8, 2.0)
				return "nibble"
			stage = Stage.BITING
			bite_strength = _roll_strength()
			return "bite"
	return ""


## Striking during a nibble scares the fish away; a new one may come later.
func spook() -> void:
	stage = Stage.GONE


## After a missed bite a persistent fish (the giant) comes back quickly.
func retry_after_miss() -> void:
	stage = Stage.INSPECTING
	_nibbles_left = 0
	_timer = rng.randf_range(2.0, 4.0)


func bite_window() -> float:
	var caution := float(fish.get("caution", 0.3))
	return clampf(1.5 - caution * 0.9, 0.5, 1.6)


func _start_approach(close_cast: bool) -> void:
	stage = Stage.APPROACHING
	var range_s: Array = fish.get("approach_seconds", [4.0, 10.0])
	_timer = rng.randf_range(float(range_s[0]), float(range_s[1])) / _speed
	if close_cast:
		_timer *= 1.4  # bait landed in shallow water near the bank


func _roll_nibbles() -> int:
	var caution := float(fish.get("caution", 0.3))
	return rng.randi_range(0, int(round(caution * 3.0)))


func _roll_strength() -> String:
	var aggression := float(fish.get("aggression", 0.3))
	var roll := rng.randf() + aggression * 0.5
	if roll > 1.1:
		return "STRONG"
	if roll < 0.35:
		return "LIGHT"
	return "NORMAL"
