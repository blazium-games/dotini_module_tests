extends SceneTree

func _initialize() -> void:
	var autowork = ClassDB.instantiate("Autowork")
	root.add_child(autowork)
	# Autowork automatically parses .gutconfig.json and command line flags inside its run_tests() invocation!
	autowork.run_tests()
	quit(autowork.get_fail_count())
