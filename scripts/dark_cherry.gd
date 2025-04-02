extends CharacterBody2D

@onready var music: AudioStreamPlayer
@onready var hud: CanvasLayer

@onready var player: Player

@onready var spawn_sprite: Sprite2D = $SpawnSprite

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var jump_cooldown: Timer = $Jump/JumpCooldown
@onready var jump_sound: AudioStreamPlayer = $Jump/JumpSound

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var death_timer: Timer = $DeathTimer

@onready var basic_slash: Area2D = $BossBasicSlash
@onready var basic_slash_cooldown: Timer = $BasicSlashCooldown

@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight

@onready var action_decision_cooldown: Timer = $ActionDecisionCooldown

@export var boss := false
@export var MAX_HEALTH = 120

var flip_sprite_at_spawn := true

const SPEED = 130.0
const JUMP_VELOCITY = -280.0
const MAX_FALLING_VELOCITY = 450
const MAX_JUMPS = 2 # Multiple jumps
const STRENGTH = 3

const EXP_DROP_VALUE = 5

enum State {Default, Fainted, Attacking, Dashing}
enum Anim {idle, run, dash, jump, fall, faint}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

var direction: float # direction input
var jumps := MAX_JUMPS # jumps left

# stats
var health: int

# mirror boss specific variables

var active := false

enum Action {None, RunToward, RunAway, Jump, Dash, BasicSlashUp,  BasicSlashDown,  BasicSlashLeft,  BasicSlashRight, MagicSlash}
var action := Action.None # indicate what the mirror boss is trying to do
var can_change_action := true

var can_jump := true
var can_attack := true

func handle_movement() -> void:
	# Restore jumps if grounded.
	if is_on_floor():
		jumps = MAX_JUMPS
	# If the player leaves the ground without jumping, it should be counted as a jump
	elif jumps == MAX_JUMPS:
		jumps = MAX_JUMPS-1
	
	# Jump if there are jumps left
	if action == Action.Jump and can_jump and jumps > 0 and state != State.Attacking:
		velocity.y = JUMP_VELOCITY
		jumps -= 1
		can_jump = false
		jump_cooldown.start()
		
		# restart animation
		anim = Anim.jump
		animation_player.stop()
		animation_player.play("jump")

	# Handle movements.
	if action == Action.RunToward:
		direction = -sign(position.x - player.position.x)
	elif action == Action.RunAway:
		direction = sign(position.x - player.position.x)
	else:
		direction = 0

func handle_slash() -> void:
	# attacking state corresponds to the basic slash being active
	if basic_slash.active:
		state = State.Attacking
	elif state == State.Attacking:
		state = State.Default

	# basic slash up
	if action == Action.BasicSlashUp and can_attack and is_hurtable() and state == State.Default:
		can_attack = false
		basic_slash.start("up")
		basic_slash_cooldown.start()
	
	# basic slash down
	elif action == Action.BasicSlashDown and can_attack and is_hurtable() and state == State.Default:
		can_attack = false
		basic_slash.start("down")
		basic_slash_cooldown.start()
	
	# basic slash left
	elif action == Action.BasicSlashLeft and can_attack and is_hurtable() and state == State.Default:
		can_attack = false
		basic_slash.start("left")
		basic_slash_cooldown.start()
		sprite.flip_h = true
	
	# basic slash right	
	elif action == Action.BasicSlashRight and can_attack and is_hurtable() and state == State.Default:
		can_attack = false
		basic_slash.start("right")
		basic_slash_cooldown.start()
		sprite.flip_h = false

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

func draw_health_bar() -> void:
	if boss:
		hud.display_boss = true
		hud.boss_name.text = "Dark Cherry"

func activate() -> void:
	active = true
	sprite.visible = true
	hurtbox.set_deferred("disabled", false)
	
	if boss:
		music.play()
		player.state = player.State.Default

func _ready() -> void:
	add_to_group("enemies")

	if boss:
		music = %Music
		hud = %HUD
		player = %Player
		music.stop()
		player.state = player.State.Stop
		flip_sprite_at_spawn = true

	else:
		player = Global.player
	
	health = MAX_HEALTH
	spawn_sprite.flip_h = flip_sprite_at_spawn
	sprite.flip_h = flip_sprite_at_spawn

func _physics_process(delta: float) -> void:
	if active:
		if can_change_action:
			find_action()

		# handle player's actions if they are not defeated
		if state != State.Fainted:
			if state != State.Dashing:
				handle_slash() # attacks
				handle_movement() # left, right and jump
			
			if state != State.Attacking:
				handle_flip_h() # flip sprite horizontally if the player is not attacking
				#handle_dash() # can't dash while attacking
		else:
			direction = 0
		
		if state != State.Dashing:
			handle_velocity(delta) # velocity update based on the above modification
		
		animate() # update the sprite animation if necessary
		move_and_slide()
		
		print(sprite.visible, ", ", hurtbox.disabled)

func change_action(new_action: Action) -> void:
	if can_change_action:
		can_change_action = false
		action_decision_cooldown.start()
		action = new_action

