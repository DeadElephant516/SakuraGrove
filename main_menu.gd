extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	var main_scene_path = "res://Scenes/TestScene/test_scene.tscn"
	get_tree().change_scene_to_file(main_scene_path)
  


func _on_settings_2_pressed() -> void:   #used for testing does buttons work
	print("Settings pressed")


func _on_credits_3_pressed() -> void:
	print("Credits pressed")


func _on_exit_4_pressed() -> void:
	get_tree().quit()
