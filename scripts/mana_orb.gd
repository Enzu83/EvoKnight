extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	if body.mana < body.max_mana \
	and body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		body.restore_mana(body.max_mana)
		animation_player.play("pickup")
