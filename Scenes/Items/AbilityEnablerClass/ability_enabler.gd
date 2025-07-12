extends Area2D

class_name AbilityEnabler

@export var ability_type: String = "" # we export the ability type to inspector optional
									# every inherited scene of this will have a field to enter an ability type
									#we can either type it in the inspector or in script file

#this signal fire will be inherited to all subclasses of the AbilityEnabler
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		SignalBus.unlock_ability.emit(ability_type)
		queue_free()
