extends CharacterBody2D

@onready var player: Player = %Player

@onready var sprite: Sprite2D = $Sprite
@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var shield: AnimatedSprite2D = $Shield

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var teleport_sound: AudioStreamPlayer = $TeleportSound
@onready var test_orb: Timer = $TestOrb

@onready var wait_timer: Timer = $WaitTimer
@onready var move_timer: Timer = $MoveTimer

const PHANTOM = preload("res://scenes/chars/farewell_ceres_phantom.tscn")

const CERES_ORB = preload("res://scenes/fx/ceres_orb.tscn")
const CERES_FOLLOWING_ORB = preload("res://scenes/fx/ceres_following_orb.tscn")
const CERES_ROTATING_ORB = preload("res://scenes/fx/ceres_rotating_orb.tscn")

const FAREWELL_CERES_CLONE = preload("res://scenes/chars/farewell_ceres_clone.tscn")

const SPEED = 300.0
const STRENGTH = 6

const HEALTH_BARS = 4

enum State {Default, Defeated, Attacking, Action, Stall}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var max_health := 275

var health := max_health
var health_bar := HEALTH_BARS-1

# boss variables
var active := false
var phase := 0

var move_positions := [
	Vector2(15916, -1614),
	Vector2(15916, -1678),
	Vector2(15660, -1614),
	Vector2(15660, -1678),
]

var move_target_position: Vector2

# actions
var action_queue = [] # list of remaining actions to perform
var last_action := -1

func _ready() -> void:
	active = false

func _physics_process(_delta: float) -> void:
	# choose next action
	if state == State.Default:
		if action_queue.size() > 0:
			perform_action() # do the next action in the list
		
		# first phase : few orb attacks and clones
		elif phase == 0:
			handle_first_phase()
		
		elif phase == 1:
			handle_second_phase()
		
		elif phase == 2:
			handle_third_phase()
		
		elif phase == 3:
			handle_fourth_phase()
		
	
	handle_flip_h()
	move_and_slide()
	

func start() -> void:
	active = true

func handle_flip_h() -> void:
	# flip the sprite to match the direction
	if position.x < player.position.x:
		sprite.flip_h = false
	elif position.x > player.position.x:
		sprite.flip_h = true

func play_animation(anim_name: String) -> void:
	# play the animation if it's no the current one
	if anim != Anim.get(anim_name):
		animation_player.play(anim_name)
		anim = Anim.get(anim_name)

func is_hurtable() -> bool:
	return not shield.visible and not effects_player.current_animation == "blink"

func hurt(damage: int, _attack: Area2D) -> bool:
	var is_hurt := is_hurtable()
	
	if is_hurt:
		# ceres still has hp
		if health > damage:
			health -= damage
			hurt_sound.play()
			hurtbox.set_deferred("disabled", true)
			hurt_invicibility_timer.start()
			effects_player.play("blink")
		
		# ceres loses an health bar
		else:
			fainted()

	return is_hurt

func fainted() -> void:
	if state != State.Defeated:
		# some left health bars
		if health_bar > 0:
			health = max_health
			health_bar -= 1
			state = State.Stall
			teleport_sound.play()
			position = Vector2(15788, -1850) # hide from the player
			
			phase += 1
			last_action = -1
			action_queue = []
		
		# no more health bars left
		else:
			health = 0
			state = State.Defeated
			death_sound.play()
			
			# boss defeated: end of fight animation
			player.state = player.State.Stop
			player.velocity.x = 0
			player.direction = 0
			player.phantom_cooldown.stop()

func get_middle_position() -> Vector2:
	return position - Vector2(0, wall_collider.shape.get_rect().size.y)

