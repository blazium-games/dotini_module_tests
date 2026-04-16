extends GutTest

func test_basic_parsing_and_types():
	var ini = DotIniFile.new()
	var content = """
	[Player]
	name="Hero"
	health=100.5
	position=Vector2(10, 20)
	inventory=["Sword", "Shield"]
	"""
	var err = ini.load_from_string(content, false)
	assert_eq(err, OK)
	assert_eq(ini.get_value_string("Player", "name"), "Hero")
	assert_eq(ini.get_value_float("Player", "health"), 100.5)
	
	var pos = ini.get_value("Player", "position")
	assert_eq(typeof(pos), TYPE_VECTOR2)
	assert_eq(pos, Vector2(10, 20))
	
	var inv = ini.get_value("Player", "inventory")
	assert_eq(typeof(inv), TYPE_ARRAY)
	assert_eq(inv.size(), 2)
	assert_eq(inv[0], "Sword")

func test_repeated_keys_arrays():
	var ini = DotIniFile.new()
	var content = """
	[Links]
	node=A
	node=B
	node=C
	"""
	ini.load_from_string(content, false)
	var arr = ini.get_value_array("Links", "node")
	assert_eq(arr.size(), 3)
	assert_eq(arr[0], "A")
	assert_eq(arr[1], "B")
	assert_eq(arr[2], "C")

func test_interpolations_and_macros():
	var ini = DotIniFile.new()
	ini.add_macro("VERSION", "2.0")
	var content = """
	[Config]
	app="SuperGame"
	path="C:/Apps/%(app)s/"
	version=%(MACRO:VERSION)s
	"""
	ini.load_from_string(content, false)
	assert_eq(ini.get_value_string("Config", "path"), "C:/Apps/SuperGame/")
	assert_eq(ini.get_value_string("Config", "version"), "2.0")

func test_schema_constraints():
	var ini = DotIniFile.new()
	ini.add_type_constraint("Data", "score", TYPE_INT)
	ini.set_value("Data", "score", 500)
	assert_eq(ini.get_value_int("Data", "score"), 500)
	
	# Attempt an invalid assignment
	ini.set_value("Data", "score", "invalid string")
	# Value should remain 500 because the string assignment was dropped
	assert_eq(ini.get_value_int("Data", "score"), 500)

func test_immutability_read_only():
	var ini = DotIniFile.new()
	ini.load_from_string("[Lockout]\nkey=123", false)
	ini.set_read_only(true)
	ini.set_value("Lockout", "key", 999)
	ini.erase_section("Lockout")
	
	assert_eq(ini.get_value_int("Lockout", "key"), 123)
	assert_true(ini.has_section("Lockout"))

func test_base64_transmission():
	var ini = DotIniFile.new()
	ini.load_from_string("[Net]\nhost=\"127.0.0.1\"\nactive=true", false)
	var b64_payload = ini.save_to_base64()
	assert_true(b64_payload.length() > 0)
	
	var receiver = DotIniFile.new()
	var err = receiver.load_from_base64(b64_payload, false)
	assert_eq(err, OK)
	assert_eq(receiver.get_value_string("Net", "host"), "127.0.0.1")
	assert_true(receiver.get_value_bool("Net", "active"))

func test_wildcard_queries():
	var ini = DotIniFile.new()
	var content = """
	[Players]
	member_1_name="Alice"
	member_2_name="Bob"
	spectator="Eve"
	"""
	ini.load_from_string(content, false)
	var keys = ini.get_keys_matching("Players", "member_*_name")
	assert_eq(keys.size(), 2)
	assert_true(keys.has("member_1_name"))
	assert_true(keys.has("member_2_name"))
	assert_false(keys.has("spectator"))

func test_append_value():
	var ini = DotIniFile.new()
	ini.set_value("List", "item", "Apple")
	ini.append_value("List", "item", "Banana")
	ini.append_value("List", "item", "Orange")
	
	var arr = ini.get_value_array("List", "item")
	assert_eq(arr.size(), 3)
	assert_eq(arr[0], "Apple")
	assert_eq(arr[1], "Banana")
	assert_eq(arr[2], "Orange")

