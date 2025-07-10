extends CharacterBody2D

class_name Player


@export var speed: float = 300.0
@export var jump_force: float = -500.0


var direction: Vector2 = Vector2.ZERO
var jumps_made: int = 0
var max_jumps: int = 2
var is_gliding: bool = false
var max_glide_time: float = PlayerData.max_glide_time
var remaining_glide_time: float = 0.0


const GRAVITY: float = 900.0
const GLIDE_GRAVITY: float = 200.0



func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	reset_jumps()
	get_input()
	move()
	handle_jump()
	glide(delta)
	move_and_slide()



func apply_gravity(delta:float) -> void:
	if !is_on_floor() and !is_gliding:
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



func glide(delta: float) -> void:
	if !is_on_floor() and PlayerData.can_glide:
		if Input.is_action_pressed("glide") and remaining_glide_time > 0.0:
			is_gliding = true
			velocity.y += GLIDE_GRAVITY * delta
			remaining_glide_time -= delta
		else:
			is_gliding = false
	else:
		is_gliding = false
		remaining_glide_time = max_glide_time
