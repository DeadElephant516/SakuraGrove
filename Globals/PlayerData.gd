extends Node

var can_double_jump: bool = false
var can_glide: bool = false



### Helper functions above to manipulate the player data and flags ####

func _ready() -> void:
	SignalBus._enable_double_jump.connect(enable_double_jump)
	SignalBus._enable_glide.connect(enable_glide)


func enable_double_jump() -> void:
	can_double_jump = true


func enable_glide() -> void:
	can_glide = true
