extends Area2D

const SPEED = 300
const STRENGTH = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var duration: Timer = $Duration

@onready var ceres: CharacterBody2D = $".."

@onready var wait_timer: Timer = $WaitTimer
@onready var target_icon: AnimatedSprite2D = $TargetIcon

var direction: Vector2
var current_speed: Vector2

var target: Player
var active := false

func init(initial_position: Vector2, targeted_node: Node2D) -> Node2D:
	position = initial_position
	target = targeted_node
	
	return self

func _ready() -> void:
	wait_timer.start()

func _process(delta: float) -> void:
	# aim the target with the icon
	target_icon.position = target.get_middle_position()
	
	# move toward the target
	if active:
		current_speed.x = move_toward(current_speed.x, direction.x * SPEED, 15)
		current_speed.y = move_toward(current_speed.y, direction.y * SPEED, 15)
		
		position += current_speed * delta

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == ceres.player and ceres.player.is_hurtable():
		body.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	animation_player.play("fade_out")

func _on_wait_timer_timeout() -> void:
	var orientation := (target.get_middle_position() - position).normalized()
	rotation += atan2(orientation.y, orientation.x)
	direction = orientation
	
	duration.start()
	active = true
	animation_player.play("shoot")
	slash_sound.play()
