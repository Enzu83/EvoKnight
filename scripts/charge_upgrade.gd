extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if Global.get_level_upgrade_state():
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		body.shield_max = 3 * body.shield_max / 4
		body.bigger_slash_max = 3 * body.bigger_slash_max / 4
		animation_player.play("pickup")
		Global.collect_level_upgrade()