func test_rename_section():
	var ini = DotIniFile.new()
	ini.load_from_string("[Legacy]\nscore=50\n# User comment", false)
	ini.rename_section("Legacy", "Modern")
	
	assert_true(ini.has_section("Modern"))
	assert_false(ini.has_section("Legacy"))
	assert_eq(ini.get_value_int("Modern", "score"), 50)
	assert_true("Modern" in ini.save_to_string())

func test_rename_key():
	var ini = DotIniFile.new()
	ini.load_from_string("[Config]\nserver_ip=\"127.0.0.1\"", false)
	ini.rename_key("Config", "server_ip", "host")
	
	assert_true(ini.has_section_key("Config", "host"))
	assert_false(ini.has_section_key("Config", "server_ip"))
	assert_eq(ini.get_value_string("Config", "host"), "127.0.0.1")

func test_clear_section():
	var ini = DotIniFile.new()
	var content = """
	[Settings]
	# Some settings
	audio=true
	video=false
	"""
	ini.load_from_string(content, false)
	assert_eq(ini.get_section_keys("Settings").size(), 2)
	ini.clear_section("Settings")
	assert_true(ini.has_section("Settings")) # Section still exists
	assert_eq(ini.get_section_keys("Settings").size(), 0) # Keys are gone

func test_ensure_value():
	var ini = DotIniFile.new()
	var val = ini.ensure_value("Settings", "Resolution", "1920x1080")
	assert_eq(val, "1920x1080", "returns ensured default immediately")
	assert_eq(ini.get_value("Settings", "Resolution"), "1920x1080", "has inserted default into file")
	val = ini.ensure_value("Settings", "Resolution", "800x600")
	assert_eq(val, "1920x1080", "returns already existing value seamlessly")

func test_get_section_as_dict():
	var ini = DotIniFile.new()
	ini.set_value("User", "Name", "Alex")
	ini.set_value("User", "Age", 30)
	var d = ini.get_section_as_dict("User")
	assert_eq(d.size(), 2, "must dump 2 variables")
	assert_eq(d.Name, "Alex", "keeps variant string")
	assert_eq(d.Age, 30, "keeps variant int")

func test_sort_section_keys():
	var ini = DotIniFile.new()
	var content = "[Zodiac]\nVirgo=6\nAries=1\nTaurus=2"
	ini.load_from_string(content, false)
	assert_eq(ini.get_section_keys("Zodiac"), PackedStringArray(["Virgo", "Aries", "Taurus"]), "default insert layout")
	ini.sort_section_keys("Zodiac", true)
	assert_eq(ini.get_section_keys("Zodiac"), PackedStringArray(["Aries", "Taurus", "Virgo"]), "Lexicographically Native bounds")
	ini.sort_section_keys("Zodiac", false)
	assert_eq(ini.get_section_keys("Zodiac"), PackedStringArray(["Virgo", "Taurus", "Aries"]), "Descends natively")

func test_clone_isolation():
	var ini = DotIniFile.new()
	ini.set_value("Global", "Debug", false)
	var dup = ini.clone()
	dup.set_value("Global", "Debug", true)
	assert_false(ini.get_value("Global", "Debug"), "Source keeps internal isolation properly!")
	assert_true(dup.get_value("Global", "Debug"), "Duplicate sets memory cleanly")

func test_global_fallback():
	var fallback = DotIniFile.new()
	fallback.set_value("Root", "theme", "Dark")
	DotIniFile.set_global_fallback(fallback)
	var ini = DotIniFile.new()
	# Fallback resolution returns the variable if it's missing in the main object
	assert_eq(ini.get_value("Root", "theme"), "Dark")
	DotIniFile.set_global_fallback(null)

func test_comments():
	var ini = DotIniFile.new()
	ini.set_value("Graphics", "vsync", true)
	ini.set_section_comment("Graphics", "This section handles graphics")
	ini.set_key_comment("Graphics", "vsync", "Vertical sync switch")
	assert_eq(ini.get_section_comment("Graphics"), "This section handles graphics")
	assert_eq(ini.get_key_comment("Graphics", "vsync"), "Vertical sync switch")

func test_clear():
	var ini = DotIniFile.new()
	ini.set_value("A", "x", 1)
	assert_true(ini.has_section("A"))
	ini.clear()
	assert_false(ini.has_section("A"))

