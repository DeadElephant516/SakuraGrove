extends CharacterBody2D
class_name Player

@export var speed: float = 300.0
@export var jump_force: float = -500.0
@export var wall_jump_force: Vector2 = Vector2(400, -500)
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
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
var is_touching_wall: bool = false
var wall_direction: int = 0 # -1 = left wall, 1 = right wall
var last_wall_jump: bool = false  # To prevent infinite wall jumps

const GRAVITY: float = 900.0
const GLIDE_GRAVITY: float = 200.0

func _physics_process(delta: float) -> void:
	check_wall_contact()

	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
	else:
		if dash_cooldown_timer > 0.0:
			dash_cooldown_timer -= delta

	apply_gravity(delta)
	reset_jumps()
	get_input()

	if !is_dashing:
		move()

	handle_jump()
	glide(delta)
	move_and_slide()

	# Reset wall jump flag when on floor
	if is_on_floor():
		last_wall_jump = false

func apply_gravity(delta: float) -> void:
	if !is_on_floor() and !is_gliding:
		velocity.y += GRAVITY * delta

func get_input() -> void:
	direction.x = Input.get_axis("left", "right")
	if Input.is_action_just_pressed("dash") and !is_dashing and dash_cooldown_timer <= 0.0:
		if direction.x != 0:
			dash()

func move() -> void:
	velocity.x = speed * direction.x

func reset_jumps() -> void:
	if is_on_floor():
		jumps_made = 0

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if is_touching_wall and not last_wall_jump:
			wall_side_jump()
		elif PlayerData.can_double_jump:
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
		if Input.is_action_pressed("glide") and remaining_glide_time > 0.0 and velocity.y > 50:
			is_gliding = true
			velocity.y += GLIDE_GRAVITY * delta
			remaining_glide_time -= delta
			if velocity.y > 100:
				velocity.y = 100
		else:
			is_gliding = false
	else:
		is_gliding = false
		remaining_glide_time = max_glide_time

func dash() -> void:
	is_dashing = true
	dash_time_left = dash_duration
	velocity.x = dash_speed * direction.x
	velocity.y = 0  # Optional: flatten vertical movement during dash

func check_wall_contact() -> void:
	is_touching_wall = false
	wall_direction = 0
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision and collision.get_collider():
			var normal = collision.get_normal()
			if abs(normal.x) > 0.5:
				is_touching_wall = true
				wall_direction = -sign(normal.x)  # Wall on right = -1, left = 1

func wall_side_jump() -> void:
	# Force jump away from wall to opposite direction
	velocity.x = wall_jump_force.x * -wall_direction
	velocity.y = wall_jump_force.y
	last_wall_jump = true
	is_touching_wall = false
	jumps_made += 1  # Optional, count wall jump as jump
