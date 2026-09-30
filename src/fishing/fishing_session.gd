class_name FishingSession
extends RefCounted
## One fishing attempt, from cast to outcome (docs/07 §3–25, §46, §48).
## Pure simulation: no nodes, no input devices — the FishingController feeds it input
## and turns its cues into visuals/audio. Fully deterministic given the RNG seed.
##
## States: IDLE → CASTING → WAITING → BITE → HOOKED → FIGHTING ⇄ EXHAUSTED → LANDED
##         any fight state → LOST (fish escaped) / BROKEN (gear failed)
##         WAITING → IDLE with outcome DRIFTED when moving water carries the bait away
##
## Moving water (docs/07 §14, §29; docs/12 §7): `current` 0..1 from the spot. The bait
## drifts while waiting, and a fish running downstream loads the line harder, while
## one fighting upstream tires faster. `current_side` is where downstream lies relative
## to the cast direction (-1 left .. 1 right).

signal state_changed(new_state: String, old_state: String)
signal cue(cue_name: String, data: Dictionary)

const IDLE := "IDLE"
const CASTING := "CASTING"
const WAITING := "WAITING"
const BITE := "BITE"
const HOOKED := "HOOKED"
const FIGHTING := "FIGHTING"
const EXHAUSTED := "EXHAUSTED"
const LANDED := "LANDED"
const LOST := "LOST"
const BROKEN := "BROKEN"

const DEFAULT_TUNING := {
	"cast_seconds": 0.9,
	"cast_min_distance": 3.0,
	"close_cast_distance": 4.5,
	"drag_min_limit": 20.0,
	"tension_response": 8.0,
	"slip_rate": 1.5,
	"line_break_seconds": 0.6,
	"hook_break_seconds": 1.5,
	"slack_threshold": 3.0,
	"slack_seconds": 3.5,
	"rod_wear": 0.04,
	"landing_distance": 1.5,
	"burst_distance": 2.2,
	"stamina_reel_cost": 6.0,
	"stamina_tension_cost": 0.08,
	"stamina_hold_cost": 3.0,
	"stamina_regen": 8.0,
	"stamina_recover_threshold": 25.0,
	"nibble_seconds": 0.35,
	"drift_seconds": 5.0,  # waiting time before the bait leaves the fish at current 1.0
	"current_load": 22.0,  # extra line load at current 1.0 when the fish runs downstream
	"current_push": 0.35,  # how fast the current swings a hooked fish downstream
}

var tuning: Dictionary = DEFAULT_TUNING.duplicate()
var rng := RandomNumberGenerator.new()

var state: String = IDLE
var result: Dictionary = {}  # set when LANDED / LOST / BROKEN

## Gear (from the equipped rod's "rod" stats).
var rod_strength: float = 50.0
var rod_durability: float = 20.0
var line_strength: float = 80.0
var hook_strength: float = 70.0
var reel_power: float = 20.0
var reel_speed: float = 1.0
var line_length: float = 20.0
var max_cast: float = 10.0

## Player controls (written by the controller every frame).
var reeling: bool = false
var rod_dir: float = 0.0  # -1 left .. 1 right
var drag: float = 0.6  # 0..1

## Live fight values (read by HUD / debug).
var tension: float = 0.0
var line_distance: float = 0.0
var player_stamina: float = 100.0
var player_exhausted: bool = false
var fish: FishFighter
var fish_def: Dictionary = {}
var fish_weight: float = 0.0
var bite_ai: FishBiteAI
var skill_level: int = 0
var cast_distance: float = 0.0
var slack_time: float = 0.0  # how long the line has been slack (HUD warns before the fish escapes)
var current: float = 0.0
var current_side: float = 0.0
var drift_time: float = 0.0  # seconds the bait has drifted since landing

var _state_time: float = 0.0
var _nibble_left: float = 0.0
var _over_line: float = 0.0
var _over_hook: float = 0.0
var _pending_fish: Dictionary = {}
var _activity: float = 1.0
var _attraction: float = 1.0


