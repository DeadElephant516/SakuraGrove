extends Control


@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var click_sfx: AudioStreamPlayer2D = $"click SFX"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _ready():
	main_buttons.visible = true
	options.visible = false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestScene/test_scene.tscn")
	click_sfx.play()


func _on_settings_2_pressed() -> void:
	print("settings pressed")
	main_buttons.visible = false
	options.visible = true
	click_sfx.play()


func _on_exit_3_pressed() -> void:
	get_tree().quit()
	click_sfx.play()


func _on_back_options_pressed() -> void:
	_ready()
	click_sfx.play()
