class_name Player
extends CharacterBody2D

# node imports
@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var up_crush_ray_cast: RayCast2D = $WallColliderRayCast/UpCrushRayCast
@onready var down_crush_ray_cast: RayCast2D = $WallColliderRayCast/DownCrushRayCast
@onready var left_crush_ray_cast: RayCast2D = $WallColliderRayCast/LeftCrushRayCast
@onready var right_crush_ray_cast: RayCast2D = $WallColliderRayCast/RightCrushRayCast
@onready var crushed_sound: AudioStreamPlayer = $WallColliderRayCast/CrushedSound


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
@onready var charged_slash_effect: Sprite2D = $ChargedSlashEffect

@onready var magic_slash: Area2D = $MagicSlash

@onready var dash_cooldown: Timer = $Dash/DashCooldown
@onready var dash_duration: Timer = $Dash/DashDuration
@onready var dash_sound: AudioStreamPlayer = $Dash/DashSound
@onready var blue_dash_sound: AudioStreamPlayer = $Dash/BlueDashSound

@onready var phantom_cooldown: Timer = $PhantomCooldown
@onready var permanent_phantom_cooldown: Timer = $PermanentPhantomCooldown

@onready var shield: Sprite2D = $Shield

# Parameters
const SPEED = 150.0
const MAX_HORIZONTAL_VELOCITY = 600.0

const JUMP_VELOCITY = -320.0
const MAX_JUMPING_VELOCITY = -700.0
const MAX_FALLING_VELOCITY = 450.0
const MAX_JUMPS = 2 # Multiple jumps
const JUMP_FRAME_WINDOW = 16 # range of frames for jump heights

const MAGIC_SLASH_MANA = 250 # mana required for magic slash
const BLUE_DASH_MANA = 100 # mana required for dashing without taking damage
const DASH_SPEED = 2 * SPEED

enum State {Default, Fainted, Crouching, Attacking, Dashing, DashingAndAttacking, Bumped, Stop}
enum Anim {idle, run, dash, jump, fall, faint, crouch}

# player state and actions
var state: State # handle all states of the player
var anim := Anim.idle # handle the current animation to be played

var direction: float # direction input

var jumps := MAX_JUMPS # jumps left
var higher_jump_height := 0 # range 0~5 of jump height when the jump key is still pressed 

var can_dash := true
var dash_direction := Vector2.ZERO
var blue_dash := false # dash that will consume mana instead of taking damage
var blue_dash_hit := false # indicate if the blue dash absorbed an hit
var phantom = preload("res://scenes/chars/phantom.tscn")

var bump_direction := Vector2.ZERO

var super_speed := false # increase speed and always create phantoms

# stats
var max_health: int
var health: int

var level: int
var level_experience := []
var experience: int

var level_stats_increase := {}

var dash_enabled := true

var mana_enabled := true
var max_mana: int
var mana: int
var mana_recovery_rate := 0

var strength: int
var defense: int

var shield_enabled := false # activate the shield by maintaining down
var shield_count := 0 # count the number of frames where down button is pressed while crouched
var shield_max := 60 # time needed for big slash activation
var shield_mana_consumption := 15 # mana drained by shield each frame

var bigger_slash := false # bigger slash ability flag
var bigger_slash_count := 0 # count the number of frames where the slash button is pressed
var bigger_slash_max := 90 # time needed for big slash activation

var ability_disabled := false # flag to check if the player had their abilities disabled by something

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

func handle_crouch() -> void:
	# handle transitions: default <=> crouching while on floor
	if is_on_floor():
		
		# default -> crouching
		if state == State.Default \
		and Input.is_action_pressed("down"):
			state = State.Crouching
		
		# crouching -> default
		elif state == State.Crouching \
		and not Input.is_action_pressed("down"):
			state = State.Default
	
	# if state is still crouching after leaving the floor, reset back to default
	elif state == State.Crouching:
		state = State.Default
	
