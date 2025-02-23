extends Area2D

var heal_value := 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	if not body.health == body.max_health \
	 and body.state != body.State.Fainted:
		body.heal(heal_value)
		animation_player.play("pickup")