func handle_first_phase() -> void:
	# choose an available action
	var available_actions := []

	for i in range(0, 4):
		if i != last_action:
			available_actions.append(i)
	
	var action: int = available_actions[randi_range(0, available_actions.size()-1)]

	# teleports at the center
	# shoots orbs around ceres
	# moves toward one of the four corners
	if action == 0:
		action_teleport(Vector2(15788, -1540), 0.6, 0.2)
		action_queue.append(["rotating_orb_shield_attack", true, 4.2, 400.0])
		action_queue.append(["wait", 2.2])
		action_move(250.0, 1.5)
	
	# disapears
	# shoots falling orbs
	# appears at the center
	elif action == 1:
		action_queue.append(["teleport_start"])
		action_queue.append(["wait", 0.5])
		action_queue.append(["spaced_floor_orb_attack"])
		action_queue.append(["wait", 3.5])
		action_queue.append(["teleport_end", Vector2(15788, -1580)])
		action_queue.append(["play_animation", "idle"])
		action_queue.append(["wait", 1.5])
	
	# shoots rotating orbs in the whole area
	elif action == 2:
		action_teleport(Vector2(15788, -1580), 0.6, 0.2)
		action_rotating_orb_whole_area()
	
	# shoots orbs around ceres
	elif action == 3:
		action_teleport(Vector2(15788, -1580), 0.6, 0.2)
		action_queue.append(["circle_orb_attack", 11, 20.0, 0.0, 0.0, 350.0])
		action_queue.append(["wait", 4.0])
	
	last_action = action

func handle_second_phase() -> void:
	# choose an available action
	var available_actions := []

	for i in range(0, 4):
		if i != last_action:
			available_actions.append(i)
	
	var action: int = available_actions[randi_range(0, available_actions.size()-1)]

	# shoots several series of orbs at the player
	if action == 0:
		action_teleport(Vector2(15788, -1580), 0.6, 0.2)
		action_queue.append(["target_orbs_attack", 3, 32, 350.0, 0.0])
		action_queue.append(["target_orbs_attack", 3, 48, 350.0, 0.05])
		action_queue.append(["target_orbs_attack", 3, 64, 350.0, 0.1])
		action_queue.append(["wait", 0.5])
		action_queue.append(["target_orbs_attack", 3, 32.0, 350.0, 0.0])
		action_queue.append(["target_orbs_attack", 3, 48.0, 350.0, 0.05])
		action_queue.append(["target_orbs_attack", 3, 64.0, 350.0, 0.1])
		action_queue.append(["wait", 0.5])
		action_queue.append(["target_orbs_attack", 3, 32.0, 350.0, 0.0])
		action_queue.append(["target_orbs_attack", 3, 48.0, 350.0, 0.05])
		action_queue.append(["target_orbs_attack", 3, 64.0, 350.0, 0.1])
		action_queue.append(["wait", 3.0])
	
	# shoots three circle orbs
	# the second one has an angle offset
	elif action == 1:
		action_teleport(Vector2(15788, -1616), 0.6, 0.2)
		action_queue.append(["circle_orb_attack", 12, 20.0, 0.0, 0.0, 300.0])
		action_queue.append(["circle_orb_attack", 12, 36.0, PI / 24, 0.6, 300.0])
		action_queue.append(["circle_orb_attack", 12, 52.0, 0.0, 1.2, 300.0])
		action_queue.append(["wait", 5.3])
	
	elif action == 2:
		action_teleport(Vector2(15788, -1680), 0.6, 0.2)
		action_queue.append(["following_orb_attack", 0.0, 9.0])
		action_queue.append(["wait", 2.5])
		
	elif action == 3:
		action_teleport(Vector2(15788, -1616), 0.6, 0.2)
		action_queue.append(["circle_orb_attack", 10, 20.0, 0.0, 0.0, 350.0])
		action_queue.append(["left_horizontal_orb_attack", 7, 11, 6.0, 160.0])
		action_queue.append(["right_horizontal_orb_attack", 7, 11, 6.0, 160.0])
		action_queue.append(["wait", 5.0])
	
	last_action = action

func handle_third_phase() -> void:
	pass

func handle_fourth_phase() -> void:
	pass

func perform_action() -> void:
	var action = action_queue.pop_front()
	
	# call with arguments
	if action.size() > 1:
		callv(action[0], action.slice(1))
	# no arguments for the action
	else:
		call(action[0])

func action_move(speed: float, end_wait_time: float) -> void:
	var move_position: Vector2 = move_positions[randi_range(0, move_positions.size()-1)]
	var phantom_position := move_position - (position - get_middle_position())
	
	action_queue.append(["phantom", phantom_position, 0.7])
	action_queue.append(["wait", 0.8])
	action_queue.append(["move", move_position, speed])
	action_queue.append(["wait", end_wait_time])

