extends Node

var can_double_jump: bool = false




### Helper functions above to manipulate the player data and flags ####

func _ready() -> void:
	SignalBus._enable_double_jump.connect(enable_double_jump)


func enable_double_jump() -> void:
	can_double_jump = true
