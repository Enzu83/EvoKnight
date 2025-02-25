class_name DashPhantom
extends Sprite2D

@onready var player: Player = $".."

func _ready() -> void:
	# get position from player's one
	position = player.get_middle_position()

	# sprite
	texture = Global.player_sprite
	modulate = Global.player_color
	
	# phantom is blue if the player's dash is invicible
	if player.blue_dash:
		frame = 45
		
	# regular dash sprite
	elif not player.super_speed:
		frame = 11
	else:
		frame = player.sprite.frame
		
	flip_h = player.sprite.flip_h  # match player's orientation