func test_merge_with():
	var ini_a = DotIniFile.new()
	ini_a.set_value("A", "x", 1)
	var ini_b = DotIniFile.new()
	ini_b.set_value("A", "y", 2)
	ini_b.set_value("A", "x", 9)
	
	ini_a.merge_with(ini_b, false)
	assert_eq(ini_a.get_value("A", "x"), 1, "Overwrite is false, should not overwrite x")
	assert_eq(ini_a.get_value("A", "y"), 2, "Should still add y")
	
	ini_a.merge_with(ini_b, true)
	assert_eq(ini_a.get_value("A", "x"), 9, "Overwrite is true, should overwrite x to 9")

func test_to_from_dictionary():
	var dict = {"Core": {"active": true, "threads": 4}}
	var ini = DotIniFile.new()
	ini.from_dictionary(dict)
	assert_eq(ini.get_value("Core", "threads"), 4)
	
	var out_dict = ini.to_dictionary()
	assert_true(out_dict.has("Core"))
	assert_eq(out_dict["Core"]["active"], true)

func test_value_b64():
	var ini = DotIniFile.new()
	ini.set_value_b64("Data", "payload", "Hello World")
	assert_eq(ini.get_value_b64("Data", "payload"), "Hello World", "decodes perfectly back to raw string")

func test_to_from_config_file():
	var cfg = ConfigFile.new()
	cfg.set_value("Engine", "fps", 60)
	var ini = DotIniFile.new()
	ini.from_config_file(cfg)
	assert_eq(ini.get_value("Engine", "fps"), 60)
	
	ini.set_value("Engine", "vsync", false)
	var out_cfg = ini.to_config_file()
	assert_eq(out_cfg.get_value("Engine", "vsync"), false)

func test_encrypted_file():
	var ini = DotIniFile.new()
	ini.set_value("Secret", "Token", "ABC123XYZ")
	var path = "user://temp_enc_test.ini"
	var err = ini.save_encrypted_pass(path, "my_strong_password")
	assert_eq(err, OK)
	
	var loader = DotIniFile.new()
	err = loader.load_encrypted_pass(path, "wrong_password", false)
	assert_ne(err, OK, "Should fail with wrong password")
	
	err = loader.load_encrypted_pass(path, "my_strong_password", false)
	assert_eq(err, OK, "Should load successfully")
	assert_eq(loader.get_value_string("Secret", "Token"), "ABC123XYZ")

func test_default_padding():
	var ini = DotIniFile.new()
	ini.set_default_padding("  ", " ", "", "  ")
	ini.set_value("A", "x", 1)
	var content = ini.save_to_string()
	assert_true("  x =1  " in content, "Outputs exact spacing defined globally")

func test_autosave_and_updates():
	var ini = DotIniFile.new()
	var path = "user://temp_autosave.ini"
	ini.load(path, false) # Use load to set file_path internally
	ini.set_autosave(true)
	ini.set_value("Auto", "save", true)
	# File should be saved automatically
	var file = FileAccess.open(path, FileAccess.READ)
	assert_true(file != null)
	var content = file.get_as_text() if file else ""
	assert_true("save=true" in content or "save = true" in content or "save=\"true\"" in content or "save=true" in content.replace(" ", ""))

func test_buffer_io():
	var ini = DotIniFile.new()
	ini.set_value("Buffer", "byte", 255)
	var buf = ini.save_to_buffer()
	assert_true(buf.size() > 0)
	
	var loader = DotIniFile.new()
	var err = loader.load_from_buffer(buf, false)
	assert_eq(err, OK)
	assert_eq(loader.get_value_int("Buffer", "byte"), 255)

func test_remove_constraints():
	var ini = DotIniFile.new()
	ini.add_type_constraint("Box", "size", TYPE_INT)
	ini.set_value("Box", "size", 10)
	ini.set_value("Box", "size", "Huge") # Refused
	assert_eq(ini.get_value_int("Box", "size"), 10)
	
	ini.remove_type_constraint("Box", "size")
	ini.set_value("Box", "size", "Huge") # Accepted
	assert_eq(ini.get_value_string("Box", "size"), "Huge")

