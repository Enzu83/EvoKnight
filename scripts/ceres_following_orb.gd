extends Area2D

const SPEED = 300
const STRENGTH = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var duration: Timer = $Duration

@onready var ceres: CharacterBody2D = $".."

@onready var initial_wait_timer: Timer = $InitialWaitTimer
@onready var wait_timer: Timer = $WaitTimer

@onready var target_icon: AnimatedSprite2D = $TargetIcon

var direction: Vector2
var current_speed: Vector2

var target: Player
var active := false
var fire := false

var initial_position: Vector2
var target_position: Vector2
var initial_wait_time: float
var play_sound: bool
var duration_time: float


func init(initial_position_: Vector2, target_: Node2D, initial_wait_time_: float = 0.0, play_sound_: bool = true, duration_time_: float = 10.0) -> Node2D:
	initial_position = initial_position_
	target = target_
	initial_wait_time = initial_wait_time_
	play_sound = play_sound_
	duration_time = duration_time_
	
	return self

func _ready() -> void:
	position = initial_position
	initial_wait_timer.start(initial_wait_time + 0.01)

func _physics_process(delta: float) -> void:
	# aim the target with the icon
	target_icon.position = target.get_middle_position()
	
	# fire only if ceres is in idle animation
	if active \
	and not fire:
		duration.start(duration_time)
		fire = true
		animation_player.play("shoot")
		slash_sound.play()
		
	# move toward the target
	if fire:
		var orientation := (target.get_middle_position() - position).normalized()
		
		direction = orientation
		
		current_speed.x = move_toward(current_speed.x, direction.x * SPEED, abs(direction.x) * 10)
		current_speed.y = move_toward(current_speed.y, direction.y * SPEED, abs(direction.y) * 10)
		
		rotation = atan2(current_speed.y, current_speed.x)
		
		position += current_speed * delta
	
	# stop attacking if ceres is defeated or stalling
	if ceres.state == ceres.State.Defeated \
	or ceres.state == ceres.State.Stall:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == ceres.player and ceres.player.is_hurtable():
		body.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	animation_player.play("fade_out")

func _on_wait_timer_timeout() -> void:
	# can shoot
	active = true

func _on_initial_wait_timer_timeout() -> void:
	target_icon.visible = true
	wait_timer.start()
