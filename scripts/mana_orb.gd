extends Area2D

var heal_value := 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	if body.mana < body.max_mana:
		body.restore_mana(body.max_mana)
		animation_player.play("pickup")
