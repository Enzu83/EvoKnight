extends Sprite2D

@onready var farewell_ceres: CharacterBody2D = $".."

func _ready() -> void:
	# get position from ceres's one
	position = farewell_ceres.get_middle_position()

	# sprite
	texture = farewell_ceres.sprite.texture
	frame = farewell_ceres.sprite.frame
		
	flip_h = farewell_ceres.sprite.flip_h  # match ceres's orientation
