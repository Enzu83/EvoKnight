extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var opened := false

func open() -> void:
	if not opened:
		opened = true
		animation_player.play("open")

func close() -> void:
	opened = false
	animation_player.play("close")
