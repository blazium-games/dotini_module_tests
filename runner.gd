extends Autowork

func _ready():
    add_directory("res://")
    run_tests()
    get_tree().quit()
