extends CharacterBody2D

# Parameters
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2 # Multiple jumps
const MAGIC_SLASH_MANA = 25 # mana required for magic slash

enum State {Default, Fainted, Attacking}

# Variables
var state := State.Default # handle all states of the player

var direction : float # direction input
var jumps := MAX_JUMPS # jumps left

# stats
var max_health := 10
var health := max_health

var next_level_experience := 50
var experience := 0

var max_mana := 40
var mana := max_mana

var strength := 1 # damage dealt to enemies

# Imports
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var jump_circle: AnimationPlayer = $Jump/JumpCircle
@onready var jump_sound: AudioStreamPlayer = $Jump/JumpSound

@onready var hurtbox: CollisionShape2D = $Hurt/Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $Hurt/HurtSound
@onready var hurt_invicibility_timer: Timer = $Hurt/HurtInvicibilityTimer

@onready var death_timer: Timer = $DeathTimer
@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var basic_slash: Area2D = $BasicSlash
@onready var magic_slash: Area2D = $MagicSlash

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
		
		# draw circle below player if they jump in the air
		if not is_on_floor():
			jump_circle.play("default")

	# Handle movements.
	direction = Input.get_axis("left", "right")

func handle_flip_h() -> void:
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

func handle_slash() -> void:
	# attacking state corresponds to the basic slash being active
	if basic_slash.active:
		state = State.Attacking
	elif state == State.Attacking:
		state = State.Default

	# basic slash
	if Input.is_action_just_pressed("basic_slash") and state == State.Default:
		if Input.is_action_pressed("up"):
			basic_slash.start("up")
		elif Input.is_action_pressed("down"):
			basic_slash.start("down")
		elif animated_sprite.flip_h:
			basic_slash.start("left")
		else:
			basic_slash.start("right")
	
	# magic slash
	if Input.is_action_just_pressed("magic_slash") and state == State.Default and not magic_slash.active and mana >= MAGIC_SLASH_MANA:
		mana -= MAGIC_SLASH_MANA
		
		if animated_sprite.flip_h:
			magic_slash.start("left")
		else:
			magic_slash.start("right")

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

func handle_bounce() -> void:
	if not is_on_floor():
		velocity.y = JUMP_VELOCITY * 0.8

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
		handle_slash() # attacks
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

func is_hurtable() -> bool:
	if effects_player.current_animation == "blink":
		return false
	else:
		return true

func hurt(damage: int) -> void:
	# player is still alive
	if health > damage:
		health -= damage
		velocity.x *= 0.5
		hurt_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		effects_player.play("blink")
		basic_slash.reset()
	
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

func _on_mana_recovery_timer_timeout() -> void:
	if mana < max_mana:
		mana += 1
