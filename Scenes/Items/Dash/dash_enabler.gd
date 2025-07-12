extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		SignalBus._enable_double_jump.emit()
		queue_free()