func handle_shield() -> void:
	if shield_enabled:
		# count frames if down is pressed while crouching and player has enough mana for shield activation
		if state != State.Stop and state != State.Fainted \
		and Input.is_action_pressed("down") \
		and state == State.Crouching \
		and mana_enabled \
		and mana >= shield_mana_consumption \
		and not shield.active:
			if shield_count < shield_max:
				shield_count += 1
			else:
				shield.activate()
		
		# reset shield
		else:
			shield_count = 0
	
	# cancel shield if no more mana or deactivate it if player faints
	if shield.active \
	and (mana == 0 or state == State.Fainted or not mana_enabled):
		shield.deactivate()

func handle_jump() -> void:
	# Restore jumps if grounded (slight margin for jumping few frames after leaving the floor).
	if is_on_floor():
		jumps = MAX_JUMPS
		higher_jump_height = 0
	# If the player leaves the ground without jumping, it should be counted as a jump
	elif jumps == MAX_JUMPS and not jump_is_on_floor():
		jumps = MAX_JUMPS - 1
	
	# Jump if there are jumps left
	# if the player is dashing, player can jump if on the floor
	if Input.is_action_just_pressed("jump") \
	and jumps > 0 \
	and ((state != State.Dashing and state != State.DashingAndAttacking) \
	or jump_is_on_floor()):
		velocity.y = JUMP_VELOCITY
		
		# end dash if the player was dashing
		if state == State.Dashing or state == State.DashingAndAttacking:
			end_dash(false)
			can_dash = true
			
			# hyperdash if the dash direction is diagonal
			if dash_direction.x != 0 and dash_direction.y != 0:
				velocity.x *= 1.7
				velocity.y *= 0.75
			
			# allow to reverse the direction of the wavedash
			if (Input.is_action_pressed("left") and not Input.is_action_pressed("right") and velocity.x > 0) \
			or (Input.is_action_pressed("right") and not Input.is_action_pressed("left") and velocity.x < 0):
				velocity.x *= -1
		
		# multiple heights possible
		else:
			higher_jump_height = 1
		
		# increase jump force if super speed is active
		if super_speed:
			velocity.y *= 1.3
		
		jumps -= 1
		jump_sound.play()
		
		# restart animation
		anim = Anim.jump
		animation_player.stop()
		animation_player.play("jump")
		
		# draw circle below player if they jump in the air
		if not jump_is_on_floor():
			jump_circle.play("default")

func handle_jump_height() -> void:
	if not is_on_floor() and higher_jump_height > 0:
		# increase when gravity is disabled
		if Input.is_action_pressed("jump") and higher_jump_height < JUMP_FRAME_WINDOW and velocity.y <= 0:
			higher_jump_height += 1
		# player stops jumping
		elif state != State.Dashing and state != State.DashingAndAttacking:
			velocity.y *= 0.4
			higher_jump_height = 0

func handle_charged_slash() -> void:
	if bigger_slash:
		# count frames
		if state != State.Stop and state != State.Fainted \
		and Input.is_action_pressed("basic_slash"):
			if bigger_slash_count < bigger_slash_max:
				bigger_slash_count += 1
		
		# reset bigger slash
		else:
			bigger_slash_count = 0

