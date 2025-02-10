extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var fainted := false
var direction := 0

func _handle_movement() -> void:
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY			

	# Hande movements.
	direction = Input.get_axis("move_left", "move_right")
	
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

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not fainted:
		_handle_movement()
	else:
		direction = 0
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
