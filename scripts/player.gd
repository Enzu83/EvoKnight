class_name Player
extends CharacterBody2D

# node imports
@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var jump_circle: AnimationPlayer = $Jump/JumpCircle
@onready var jump_sound: AudioStreamPlayer = $Jump/JumpSound

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var death_timer: Timer = $DeathTimer

@onready var basic_slash: Area2D = $BasicSlash
@onready var basic_slash_cooldown: Timer = $BasicSlashCooldown

@onready var magic_slash: Area2D = $MagicSlash

@onready var dash_cooldown: Timer = $DashCooldown
@onready var dash_duration: Timer = $DashDuration
@onready var phantom_cooldown: Timer = $PhantomCooldown
@onready var dash_sound: AudioStreamPlayer2D = $DashSound

# Parameters
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_FALLING_VELOCITY = 450
const MAX_JUMPS = 2 # Multiple jumps

const MANA_RECOVERY_RATE = 20 # mana recovered per frame
const MAGIC_SLASH_MANA = 250 # mana required for magic slash
const DASH_MANA = 100 # mana required for dashing
const DASH_SPEED = 2 * SPEED

enum State {Default, Fainted, Attacking, Dashing}
enum Anim {idle, run, dash, jump, fall, faint}

# player state and actions
var state := State.Default # handle all states of the player
var anim := Anim.idle # handle the current animation to be played

var direction: float # direction input
var jumps := MAX_JUMPS # jumps left

var can_dash := true
var dash_direction := Vector2.ZERO
var phantom = preload("res://scenes/chars/phantom.tscn")

# stats
var max_health := 10
var health := max_health

var next_level_experience := 50
var experience := 0

var max_mana := 400
var mana := max_mana

var strength := 1 # damage dealt to enemies

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
		anim = Anim.jump
		animation_player.stop()
		animation_player.play("jump")
		
		# draw circle below player if they jump in the air
		if not is_on_floor():
			jump_circle.play("default")

	# Handle movements.
	direction = Input.get_axis("left", "right")

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
		elif sprite.flip_h:
			basic_slash.start("left")
		else:
			basic_slash.start("right")
	
	# magic slash
	if Input.is_action_just_pressed("magic_slash") and state == State.Default and not magic_slash.active and mana >= MAGIC_SLASH_MANA:
		mana -= MAGIC_SLASH_MANA
		
		if sprite.flip_h:
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
		phantom_cooldown.start()
		dash_sound.play()
		create_phantom()
		
		# find dash direction
		dash_direction = Vector2.ZERO
		
		# horizontal dash direction
		if direction < 0:
			dash_direction.x = -1
		elif direction > 0:
			dash_direction.x = 1
		
		# vertical dash direction
		if Input.is_action_pressed("up"):
			dash_direction.y = -1
		elif Input.is_action_pressed("down"):
			dash_direction.y = 1
		
		# downward dash direction while on floor is irrelevant
		if dash_direction.y == 1 and is_on_floor():
			dash_direction.y = 0
		
		# if the dash has no direction, find one with the orientation
		if dash_direction == Vector2.ZERO:
			if sprite.flip_h:
				dash_direction.x = -1
			else:
				dash_direction.x = 1
		
		# normalize the dash direction vector to keep the same velocity for each direction
		velocity = DASH_SPEED * dash_direction.normalized()

func handle_flip_h() -> void:
	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true

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
		
		# prevent player to go too fast
		if velocity.y > MAX_FALLING_VELOCITY:
			velocity.y = MAX_FALLING_VELOCITY

func handle_bounce() -> void:
	if not is_on_floor():
		velocity.y = JUMP_VELOCITY * 0.8

func play_animation(anim_name: String) -> void:
	# play the animation if it's no the current one
	if anim != Anim.get(anim_name):
		animation_player.play(anim_name)
		anim = Anim.get(anim_name)

func animate() -> void:
	if state == State.Dashing:
		play_animation("dash")

	elif state != State.Fainted:
		if is_on_floor():
			if direction == 0:
				play_animation("idle")
			else:
				play_animation("run")
		elif velocity.y > 0:
			play_animation("fall")
		else:
			play_animation("jump")
	else:
		play_animation("faint")

func _ready() -> void:
	sprite.texture = Global.player_sprite
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
	return not effects_player.current_animation == "blink"

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
		play_animation("faint")
		state = State.Fainted
		velocity.y = 0
		death_sound.play()
		death_timer.start()

func create_phantom() -> void:
	# create a phantom only if the player is moving or dashing
	if velocity != Vector2.ZERO or state == State.Dashing:
		add_child(phantom.instantiate())

func end_dash() -> void:
	# end player dash animation and stop its velocity if not sliding
	if state == State.Dashing:
		state = State.Default
		velocity = Vector2.ZERO
		phantom_cooldown.stop() # stop phantom display

func _on_death_timer_timeout() -> void:
	Global.reset()

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_mana_recovery_timer_timeout() -> void:
	if state != State.Fainted:
		if mana < max_mana:
			mana += MANA_RECOVERY_RATE

func _on_phantom_cooldown_timeout() -> void:
	create_phantom()

func _on_dash_duration_timeout() -> void:
	end_dash()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