func action_teleport(teleport_position: Vector2, teleport_time: float, end_wait_time: float) -> void:
	action_queue.append(["teleport_start"])
	action_queue.append(["wait", teleport_time])
	action_queue.append(["teleport_end", teleport_position])
	action_queue.append(["play_animation", "idle"])
	action_queue.append(["wait", end_wait_time])

func action_rotating_orb_whole_area() -> void:
	action_queue.append(["rotating_orb_attack", false, Vector2(0, 32), Vector2(0, 16)])
	action_queue.append(["rotating_orb_attack", false, Vector2(0, -32), Vector2(0, -16)])
	action_queue.append(["rotating_orb_attack", false, Vector2(-32, 0), Vector2(-16, 0)])
	action_queue.append(["rotating_orb_attack", false, Vector2(32, 0), Vector2(16, 0)])
	action_queue.append(["wait", 11.5])

func wait(duration: float) -> void:
	state = State.Action
	wait_timer.start(duration)

func phantom(spawn_position: Vector2, duration: float = 0.2) -> void:
	state = State.Action
	play_animation("idle")
	add_child(PHANTOM.instantiate().init(spawn_position, duration))
	wait_timer.start(duration)

func move(target_position: Vector2, speed: float) -> void:
	var delta_position := target_position - position
	var duration := delta_position.length() / speed
	var move_angle := atan2(delta_position.y, delta_position.x)

	if duration > 0:
		state = State.Action
		
		velocity.x = speed * cos(move_angle)
		velocity.y = speed * sin(move_angle)
		
		move_target_position = target_position
		move_timer.start(duration)
	
		play_animation("idle")
	
func teleport_start() -> void:
	state = State.Action
	play_animation("teleport_start")
	wait_timer.start(0.6) # time of the animation

func teleport_end(target_position: Vector2) -> void:
	state = State.Action
	position = target_position
	play_animation("teleport_end")
	wait_timer.start(0.6) # time of the animation

func circle_orb_attack(number_of_orbs: int = 1, distance: float = 20.0, angle_offset: float = 0.0, initial_wait_time: float = 0.0, speed: float = 300.0) -> void:
	var fire := false
	
	for i in range(number_of_orbs):
		var angle := angle_offset + i * 2 * PI / number_of_orbs - PI / 2
		add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + distance * Vector2(cos(angle_offset + angle), sin(angle_offset + angle)), initial_wait_time, not fire, 6.0, speed))

		fire = true

func spaced_floor_orb_attack(begin: int = 0, end: int = 9) -> void:
	var fire := false
	
	for i in range(begin, end):
		add_child(CERES_ORB.instantiate()
						   .init(Vector2(15600 + 47 * i, -1788), Vector2(15600 + 47 * i, -1480), 0.0, not fire)
						   .second_target(Vector2(15600 + 47 * i, -1736)) # draw a target at the top of the area to indicate the spawn of falling orbs
		)
		fire = true

func following_orb_attack(initial_time: float, duration: float = 10.0) -> void:
	add_child(CERES_FOLLOWING_ORB.instantiate().init(get_middle_position(), player, initial_time, true, duration))

func left_horizontal_orb_attack(hole_begin: int, hole_end: int, duration: float = 6.0, speed: float = 300.0) -> void:
	var fire := false
	
	for i in range(17):
		# spawn orbs everywhere except the hole area
		if i < hole_begin or i > hole_end:
			# only the first orb makes a sound
			add_child(CERES_ORB.instantiate().init(Vector2(15568, -1736 + 16 * i), Vector2(15600, -1736 + 16 * i), 0, not fire, duration, speed))
			fire = true

func right_horizontal_orb_attack(hole_begin: int, hole_end: int, duration: float = 6.0, speed: float = 300.0) -> void:
	var fire := false
	
	for i in range(17):
		# spawn orbs everywhere except the hole area
		if i < hole_begin or i > hole_end:
			# only the first orb makes a sound
			add_child(CERES_ORB.instantiate().init(Vector2(16008, -1736 + 16 * i), Vector2(15976, -1736 + 16 * i), 0, not fire, duration, speed))
			fire = true

