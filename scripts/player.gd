extends CharacterBody2D

# Parameters
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2 # Multiple jumps

enum State {Default, Fainted, Attacking}

# Variables
var state := State.Default # handle all states of the player

var direction : float # direction input
var jumps := MAX_JUMPS # jumps left
var max_health := 100 # current maximum health
var health := max_health # remaining health

# Imports
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var jump_sound: AudioStreamPlayer = $JumpSound

@onready var hurtbox: CollisionShape2D = $Hurt/Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hurt_invicibility_timer: Timer = $HurtInvicibilityTimer

@onready var death_timer: Timer = $DeathTimer
@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var basic_slash: Area2D = $BasicSlash

func handle_movement() -> void:
	# Restore jumps if grounded.
	if is_on_floor():
		jumps = MAX_JUMPS
	# If the player leaves the ground without jumping, it should be counted as a jump
	elif jumps == MAX_JUMPS:
		jumps = MAX_JUMPS-1
	
	# Jump if there are jumps left
	if Input.is_action_just_pressed("jump") and jumps > 0 and state != State.Attacking:
		velocity.y = JUMP_VELOCITY
		jumps -= 1
		jump_sound.play()
		
		# restart animation
		animated_sprite.stop()
		animated_sprite.play("jump")

	# Handle movements.
	direction = Input.get_axis("left", "right")

func handle_flip_h() -> void:
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

func handle_basic_slash() -> void:
	if basic_slash.active:
		state = State.Attacking
	elif state == State.Attacking:
		state = State.Default

	if Input.is_action_just_pressed("basic_slash") and state != State.Attacking:
		if Input.is_action_pressed("up"):
			basic_slash.start("up")
		elif Input.is_action_pressed("down"):
			basic_slash.start("down")
		elif animated_sprite.flip_h:
			basic_slash.start("left")
		else:
			basic_slash.start("right")

func handle_velocity(delta: float) -> void:
	var speed_force := SPEED # usual speed
	
	# move slower if the player is attacking
	if state == State.Attacking:
		speed_force *= 0.7
	
	if direction:
		velocity.x = direction * speed_force
	else:
		velocity.x = move_toward(velocity.x, 0, speed_force)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

func animate() -> void:
	if state != State.Fainted:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		elif velocity.y > 0:
			if animated_sprite.animation != "fall":
				animated_sprite.play("fall")
		else:
			# Need to restart animation for jumping in mid-air
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
	else:
		if animated_sprite.animation != "faint":
			animated_sprite.play("faint")

func _ready() -> void:
	add_to_group("players")	

func _physics_process(delta: float) -> void:
	# handle player's actions if they are not defeated
	if state != State.Fainted:
		handle_basic_slash() # attack
		handle_movement() # left, right and jump
		
		# flip sprite horizontally if the player is not attacking
		if state != State.Attacking:
			handle_flip_h()
	else:
		direction = 0
	
	handle_velocity(delta) # velocity update based on the above modification

	animate() # update the sprite animation if necessary
	move_and_slide()


# get the position of the player with a vertical offset depending on the hurtbox's size
func get_middle_position() -> Vector2:
	return position - Vector2(0, hurtbox.shape.get_rect().size.y)

func hurt(damage: int) -> void:
	# player is still alive
	if health > damage:
		health -= damage
		velocity.x *= 0.5
		hurt_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		effects_player.play("blink")
	
	# player is dead
	else:
		fainted()
		
func fainted() -> void:
	if state != State.Fainted:
		health = 0
		animated_sprite.play("faint")
		state = State.Fainted
		velocity.y = 0
		death_sound.play()
		death_timer.start()

func _on_death_timer_timeout() -> void:
	get_tree().reload_current_scene()

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()