func handle_slash() -> void:
	# reset attack state
	if not basic_slash.active \
	and state == State.Attacking:
		state = State.Default

	# basic slash
	if (Input.is_action_just_pressed("basic_slash") \
	or (Input.is_action_just_released("basic_slash") and bigger_slash and bigger_slash_count == bigger_slash_max)) \
	and (state == State.Default or state == State.Crouching or state == State.Dashing or state == State.Bumped):
		# attacking while dashing
		if state == State.Dashing:
			state = State.DashingAndAttacking
		else:
			state = State.Attacking

		# check for bigger slash
		if bigger_slash and bigger_slash_count == bigger_slash_max:
			basic_slash.size = 2
			basic_slash.multiplier = 1.5

		# direction based slash
		if Input.is_action_pressed("up"):
			basic_slash.start("up")
		elif Input.is_action_pressed("down"):
			basic_slash.start("down")
		elif Input.is_action_pressed("left"):
			basic_slash.start("left")
		elif Input.is_action_pressed("right"):
			basic_slash.start("right")
		
		# default direction based on orientation
		elif sprite.flip_h:
			basic_slash.start("left")
		else:
			basic_slash.start("right")
	
	# magic slash
	elif mana_enabled and Input.is_action_just_pressed("magic_slash") \
	and (state == State.Default or state == State.Dashing) \
	and not magic_slash.active \
	and mana >= MAGIC_SLASH_MANA:
		mana -= MAGIC_SLASH_MANA
		
		# direction based magic slash
		if Input.is_action_pressed("left"):
			magic_slash.start("left")
		elif Input.is_action_pressed("right"):
			magic_slash.start("right")
		
		# default direction based on orientation
		elif sprite.flip_h:
			magic_slash.start("left")
		else:
			magic_slash.start("right")

func handle_dash() -> void:
	if dash_enabled and Input.is_action_just_pressed("dash") \
	and can_dash \
	and (state == State.Default or state == State.Crouching or state == State.Crouching or state == State.Attacking or state == State.Bumped):
		# dashing while attacking
		if state == State.Attacking:
			state = State.DashingAndAttacking
		else:
			state = State.Dashing
		
		# toggle dash blocks
		Global.toggle_dash_block()
		
		# prevent for re-dashing instantly only if the player is in the air
		if not is_on_floor():
			can_dash = false
			dash_cooldown.start()
		
		dash_duration.start()
		phantom_cooldown.start()
		dash_sound.play()
		handle_flip_h()
		
		# phantom trace
		if mana_enabled and mana >= BLUE_DASH_MANA:
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

		# if the dash has no direction, find one with the orientation
		if dash_direction == Vector2.ZERO:
			if sprite.flip_h:
				dash_direction.x = -1
			else:
				dash_direction.x = 1
		
		# reduce diagonal dash force
		if dash_direction.length() > 1:
			dash_direction *= 0.8

		velocity = DASH_SPEED * dash_direction

func handle_flip_h() -> void:
	if state != State.Crouching:
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
	
	else:
		if Input.is_action_just_pressed("right"):
			sprite.flip_h = false
		elif Input.is_action_just_pressed("left"):
			sprite.flip_h = true

func handle_velocity(delta: float) -> void:
	# get horizontal input if player can move
	if state != State.Fainted \
	and state != State.Stop:
		direction = sign(Input.get_axis("left", "right"))
	# stop movement if the player faints
	else:
		direction = 0
	
	var speed_force := SPEED # usual speed
	
	# don't move if crouching
	if state == State.Crouching:
		speed_force = 0
	# move slower if the player is attacking
	elif state == State.Attacking:
		speed_force *= 0.7
	
	# move faster in super speed state
	if super_speed:
		speed_force *= 1.5

	# regular horizontal velocity handle
	if abs(velocity.x) <= speed_force and \
	not (state == State.Bumped and bump_direction.x != 0):
		
		if direction:
			# acceleration toward speed cap
			if velocity.x == 0 or direction * velocity.x > 0:
				velocity.x = move_toward(velocity.x, direction * speed_force, 1700 * delta)
			# changing direction
			else:
				velocity.x = direction * speed_force
		
		# air momentum
		elif not is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 9000 * delta)
		# decelerate quickly when on floor
		else:
			velocity.x = move_toward(velocity.x, 0, 3500 * delta)

	# reduce velocity if crouching
	elif state == State.Crouching:
		velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	# when player is bumped horizontally and moves the opposite way
	elif direction * velocity.x < 0:
		velocity.x = move_toward(velocity.x, 0, 900 * delta)
	
	# when player is bumped horizontally and don't move
	elif direction == 0 and velocity.x != 0:
		velocity.x = move_toward(velocity.x, 0, 420 * delta)

	# when player is bumped horizontally and moves the same way
	elif direction * velocity.x > 0:
		velocity.x = move_toward(velocity.x, 0, 180 * delta)
	
	# handling gravity
	# disable it when the jump key is still pressed while jumping (up to 5 frames)
	if not is_on_floor():
			velocity += get_gravity() * delta
			
			# prevent wrong falling too fast (larger value if pressed down)
			var falling_speed_cap := MAX_FALLING_VELOCITY
			
			if Input.is_action_pressed("down"):
				falling_speed_cap *= 1.25
			
			if velocity.y > falling_speed_cap:
				velocity.y = move_toward(velocity.y, falling_speed_cap, get_gravity().y * delta)

	# cap velocity
	if abs(velocity.x) > MAX_HORIZONTAL_VELOCITY:
		velocity.x = sign(velocity.x) * MAX_HORIZONTAL_VELOCITY
	
	if velocity.y < MAX_JUMPING_VELOCITY:
		velocity.y = MAX_JUMPING_VELOCITY

