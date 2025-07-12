extends CharacterBody2D

class_name Player

var speed: float
var jump_force: float

var dash_speed: float 
var dash_duration: float

@export var dash_cooldown: float = 0.5


var direction: Vector2 = Vector2.ZERO
var jumps_made: int = 0
var max_jumps: int = 2
var is_gliding: bool = false
var max_glide_time: float = PlayerData.max_glide_time
var remaining_glide_time: float = 0.0

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_timer: float = 0.0


const GRAVITY: float = 900.0
const GLIDE_GRAVITY: float = 200.0


func _ready() -> void:
	initialize_values()


func _physics_process(delta: float) -> void:

	get_input()

	if !is_dashing:
		apply_gravity(delta)
		reset_jumps()
		move()
		handle_jump()
		glide(delta)
		
	dash(delta)
	
	move_and_slide()




func apply_gravity(delta: float) -> void:
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
	if is_on_floor() or !PlayerData.can_glide:
		is_gliding = false
		remaining_glide_time = max_glide_time
		return #RETURN EARLY IF WE ARE ALREADY GLIDING TO AVOID FURTHER CHECKS
	#APPLY GLIDE LOGIC
	
	if Input.is_action_pressed("glide") and remaining_glide_time > 0.0 and velocity.y > 0:
		is_gliding = true
		#Increase velocity.y by glide gravity, but don’t let it go over 100.
		velocity.y = min(velocity.y + GLIDE_GRAVITY * delta, 100.0)
		velocity.x = speed / 2 * direction.x
		remaining_glide_time -= delta
	else:
		is_gliding = false


func dash(delta: float) -> void:
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		return #RETURN EARLY IF WE ARE ALREADY DASHING TO AVOID FURTHER CHECKS
	
	 #Subtract delta from the cooldown timer, but never let it drop below 0.0."
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	#APPLY DASH LOGIC
	if PlayerData.can_dash:
		if Input.is_action_just_pressed("dash") and direction.x != 0 and dash_cooldown_timer <= 0.0:
			is_dashing = true
			dash_time_left = dash_duration
			velocity.x = dash_speed * direction.x
			velocity.y = 0




func initialize_values() -> void:
	speed = PlayerData.speed
	jump_force = PlayerData.jump_force
	max_glide_time = PlayerData.max_glide_time
	dash_speed = PlayerData.dash_speed
	dash_duration = PlayerData.dash_duration
