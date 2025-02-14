class_name DashPhantom
extends Sprite2D

@onready var player: Player = $".."

func _ready() -> void:
	# get position from player's one
	position = player.get_middle_position()

	# sprite
	texture = Global.player_sprite
	modulate = Global.player_color
	
	# if the player is in idle animation, chane the frame to the dashing one
	if player.sprite.frame < 9:
		frame = 11
	else:
		frame = player.sprite.frame
		
	frame = 45
	flip_h = player.sprite.flip_h
