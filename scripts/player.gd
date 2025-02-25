class_name Player
extends CharacterBody2D

# node imports
@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var jump: Sprite2D = $Jump
@onready var jump_circle: AnimationPlayer = $Jump/JumpCircle
@onready var jump_sound: AudioStreamPlayer = $Jump/JumpSound

@onready var jump_ray_cast_down: RayCast2D = $JumpRayCast/Down
@onready var jump_ray_cast_down_left: RayCast2D = $JumpRayCast/DownLeft
@onready var jump_ray_cast_down_right: RayCast2D = $JumpRayCast/DownRight
@onready var jump_ray_cast_left: RayCast2D = $JumpRayCast/Left
@onready var jump_ray_cast_right: RayCast2D = $JumpRayCast/Right


@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var death_timer: Timer = $DeathTimer

@onready var basic_slash: Area2D = $BasicSlash

@onready var magic_slash: Area2D = $MagicSlash

@onready var dash_cooldown: Timer = $Dash/DashCooldown
@onready var dash_duration: Timer = $Dash/DashDuration
@onready var dash_sound: AudioStreamPlayer = $Dash/DashSound
@onready var blue_dash_sound: AudioStreamPlayer = $Dash/BlueDashSound

@onready var phantom_cooldown: Timer = $PhantomCooldown

@onready var bumped_timer: Timer = $BumpedTimer

# Parameters
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_FALLING_VELOCITY = 450
const MAX_JUMPS = 2 # Multiple jumps

const MANA_RECOVERY_RATE = 0 #20 # mana recovered per frame
const MAGIC_SLASH_MANA = 250 # mana required for magic slash
const BLUE_DASH_MANA = 100 # mana required for dashing without taking damage
const DASH_SPEED = 2 * SPEED

enum State {Default, Fainted, Attacking, Dashing, DashingAndAttacking, Bumped, Stop}
enum Anim {idle, run, dash, jump, fall, faint}

# player state and actions
var state: State # handle all states of the player
var anim := Anim.idle # handle the current animation to be played

var direction: float # direction input

var jumps := MAX_JUMPS # jumps left

var can_dash := true
var dash_direction := Vector2.ZERO
var blue_dash := false # dash that will consume mana instead of taking damage
var blue_dash_hit := false # indicate if the blue dash absorbed an hit
var phantom = preload("res://scenes/chars/phantom.tscn")

# stats
var max_health: int
var health: int

var level: int
var level_experience := []
var experience: int

var level_stats_increase := {}

var max_mana: int
var mana: int

var strength: int
var defense: int

# Allow grounded jump short after leaving the floor without jumping
func jump_is_on_floor() -> bool:
	if is_on_floor():
		return true
	
	# always grounded if the main ray cast down is colliding
	elif jump_ray_cast_down.is_colliding():
		return true
	
	# raycast down left colliding but not left (jumping next to a wall)
	elif jump_ray_cast_down_left.is_colliding() \
	and not jump_ray_cast_left.is_colliding():
		return true
		
	# raycast down right colliding but not right (jumping next to a wall)
	elif jump_ray_cast_down_right.is_colliding() and not jump_ray_cast_right.is_colliding():
		return true
	
	else:
		return false

func handle_movement() -> void:
	# Restore jumps if grounded (slight margin for jumping few frames after leaving the floor).
	if is_on_floor():
		jumps = MAX_JUMPS
	# If the player leaves the ground without jumping, it should be counted as a jump
	elif jumps == MAX_JUMPS and not jump_is_on_floor():
		jumps = MAX_JUMPS-1
	
	# Jump if there are jumps left
	if Input.is_action_just_pressed("jump") and jumps > 0:
		velocity.y = JUMP_VELOCITY
		jumps -= 1
		jump_sound.play()
		
		# restart animation
		anim = Anim.jump
		animation_player.stop()
		animation_player.play("jump")
		
		# draw circle below player if they jump in the air
		if not jump_is_on_floor():
			jump_circle.play("default")

	# Handle movements.
	direction = sign(Input.get_axis("left", "right"))

func handle_slash() -> void:
	# reset attack state
	if not basic_slash.active \
	and state == State.Attacking:
		state = State.Default

	# basic slash
	if Input.is_action_just_pressed("basic_slash") \
	and (state == State.Default or state == State.Dashing or state == State.Bumped):
		# attacking while dashing
		if state == State.Dashing:
			state = State.DashingAndAttacking
		else:
			state = State.Attacking
		
		if Input.is_action_pressed("up"):
			basic_slash.start("up")
		elif Input.is_action_pressed("down"):
			basic_slash.start("down")
		elif sprite.flip_h:
			basic_slash.start("left")
		else:
			basic_slash.start("right")
	
	# magic slash
	elif Input.is_action_just_pressed("magic_slash") \
	and (state == State.Default or state == State.Dashing) \
	and not magic_slash.active \
	and mana >= MAGIC_SLASH_MANA:
		mana -= MAGIC_SLASH_MANA
		
		if sprite.flip_h:
			magic_slash.start("left")
		else:
			magic_slash.start("right")

func handle_dash() -> void:
	if Input.is_action_just_pressed("dash") \
	and can_dash \
	and (state == State.Default or state == State.Attacking or state == State.Bumped):
		# dashing while attacking
		if state == State.Attacking:
			state = State.DashingAndAttacking
		else:
			state = State.Dashing
		
		can_dash = false
		dash_cooldown.start()
		dash_duration.start()
		phantom_cooldown.start()
		dash_sound.play()
		handle_flip_h()
		
		# phantom trace
		if mana >= BLUE_DASH_MANA:
			blue_dash = true
		else:
			blue_dash = false
		
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
	# end bump when landing
	if state == State.Bumped and is_on_floor():
		state = State.Default
	
	# gravity + direction controls
	elif state != State.Bumped:
		
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
			
			# prevent wrong falling too fast
			if velocity.y > MAX_FALLING_VELOCITY:
				velocity.y = MAX_FALLING_VELOCITY

