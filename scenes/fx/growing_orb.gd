extends Sprite2D

@export var color := "black"

const LIGHT_ORB = preload("res://assets/sprites/fx/spr_light_orb.png")
const DARK_ORB = preload("res://assets/sprites/fx/spr_dark_orb.png")

func init(initial_position: Vector2, color_: String) -> Node2D:
	position = initial_position
	color = color_
	return self

func _ready() -> void:
	if color == "light":
		texture = LIGHT_ORB
		
	elif color == "dark":
		texture = DARK_ORB
