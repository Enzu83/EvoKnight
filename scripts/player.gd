class_name Player
extends CharacterBody2D

# Parameters
const SPEED = 150.0

const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2 # Multiple jumps

const MANA_RECOVERY_RATE = 2 # mana recover per frame
const MAGIC_SLASH_MANA = 25 # mana required for magic slash
const DASH_MANA = 10 # mana required for dashing
const DASH_SPEED = 2 * SPEED

enum State {Default, Fainted, Attacking, Dashing}

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

var can_dash := true
var dash_phantom = preload("res://scenes/chars/dash_phantom.tscn")

# Imports
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var jump_circle: AnimationPlayer = $Jump/JumpCircle
@onready var jump_sound: AudioStreamPlayer = $Jump/JumpSound

@onready var hurtbox: CollisionShape2D = $Hurt/Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $Hurt/HurtSound
@onready var hurt_invicibility_timer: Timer = $Hurt/HurtInvicibilityTimer
@onready var death_timer: Timer = $Hurt/DeathTimer
@onready var death_sound: AudioStreamPlayer = $Hurt/DeathSound

@onready var basic_slash: Area2D = $BasicSlash
@onready var magic_slash: Area2D = $MagicSlash

@onready var dash_cooldown: Timer = $DashCooldown
@onready var dash_duration: Timer = $DashDuration
@onready var dash_phantom_cooldown: Timer = $DashPhantomCooldown

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

func handle_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and state == State.Default and mana >= DASH_MANA:
		can_dash = false
		state = State.Dashing
		mana -= DASH_MANA
		dash_cooldown.start()
		dash_duration.start()
		dash_phantom_cooldown.start()
		
		# find dash direction
		var dash_direction := Vector2.ZERO
		
		# horizontal dash direction
		if Input.is_action_pressed("left"):
			dash_direction.x = -1
		elif Input.is_action_pressed("right"):
			dash_direction.x = 1
		
		# vertical dash direction
		if Input.is_action_pressed("up"):
			dash_direction.y = -1
		elif Input.is_action_pressed("down"):
			dash_direction.y = 1
		
		# forward dash by default if no inputs
		if dash_direction == Vector2.ZERO:
			if animated_sprite.flip_h:
				dash_direction.x = -1
			else:
				dash_direction.x = 1
		
		# normalize the dash direction vector to keep the same velocity for each direction
		velocity = DASH_SPEED * dash_direction.normalized()

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
	if state == State.Dashing:
		animated_sprite.play("dash")

	elif state != State.Fainted:
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
		if state != State.Dashing:
			handle_slash() # attacks
			handle_movement() # left, right and jump
		
		if state != State.Attacking:
			handle_flip_h() # flip sprite horizontally if the player is not attacking
			handle_dash() # can't dash while attacking
	else:
		direction = 0
	
	if state != State.Dashing:
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
	end_dash()
	
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

func end_dash() -> void:
	# end player dash animation and stop its velocity
	if state == State.Dashing:
		state = State.Default
		velocity = Vector2.ZERO
		dash_phantom_cooldown.stop() # stop dash phantom display

func _on_death_timer_timeout() -> void:
	get_tree().reload_current_scene()

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_mana_recovery_timer_timeout() -> void:
	if state != State.Fainted:
		if mana < max_mana:
			mana += MANA_RECOVERY_RATE

func _on_dash_phantom_cooldown_timeout() -> void:
	var new_dash_phantom = dash_phantom.instantiate().init(get_middle_position(), animated_sprite.flip_h)
	add_child(new_dash_phantom)

func _on_dash_duration_timeout() -> void:
	end_dash()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