# what to do on that frame
func find_action() -> void:
	# do nothing if the player is defeated
	if player.health == 0:
		change_action(Action.None)
	
	# attack left if the player is in range and hurtable
	elif state == State.Default \
	and player.is_hurtable() \
	and position.x > player.position.x \
	and abs(position.x - player.position.x) < 32 \
	and abs(position.y - player.position.y) < 24:
		change_action(Action.BasicSlashLeft)
	
	# attack right if the player is in range and hurtable
	elif state == State.Default \
	and player.is_hurtable() \
	and position.x < player.position.x \
	and abs(position.x - player.position.x) < 32 \
	and abs(position.y - player.position.y) < 24:
		change_action(Action.BasicSlashRight)
	
	# attack up if the player is in range and hurtable
	elif state == State.Default \
	and player.is_hurtable() \
	and position.y > player.position.y \
	and abs(position.y - player.position.y) < 32 \
	and abs(position.x - player.position.x) < 24:
		change_action(Action.BasicSlashUp)
	
	# attack down if the player is in range and hurtable
	elif state == State.Default \
	and player.is_hurtable() \
	and player.position.y > position.y \
	and abs(position.y - player.position.y) < 32 \
	and abs(position.x - player.position.x) < 24:
		change_action(Action.BasicSlashDown)
	
	# run away if player is attacking forward
	elif player.state == player.State.Attacking \
	and not (ray_cast_left.is_colliding() or ray_cast_right.is_colliding()) \
	and (abs(position.x - player.position.x) < 96) \
	and (abs(position.y - player.position.y) < 32) \
	and ((player.basic_slash.direction == "left" and position.x < player.position.x) or (player.basic_slash.direction == "right" and position.x > player.position.x)):
		change_action(Action.RunAway)
	
	# run away if player is attacking from above
	elif player.state == player.State.Attacking \
	and not (ray_cast_left.is_colliding() or ray_cast_right.is_colliding()) \
	and (abs(position.x - player.position.x) < 32) \
	and (position.y - player.position.y > 32) \
	and player.basic_slash.direction == "down":
		change_action(Action.RunAway)
	
	# jump if the player casts a magic slash and it's coming close
	elif player.magic_slash.active \
	and ((player.magic_slash.direction == 1 and position.x > player.magic_slash.position.x and position.x - player.magic_slash.position.x < 96) or (player.magic_slash.direction == -1 and player.magic_slash.position.x > position.x and player.magic_slash.position.x - position.x < 96)) \
	and abs(position.y - player.magic_slash.position.y) < 32:
		change_action(Action.Jump)
	
	# jump if the player attacks while dashing horizontally toward and near
	elif player.state == player.State.DashingAndAttacking \
	and ((player.dash_direction.x == 1 and position.x > player.position.x and position.x - player.position.x < 128) or (player.dash_direction.x == -1 and player.position.x > position.x and player.position.x - position.x < 128)) \
	and abs(position.y - player.get_middle_position().y) < 32:
		change_action(Action.Jump)
	
	# run toward if it's safe to do it and if the player is not too high
	elif not (player.state == player.State.Attacking \
	and player.state == player.State.Dashing \
	#and abs(position.y - player.position.y) < 64 \
	and (abs(position.x - player.position.x) > 96)) \
	and abs(position.x - player.position.x) >= 28:
		change_action(Action.RunToward)

	# jump to reach the player that is above but not too far
	elif action != Action.RunAway \
	and abs(position.x - player.position.x) < 64 \
	and position.y - player.get_middle_position().y > 32 \
	#and position.y - player.get_middle_position().y < 64 \
	and can_jump:
		change_action(Action.Jump)
	
	# run away if the player is too close and there's no wall
	elif abs(position.x - player.position.x) < 16:
		change_action(Action.RunAway)

	# do nothing
	else:
		change_action(Action.None)

func is_hurtable() -> bool:
	return not effects_player.current_animation == "blink"

func end_dash() -> void:
	pass

func hurt(damage: int, _attack: Area2D) -> bool:
	if is_hurtable():
		end_dash()
		
		# boss is still alive
		if health > damage:
			health -= damage
			velocity.x *= 0.5
			hurt_sound.play()
			hurtbox.set_deferred("disabled", true)
			hurt_invicibility_timer.start()
			effects_player.play("blink")
		
		# boss is dead
		else:
			fainted()
		
	return not is_hurtable()

func fainted() -> void:
	if state != State.Fainted:
		health = 0
		play_animation("faint")
		state = State.Fainted
		velocity.y = 0
		death_sound.play()
		
		# exp drops
		if boss:
			Global.create_multiple_exp_drop(EXP_DROP_VALUE, position, 250)
		
		# keep track of dark cherry clones
		else:
			get_parent().dark_cherry_spawn_counter -= 1

		death_timer.start()

func _on_jump_cooldown_timeout() -> void:
	can_jump = true

func _on_action_decision_cooldown_timeout() -> void:
	can_change_action = true

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_death_timer_timeout() -> void:
	if boss:
		Global.next_level()
	else:
		queue_free()

func _on_basic_slash_cooldown_timeout() -> void:
	can_attack = true

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)
