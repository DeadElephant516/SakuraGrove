extends Node2D

@export var duration := 0.4
@export var lifetime: float = 1.0  # Beam lasts 1 seconds

func _ready():
	$Timer.wait_time = duration
	$Timer.start()
	$Area2D.body_entered.connect(_on_body_entered)
	
	# Create a timer to destroy the beam
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()

func _on_body_entered(body):
	if body.has_method("purify"):
		body.purify()
	elif body.has_method("take_damage"):
		body.take_damage(9999)  # Or apply any effect

func _on_Timer_timeout():
	queue_free()

func _on_lifetime_timeout():
	queue_free()  # Destroy the beam after lifetime expires
