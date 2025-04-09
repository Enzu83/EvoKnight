extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if Global.mana_orb_collected:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		body.mana_enabled = true
		Global.mana_orb_collected = true
		animation_player.play("pickup")
