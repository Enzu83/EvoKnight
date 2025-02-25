extends Area2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPRING_FORCE = -450.0

func spring(body: Node2D) -> void:
	animation_player.stop()
	animation_player.play("spring")
	body.bumped(SPRING_FORCE, Vector2.DOWN)

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	
	if body == player:
		spring(body)

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		spring(body)
