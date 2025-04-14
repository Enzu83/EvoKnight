extends Sprite2D

@export var direction: Vector2
@export var speed: float

func init(direction_: Vector2, speed_: float) -> Node2D:
	direction = direction_
	speed = speed_
	
	return self

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	if scale > delta * Vector2.ONE:
		scale -= delta * Vector2.ONE
	else:
		queue_free()

func _on_change_sprite_timer_timeout() -> void:
	frame = posmod(frame + 1, 2)
