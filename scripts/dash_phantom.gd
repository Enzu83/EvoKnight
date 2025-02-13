class_name DashPhantom
extends Sprite2D

func init(initial_position: Vector2, horizontal_flip: bool) -> DashPhantom:
	position = initial_position
	flip_h = horizontal_flip
	return self
