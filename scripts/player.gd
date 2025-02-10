extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2 # Double jump

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var basic_slash: Area2D = $BasicSlash

var fainted := false
var direction := 0
var jumps_left := MAX_JUMPS

func handle_movement() -> void:
	# Restore jumps if grounded.
	if is_on_floor():
		jumps_left = MAX_JUMPS
	
	# Jump if there are jumps left
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Hande movements.
	direction = Input.get_axis("left", "right")
	
	# Animate
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
	
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

func handle_basic_slash() -> void:	
	if Input.is_action_just_pressed("basic_slash") and not basic_slash.active:
		basic_slash.start(direction)
		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not fainted:
		handle_movement()
		handle_basic_slash()
	else:
		direction = 0
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
