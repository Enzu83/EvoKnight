extends Area2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPRING_FORCE = -450.0

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	
	if body == player:
		animation_player.play("spring")
		body.bumped(SPRING_FORCE, Vector2.DOWN)
