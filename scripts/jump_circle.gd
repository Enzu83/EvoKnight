extends Sprite2D

@onready var player: Player = $".."
@onready var jump_circle: AnimationPlayer = $JumpCircle

func _process(_delta: float) -> void:
	if jump_circle.current_animation == "default":
		# offset to match the jump animation
		if player.sprite.flip_h:
			position.x = 4
		else:
			position.x = -4
