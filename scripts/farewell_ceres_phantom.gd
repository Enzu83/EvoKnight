extends Sprite2D

@onready var farewell_ceres: CharacterBody2D = $".."
@onready var vanish: AnimationPlayer = $Vanish
@onready var duration: Timer = $Duration

var initial_position: Vector2
var duration_time: float

func init(initial_position_: Vector2, duration_time_: float = 0.2) -> Node2D:
	initial_position = initial_position_
	duration_time = duration_time_
	return self
	
func _ready() -> void:
	position = initial_position

	# sprite
	texture = farewell_ceres.sprite.texture
	frame = farewell_ceres.sprite.frame
		
	flip_h = farewell_ceres.sprite.flip_h  # match ceres's orientation
	
	vanish.speed_scale = 0.2 / duration_time
	duration.start(duration_time)

func _on_duration_timeout() -> void:
	queue_free()
