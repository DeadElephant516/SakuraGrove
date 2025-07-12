extends Node

var speed:float = 300.0
var jump_force: float = -500.0
var can_double_jump: bool = false
var can_glide: bool = false
var max_glide_time: float = 2.0
var can_dash: bool = false
var dash_speed: float = 800.0
var dash_duration: float = 0.2



### Helper functions above to manipulate the player data and flags ####

func _ready() -> void:
	SignalBus.unlock_ability.connect(_on_unlock_ability)

#WE MACH THE ABILITY TYPE ARGUMENT THAT THE SIGNAL WILL GIVES US TO HANDLE OUR FLAGS
func _on_unlock_ability(ability_type: String) -> void:
	match ability_type:
		"double_jump": can_double_jump = true
		"glide": can_glide = true
		"dash": can_dash = true
