extends CharacterBody2D

class_name Player

# ------------------------------------------------------------------------------
# Player Movement Controller with Finite State Machine (FSM)
#
# States:
#  - IDLE  : Standing still
#  - WALK  : Moving horizontally
#  - JUMP  : Initial jump or double jump
#  - GLIDE : Slow-fall/glide after jump
#  - DASH  : Quick burst horizontal movement
# ------------------------------------------------------------------------------

# -- Movement ------------------------------------------------------------
# Base horizontal movement speed
var speed: float
# Upward impulse strength for jump
var jump_force: float
# Input direction: -1 (left), 0 (none), +1 (right)
var direction: Vector2 = Vector2.ZERO

# -- Jumping -------------------------------------------------------------
# Tracks how many jumps have been used (for double jump)
var jumps_made: int = 0
# Maximum allowed jumps in air (1 = single jump, 2 = double jump)
var max_jumps: int = 2

# -- Gliding -------------------------------------------------------------
# Whether the player is actively gliding
var is_gliding: bool = false
# Total allowed glide duration (seconds)
var max_glide_time: float = PlayerData.max_glide_time
# Remaining glide time left
var remaining_glide_time: float = 0.0
# Gravity applied while gliding (slower fall)
const GLIDE_GRAVITY: float = 200.0

# -- Dashing -------------------------------------------------------------
# Whether the player is currently dashing
var is_dashing: bool = false
# Dash speed multiplier
var dash_speed: float
# Duration of dash in seconds
var dash_duration: float
# Time left in the current dash
var dash_time_left: float = 0.0
# Countdown before next dash allowed
var dash_cooldown_timer: float = 0.0
# Configurable cooldown between dashes
@export var dash_cooldown: float = 0.5

# -- Gravity -------------------------------------------------------------
# Normal gravity acceleration
const GRAVITY: float = 900.0

# -- Finite State Machine (FSM) ------------------------------------------
# Define possible player states
enum State { IDLE, WALK, JUMP, GLIDE, DASH }
# Current active state (starts as IDLE)
var current_state: State = State.IDLE

# ------------------------------------------------------------------------------
# Godot Lifecycle Hooks
# ------------------------------------------------------------------------------

func _ready() -> void:
	"""
	Called when the node is added to the scene.
	Initializes all player-related values from PlayerData.
	"""
	initialize_values()

func _physics_process(delta: float) -> void:
	"""
	Called each physics frame (~60 FPS).
	Handles input, cooldowns, gravity, state updates, and movement.
	"""
	# 1. Read horizontal input axes
	get_input()

	# 2. Decrease dash cooldown timer regardless of state
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	# 3. Apply gravity (unless grounded, gliding, or dashing)
	apply_gravity(delta)

	# 4. Reset jump counter when grounded
	reset_jumps()

	# 5. Update current FSM state (checks transitions & actions)
	update_states(delta)

	# 6. Move the character according to velocity
	move_and_slide()

# ------------------------------------------------------------------------------
# FSM Core: State Switching Logic
# ------------------------------------------------------------------------------

func change_state(new_state: State) -> void:
	"""
	Switches FSM to 'new_state' if different from current.
	Handles one-time entry logic (e.g. starting glide).
	"""
	if current_state == new_state:
		return  # No change if already in this state

	current_state = new_state

	# On entering GLIDE, ensure upward velocity won't carry us up
	if new_state == State.GLIDE:
		if velocity.y < 0:
			# Cancel any upward motion
			velocity.y = 0
		is_gliding = true
	else:
		# Exiting glide state
		is_gliding = false

	print("State:", State.keys()[current_state])

