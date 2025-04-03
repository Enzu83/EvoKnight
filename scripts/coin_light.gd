extends Sprite2D

@onready var coin: Area2D = $".."

func _physics_process(_delta: float) -> void:
	if coin.activated:
		frame = 1
	else:
		frame = 0
