extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if Global.get_level_upgrade_state():
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		body.max_mana += 100
		body.restore_mana(body.max_mana)
		animation_player.play("pickup")
		Global.collect_level_upgrade()