func update_states(delta: float) -> void:
	"""
	Called every _physics_process to evaluate and execute
	behavior for the current state, and transition when needed.
	"""
	match current_state:
		State.IDLE:
			# --- IDLE State: waiting for input ---
			if Input.is_action_just_pressed("jump") and is_on_floor():
				jump()
				change_state(State.JUMP)
			elif Input.is_action_just_pressed("dash") and can_dash():
				start_dash()
				change_state(State.DASH)
			elif direction.x != 0:
				change_state(State.WALK)

		State.WALK:
			# --- WALK State: horizontal movement ---
			move()
			if Input.is_action_just_pressed("jump") and is_on_floor():
				jump()
				change_state(State.JUMP)
			elif Input.is_action_just_pressed("dash") and can_dash():
				start_dash()
				change_state(State.DASH)
			elif direction.x == 0:
				change_state(State.IDLE)

		State.JUMP:
			# --- JUMP State: airborne, can double jump/glide/dash ---
			move()
			# Landing check: reset glide and go to IDLE
			if is_on_floor():
				remaining_glide_time = max_glide_time
				is_gliding = false
				change_state(State.IDLE)
				return

			# Double jump: if allowed and presses jump again
			if PlayerData.can_double_jump and Input.is_action_just_pressed("jump") and jumps_made < max_jumps:
				double_jump()
				return

			# Glide: if falling and holding glide key
			if can_glide() and velocity.y > 0 and Input.is_action_pressed("glide"):
				change_state(State.GLIDE)
				return

			# Dash: if pressing dash mid-air
			if Input.is_action_just_pressed("dash") and can_dash():
				start_dash()
				change_state(State.DASH)
				return

		State.GLIDE:
			# --- GLIDE State: slow fall and horizontal control ---
			glide(delta)
			# End glide when landing or out of time
			if is_on_floor() or remaining_glide_time <= 0:
				change_state(State.IDLE)

		State.DASH:
			# --- DASH State: burst movement, then return ---
			dash(delta)
			# Once dash completes, transition based on grounded
			if not is_dashing:
				var next = State.IDLE if is_on_floor() else State.JUMP
				change_state(next)

# ------------------------------------------------------------------------------
# Core Movement Helpers
# ------------------------------------------------------------------------------

func get_input() -> void:
	"""
	Reads left/right input and sets 'direction.x'.
	Uses InputMap actions 'left' and 'right'.
	"""
	direction.x = Input.get_axis("left", "right")
	if direction.x < 0.0:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false

func move() -> void:
	"""
	Applies horizontal movement based on 'speed' and 'direction'.
	"""
	velocity.x = speed * direction.x

func apply_gravity(delta: float) -> void:
	"""
	Applies downward acceleration when airborne,
	except during gliding or dashing.
	"""
	if not is_on_floor() and not is_gliding and not is_dashing:
		velocity.y += GRAVITY * delta

func reset_jumps() -> void:
	"""
	Resets jump count when player is grounded.
	"""
	if is_on_floor():
		jumps_made = 0

# ------------------------------------------------------------------------------
# Jumping
# ------------------------------------------------------------------------------

func jump() -> void:
	"""
	Performs a single jump: sets vertical velocity, increments jump counter.
	"""
	velocity.y = jump_force
	jumps_made += 1

func double_jump() -> void:
	"""
	Performs a second jump in mid-air if allowed.
	"""
	velocity.y = jump_force
	jumps_made += 1

# ------------------------------------------------------------------------------
# Gliding
# ------------------------------------------------------------------------------

func glide(delta: float) -> void:
	"""
	Handles glide physics: slow fall and horizontal control.
	Decrements remaining glide time.
	"""
	# Cancel glide if grounded or disabled
	if is_on_floor() or not PlayerData.can_glide:
		is_gliding = false
		remaining_glide_time = max_glide_time
		return

	# Active glide: slow-fall and half-speed horizontal
	if Input.is_action_pressed("glide") and remaining_glide_time > 0.0 and velocity.y > 0:
		is_gliding = true
		velocity.y = min(velocity.y + GLIDE_GRAVITY * delta, 100.0)
		velocity.x = speed * 0.5 * direction.x
		remaining_glide_time -= delta
	else:
		is_gliding = false

func can_glide() -> bool:
	"""
	Returns true if glide is unlocked, has time left, and is falling.
	"""
	return PlayerData.can_glide and remaining_glide_time > 0.0 and velocity.y > 0

# ------------------------------------------------------------------------------
# Dashing
# ------------------------------------------------------------------------------

func start_dash() -> void:
	"""
	Initiates a dash: sets dash state, timers, and horizontal velocity.
	Cancels vertical movement.
	"""
	is_dashing = true
	dash_time_left = dash_duration
	velocity.x = dash_speed * direction.x
	velocity.y = 0

func dash(delta: float) -> void:
	"""
	Updates dash timer; ends dash when time runs out and starts cooldown.
	"""
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown

func can_dash() -> bool:
	"""
	Returns true if dash is unlocked, cooldown is over, and player is moving.
	"""
	return PlayerData.can_dash and dash_cooldown_timer <= 0.0 and direction.x != 0

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func initialize_values() -> void:
	"""
	Loads tunable parameters from PlayerData and sets initial timers.
	"""
	speed = PlayerData.speed
	jump_force = PlayerData.jump_force
	max_glide_time = PlayerData.max_glide_time
	remaining_glide_time = max_glide_time
	dash_speed = PlayerData.dash_speed
	dash_duration = PlayerData.dash_duration
	dash_cooldown_timer = 0.0
