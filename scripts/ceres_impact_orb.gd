extends Area2D

const SPEED = 250
const STRENGTH = 6

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var impact_sound: AudioStreamPlayer = $ImpactSound

@onready var ceres: CharacterBody2D = $".."

@onready var target_icon: AnimatedSprite2D = $TargetIcon
@onready var wait_timer: Timer = $WaitTimer

var current_speed: Vector2

var target_position: Vector2
var active := false
var impact := false

var initial_skipped_time: int # (ms) skipped for the wait timer

func init(targeted_position: Vector2, skipped_time: int) -> Node2D:
	target_position = targeted_position
	initial_skipped_time = skipped_time
	return self

func _ready() -> void:
	# reduce the time before falling
	wait_timer.start(wait_timer.wait_time - initial_skipped_time / 1000.0)

func _process(delta: float) -> void:
	target_icon.position = target_position

	# move toward the target position
	if active \
	and not impact:
		current_speed.y = move_toward(current_speed.y, SPEED, 20)
		position += current_speed * delta
		
		# land on the target floor
		if position.y > target_position.y:
			impact = true
			position.y = target_position.y
			animation_player.play("impact")
			impact_sound.play()
	
	# stop attacking if ceres is defeated
	if ceres.state == ceres.State.Defeated \
	or ceres.state == ceres.State.Fainted:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == ceres.player and ceres.player.is_hurtable():
		body.hurt(STRENGTH)

func _on_wait_timer_timeout() -> void:
	active = true
	position.x = target_position.x # align with the target
	position.y = -432 # start at the top of the room
	animation_player.play("shoot")
