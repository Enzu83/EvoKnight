extends CharacterBody2D

@onready var player: Player = %Player

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

@onready var action_decision_cooldown: Timer = $ActionDecisionCooldown

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_FALLING_VELOCITY = 450
const MAX_JUMPS = 2 # Multiple jumps

const MAX_HEALTH = 100
const EXP_GIVEN = 50

enum State {Default, Fainted, Attacking, Dashing}
enum Anim {idle, run, dash, jump, fall, faint}

# player state and actions
var state := State.Default # handle all states of the player
var anim := Anim.idle # handle the current animation to be played

var direction: float # direction input
var jumps := MAX_JUMPS # jumps left

# stats
var health := MAX_HEALTH

# mirror boss specific variables

enum Action {None, RunToward, RunAway, Jump, Dash, BasicSlash, MagicSlash}
var action := Action.None # indicate what the mirror boss is trying to do
var can_change_action := true

var can_jump := true

func handle_movement() -> void:
	# Restore jumps if grounded.
	if is_on_floor():
		jumps = MAX_JUMPS
	# If the player leaves the ground without jumping, it should be counted as a jump
	elif jumps == MAX_JUMPS:
		jumps = MAX_JUMPS-1
	
	# Jump if there are jumps left
	if action == Action.Jump and jumps > 0 and state != State.Attacking:
		velocity.y = JUMP_VELOCITY
		jumps -= 1
		jump_cooldown.start()
		
		# restart animation
		anim = Anim.jump
		animation_player.stop()
		animation_player.play("jump")

	# Handle movements.
	if action == Action.RunToward and abs(position.x - player.position.x) >= 8:
		direction = -sign(position.x - player.position.x)
	elif action == Action.RunAway and abs(position.x - player.position.x) >= 8:
		direction = sign(position.x - player.position.x)
	else:
		direction = 0

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
	add_to_group("enemies")	

func _physics_process(delta: float) -> void:
	if can_change_action:
		find_action()
	#print(Action.find_key(action))

	# handle player's actions if they are not defeated
	if state != State.Fainted:
		if state != State.Dashing:
			#handle_slash() # attacks
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

func change_action(new_action: Action) -> void:
	if can_change_action:
		can_change_action = false
		action_decision_cooldown.start()
		action = new_action

# what to do on that frame
func find_action() -> void:
	if player.state == player.State.Attacking \
	and (abs(position.x - player.position.x) < 96) \
	and (abs(position.y - player.position.y) < 32) \
	and ((player.basic_slash.direction == "left" and position.x < player.position.x) or (player.basic_slash.direction == "right" and position.x > player.position.x)):
		change_action(Action.RunAway)
	
	elif not (player.state == player.State.Attacking and (abs(position.x - player.position.x) > 96)) \
	and abs(position.x - player.position.x) > 36:
		change_action(Action.RunToward)

	elif action != Action.RunAway and position.y - player.get_middle_position().y > 32 and can_jump:
		change_action(Action.Jump)
		
	elif abs(position.x - player.position.x) < 16:
		change_action(Action.RunAway)

	else:
		change_action(Action.None)

func is_hurtable() -> bool:
	return not effects_player.current_animation == "blink"

func end_dash() -> void:
	pass

func hurt(damage: int, _attack: Area2D) -> void:
	if is_hurtable():
		end_dash()
		
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
		player.experience += EXP_GIVEN
		play_animation("faint")
		state = State.Fainted
		velocity.y = 0
		death_sound.play()
		death_timer.start()

func _on_jump_cooldown_timeout() -> void:
	can_jump = true

func _on_action_decision_cooldown_timeout() -> void:
	can_change_action = true

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_death_timer_timeout() -> void:
	visible = false
