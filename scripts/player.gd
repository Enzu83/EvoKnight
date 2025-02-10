extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2 # Multiple jumps

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var basic_slash: Area2D = $BasicSlash

@onready var death_timer: Timer = $DeathTimer
@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var jump_sound: AudioStreamPlayer = $JumpSound

var fainted := false
var direction := 0
var jumps_left := MAX_JUMPS

func handle_movement() -> void:
	# Restore jumps if grounded.
	if is_on_floor():
		jumps_left = MAX_JUMPS
	# If the player leaves the ground without jumping, it should be counted as a jump
	elif jumps_left == MAX_JUMPS:
		jumps_left = MAX_JUMPS-1
	
	# Jump if there are jumps left
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		jump_sound.play()

	# Handle movements.
	direction = Input.get_axis("left", "right")

func handle_flip_h() -> void:
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

func handle_basic_slash() -> void:	
	if Input.is_action_just_pressed("basic_slash") and not basic_slash.active:
		var orientation := ""
		
		if Input.is_action_just_pressed("up"):
			orientation = "up"
		elif Input.is_action_just_pressed("down"):
			orientation = "down"
		elif Input.is_action_just_pressed("left"):
			orientation = "left"
		elif Input.is_action_just_pressed("right"):
			orientation = "right"
	
		# Default direction
		elif animated_sprite.flip_h:
			orientation = "left"
		else:
			orientation = "right"
			
		basic_slash.start(orientation)

func handle_velocity(delta: float) -> void:
	var speed_force := SPEED # usual speed
	
	# move slower if the player is attacking
	if basic_slash.active:
		speed_force *= 0.7
	
	if direction:
		velocity.x = direction * speed_force
	else:
		velocity.x = move_toward(velocity.x, 0, speed_force)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

func animate() -> void:
	if not fainted:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		elif velocity.y > 0:
			if animated_sprite.animation != "fall":
				animated_sprite.play("fall")
		else:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
	else:
		if animated_sprite.animation != "faint":
			animated_sprite.play("faint")

func _ready() -> void:
	add_to_group("players")	

func _physics_process(delta: float) -> void:
	# handle player's actions if they are not defeated
	if not fainted:
		handle_movement() # left, right and jump
		
		# flip sprite horizontally if the player is not attacking
		if not basic_slash.active:
			handle_flip_h()
		
		handle_basic_slash() # attack
	else:
		direction = 0
	
	# update velocity
	handle_velocity(delta)

	animate()
	move_and_slide()

func hurt() -> void:
	if not fainted:
		death_sound.play()
		animated_sprite.play("faint")
		fainted = true
		velocity.y = 0
		death_timer.start()

func _on_death_timer_timeout() -> void:
	get_tree().reload_current_scene()
