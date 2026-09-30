class_name GameAudio
extends Node
## Placeholder audio: every sound is synthesised at startup so the slice has feedback
## (docs/18 §49–50) before real recordings exist. Replace by loading streams from
## assets/sounds/ with the same names.

const RATE := 22050
const POOL_SIZE := 10

var streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _rng := RandomNumberGenerator.new()
var ambient: AudioStreamPlayer
var drain_water: AudioStreamPlayer3D


func _ready() -> void:
	_rng.seed = 7
	streams["plop"] = _synth(0.18, func(t, _i): return sin(TAU * (250.0 + 650.0 * exp(-t * 25.0)) * t) * exp(-t * 18.0))
	streams["tick"] = _synth(0.015, func(t, _i): return _rng.randf_range(-1, 1) * exp(-t * 400.0))
	streams["splash_small"] = _noise(0.45, 0.25, 0.02, 7.0)
	streams["splash_big"] = _noise(1.1, 0.12, 0.03, 3.0, 55.0)
	streams["creak"] = _synth(0.5, func(t, _i):
		var f := 80.0 + 25.0 * sin(t * 30.0)
		return (fmod(t * f, 1.0) * 2.0 - 1.0) * 0.5 * sin(PI * t / 0.5))
	streams["snap"] = _synth(0.3, func(t, _i): return _rng.randf_range(-1, 1) * exp(-t * 30.0) + sin(TAU * 140.0 * t) * exp(-t * 20.0) * 0.6)
	streams["whoosh"] = _noise(0.4, 0.5, 0.2, 5.0)
	streams["drag"] = _synth(0.12, func(t, _i): return (fmod(t * 190.0, 1.0) * 2.0 - 1.0) * 0.35 * exp(-t * 10.0))
	streams["step"] = _noise(0.09, 0.15, 0.005, 40.0)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 6.0
		p.max_distance = 60.0
		add_child(p)
		_pool.append(p)
	ambient = AudioStreamPlayer.new()
	ambient.stream = _loop_noise(4.0, 0.05)
	ambient.volume_db = -26.0
	add_child(ambient)
	ambient.play()
	drain_water = AudioStreamPlayer3D.new()
	drain_water.stream = _loop_noise(3.0, 0.3)
	drain_water.unit_size = 10.0
	drain_water.max_distance = 45.0
	drain_water.volume_db = -6.0
	add_child(drain_water)


func place_drain_water(pos: Vector3) -> void:
	drain_water.global_position = pos
	drain_water.play()


func play(sound_name: String, position: Vector3, volume_db: float = 0.0) -> void:
	if not streams.has(sound_name):
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = streams[sound_name]
	p.global_position = position
	p.volume_db = volume_db
	p.pitch_scale = _rng.randf_range(0.92, 1.08)
	p.play()


# --- Synthesis ------------------------------------------------------------------

func _synth(seconds: float, sample: Callable) -> AudioStreamWAV:
	var count := int(seconds * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var v := clampf(float(sample.call(float(i) / RATE, i)), -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


## Low-passed noise burst. smooth: 0..1 filter coefficient (lower = darker).
func _noise(seconds: float, smooth: float, attack: float, decay: float, thump_hz: float = 0.0) -> AudioStreamWAV:
	var state := [0.0]
	return _synth(seconds, func(t, _i):
		state[0] += (_rng.randf_range(-1, 1) - state[0]) * smooth
		var env := minf(1.0, t / maxf(attack, 0.001)) * exp(-t * decay)
		var v: float = state[0] * 2.2 * env
		if thump_hz > 0.0:
			v += sin(TAU * thump_hz * t) * exp(-t * 6.0) * 0.8
		return v)


func _loop_noise(seconds: float, smooth: float) -> AudioStreamWAV:
	var wav := _noise(seconds, smooth, 0.0001, 0.0)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = int(seconds * RATE) - 1
	return wav
