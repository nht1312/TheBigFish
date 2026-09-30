class_name FishFighter
extends RefCounted
## Hooked-fish behaviour (docs/08 §10–18, §22, §25, §28).
##
## Picks timed actions weighted by archetype (or by the current phase for scripted fish),
## produces a pulling force and a lateral direction the player has to counter.

const ARCHETYPE_ACTIONS := {
	"PASSIVE": {"RUN": 3, "REST": 4, "TURN": 2, "SHAKE": 1},
	"AGGRESSIVE": {"RUN": 4, "BURST": 3, "TURN": 2, "REST": 1},
	"CAUTIOUS": {"RUN": 3, "SHAKE": 2, "REST": 3, "TURN": 2},
	"ERRATIC": {"TURN": 4, "BURST": 2, "RUN": 2, "SHAKE": 2},
	"DEEP_DIVER": {"DIVE": 4, "RUN": 3, "REST": 3},
	"SURFACE_RUNNER": {"RUN": 5, "SURFACE": 2, "TURN": 2, "REST": 1},
	"BOTTOM_FEEDER": {"DIVE": 3, "HIDE": 3, "REST": 4},
}

## Fraction of the fish's strength put on the line by each action.
const ACTION_PULL := {
	"RUN": 0.8, "BURST": 1.3, "TURN": 0.55, "SHAKE": 0.5, "REST": 0.15, "DIVE": 0.95, "SURFACE": 0.6, "HIDE": 0.7,
}

const ACTION_SECONDS := {
	"RUN": [1.2, 2.6], "BURST": [0.5, 1.1], "TURN": [0.6, 1.2], "SHAKE": [0.6, 1.4],
	"REST": [1.0, 2.4], "DIVE": [1.2, 2.4], "SURFACE": [0.8, 1.6], "HIDE": [1.2, 2.2],
}

const EXHAUSTED_RATIO := 0.12

var def: Dictionary
var rng: RandomNumberGenerator
var strength: float
var speed: float
var max_stamina: float
var stamina: float
var aggression: float
var turn_rate: float
var never_exhausts: bool

var action: String = "RUN"
var lateral: float = 0.0  # -1 (left) .. 1 (right)
var phase_name: String = ""

var _lateral_target: float = 0.0
var _action_left: float = 0.0
var _phase_index: int = -1
var _phase_left: float = 0.0
var _clock: float = 0.0


func _init(fish_def: Dictionary, weight_kg: float, p_rng: RandomNumberGenerator) -> void:
	def = fish_def
	rng = p_rng
	var w: Array = def.get("weight_kg", [weight_kg, weight_kg])
	var span := maxf(0.001, float(w[1]) - float(w[0]))
	var size_factor := lerpf(0.85, 1.15, clampf((weight_kg - float(w[0])) / span, 0.0, 1.0))
	strength = float(def.get("strength", 20)) * size_factor
	speed = float(def.get("speed", 1.0))
	max_stamina = float(def.get("stamina", 100)) * size_factor
	stamina = max_stamina
	aggression = float(def.get("aggression", 0.3))
	turn_rate = float(def.get("turn_rate", 2.0))
	never_exhausts = def.get("scripted_outcome", "") != ""
	if not def.get("phases", []).is_empty():
		_next_phase()
	_set_action("BURST" if aggression > 0.5 else "RUN")  # hooked: detects resistance and reacts (docs/08 §9)


## player_forcing: the player is reeling hard at high tension (docs/08 §25).
func tick(delta: float, tension: float, player_forcing: bool) -> void:
	_clock += delta
	if not def.get("phases", []).is_empty():
		_phase_left -= delta
		if _phase_left <= 0.0:
			_next_phase()
	_action_left -= delta
	if _action_left <= 0.0:
		_set_action(_choose_action(player_forcing))
	lateral = move_toward(lateral, _lateral_target, turn_rate * 0.5 * delta)
	if action == "REST" and tension < 20.0 and not is_exhausted():
		stamina = minf(max_stamina, stamina + max_stamina * 0.035 * delta)


func pull() -> float:
	var p := strength * float(ACTION_PULL[action]) * (0.35 + 0.65 * stamina_ratio())
	if action == "SHAKE":
		p *= 0.6 + 0.4 * sin(_clock * 18.0)
	if is_exhausted():
		p *= 0.35
	return p


func drain(amount: float) -> void:
	if never_exhausts:
		return
	stamina = maxf(0.0, stamina - amount)


func stamina_ratio() -> float:
	return 1.0 if max_stamina <= 0.0 else stamina / max_stamina


func is_exhausted() -> bool:
	return not never_exhausts and stamina_ratio() < EXHAUSTED_RATIO


func force_action(a: String) -> void:
	_set_action(a)


func _choose_action(player_forcing: bool) -> String:
	if is_exhausted():
		return "REST" if rng.randf() < 0.6 else "TURN"
	var weights: Dictionary = ARCHETYPE_ACTIONS.get(str(def.get("archetype", "PASSIVE")), ARCHETYPE_ACTIONS["PASSIVE"])
	if _phase_index >= 0:
		weights = def["phases"][_phase_index].get("actions", weights)
	var burst_bonus := aggression * stamina_ratio() * (2.0 if player_forcing else 0.5)
	var total := 0.0
	for a in weights:
		total += float(weights[a]) + (burst_bonus if a == "BURST" else 0.0)
	var roll := rng.randf() * total
	for a in weights:
		roll -= float(weights[a]) + (burst_bonus if a == "BURST" else 0.0)
		if roll <= 0.0:
			return a
	return weights.keys()[0]


func _set_action(a: String) -> void:
	action = a
	var secs: Array = ACTION_SECONDS[a]
	_action_left = rng.randf_range(float(secs[0]), float(secs[1]))
	match a:
		"RUN", "BURST", "SURFACE":
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			_lateral_target = side * rng.randf_range(0.4, 1.0)
		"TURN":
			_lateral_target = -signf(lateral if lateral != 0.0 else 1.0) * rng.randf_range(0.5, 1.0)
		"DIVE", "HIDE":
			_lateral_target = lateral * 0.3
		_:
			_lateral_target = lateral * 0.5


func _next_phase() -> void:
	var phases: Array = def.get("phases", [])
	_phase_index = mini(_phase_index + 1, phases.size() - 1)
	var phase: Dictionary = phases[_phase_index]
	phase_name = str(phase.get("name", ""))
	_phase_left = float(phase.get("seconds", 5.0))
	_action_left = 0.0  # re-pick immediately with the new phase weights
