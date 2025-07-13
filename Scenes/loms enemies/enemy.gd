extends CharacterBody2D

class_name Enemy

# Export variables for tuning
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 80.0
@export var patrol_range: float = 100.0
@export var wait_time: float = 1.0
@export var detection_range: float = 80.0
@export var stun_duration: float = 1.0
@export var knockback_force: float = 300.0

# Raycast offset for edge/wall checks
const RAYCAST_OFFSET: float = 15.0
const GRAVITY: float = 900.0

# FSM States
enum State { PATROL, CHASE, STUN, WAIT, TURN }
var current_state: State = State.PATROL

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var ground_raycast: RayCast2D = $GroundRaycast
@onready var wall_raycast: RayCast2D = $WallRaycast
@onready var player_detection: Area2D = $PlayerDetection

# Movement & State variables
var direction: int = 1
var origin_position: Vector2
var wait_timer: float = 0.0
var stun_timer: float = 0.0

# Player detection
var player_ref: Player = null
var player_detected: bool = false

func _ready() -> void:
	origin_position = global_position

	ground_raycast.position.x = RAYCAST_OFFSET * direction
	wall_raycast.position.x = RAYCAST_OFFSET * direction

	player_ref = get_tree().get_first_node_in_group("player") as Player
	player_detection.body_entered.connect(_on_player_entered)
	player_detection.body_exited.connect(_on_player_exited)

	# Set enemy to be on both layer 2 and 3
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, true)
	
	# Set what the enemy can collide with (usually ground/walls on layer 1)
	set_collision_mask_value(1, true)
	
	print("Enemy initialized at position: ", global_position)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	update_state_machine(delta)
	move_and_slide()
	update_sprite_direction()

	if global_position.y > get_viewport_rect().size.y + 100:
		reset_to_origin()

func update_state_machine(delta: float) -> void:
	match current_state:
		State.PATROL:
			handle_patrol()
		State.CHASE:
			handle_chase()
		State.WAIT:
			handle_wait(delta)
		State.STUN:
			handle_stun(delta)
		State.TURN:
			pass

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state

	match new_state:
		State.WAIT:
			wait_timer = wait_time
			velocity.x = 0
		State.STUN:
			stun_timer = stun_duration
			velocity.x = 0
			flash_red()
		State.TURN:
			switch_direction()
			change_state(State.WAIT)
	
	print("Enemy state: %s -> %s" % [State.keys()[old_state], State.keys()[new_state]])

func handle_patrol() -> void:
	if player_detected and player_ref:
		change_state(State.CHASE)
		return

	if should_turn_around():
		change_state(State.TURN)
		return

	velocity.x = patrol_speed * direction

func handle_chase() -> void:
	if not player_detected or not player_ref:
		change_state(State.PATROL)
		return

	var player_direction = sign(player_ref.global_position.x - global_position.x)

	if should_turn_around():
		change_state(State.TURN)
		return

	velocity.x = chase_speed * player_direction
	direction = int(player_direction)

func handle_wait(delta: float) -> void:
	wait_timer -= delta
	velocity.x = move_toward(velocity.x, 0, patrol_speed * 2 * delta)

	if wait_timer <= 0:
		var next_state = State.CHASE if player_detected else State.PATROL
		change_state(next_state)

func handle_stun(delta: float) -> void:
	stun_timer -= delta
	velocity.x = move_toward(velocity.x, 0, patrol_speed * 3 * delta)

	if stun_timer <= 0:
		change_state(State.PATROL)

func should_turn_around() -> bool:
	if wall_raycast.is_colliding():
		return true
	if is_at_platform_edge():
		return true
	if abs(global_position.x - origin_position.x) > patrol_range:
		return true
	return false

func is_at_platform_edge() -> bool:
	ground_raycast.position.x = RAYCAST_OFFSET * direction
	ground_raycast.force_raycast_update()
	return not ground_raycast.is_colliding()

func switch_direction() -> void:
	direction *= -1
	ground_raycast.position.x = RAYCAST_OFFSET * direction
	wall_raycast.position.x = RAYCAST_OFFSET * direction

func update_sprite_direction() -> void:
	if sprite:
		sprite.flip_h = direction < 0

func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		player_detected = true
		player_ref = body
		print("Player detected!")

func _on_player_exited(body: Node2D) -> void:
	if body is Player:
		player_detected = false
		print("Player lost!")

func take_damage(damage_amount: int = 1, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.STUN:
		return

	print("Enemy took damage!")

	if knockback_dir != Vector2.ZERO:
		velocity += knockback_dir * knockback_force

	change_state(State.STUN)

func can_be_jumped_on() -> bool:
	return current_state != State.STUN

func flash_red() -> void:
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

# ------------------------------------------------------------------------------
# Step 6: Utility Functions
# ------------------------------------------------------------------------------

func reset_to_origin() -> void:
	"""
	Resets enemy to its starting position and state.
	Useful for when enemy falls off the world or gets stuck.
	"""
	global_position = origin_position
	velocity = Vector2.ZERO
	change_state(State.PATROL)
	print("Enemy reset to origin")

func get_distance_to_player() -> float:
	"""
	Returns the distance between enemy and player.
	Returns INF if no player reference exists.
	"""
	if player_ref:
		return global_position.distance_to(player_ref.global_position)
	return INF

func is_player_above() -> bool:
	"""
	Checks if player is positioned above the enemy.
	Useful for jump-on detection and AI decisions.
	"""
	if player_ref:
		return player_ref.global_position.y < global_position.y - 10
	return false

func get_debug_info() -> String:
	"""
	Returns a formatted debug string with current enemy state info.
	Useful for on-screen debugging or console output.
	"""
	return "State: %s | Dir: %d | Player: %s" % [
		State.keys()[current_state],
		direction,
		"Detected" if player_detected else "Lost"
	]