func configure(gear: Dictionary, p_tuning: Dictionary = {}) -> void:
	for key in p_tuning:
		tuning[key] = p_tuning[key]
	rod_strength = float(gear.get("strength", rod_strength))
	line_strength = float(gear.get("line_strength", line_strength))
	hook_strength = float(gear.get("hook_strength", hook_strength))
	reel_power = float(gear.get("reel_power", reel_power))
	reel_speed = float(gear.get("reel_speed", reel_speed))
	line_length = float(gear.get("line_length", line_length))
	max_cast = float(gear.get("max_cast", max_cast))


func is_busy() -> bool:
	return state != IDLE


func is_fighting() -> bool:
	return state in [HOOKED, FIGHTING, EXHAUSTED]


func is_finished() -> bool:
	return state in [LANDED, LOST, BROKEN]


## power 0..1 → distance. pick = FishSelector result ({} = nothing will bite).
func cast(power: float, pick: Dictionary, activity: float, attraction: float, p_skill_level: int = 0) -> void:
	if state != IDLE:
		return
	skill_level = p_skill_level
	cast_distance = lerpf(float(tuning["cast_min_distance"]), max_cast, clampf(power, 0.0, 1.0))
	line_distance = cast_distance
	_pending_fish = pick
	_activity = activity
	_attraction = attraction
	drift_time = 0.0
	result = {}
	_set_state(CASTING)


## Player strikes (hook set). Meaning depends on the state.
func strike() -> void:
	match state:
		WAITING:
			if _nibble_left > 0.0 and bite_ai:
				bite_ai.spook()  # struck on a fake bite
				_nibble_left = 0.0
				cue.emit("spooked", {})
				_schedule_new_fish(2.0)
			else:
				cue.emit("strike_empty", {})
		BITE:
			_attempt_hook()


## Moving water at the spot the bait lands in. Call before cast().
func set_water(p_current: float, p_current_side: float) -> void:
	current = clampf(p_current, 0.0, 1.0)
	current_side = clampf(p_current_side, -1.0, 1.0)


## Seconds a bait stays in place before the current carries it off (INF in still water).
func drift_limit() -> float:
	if current < 0.05:
		return INF
	return float(tuning["drift_seconds"]) / current


## Reel in without a fish (keeps bait).
func cancel() -> void:
	if state in [CASTING, WAITING]:
		result = {"outcome": "CANCELLED", "bait_consumed": false}
		_set_state(IDLE)


## Back to IDLE after an outcome has been handled.
func reset() -> void:
	fish = null
	bite_ai = null
	fish_def = {}
	tension = 0.0
	reeling = false
	rod_dir = 0.0
	_set_state(IDLE)


func tick(delta: float) -> void:
	_state_time += delta
	match state:
		CASTING:
			if _state_time >= float(tuning["cast_seconds"]):
				cue.emit("float_landed", {"distance": cast_distance})
				_set_state(WAITING)
				_begin_waiting()
		WAITING:
			_tick_waiting(delta)
		BITE:
			if _state_time > bite_ai.bite_window():
				_bite_missed()
		HOOKED:
			_set_state(FIGHTING)
		FIGHTING, EXHAUSTED:
			_tick_fight(delta)
		IDLE, LANDED, LOST, BROKEN:
			_regen_stamina(delta)


func fish_state_name() -> String:
	if not is_fighting() or fish == null:
		return ""
	return "EXHAUSTED" if fish.is_exhausted() else fish.action


# --- Waiting / bite -----------------------------------------------------------

func _begin_waiting() -> void:
	if _pending_fish.is_empty():
		bite_ai = null  # not every cast finds a fish (docs/07 §7)
		return
	fish_def = _pending_fish["fish"]
	fish_weight = float(_pending_fish["weight"])
	var close := cast_distance < float(tuning["close_cast_distance"])
	bite_ai = FishBiteAI.new(fish_def, rng, _activity, _attraction, close)


