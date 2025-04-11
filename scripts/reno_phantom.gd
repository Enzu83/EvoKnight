extends Sprite2D

@export var speed: float
@export var initial_position: Vector2

func init(initial_position_: Vector2, speed_: float) -> Node2D:
	initial_position = initial_position_
	speed = speed_
	return self

func _ready() -> void:
	position = initial_position
	
	if speed < 0:
		flip_h = true

func _physics_process(delta: float) -> void:
	position.x += speed * delta

func _on_duration_timeout() -> void:
	queue_free()