func test_erase_section_key():
	var ini = DotIniFile.new()
	ini.set_value("T", "k1", 1)
	ini.set_value("T", "k2", 2)
	assert_true(ini.has_section_key("T", "k1"))
	ini.erase_section_key("T", "k1")
	assert_false(ini.has_section_key("T", "k1"))
	assert_true(ini.has_section_key("T", "k2"))

func test_get_sections_exact():
	var ini = DotIniFile.new()
	var content = "\n[A]\nk=1\n[A]\nk=2\n[B]\nj=3\n"
	ini.load_from_string(content, false)
	
	var secs = ini.get_sections()
	assert_eq(secs.size(), 2)
	assert_true(secs.has("A"))
	assert_true(secs.has("B"))
	
	var a_keys = ini.get_section_keys("A")
	assert_eq(a_keys.size(), 1, "Should correctly merge keys inside get_section_keys")
	assert_eq(a_keys[0], "k")

func test_native_type_retrievers():
	var ini = DotIniFile.new()
	# Inject a raw INI with differing data types dynamically
	var content = "[Math]\npi=3.1415\nactive=true\ncount=42"
	ini.load_from_string(content, false)
	assert_almost_eq(ini.get_value_float("Math", "pi"), 3.1415, 0.001)
	assert_true(ini.get_value_bool("Math", "active"))
	assert_eq(ini.get_value_int("Math", "count"), 42)
	assert_eq(ini.get_value_raw("Math", "pi"), "3.1415", "should strictly return unmodified string regardless of mathematical variants parsing")
	
func test_save_all():
	var child_path = "user://temp_save_all_child.ini"
	var parent_path = "user://temp_save_all_parent.ini"
	
	# Create and save a valid child
	var child = DotIniFile.new()
	child.set_value("T", "x", 1)
	child.save(child_path)
	
	# Create and save a parent with an include
	var parent = DotIniFile.new()
	var parent_str = "#include \"temp_save_all_child.ini\"\n[Z]\nkey=val"
	parent.load_from_string(parent_str, false)
	parent.save(parent_path)
	
	# Load parent from disk to set file mappings correctly natively across the C++ tree
	var loaded_parent = DotIniFile.new()
	loaded_parent.load(parent_path, false)
	
	# Modify the include
	var includes = loaded_parent.get_included_files()
	assert_eq(includes.size(), 1, "Parent mapped the child accurately")
	includes[0].set_value("T", "x", 99)
	
	# Trigger recursive save bounds
	var err = loaded_parent.save_all()
	assert_eq(err, OK, "Recursive save correctly cascades files")
	
	# Reload child directly to verify mutation persisted across tree
	var validator = DotIniFile.new()
	validator.load(child_path, false)
	assert_eq(validator.get_value_int("T", "x"), 99, "Child modifications flushed to disk successfully")
	
func test_signals():
	var ini = DotIniFile.new()
	watch_signals(ini)
	ini.set_value("T", "k", 1)
	assert_signal_emitted(ini, "value_changed", "signals value_changed when dynamically setting values")
	
	ini.erase_section("T")
	assert_signal_emitted(ini, "section_erased", "signals section_erased when erasing section boundary")

func test_macros():
	var ini = DotIniFile.new()
	ini.add_macro("HOME", "/bin")
	assert_eq(ini.get_macro("HOME"), "/bin")
	ini.add_macro("USER", "alex")
	ini.set_value("Path", "dir", "%(MACRO:HOME)s/%(MACRO:USER)s")
	# Value should interpolate dynamically during retrieval
	assert_eq(ini.get_value_string("Path", "dir"), "/bin/alex")

func test_read_bounds():
	var ini = DotIniFile.new()
	ini.set_value("Sec", "k", 10)
	assert_true(ini.has_section("Sec"))
	assert_true(ini.has_section_key("Sec", "k"))
	
	ini.clear_section("Sec")
	assert_false(ini.has_section_key("Sec", "k"))
	assert_true(ini.has_section("Sec"))

func test_get_included_files():
	var child = DotIniFile.new()
	child.set_value("A", "x", 1)
	var child_path = "user://child_file.ini"
	child.save(child_path)
	
	var parent_content = "#include \"user://child_file.ini\"\n[B]\ny=2"
	var parent = DotIniFile.new()
	parent.load_from_string(parent_content, false)
	
	var includes = parent.get_included_files()
	assert_true(includes is Array, "API surface returns cleanly")
