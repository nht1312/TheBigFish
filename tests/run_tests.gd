extends SceneTree
## Headless test runner. Usage:
##   godot --headless --path . -s tests/run_tests.gd
## Runs every test_* method of every tests/unit/test_*.gd. Exit code 1 on failure.


func _initialize() -> void:
	var total := 0
	var failed: Array[String] = []
	var files := DirAccess.get_files_at("res://tests/unit")
	files.sort()
	for file_name in files:
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		var script: GDScript = load("res://tests/unit/" + file_name)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test._current = "%s::%s" % [file_name.get_basename(), name]
			test.before_each()
			test.call(name)
			test.after_each()
			total += 1
			if test.failures.is_empty():
				print("  ok   ", test._current)
			else:
				print("  FAIL ", test._current)
				for f in test.failures:
					print("         ", f)
				failed.append_array(test.failures)
	print("\n%d tests, %d failures" % [total, failed.size()])
	quit(1 if not failed.is_empty() else 0)
