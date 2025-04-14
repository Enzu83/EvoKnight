extends CharacterBody2D

@onready var player: Player

@onready var farewell_ceres: CharacterBody2D = $"../.."
@onready var sprite: Sprite2D = $Sprite
@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var wait_timer: Timer = $WaitTimer
@onready var move_timer: Timer = $MoveTimer

const PHANTOM = preload("res://scenes/chars/farewell_ceres_phantom.tscn")

const CERES_ORB = preload("res://scenes/fx/ceres_orb.tscn")
const CERES_FOLLOWING_ORB = preload("res://scenes/fx/ceres_following_orb.tscn")
const CERES_ROTATING_ORB = preload("res://scenes/fx/ceres_rotating_orb.tscn")

const FAREWELL_CERES_CLONE = preload("res://scenes/chars/farewell_ceres_clone.tscn")

const STRENGTH = 6

enum State {Default, Defeated, Attacking, Action, Stall}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

var initial_position: Vector2

var move_target_position: Vector2

var health := 1

# actions
var action_queue = [] # list of remaining actions to perform
var last_action := -1

func init(initial_position_: Vector2) -> Node2D:
	initial_position = initial_position_
	return self

func _ready() -> void:
	player = farewell_ceres.player
	
	position = initial_position
	
	handle_flip_h()

func _physics_process(_delta: float) -> void:
	sprite.visible = farewell_ceres.sprite.visible
	sprite.texture = farewell_ceres.sprite.texture
	sprite.frame = farewell_ceres.sprite.frame

	handle_flip_h()

func handle_flip_h() -> void:
	# flip the sprite to match the direction
	if position.x <  farewell_ceres.player.position.x:
		sprite.flip_h = false
	elif position.x >  farewell_ceres.player.position.x:
		sprite.flip_h = true

func hurt(_damage: int, _attack: Area2D) -> bool:
	farewell_ceres.teleport_sound.play()
	queue_free()
	return false

func get_middle_position() -> Vector2:
	return position - Vector2(0, wall_collider.shape.get_rect().size.y)

func play_animation(_anim_name: String) -> void:
	pass

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
	action_queue.append(["wait", 10.5])

func wait(duration: float) -> void:
	state = State.Action
	play_animation("idle")
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

func teleport_end(_target_position: Vector2) -> void:
	state = State.Action
	#position = target_position
	play_animation("teleport_end")
	wait_timer.start(0.6) # time of the animation

func spawn_clone(_clone_position: Vector2) -> void:
	# clones don't spawn other clones
	pass
	
func delete_clones() -> void:
	# clones don't delete themselves
	pass

func end_fight() -> void:
	pass
	
func circle_orb_attack(number_of_orbs: int = 1, distance: float = 20.0, angle_offset: float = 0.0, initial_wait_time: float = 0.0, speed: float = 300.0) -> void:
	for i in range(number_of_orbs):
		var angle := angle_offset + i * 2 * PI / number_of_orbs - PI / 2
		add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + distance * Vector2(cos(angle_offset + angle), sin(angle_offset + angle)), initial_wait_time, false, 6.0, speed))

func spaced_floor_orb_attack(begin: int = 0, end: int = 9) -> void:
	
	
	for i in range(begin, end):
		add_child(CERES_ORB.instantiate()
						   .init(Vector2(15600 + 47 * i, -1788), Vector2(15600 + 47 * i, -1480), 0.0, false)
						   .second_target(Vector2(15600 + 47 * i, -1736)) # draw a target at the top of the area to indicate the spawn of falling orbs
		)

func following_orb_attack(initial_time: float, duration: float = 10.0) -> void:
	add_child(CERES_FOLLOWING_ORB.instantiate().init(get_middle_position(), player, initial_time, false, duration))

func left_horizontal_orb_attack(hole_begin: int, hole_end: int, duration: float = 6.0, speed: float = 300.0) -> void:
	
	
	for i in range(17):
		# spawn orbs everywhere except the hole area
		if i < hole_begin or i > hole_end:
			# only the first orb makes a sound
			add_child(CERES_ORB.instantiate().init(Vector2(15568, -1736 + 16 * i), Vector2(15600, -1736 + 16 * i), 0, false, duration, speed))
			

func right_horizontal_orb_attack(hole_begin: int, hole_end: int, duration: float = 6.0, speed: float = 300.0) -> void:
	
	
	for i in range(17):
		# spawn orbs everywhere except the hole area
		if i < hole_begin or i > hole_end:
			# only the first orb makes a sound
			add_child(CERES_ORB.instantiate().init(Vector2(16008, -1736 + 16 * i), Vector2(15976, -1736 + 16 * i), 0, false, duration, speed))
			

func rotating_orb_shield_attack(clockwise: bool, number_of_orbs: int = 3, distance: float = 20.0, angle_offset: float = 0.0, initial_wait_time: float = 0.0, duration: float = 6.0, rotation_speed: float = 300.0) -> void:
	
	
	for i in range(number_of_orbs):
		var angle := angle_offset + i * 2 * PI / number_of_orbs - PI / 2
		add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + distance * Vector2(cos(angle_offset + angle), sin(angle_offset + angle)), initial_wait_time, duration, false, clockwise, rotation_speed, 0.0, true))

		

func rotating_orb_attack(clockwise: bool, rotation_position: Vector2, rotation_increment_position: Vector2) -> void:
	
	
	for i in range(15):
		add_child(CERES_ROTATING_ORB.instantiate().init(
			get_middle_position(), # spawning position
			get_middle_position() + rotation_position + i * rotation_increment_position, # rotation starting position
			1.0 + 0.05 * i, # wait time before moving at the beginning
			10, # duration
			false,  # sound or not
			clockwise, # rotation direction
			50, # speed of the rotation
			2.0 - 0.05 * i) # wait before rotation (inverse of starting wait time to time all the orbs)
		)
		

func target_orbs_attack(semi_length: int, distance: float = 40.0, speed: float = 300.0, initial_wait_time: float = 0.0) -> void:
	# delta_position length is bounded
	var delta_position := distance *(player.get_middle_position() - get_middle_position()).normalized()
	
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

func _on_wait_timer_timeout() -> void:
	if state == State.Action:
		state = State.Default

func _on_move_timer_timeout() -> void:
	if state == State.Action:
		state = State.Default
		velocity = Vector2.ZERO
		position = move_target_position

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)
