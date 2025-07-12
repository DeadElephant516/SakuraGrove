extends CharacterBody2D

class_name EnemyBase

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var speed: float
const GRAVITY: float = 1200

func handle_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		die()

func die() -> void:
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_physics_process(true)
	set_process(true)
	print("enemy active")


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if global_position.distance_to(PlayerData.player_position) > 700:
		set_physics_process(false)
		set_process(false)
		print("enemies deactivated")


func _on_hit_box_area_entered(area: Area2D) -> void:
	handle_damage(area.damage)
	print(area.name, 'entered')
	area.queue_free()
