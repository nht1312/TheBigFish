class_name GameClock
extends RefCounted
## Time of day and weather (docs/18 §33–35). Kept deliberately simple for the Vertical Slice:
## no automatic weather simulation yet, only explicit changes (story/debug).

const PHASE_MORNING := "MORNING"
const PHASE_AFTERNOON := "AFTERNOON"
const PHASE_EVENING := "EVENING"
const PHASE_NIGHT := "NIGHT"

const WEATHERS: Array[String] = ["SUNNY", "CLOUDY", "LIGHT_RAIN", "HEAVY_RAIN", "STORM"]

const MINUTES_PER_DAY := 24 * 60

var bus: EventBus
var day: int = 1
var minutes: float = 7 * 60.0  # minutes since midnight
var time_scale: float = 1.0  # game minutes per real second
var weather: String = "SUNNY"

var _phase_activity := {PHASE_MORNING: 1.2, PHASE_AFTERNOON: 0.9, PHASE_EVENING: 1.25, PHASE_NIGHT: 0.8}
var _weather_activity := {"SUNNY": 1.0, "CLOUDY": 1.1, "LIGHT_RAIN": 1.25, "HEAVY_RAIN": 0.8, "STORM": 0.4}


func _init(p_bus: EventBus) -> void:
	bus = p_bus


func advance(real_seconds: float) -> void:
	var old_hour := hour()
	var old_phase := day_phase()
	minutes += real_seconds * time_scale
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1
	if hour() != old_hour:
		bus.emit_event(GameEvents.HOUR_CHANGED, {"hour": hour(), "day": day})
	if day_phase() != old_phase:
		bus.emit_event(GameEvents.DAY_PHASE_CHANGED, {"phase": day_phase()})


## Skips game time (travel, work, sleep) and emits the usual hour/phase events.
func advance_minutes(game_minutes: float) -> void:
	var scale := time_scale
	time_scale = 1.0
	advance(game_minutes)
	time_scale = scale


## Sleeps until the next occurrence of `wake_hour` (always at least into the next morning).
func sleep_until(wake_hour: int) -> void:
	var target := wake_hour * 60.0
	var delta := target - minutes
	if delta <= 60.0:
		delta += MINUTES_PER_DAY
	advance_minutes(delta)


func hour() -> int:
	return int(minutes) / 60


func minute() -> int:
	return int(minutes) % 60


func total_minutes() -> float:
	return (day - 1) * MINUTES_PER_DAY + minutes


func time_string() -> String:
	return "%02d:%02d" % [hour(), minute()]


func day_phase() -> String:
	var h := hour()
	if h >= 5 and h < 12:
		return PHASE_MORNING
	if h >= 12 and h < 17:
		return PHASE_AFTERNOON
	if h >= 17 and h < 20:
		return PHASE_EVENING
	return PHASE_NIGHT


func set_time(h: int, m: int = 0) -> void:
	var old_phase := day_phase()
	minutes = clampi(h, 0, 23) * 60.0 + clampi(m, 0, 59)
	bus.emit_event(GameEvents.HOUR_CHANGED, {"hour": hour(), "day": day})
	if day_phase() != old_phase:
		bus.emit_event(GameEvents.DAY_PHASE_CHANGED, {"phase": day_phase()})


func set_weather(w: String) -> bool:
	w = w.to_upper()
	if not WEATHERS.has(w):
		return false
	if w != weather:
		weather = w
		bus.emit_event(GameEvents.WEATHER_CHANGED, {"weather": weather})
	return true


## How active fish are right now (docs/07 §31–32). 1.0 = normal.
func fish_activity() -> float:
	return float(_phase_activity[day_phase()]) * float(_weather_activity[weather])


func to_dict() -> Dictionary:
	return {"day": day, "minutes": minutes, "time_scale": time_scale, "weather": weather}


func load_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	minutes = float(d.get("minutes", 7 * 60.0))
	time_scale = float(d.get("time_scale", 1.0))
	weather = str(d.get("weather", "SUNNY"))
