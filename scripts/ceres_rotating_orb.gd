extends Area2D

const SPEED = 300
const ROTATION_SPEED = 120
const STRENGTH = 7

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: CollisionShape2D = $Hitbox

@onready var initial_wait_timer: Timer = $InitialWaitTimer
@onready var duration_timer: Timer = $DurationTimer
@onready var rotation_wait_timer: Timer = $RotationWaitTimer

@onready var ceres: CharacterBody2D = $".."

@onready var target_icon: AnimatedSprite2D = $TargetIcon

var active := false

var state := 0

var initial_position: Vector2
var target_position: Vector2
var initial_wait_time: float
var duration: float
var play_sound: bool

var clockwise: bool
var rotation_distance: float
var rotation_speed: float
var rotation_wait_time: float
var follow_ceres: bool

func init(initial_position_: Vector2, target_position_: Vector2, initial_wait_time_: float = 1.7, duration_: float = 10.0, play_sound_: bool = true, clockwise_: bool = false, rotation_speed_: float = ROTATION_SPEED, rotation_wait_time_: float = 0.01, follow_ceres_: bool = false) -> Node2D:
	initial_position = initial_position_
	target_position = target_position_
	initial_wait_time = initial_wait_time_
	duration = duration_
	play_sound = play_sound_
	clockwise = clockwise_
	rotation_speed = rotation_speed_
	rotation_wait_time = rotation_wait_time_
	follow_ceres = follow_ceres_
	
	return self

func _ready() -> void:
	position = initial_position
	target_icon.position = target_position
	initial_wait_timer.start(initial_wait_time + 0.01)
	duration_timer.start(duration)
	target_icon.visible = true
	
	var initial_orientation := (target_icon.position - position).normalized()
	rotation += atan2(initial_orientation.y, initial_orientation.x)

func _physics_process(delta: float) -> void:
	# initial wait time
	if active \
	and state == 0:
		state = 1
		animation_player.play("shoot")
		
		if play_sound:
			slash_sound.play()
		
	# move toward the target
	if state == 1:
		position = position.move_toward(target_position, SPEED * delta)
		
		# change orientation of the orb and wait for the rotation
		if position == target_position:
			state = 2
			sprite.visible = true
			hitbox.disabled = false
			
			if clockwise:
				sprite.rotation_degrees += 90
				hitbox.position = Vector2(0, 7)
			else:
				sprite.rotation_degrees -= 90
				hitbox.position = Vector2(0, -7)
			
			rotation_wait_timer.start(rotation_wait_time + 0.01)
			rotation_distance = (position - initial_position).length()
		
	# rotation movement
	if state == 3:
		if clockwise:
			rotation_degrees += rotation_speed * delta
		else:
			rotation_degrees -= rotation_speed * delta
		
		# update rotation center if the orb follows ceres
		if follow_ceres:
			initial_position = ceres.get_middle_position()
		
		position = initial_position + rotation_distance * Vector2(cos(deg_to_rad(rotation_degrees)), sin(deg_to_rad(rotation_degrees)))
		
	# stop attacking if ceres is defeated
	if ceres.state == ceres.State.Defeated:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == ceres.player and ceres.player.is_hurtable():
		body.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	animation_player.play("fade_out")

func _on_initial_wait_timer_timeout() -> void:
	active = true # can shoot

func _on_rotation_wait_timer_timeout() -> void:
	state = 3