func rotating_orb_shield_attack(clockwise: bool, duration: float, rotation_speed: float = 300.0) -> void:
	add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + 0.7 * Vector2(0, 40), 1.5, duration, true, clockwise, rotation_speed, 0.0, true))
	add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + 0.7 * Vector2(-34, -20), 1.5, duration, true, clockwise, rotation_speed, 0.0, true))
	add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + 0.7 * Vector2(34, -20), 1.5, duration, true, clockwise, rotation_speed, 0.0, true))

func rotating_orb_attack(clockwise: bool, rotation_position: Vector2, rotation_increment_position: Vector2) -> void:
	var fire := false
	
	for i in range(15):
		add_child(CERES_ROTATING_ORB.instantiate().init(
			get_middle_position(), # spawning position
			get_middle_position() + rotation_position + i * rotation_increment_position, # rotation starting position
			1.0 + 0.05 * i, # wait time before moving at the beginning
			10, # duration
			not fire,  # sound or not
			clockwise, # rotation direction
			60, # speed of the rotation
			2.0 - 0.05 * i) # wait before rotation (inverse of starting wait time to time all the orbs)
		)
		fire = true

func target_orbs_attack(semi_length: int, max_distance: float = 40.0, speed: float = 300.0, initial_wait_time: float = 0.0) -> void:
	# delta_position length is bounded
	var delta_position := player.get_middle_position() - get_middle_position()
	
	if delta_position.length() > max_distance:
		delta_position = max_distance * delta_position.normalized()
	
	# angle of the orb targeting directly the player
	var default_angle := atan2(delta_position.y, delta_position.x)
	
	# middle orb
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + delta_position, initial_wait_time, true, 6.0, speed))
	
	# side orbs
	for i in range(semi_length):
		var angle := (i + 1) * PI / 18
		
		add_child(CERES_ORB.instantiate().init(
			get_middle_position(),
			# position + orientatation
			get_middle_position() + delta_position.length() * Vector2(cos(default_angle - angle), sin(default_angle - angle)), 
			initial_wait_time, # initial_wait_time
			false, # no sound
			6.0, # duration
			speed) # orb speed
		)
		
		add_child(CERES_ORB.instantiate().init(
			get_middle_position(),
			# position + orientatation
			get_middle_position() + delta_position.length() * Vector2(cos(default_angle + angle), sin(default_angle + angle)),
			initial_wait_time, # initial_wait_time
			false, # no sound
			6.0, # duration
			speed) # orb speed
		)

func spawn_clone(clone_position: Vector2) -> void:
	add_child(FAREWELL_CERES_CLONE.instantiate().init(clone_position))

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)

func _on_hurt_invicibility_timer_timeout() -> void:
	if state != State.Stall:
		hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_phantom_cooldown_timeout() -> void:
	if velocity.length() > 0:
		phantom(get_middle_position())

func _on_test_orb_timeout() -> void:
	pass
	#target_orbs_attack(3)
	#circle_orb_attack()
	#spaced_floor_orb_attack()
	#left_horizontal_orb_attack(6, 9)
	#right_horizontal_orb_attack(12, 14)
	#rotating_orb_attack(false, Vector2(0, 32), Vector2(0, 16))
	#rotating_orb_attack(false, Vector2(0, -32), Vector2(0, -16))
	#rotating_orb_attack(false, Vector2(-32, 0), Vector2(-16, 0))
	#rotating_orb_attack(false, Vector2(32, 0), Vector2(16, 0))
	#spawn_clone(Vector2(15710, -1544))
	#spawn_clone(Vector2(15866, -1544))
	#spawn_clone(position)
	#following_orb_attack()
	#rotating_orb_shield_attack(true, 5)

func _on_wait_timer_timeout() -> void:
	if state == State.Action:
		state = State.Default

func _on_move_timer_timeout() -> void:
	if state == State.Action:
		state = State.Default
		velocity = Vector2.ZERO
		position = move_target_position
