extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	if not body.health == body.max_health \
	and body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		body.heal(body.max_health)
		animation_player.play("pickup")