func handle_bounce() -> void:
	if not is_on_floor() and state != State.DashingAndAttacking:
		velocity.y = JUMP_VELOCITY * 0.8
		jumps = MAX_JUMPS - 1

func play_animation(anim_name: String) -> void:
	# play the animation if it's not the current one
	if anim != Anim.get(anim_name):
		animation_player.play(anim_name)
		anim = Anim.get(anim_name)

func animate() -> void:
	if state == State.Dashing or state == State.DashingAndAttacking:
		play_animation("dash")

	elif state == State.Fainted:
		play_animation("faint")
	else:
		if is_on_floor():
			if direction == 0:
				play_animation("idle")
			else:
				play_animation("run")

		elif velocity.y > 0:
			play_animation("fall")
		else:
			play_animation("jump")

func init_info() -> void:
	# retrieve info for global
	sprite.texture = Global.player_sprite
	
	max_health = Global.player_max_health
	health = Global.player_health
	
	level = Global.player_level
	level_experience = Global.player_level_experience
	experience = Global.player_experience
	
	level_stats_increase = Global.player_level_stats_increase
	
	max_mana = Global.player_max_mana
	mana = Global.player_mana
	
	strength = Global.player_strength
	defense = Global.player_defense
	
	# restore health of the player if the player fainted
	if health == 0:
		health = max_health
		mana = 0

func _ready() -> void:
	add_to_group("players")
	init_info()
	state = State.Default

func _physics_process(delta: float) -> void:
	if state != State.Stop:
		# handle player's actions if they are not defeated
		if state != State.Fainted:
			handle_slash() # attacks
			
			if state != State.Dashing and state != State.DashingAndAttacking:
				handle_movement() # left, right and jump
			
			if state != State.Attacking and state != State.DashingAndAttacking:
				handle_flip_h() # flip sprite horizontally if the player is not attacking
			
			handle_dash() # can't dash while attacking
		else:
			direction = 0
		
		if state != State.Dashing \
		and state != State.DashingAndAttacking:
			handle_velocity(delta) # velocity update based on the above modification
			
	animate() # update the sprite animation if necessary
	move_and_slide()

func _process(_delta: float) -> void:
	# store the info after each frame
	Global.store_player_info()

# get the position of the player with a vertical offset depending on the hurtbox's size
func get_middle_position() -> Vector2:
	return position - Vector2(0, wall_collider.shape.get_rect().size.y)

func is_hurtable() -> bool:
	# can't be hurt if:
	#	- the sprite blinks
	#	- the player faints
	#	- in Stop state
	return not effects_player.current_animation == "blink" and state != State.Fainted and state != State.Stop

func hurt(damage: int) -> void:
	# hit during blue dash: animation and mana cost
	if blue_dash:
		if not blue_dash_hit:
			blue_dash_hit = true
			mana -= BLUE_DASH_MANA
			blue_dash_sound.play()
	
	# player is still alive
	elif health > max(1, damage - defense):
		health -= max(1, damage - defense)
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
		phantom_cooldown.stop()
		death_sound.play()
		death_timer.start()

func create_phantom() -> void:
	# create a phantom only if the player is moving or dashing
	if velocity != Vector2.ZERO or state == State.Dashing:
		add_child(phantom.instantiate())

func end_dash(cancel_velocity: bool) -> void:
	# end player dash animation and stop its velocity
	if state == State.Dashing or state == State.DashingAndAttacking:
		state = State.Default
		
		if cancel_velocity:
			velocity = Vector2.ZERO
		
		phantom_cooldown.stop() # stop phantom display
		hurtbox.set_deferred("disabled", false)
		blue_dash = false
		blue_dash_hit = false

func heal(amount: int) -> void:
	if health + amount > max_health:
		health = max_health
	else:
		health += amount

func restore_mana(amount: int) -> void:
	if mana + amount > max_mana:
		mana = max_mana
	else:
		mana += amount

func gain_exp(amount: int) -> void:
	experience += amount
	
	while level < level_experience.size()-1 \
	and experience >= level_experience[level + 1]:
		level_up()
		

func level_up() -> void:
	level += 1
	
	experience -= level_experience[level]
	
	max_health += level_stats_increase["max_health"][level]
	strength += level_stats_increase["strength"][level]
	defense += level_stats_increase["defense"][level]
	
	health = max_health
	
	# level up animation
	Global.level_up.start(
		level_stats_increase["max_health"][level], 
		level_stats_increase["strength"][level],
		level_stats_increase["defense"][level]
		)

func bumped(bump_force: float, bump_direction: Vector2) -> void:
	end_dash(false)
	state = State.Bumped
	bumped_timer.start()
	velocity = bump_force * bump_direction

func _on_death_timer_timeout() -> void:
	Global.store_player_info()
	Global.reset_level()

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_mana_recovery_timer_timeout() -> void:
	if state != State.Fainted and velocity == Vector2.ZERO:
		restore_mana(MANA_RECOVERY_RATE)

func _on_phantom_cooldown_timeout() -> void:
	create_phantom()

func _on_dash_duration_timeout() -> void:
	if state == State.Dashing or state == State.DashingAndAttacking:
		end_dash(true)

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _on_bumped_timer_timeout() -> void:
	if state == State.Bumped:
		state = State.Default
