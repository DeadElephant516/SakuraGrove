extends CharacterBody2D

class_name Enemy

# ------------------------------------------------------------------------------
# Enemy AI with Finite State Machine (FSM)
#
# States:
#  - IDLE     : Standing still, looking for player
#  - PATROL   : Moving back and forth on platform
#  - CHASE    : Following the player
#  - ATTACK   : Close to player, attacking
#  - STUNNED  : Temporarily disabled after taking damage
# ------------------------------------------------------------------------------

# -- Basic Properties --
@export var health: int = 3
@export var max_health: int = 3
@export var patrol_speed: float = 30.0
@export var chase_speed: float = 80.0
@export var attack_speed: float = 40.0

# -- AI Behavior --
@export var detection_range: float = 150.0
@export var attack_range: float = 40.0
@export var patrol_distance: float = 100.0
@export var chase_time_limit: float = 5.0  # Stop chasing after this time

# -- Finite State Machine --
enum State { IDLE, PATROL, CHASE, ATTACK, STUNNED }
var current_state: State = State.IDLE
var state_timer: float = 0.0

# -- Movement --
var direction: int = 1  # 1 = right, -1 = left
var patrol_origin: Vector2
var patrol_left_bound: float
var patrol_right_bound: float

# -- Player Reference --
var player: Player = null
var last_player_position: Vector2
var chase_timer: float = 0.0

# -- Attack --
var attack_cooldown: float = 0.0
@export var attack_cooldown_time: float = 1.5
@export var attack_damage: int = 1

# -- Stun --
var stun_timer: float = 0.0
@export var stun_duration: float = 1.0

# -- Gravity --
const GRAVITY: float = 980.0

# -- Visual Feedback --
var sprite: Sprite2D
var original_color: Color

# ------------------------------------------------------------------------------
# Godot Lifecycle
# ------------------------------------------------------------------------------

func _ready():
	add_to_group("enemies")
	
	# Set up patrol bounds
	patrol_origin = global_position
	patrol_left_bound = patrol_origin.x - patrol_distance
	patrol_right_bound = patrol_origin.x + patrol_distance
	
	# Get sprite for visual feedback
	sprite = get_node("Sprite2D") if has_node("Sprite2D") else null
	if sprite:
		original_color = sprite.modulate
	
	# Find player
	find_player()
	
	# Start in PATROL state
	change_state(State.PATROL)

func _physics_process(delta: float):
	# Update timers
	state_timer += delta
	attack_cooldown = max(attack_cooldown - delta, 0.0)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Update AI state
	update_states(delta)
	
	# Move the enemy
	move_and_slide()
	
	# Handle edge detection for patrol
	handle_edges()

# ------------------------------------------------------------------------------
# FSM Core Logic
# ------------------------------------------------------------------------------

func change_state(new_state: State) -> void:
	"""
	Changes to a new state and handles entry logic.
	"""
	if current_state == new_state:
		return
	
	# Exit current state
	exit_state(current_state)
	
	# Enter new state
	current_state = new_state
	state_timer = 0.0
	enter_state(new_state)
	
	print("Enemy State: ", State.keys()[current_state])

func enter_state(state: State) -> void:
	"""
	Handles one-time logic when entering a state.
	"""
	match state:
		State.IDLE:
			velocity.x = 0
		
		State.PATROL:
			# Choose random direction if at origin
			if abs(global_position.x - patrol_origin.x) < 10:
				direction = 1 if randf() > 0.5 else -1
		
		State.CHASE:
			chase_timer = chase_time_limit
			if sprite:
				sprite.modulate = Color.ORANGE  # Visual indicator
		
		State.ATTACK:
			velocity.x = 0
			if sprite:
				sprite.modulate = Color.RED  # Visual indicator
		
		State.STUNNED:
			velocity.x = 0
			stun_timer = stun_duration
			if sprite:
				sprite.modulate = Color.BLUE  # Visual indicator

func exit_state(state: State) -> void:
	"""
	Handles cleanup when leaving a state.
	"""
	match state:
		State.CHASE, State.ATTACK, State.STUNNED:
			if sprite:
				sprite.modulate = original_color

func update_states(delta: float) -> void:
	"""
	Updates the current state and handles transitions.
	"""
	match current_state:
		State.IDLE:
			update_idle_state(delta)
		
		State.PATROL:
			update_patrol_state(delta)
		
		State.CHASE:
			update_chase_state(delta)
		
		State.ATTACK:
			update_attack_state(delta)
		
		State.STUNNED:
			update_stunned_state(delta)

