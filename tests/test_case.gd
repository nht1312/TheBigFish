class_name TestCase
extends RefCounted
## Minimal assertion base for tests/run_tests.gd. Test methods start with "test_".

var failures: Array[String] = []
var _current: String = ""


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Fresh game context over the real project data.
func make_ctx() -> GameContext:
	var ctx := GameContext.new(DataRegistry.new().load_from("res://data"), GameContext.load_config("res://config"))
	ctx.story_events.rng.seed = 1
	return ctx


func assert_true(value: bool, message: String = "expected true") -> void:
	if not value:
		_fail(message)


func assert_false(value: bool, message: String = "expected false") -> void:
	if value:
		_fail(message)


func assert_eq(actual, expected, message: String = "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_num(actual) and _is_num(expected)):
		_fail("%s expected %s (%s) got %s (%s)" % [message, str(expected), type_string(typeof(expected)), str(actual), type_string(typeof(actual))])
	elif actual != expected:
		_fail("%s expected %s got %s" % [message, str(expected), str(actual)])


func assert_gt(actual: float, bound: float, message: String = "") -> void:
	if not actual > bound:
		_fail("%s expected > %s got %s" % [message, bound, actual])


func assert_lt(actual: float, bound: float, message: String = "") -> void:
	if not actual < bound:
		_fail("%s expected < %s got %s" % [message, bound, actual])


func _is_num(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


func _fail(message: String) -> void:
	failures.append("%s: %s" % [_current, message])
