extends GutTest

func before_all():
	ENV.clear()

func test_set_and_get():
	ENV.set_env("FOO", "BAR")
	assert_eq(String(ENV.get_env("FOO")), "BAR")

func test_type_casting():
	ENV.set_env("INT_VAR", "123")
	ENV.set_env("BOOL_VAR", "true")
	ENV.set_env("FLOAT_VAR", "45.67")
	
	assert_eq(ENV.get_env_int("INT_VAR"), 123)
	assert_eq(ENV.get_env_bool("BOOL_VAR"), true)
	assert_almost_eq(ENV.get_env_float("FLOAT_VAR"), 45.67, 0.01)

func test_variable_expansion():
	var file = FileAccess.open("user://test_expand.env", FileAccess.WRITE)
	file.store_line("BASE=10")
	file.store_line("MULTI=20")
	file.store_line("COMBO=$BASE-${MULTI}")
	file.store_line("MISSING=$NOTFOUND")
	file.close()
	
	ENV.config("user://test_expand.env", true)
	
	assert_eq(String(ENV.get_env("COMBO")), "10-20")
	assert_eq(String(ENV.get_env("MISSING")), "")

func test_save_functionality():
	ENV.clear()
	ENV.set_env("SAVED", "hello")
	ENV.set_env("NUMBER", "42")
	
	ENV.save("user://test_save.env")
	
	ENV.clear()
	
	ENV.config("user://test_save.env", true)
	assert_eq(String(ENV.get_env("SAVED")), "hello")
	assert_eq(ENV.get_env_int("NUMBER"), 42)
