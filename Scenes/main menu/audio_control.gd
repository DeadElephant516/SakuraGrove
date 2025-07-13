extends HSlider

@export var audio_bus_name: String

var audio_bus_id: int = -1

func _ready():
	# Remove 'var' to assign to instance variable, not create local variable
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	
	# Error checking - make sure the bus exists
	if audio_bus_id == -1:
		print("Error: Audio bus '", audio_bus_name, "' not found!")
		return
	
	# Set slider to current volume
	var current_volume = AudioServer.get_bus_volume_db(audio_bus_id)
	set_value_no_signal(current_volume)

func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	# Check if bus is valid before setting volume
	if audio_bus_id != -1:
		AudioServer.set_bus_volume_db(audio_bus_id, db)
	else:
		print("Cannot set volume: Invalid audio bus")
