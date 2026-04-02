extends GutTest

func before_all():
	ENV.clear()

func test_set_and_get():
	ENV.set_env("FOO", "BAR")
	assert_eq(String(ENV.get_env("FOO")), "BAR")

func test_defaults():
	assert_eq(String(ENV.get_env("MISSING_KEY", "DEFAULT")), "DEFAULT")
	assert_eq(ENV.get_env_int("MISSING_INT", 42), 42)
	assert_eq(ENV.get_env_bool("MISSING_BOOL", true), true)
	assert_eq(ENV.get_env_float("MISSING_FLOAT", 3.14), 3.14)

func test_remove_env():
	ENV.set_env("TEMP_VAR", "TEMP")
	assert_eq(String(ENV.get_env("TEMP_VAR")), "TEMP")
	ENV.remove_env("TEMP_VAR")
	assert_eq(String(ENV.get_env("TEMP_VAR", "GONE")), "GONE")

func test_get_all_and_files():
	ENV.clear()
	ENV.set_env("G_VAR", "GLOBAL")
	
	var all_env = ENV.get_all_env()
	assert_true(all_env.has("G_VAR"))
	
	var file = FileAccess.open("user://test_inspect.env", FileAccess.WRITE)
	file.store_line("A=1")
	file.close()
	
	ENV.config("user://test_inspect.env", true)
	
	var files = ENV.get_env_files()
	assert_true(files.has("user://test_inspect.env"))
	
	var file_envs = ENV.get_envs_from_file("user://test_inspect.env")
	assert_true(file_envs.has("A"))
	assert_false(file_envs.has("G_VAR"))

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