func update_idle_state(delta: float) -> void:
	"""
	IDLE: Look for player, transition to patrol after delay.
	"""
	velocity.x = 0
	
	# Look for player
	if can_see_player():
		change_state(State.CHASE)
		return
	
	# After 2 seconds, start patrolling
	if state_timer > 2.0:
		change_state(State.PATROL)

func update_patrol_state(delta: float) -> void:
	"""
	PATROL: Move back and forth, look for player.
	"""
	# Move in current direction
	velocity.x = patrol_speed * direction
	
	# Check if we've reached patrol bounds
	if global_position.x <= patrol_left_bound and direction == -1:
		direction = 1
	elif global_position.x >= patrol_right_bound and direction == 1:
		direction = -1
	
	# Look for player
	if can_see_player():
		change_state(State.CHASE)

func update_chase_state(delta: float) -> void:
	"""
	CHASE: Follow the player aggressively.
	"""
	chase_timer -= delta
	
	# Stop chasing if timer runs out
	if chase_timer <= 0.0:
		change_state(State.PATROL)
		return
	
	# Stop chasing if player is too far
	if not can_see_player():
		change_state(State.PATROL)
		return
	
	# Move towards player
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Switch to attack if close enough
		if distance_to_player <= attack_range:
			change_state(State.ATTACK)
			return
		
		# Move towards player
		var direction_to_player = sign(player.global_position.x - global_position.x)
		velocity.x = chase_speed * direction_to_player
		
		# Update facing direction
		direction = int(direction_to_player)

func update_attack_state(delta: float) -> void:
	"""
	ATTACK: Attack the player when in range.
	"""
	velocity.x = 0
	
	if not player:
		change_state(State.PATROL)
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# If player moved away, chase them
	if distance_to_player > attack_range:
		change_state(State.CHASE)
		return
	
	# Attack if cooldown is ready
	if attack_cooldown <= 0.0:
		perform_attack()
		attack_cooldown = attack_cooldown_time

func update_stunned_state(delta: float) -> void:
	"""
	STUNNED: Temporarily disabled, can't move or attack.
	"""
	velocity.x = 0
	stun_timer -= delta
	
	if stun_timer <= 0.0:
		change_state(State.IDLE)

# ------------------------------------------------------------------------------
# AI Helper Functions
# ------------------------------------------------------------------------------

func find_player() -> void:
	"""
	Finds the player node in the scene.
	"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func can_see_player() -> bool:
	"""
	Returns true if player is within detection range.
	"""
	if not player:
		return false
	
	var distance = global_position.distance_to(player.global_position)
	return distance <= detection_range

func perform_attack() -> void:
	"""
	Performs an attack on the player.
	"""
	if not player:
		return
	
	print("Enemy attacks player!")
	
	# Here you can add attack logic:
	# - Deal damage to player
	# - Apply knockback
	# - Play attack animation/sound
	# - Create attack effects
	
	# Example: Apply knockback to player
	var knockback_direction = sign(player.global_position.x - global_position.x)
	if knockback_direction == 0:
		knockback_direction = 1
	
	# You would call a player method like:
	# player.take_damage(attack_damage, Vector2(knockback_direction * 200, -100))

func handle_edges() -> void:
	"""
	Prevents enemy from falling off edges during patrol.
	"""
	if current_state == State.PATROL:
		# Check if we're about to fall off an edge
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + Vector2(direction * 40, 50)
		)
		var result = space_state.intersect_ray(query)
		
		# If no ground ahead, turn around
		if result.is_empty():
			direction = -direction

# ------------------------------------------------------------------------------
# Damage System
# ------------------------------------------------------------------------------

func take_damage(damage: int, knockback: Vector2 = Vector2.ZERO) -> void:
	"""
	Called when enemy takes damage from player attacks.
	"""
	if current_state == State.STUNNED:
		return  # Can't take damage while stunned
	
	health -= damage
	print("Enemy took ", damage, " damage! Health: ", health)
	
	# Apply knockback
	if knockback != Vector2.ZERO:
		velocity += knockback
	
	# Visual feedback
	flash_damage()
	
	# Stun the enemy briefly
	change_state(State.STUNNED)
	
	# Die if health reaches 0
	if health <= 0:
		die()

func flash_damage() -> void:
	"""
	Creates a brief flash effect when taking damage.
	"""
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite, "modulate", original_color, 0.1)

func die() -> void:
	"""
	Handles enemy death.
	"""
	print("Enemy died!")
	
	# Add death effects here:
	# - Play death animation
	# - Spawn particles
	# - Play death sound
	# - Give player points/experience
	# - Drop items
	
	queue_free()

func can_be_jumped_on() -> bool:
	"""
	Returns true if player can jump on this enemy.
	"""
	return current_state != State.STUNNED