func _schedule_new_fish(delay_factor: float) -> void:
	if _pending_fish.is_empty():
		return
	bite_ai = FishBiteAI.new(fish_def, rng, _activity / delay_factor, _attraction, false)


func _tick_waiting(delta: float) -> void:
	_nibble_left = maxf(0.0, _nibble_left - delta)
	drift_time += delta
	if drift_time > drift_limit():
		result = {"outcome": "DRIFTED", "bait_consumed": false}
		cue.emit("drifted", {})
		_set_state(IDLE)
		return
	if bite_ai == null:
		return
	match bite_ai.tick(delta):
		"nibble":
			_nibble_left = float(tuning["nibble_seconds"])
			cue.emit("nibble", {})
		"shadow":
			cue.emit("shadow", {})
		"bite":
			_set_state(BITE)
			cue.emit("bite", {"strength": bite_ai.bite_strength, "giant": fish_def.get("giant", false)})


func _attempt_hook() -> void:
	var window := bite_ai.bite_window()
	var quality := 1.0 - clampf(_state_time / window, 0.0, 1.0)
	var chance := 0.6 + 0.35 * quality + 0.04 * skill_level - 0.35 * float(fish_def.get("caution", 0.3))
	chance += float(fish_def.get("hook_bonus", 0.0))
	if fish_def.get("persistent_bite", false) or rng.randf() < clampf(chance, 0.05, 0.98):
		fish = FishFighter.new(fish_def, fish_weight, rng)
		tension = fish.pull() * 0.5
		_over_line = 0.0
		_over_hook = 0.0
		slack_time = 0.0
		_set_state(HOOKED)
		cue.emit("hooked", {"fish": fish_def.get("id", "")})
	else:
		_finish(LOST, "HOOK_MISSED", rng.randf() < 0.5)


func _bite_missed() -> void:
	if fish_def.get("persistent_bite", false):
		bite_ai.retry_after_miss()
		_set_state(WAITING)
		cue.emit("bite_missed", {})
	else:
		_finish(LOST, "BAIT_STOLEN", true)


# --- Fight --------------------------------------------------------------------

