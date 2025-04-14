extends Area2D

const SPEED = 300
const STRENGTH = 6

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var duration: Timer = $Duration

@onready var ceres: CharacterBody2D = $".."

@onready var target_icon: AnimatedSprite2D = $TargetIcon

var direction: Vector2
var current_speed: Vector2

var origin: Node2D
var target: Player
var active := false
var fire := false

func init(origin_node: Node2D, targeted_node: Node2D) -> Node2D:
	origin = origin_node
	target = targeted_node
	
	return self

func _physics_process(delta: float) -> void:
	# aim the target with the icon
	target_icon.position = target.get_middle_position()
	
	# fire only if ceres is in idle animation
	if active \
	and not fire \
	and origin.anim == origin.Anim.idle:
		position = origin.get_middle_position()
		var orientation := (target.get_middle_position() - position).normalized()
		rotation += atan2(orientation.y, orientation.x)
		direction = orientation
		
		duration.start()
		fire = true
		animation_player.play("shoot")
		slash_sound.play()
		
	# move toward the target
	if fire:
		current_speed.x = move_toward(current_speed.x, direction.x * SPEED, abs(direction.x) * 20)
		current_speed.y = move_toward(current_speed.y, direction.y * SPEED, abs(direction.y) * 20)
		
		position += current_speed * delta
	
	# stop attacking if ceres is defeated
	if ceres.state == ceres.State.Defeated \
	or ceres.state == ceres.State.Stall \
	or ceres.health == 0:
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
