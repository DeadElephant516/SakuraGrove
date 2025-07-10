extends CharacterBody2D

class_name Player

@export var speed: float = 300.0
@export var jump_force: float = -500.0

var direction: Vector2 = Vector2.ZERO
var jumps_made: int = 0
var max_jumps: int = 2

const GRAVITY: float = 900.0


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	reset_jumps()
	get_input()
	move()
	handle_jump()
	move_and_slide()


func apply_gravity(delta:float) -> void:
	if !is_on_floor():
		velocity.y += GRAVITY * delta


func get_input() -> void:
	direction.x = Input.get_axis("left", "right")


func move() -> void:
	velocity.x = speed * direction.x


func reset_jumps() -> void:
	if is_on_floor():
		jumps_made = 0


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if PlayerData.can_double_jump:
			double_jump()
		else:
			jump()


func jump() -> void:
	if is_on_floor(): 
		velocity.y = jump_force


func double_jump() -> void:
	if jumps_made < max_jumps:
		velocity.y = jump_force
		jumps_made += 1