func _tick_fight(delta: float) -> void:
	var scripted := str(fish_def.get("scripted_outcome", ""))
	var can_reel := reeling and not player_exhausted
	fish.tick(delta, tension, can_reel and tension > 60.0)
	var pull := fish.pull()

	# Rod angle vs the fish's direction: countering tires it, following eases tension (docs/07 §16).
	var align := 0.0
	if absf(rod_dir) > 0.2 and absf(fish.lateral) > 0.1:
		align = -signf(rod_dir) * signf(fish.lateral) * minf(1.0, absf(fish.lateral) * 1.5)
	var tension_mult := 1.0 - 0.15 * maxf(0.0, -align)
	var fatigue_mult := 1.0 + maxf(0.0, align) - 0.5 * maxf(0.0, -align)

	# Current: swings the fish downstream; running with it loads the line, against it tires the fish.
	var flow_load := 0.0
	if current > 0.0:
		fish.lateral = clampf(fish.lateral + current_side * current * float(tuning["current_push"]) * delta, -1.0, 1.0)
		var with_flow := clampf(fish.lateral * current_side, -1.0, 1.0)
		flow_load = current * float(tuning["current_load"]) * (0.35 + maxf(0.0, with_flow))
		fatigue_mult += current * maxf(0.0, -with_flow)

	var raw := pull * tension_mult + flow_load + (reel_power if can_reel else 0.0)
	var drag_limit := lerpf(float(tuning["drag_min_limit"]), 100.0, clampf(drag, 0.0, 1.0))
	var at_line_end := line_distance >= line_length - 0.01
	var target := raw
	if raw > drag_limit and not at_line_end:
		# Drag slips: line pays out instead of taking the full load (docs/07 §18).
		line_distance += (raw - drag_limit) / maxf(fish.strength, 1.0) * fish.speed * float(tuning["slip_rate"]) * delta
		target = drag_limit + (raw - drag_limit) * 0.15
		if rng.randf() < delta * 6.0:
			cue.emit("drag_slip", {})
	elif can_reel:
		var resist := clampf(pull / (reel_power * 2.0 + pull), 0.0, 0.85)
		line_distance -= reel_speed * (1.0 - resist) * delta
	line_distance = clampf(line_distance, 0.0, line_length)
	tension = lerpf(tension, clampf(target, 0.0, 100.0), 1.0 - exp(-float(tuning["tension_response"]) * delta))

	# Fish fatigue grows with how hard it pulls against pressure.
	var effort := pull / maxf(fish.strength, 1.0)
	var drain_rate := fish.max_stamina / maxf(1.0, float(fish_def.get("fight_seconds", 12.0)))
	fish.drain(effort * drain_rate * fatigue_mult * (0.4 + tension / 60.0) * delta)

	_update_player_stamina(delta, can_reel)

	# Gear limits.
	if tension > rod_strength:
		rod_durability -= (tension - rod_strength) * float(tuning["rod_wear"]) * delta
		if rng.randf() < delta * 3.0:
			cue.emit("rod_creak", {"severity": (tension - rod_strength) / (100.0 - rod_strength)})
		if rod_durability <= 0.0:
			rod_durability = 0.0
			_finish(BROKEN, "ROD", true)
			return
	if scripted == "":
		_over_line = _over_line + delta if tension > line_strength else maxf(0.0, _over_line - delta)
		if _over_line > float(tuning["line_break_seconds"]):
			_finish(BROKEN, "LINE", true)
			return
		_over_hook = _over_hook + delta if tension > hook_strength else maxf(0.0, _over_hook - delta)
		if _over_hook > float(tuning["hook_break_seconds"]):
			_finish(LOST, "HOOK", true)
			return
		slack_time = slack_time + delta if tension < float(tuning["slack_threshold"]) else 0.0
		if slack_time > float(tuning["slack_seconds"]):
			_finish(LOST, "SLACK", true)
			return

	# Exhaustion and landing (docs/07 §22, §41).
	if fish.is_exhausted():
		if state != EXHAUSTED:
			_set_state(EXHAUSTED)
			cue.emit("fish_exhausted", {})
		if line_distance <= float(tuning["landing_distance"]):
			_finish(LANDED, "", true)
	else:
		if state == EXHAUSTED:
			_set_state(FIGHTING)
		if line_distance <= float(tuning["burst_distance"]) and fish.action != "BURST":
			fish.force_action("BURST")  # a fresh fish will not come to hand
			cue.emit("splash", {"size": fish_weight})


func _update_player_stamina(delta: float, can_reel: bool) -> void:
	if can_reel:
		player_stamina -= (float(tuning["stamina_reel_cost"]) + tension * float(tuning["stamina_tension_cost"])) * delta
	elif tension > 60.0:
		player_stamina -= float(tuning["stamina_hold_cost"]) * delta
	else:
		player_stamina += float(tuning["stamina_regen"]) * delta
	player_stamina = clampf(player_stamina, 0.0, 100.0)
	if player_stamina <= 0.0:
		player_exhausted = true
	elif player_stamina >= float(tuning["stamina_recover_threshold"]):
		player_exhausted = false


func _regen_stamina(delta: float) -> void:
	player_stamina = minf(100.0, player_stamina + float(tuning["stamina_regen"]) * delta)
	if player_stamina >= float(tuning["stamina_recover_threshold"]):
		player_exhausted = false


func _finish(outcome: String, reason: String, bait_consumed: bool) -> void:
	result = {
		"outcome": outcome,
		"reason": reason,
		"fish": str(fish_def.get("id", "")),
		"weight": fish_weight,
		"bait_consumed": bait_consumed,
		"rod_durability": rod_durability,
	}
	tension = 0.0 if outcome != LANDED else tension
	_set_state(outcome)
	cue.emit(outcome.to_lower(), result)


func _set_state(new_state: String) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	_state_time = 0.0
	state_changed.emit(new_state, old)
