extends GutTest

func before_all():
	ENV.clear()

func test_set_and_get():
	ENV.set_env("FOO", "BAR")
	assert_eq(String(ENV.get_env("FOO")), "BAR")

func test_defaults():
	assert_eq(String(ENV.get_env("MISSING_KEY", "DEFAULT")), "DEFAULT")
	assert_eq(ENV.get_env_int("MISSING_INT", 42), 42)
	assert_eq(ENV.get_env_bool("TEST_BOOL", true), true)
	assert_almost_eq(ENV.get_env_float("TEST_FLOAT", 3.14), 3.14, 0.001)

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

func test_load_env_file_cascading():
	ENV.clear()
	var base_file = FileAccess.open(".env", FileAccess.WRITE)
	base_file.store_line("CASCADE_BASE=alpha")
	base_file.close()
	
	var overlay = FileAccess.open(".env.local", FileAccess.WRITE)
	overlay.store_line("CASCADE_OVERLAY=beta")
	overlay.close()

	ENV.load_env_file(".env.local")
	assert_eq(String(ENV.get_env("CASCADE_BASE")), "alpha")
	assert_eq(String(ENV.get_env("CASCADE_OVERLAY")), "beta")

func test_export_key_stripping():
	ENV.clear()
	var file = FileAccess.open("user://test_export.env", FileAccess.WRITE)
	file.store_line("export HOST=127.0.0.1")
	file.store_line("export PORT=8080")
	file.close()

	ENV.config("user://test_export.env", true)
	
	assert_eq(String(ENV.get_env("HOST")), "127.0.0.1")
	assert_eq(ENV.get_env_int("PORT"), 8080)

func test_literal_single_quotes():
	ENV.clear()
	var file = FileAccess.open("user://test_literal.env", FileAccess.WRITE)
	file.store_line("VAR1=\"hello\\nworld\"")
	file.store_line("VAR2='hello\\nworld'")
	file.store_line("VAR3='$VAR1'")
	file.close()

	ENV.config("user://test_literal.env", true)

	assert_eq(String(ENV.get_env("VAR1")), "hello\nworld")
	assert_eq(String(ENV.get_env("VAR2")), "hello\\nworld")
	assert_eq(String(ENV.get_env("VAR3")), "$VAR1")

func test_has_env_file():
	ENV.clear()
	var base_file = FileAccess.open(".env", FileAccess.WRITE)
	base_file.store_line("A=1")
	base_file.close()
	ENV.load_env_file(".env", true)
	
	assert_true(ENV.has_env_file(".env"))
	assert_false(ENV.has_env_file("nonexistent.env"))

func test_type_casting():
	ENV.set_env("INT_VAR", "123")
	ENV.set_env("BOOL_VAR", "true")
	ENV.set_env("FLOAT_VAR", "45.67")
	
	ENV.set_env("FALSE_BOOL_1", "false")
	ENV.set_env("FALSE_BOOL_2", "no")
	ENV.set_env("FALSE_BOOL_3", "0")
	
	assert_eq(ENV.get_env_int("INT_VAR"), 123)
	assert_eq(ENV.get_env_bool("BOOL_VAR"), true)
	assert_almost_eq(ENV.get_env_float("FLOAT_VAR"), 45.67, 0.01)
	
	assert_false(ENV.get_env_bool("FALSE_BOOL_1"))
	assert_false(ENV.get_env_bool("FALSE_BOOL_2"))
	assert_false(ENV.get_env_bool("FALSE_BOOL_3"))

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

func test_advanced_interpolation_fallbacks():
	ENV.clear()
	var file = FileAccess.open("user://test_fallbacks.env", FileAccess.WRITE)
	file.store_line("EXISTING=Value")
	file.store_line("MISSING_FALLBACK=${NOT_EXIST:-Hello World}")
	file.store_line("EXIST_FALLBACK=${EXISTING:-Fallback}")
	file.store_line("ESCAPED_DOLLAR=\\$NOT_EXPANDED")
	file.close()
	ENV.config("user://test_fallbacks.env", true)
	
	assert_eq(String(ENV.get_env("MISSING_FALLBACK")), "Hello World")
	assert_eq(String(ENV.get_env("EXIST_FALLBACK")), "Value")
	assert_eq(String(ENV.get_env("ESCAPED_DOLLAR")), "$NOT_EXPANDED")