func handle_bounce() -> void:
	if not is_on_floor() and state != State.DashingAndAttacking:
		velocity.y = JUMP_VELOCITY * 0.8
		jumps = MAX_JUMPS - 1

		# restart animation
		anim = Anim.jump
		animation_player.stop()
		animation_player.play("jump")

func handle_super_speed() -> void:
	if super_speed:
		if permanent_phantom_cooldown.is_stopped():
			permanent_phantom_cooldown.start()
	else:
		permanent_phantom_cooldown.stop()

func handle_bumped() -> void:
	if state == State.Bumped:
		# end bump when landing
		if is_on_floor():
			state = State.Default
		
		elif bump_direction.x != 0 and velocity.x == 0:
			state = State.Default

func handle_crushed() -> void:
	if (up_crush_ray_cast.is_colliding() and not up_crush_ray_cast.get_collider().is_in_group("one-way platforms")) \
	or (down_crush_ray_cast.is_colliding() and not down_crush_ray_cast.get_collider().is_in_group("one-way platforms")) \
	or (left_crush_ray_cast.is_colliding() and not left_crush_ray_cast.get_collider().is_in_group("one-way platforms")) \
	or (right_crush_ray_cast.is_colliding() and not right_crush_ray_cast.get_collider().is_in_group("one-way platforms")):
		#crushed_sound.play()
		fainted()

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
			if Input.is_action_pressed("down") \
			and state != State.Stop \
			and not (state == State.Attacking and direction != 0):
				play_animation("crouch")
			elif velocity.x == 0:
				play_animation("idle")
			else:
				play_animation("run")

		elif velocity.y > 0:
			play_animation("fall")
		elif velocity.y < 0:
			play_animation("jump")

func init_info() -> void:
	# retrieve info from global
	update_sprite()
	
	max_health = Global.player_max_health
	health = Global.player_health
	
	level = Global.player_level
	level_experience = Global.player_level_experience
	experience = Global.player_experience
	
	level_stats_increase = Global.player_level_stats_increase
	
	dash_enabled = Global.player_dash_enabled
	
	mana_enabled = Global.player_mana_enabled
	max_mana = Global.player_max_mana
	mana = Global.player_mana
	mana_recovery_rate = Global.player_mana_recovery_rate
	
	strength = Global.player_strength
	defense = Global.player_defense
	
	shield_enabled = Global.player_shield_enabled
	
	bigger_slash = Global.player_bigger_slash
	
	# restore health of the player if the player fainted
	if health == 0:
		health = max_health
		mana = 0

func update_sprite() -> void:
	sprite.texture = Global.player_sprite
	basic_slash.sprite.texture = Global.basic_slash_sprite
	magic_slash.sprite.texture = Global.magic_slash_sprite
	charged_slash_effect.texture = Global.charged_slash_effect_sprite

func _ready() -> void:
	add_to_group("players")
	init_info()
	state = State.Default

