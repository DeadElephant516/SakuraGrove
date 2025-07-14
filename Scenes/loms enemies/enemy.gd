extends CharacterBody2D
class_name Enemy

# Movement settings
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 100.0
@export var patrol_distance: float = 150.0
@export var detection_radius: float = 200.0  # Increased detection radius
@export var chase_threshold: float = 50.0    # Distance to start chasing
@export var attack_range: float = 30.0       # Distance to perform attacks
@export var jump_force: float = 300.0
@export var stun_time: float = 1.0

# Combat settings
@export var attack_cooldown: float = 1.0
@export var damage: int = 1
@export var health: int = 3

# Physics
const GRAVITY: float = 980.0
const MAX_FALL_SPEED: float = 500.0

# AI State
enum AIState { IDLE, PATROL_RIGHT, PATROL_LEFT, CHASE, ATTACK, RETREAT, STUNNED, SEARCH }
var current_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var attack_timer: float = 0.0
var last_seen_position: Vector2 = Vector2.ZERO
var search_time: float = 3.0
var search_radius: float = 100.0

# References
@onready var sprite = $Sprite2D
@onready var vision_area = $VisionArea
@onready var floor_detector = $FloorDetector
@onready var wall_detector = $WallDetector

# Variables
var spawn_position: Vector2
var player: Node2D = null
var player_in_vision: bool = false
var facing_right: bool = true
var patrol_target: Vector2
var can_attack: bool = true
var search_direction: int = 1

# Debug
@export var debug_enabled: bool = true

func _ready():
	spawn_position = global_position
	patrol_target = spawn_position + Vector2(patrol_distance, 0)

	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_entered)
		vision_area.body_exited.connect(_on_vision_area_exited)
	else:
		print("VisionArea node missing!")

	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player = players[0]
	else:
		print("No player in 'players' group!")

	change_state(AIState.PATROL_RIGHT)

func _physics_process(delta):
	apply_gravity(delta)
	update_ai(delta)
	update_facing_direction()
	move_and_slide()

	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	else:
		can_attack = true

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	else:
		velocity.y = 0

func update_ai(delta):
	var distance_to_player = INF
	if player:
		distance_to_player = global_position.distance_to(player.global_position)

	match current_state:
		AIState.IDLE:
			handle_idle(distance_to_player)
		AIState.PATROL_RIGHT:
			handle_patrol_right(distance_to_player)
		AIState.PATROL_LEFT:
			handle_patrol_left(distance_to_player)
		AIState.CHASE:
			handle_chase(distance_to_player)
		AIState.ATTACK:
			handle_attack()
		AIState.RETREAT:
			handle_retreat()
		AIState.STUNNED:
			handle_stunned()
		AIState.SEARCH:
			handle_search(delta)

func handle_idle(distance: float):
	velocity.x = 0
	if player_in_vision and distance < detection_radius:
		last_seen_position = player.global_position
		change_state(AIState.CHASE)
	elif state_timer > 2.0:
		change_state(AIState.PATROL_RIGHT)

func handle_patrol_right(distance: float):
	if player_in_vision and distance < detection_radius:
		last_seen_position = player.global_position
		change_state(AIState.CHASE)
		return

	velocity.x = patrol_speed
	if global_position.x >= spawn_position.x + patrol_distance:
		change_state(AIState.PATROL_LEFT)

	if wall_detector and wall_detector.is_colliding() and is_on_floor():
		velocity.y = -jump_force

func handle_patrol_left(distance: float):
	if player_in_vision and distance < detection_radius:
		last_seen_position = player.global_position
		change_state(AIState.CHASE)
		return

	velocity.x = -patrol_speed
	if global_position.x <= spawn_position.x - patrol_distance:
		change_state(AIState.PATROL_RIGHT)

	if wall_detector and wall_detector.is_colliding() and is_on_floor():
		velocity.y = -jump_force

func handle_chase(distance: float):
	if not player:
		change_state(AIState.PATROL_RIGHT)
		return

	if not player_in_vision:
		last_seen_position = player.global_position
		change_state(AIState.SEARCH)
		return

	if distance < attack_range and can_attack:
		change_state(AIState.ATTACK)
		return

	if distance > detection_radius * 1.5:
		change_state(AIState.RETREAT)
		return

	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * chase_speed

	if is_on_floor():
		if player.global_position.y < global_position.y - 20 or (wall_detector and wall_detector.is_colliding()):
			velocity.y = -jump_force

func handle_attack():
	velocity.x = 0
	if can_attack:
		perform_attack()
		can_attack = false
		attack_timer = attack_cooldown
		change_state(AIState.CHASE)

func handle_retreat():
	var direction = (spawn_position - global_position).normalized()
	velocity.x = direction.x * patrol_speed
	if global_position.distance_to(spawn_position) < 20:
		change_state(AIState.IDLE)

func handle_stunned():
	velocity.x = 0
	if state_timer > stun_time:
		change_state(AIState.IDLE)

func handle_search(delta):
	state_timer -= delta
	velocity.x = search_direction * patrol_speed * 0.5
	if state_timer <= 0:
		search_direction *= -1
		state_timer = search_time
	if player_in_vision:
		change_state(AIState.CHASE)
	elif global_position.distance_to(last_seen_position) > search_radius:
		change_state(AIState.RETREAT)

func perform_attack():
	if debug_enabled:
		print("Enemy attacking!")
	# Implement actual attack logic here

func change_state(new_state: AIState):
	if current_state != new_state:
		if debug_enabled:
			print("State change:", AIState.keys()[current_state], "->", AIState.keys()[new_state])
		current_state = new_state
		state_timer = 0

func update_facing_direction():
	if velocity.x > 0 and not facing_right:
		sprite.flip_h = false
		facing_right = true
	elif velocity.x < 0 and facing_right:
		sprite.flip_h = true
		facing_right = false

func _on_vision_area_entered(body):
	if body.is_in_group("players"):
		player = body
		player_in_vision = true
		if debug_enabled:
			print("Player entered vision")

func _on_vision_area_exited(body):
	if body == player:
		player_in_vision = false
		if debug_enabled:
			print("Player exited vision")

func take_damage(amount: int, knockback: Vector2):
	health -= amount
	velocity += knockback
	change_state(AIState.STUNNED)
	if health <= 0:
		queue_free()

func can_be_jumped_on() -> bool:
	return true