func test_structural_types_and_expansion():
	ENV.clear()
	var file = FileAccess.open("user://test_structs.env", FileAccess.WRITE)
	file.store_line("LIST=a, b, c")
	file.store_line("MAP={\"key\":\"value\"}")
	file.store_line("VERSION=1.0.0")
	file.close()

	ENV.config("user://test_structs.env", true)

	var arr = ENV.get_env_array("LIST")
	assert_eq(arr.size(), 3)
	assert_eq(arr[0], "a")
	assert_eq(arr[1], "b")
	assert_eq(arr[2], "c")

	var dict = ENV.get_env_dict("MAP")
	assert_true(dict.has("key"))
	assert_eq(String(dict["key"]), "value")

	var expanded = ENV.expand_string("Blazium ${VERSION:-0.0.0} deployed to $LIST")
	assert_eq(expanded, "Blazium 1.0.0 deployed to a, b, c")
    
	var missing = ENV.expand_string("Fallback: ${UNKNOWN:-MissingData}")
	assert_eq(missing, "Fallback: MissingData")

func test_os_priority_and_groups():
	ENV.clear()
	var file = FileAccess.open("user://test_ops.env", FileAccess.WRITE)
	file.store_line("APP_NAME=Blazium")
	file.store_line("APP_PORT=8080")
	file.store_line("SECRET=123")
	file.close()

	OS.set_environment("APP_PORT", "9000")
	ENV.config("user://test_ops.env", true)

	assert_eq(String(ENV.get_env("APP_PORT")), "9000")

	ENV.set_prioritize_os_env(false)
	assert_eq(String(ENV.get_env("APP_PORT")), "8080")
	
	ENV.set_prioritize_os_env(true)
	OS.unset_environment("APP_PORT")

	var group = ENV.get_env_group("APP_")
	assert_eq(group.size(), 2)
	assert_eq(String(group["APP_NAME"]), "Blazium")

func test_generate_example():
	ENV.clear()
	ENV.set_env("PRIVATE_KEY", "secret")
	ENV.set_env("PUBLIC_KEY", "open")
	ENV.generate_example("user://test_example.env")

	var file = FileAccess.open("user://test_example.env", FileAccess.READ)
	assert_not_null(file)
	var content = file.get_as_text()
	file.close()

	assert_true(content.contains("PRIVATE_KEY="))
	assert_true(content.contains("PUBLIC_KEY="))
	assert_false(content.contains("secret"))

func test_multiline_parsing():
	ENV.clear()
	var file = FileAccess.open("user://test_multiline.env", FileAccess.WRITE)
	file.store_string("MULTILINE=\"Line1\nLine2\nLine3\"\n")
	file.store_line("KEY2=Value2")
	file.close()

	ENV.config("user://test_multiline.env", true)
	var multi = String(ENV.get_env("MULTILINE"))
	assert_eq(multi, "Line1\nLine2\nLine3")
	assert_eq(String(ENV.get_env("KEY2")), "Value2")

func test_export_json_and_os_sync():
	ENV.clear()
	ENV.set_env("EXPORT1", "value1")
	ENV.export_json("user://test_export.json")
	var file = FileAccess.open("user://test_export.json", FileAccess.READ)
	assert_not_null(file)
	var content = JSON.parse_string(file.get_as_text())
	file.close()
	assert_eq(String(content["EXPORT1"]), "value1")
	
	ENV.set_env("TEMP_TARGET", "OS_TEST_VAL")
	ENV.push_to_os_env()
	var os_val = OS.get_environment("TEMP_TARGET")
	assert_eq(os_val, "OS_TEST_VAL")
	OS.unset_environment("TEMP_TARGET")

func test_auto_config_precedence():
	ENV.clear()
	var f1 = FileAccess.open("user://.env", FileAccess.WRITE)
	f1.store_line("APP_NAME=Base")
	f1.store_line("APP_PORT=8080")
	f1.close()

	var f2 = FileAccess.open("user://.env.local", FileAccess.WRITE)
	f2.store_line("APP_PORT=9090")
	f2.close()

	var f3 = FileAccess.open("user://.env.production", FileAccess.WRITE)
	f3.store_line("APP_URL=prod.blazium.app")
	f3.store_line("APP_NAME=ProdBase")
	f3.close()

	ENV.auto_config("user://", "production")

	# .env.production should override .env
	assert_eq(String(ENV.get_env("APP_NAME")), "ProdBase")
	# .env.local overrides .env
	assert_eq(String(ENV.get_env("APP_PORT")), "9090")
	# Brought from .env.production
	assert_eq(String(ENV.get_env("APP_URL")), "prod.blazium.app")

func test_require_envs():
	ENV.clear()
	ENV.set_env("REQ1", "val1")
	ENV.set_env("REQ2", "val2")

	assert_true(ENV.require_envs(["REQ1", "REQ2"]))
	assert_false(ENV.require_envs(["REQ1", "MISSING_KEY"]))

func test_save_functionality():
	ENV.clear()
	ENV.set_env("SAVED", "hello")
	ENV.set_env("NUMBER", "42")
	
	ENV.save("user://test_save.env")
	
	ENV.clear()
	
	ENV.config("user://test_save.env", true)
	assert_eq(String(ENV.get_env("SAVED")), "hello")
	assert_eq(ENV.get_env_int("NUMBER"), 42)