func _physics_process(delta: float) -> void:
	if state != State.Stop:
		# handle player's actions if they are not defeated
		if state != State.Fainted:
			if state != State.Attacking and state != State.DashingAndAttacking:
				handle_flip_h() # flip sprite horizontally if the player is not attacking
			
			handle_crouch() # crouch animation
			handle_shield() # attack protection
			handle_dash() # can't dash while attacking
			handle_jump() # left, right and jump
			handle_jump_height() # different jump heights
			handle_slash() # regular slash
			handle_charged_slash() # bigger slash attack (if upgrade is unlocked)
			handle_super_speed() # permanent 1.5x multiplier
			handle_bumped() # launched by another object
			handle_crushed() # check if player is between two walls

	if state != State.Dashing \
	and state != State.DashingAndAttacking:
		handle_velocity(delta) # velocity update based on the above modifications

	animate() # update the sprite animation if necessary
	
	if direction == 0 and not Input.is_action_pressed("jump"):
		pass
		#move_and_collide(Vector2.ZERO)
	move_and_slide()

func _process(_delta: float) -> void:
	# store the info after each frame
	Global.store_player_info()

# get the position of the player with a vertical offset depending on the hurtbox's size
func get_middle_position() -> Vector2:
	return position - Vector2(0, 16)

func is_hurtable() -> bool:
	# can't be hurt if:
	#	- the sprite blinks
	#	- the player faints
	#	- in Stop state
	return not effects_player.current_animation == "blink" and state != State.Fainted and state != State.Stop

func hurt(damage: int, ignore_defense: bool = false, through_blue_dash: bool = false) -> void:
	if not ignore_defense:
		damage -= defense
	
	# shield absorbs hit if active
	if shield.active:
		shield.explode()
	
	# hit during blue dash: animation and mana cost
	elif blue_dash and not through_blue_dash:
		if not blue_dash_hit:
			blue_dash_hit = true
			mana -= BLUE_DASH_MANA
			blue_dash_sound.play()
			hurtbox.set_deferred("disabled", true)
	
	# player is still alive
	elif health > max(1, damage):
		health -= max(1, damage)
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
		play_animation("faint")
		state = State.Fainted
		velocity = Vector2.ZERO
		higher_jump_height = 0
		phantom_cooldown.stop()
		hurtbox.set_deferred("disabled", true)
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
		
		# reset hurtbox collision if player was hit during blue dash
		if blue_dash_hit:
			hurtbox.set_deferred("disabled", false)
		
		blue_dash = false
		blue_dash_hit = false

func heal(amount: int) -> void:
	if health + amount > max_health:
		health = max_health
	else:
		health += amount

func restore_mana(amount: int) -> void:
	# full restore
	if mana + amount > max_mana:
		mana = max_mana
		
	# no more mana
	elif mana + amount < 0:
		mana = 0

	# usual case
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

func bumped(bump_force: float, direction_of_bump: Vector2) -> void:
	# reset dash
	end_dash(false)
	dash_cooldown.stop()
	can_dash = true
	
	state = State.Bumped
	
	velocity = bump_force * direction_of_bump
	bump_direction = direction_of_bump
	
	# restore a jump if player has none
	if jumps == 0:
		jumps = 1

func _on_death_timer_timeout() -> void:
	Global.store_player_info()
	Global.reset_level()

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_mana_recovery_timer_timeout() -> void:
	if state != State.Fainted:
		# natural regeneration
		if mana_enabled and mana_recovery_rate > 0:
			restore_mana(mana_recovery_rate)
		
		# drain mana if shield is active
		if shield.active:
			restore_mana(-shield_mana_consumption)

func _on_phantom_cooldown_timeout() -> void:
	# don't create more phantoms if the super speed already creates ones
	if not super_speed:
		create_phantom()

func _on_permanent_phantom_cooldown_timeout() -> void:
	create_phantom()

func _on_dash_duration_timeout() -> void:
	if state == State.Dashing or state == State.DashingAndAttacking:
		end_dash(true)

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
