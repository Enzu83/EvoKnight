extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const VANISH_TEXT = preload("res://scenes/other/vanish_text.tscn")

func _ready() -> void:
	if Global.get_level_upgrade_state():
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		body.max_health += 5
		body.heal(body.max_health)
		animation_player.play("pickup")
		Global.collect_level_upgrade()

		body.add_child(VANISH_TEXT.instantiate().init("Health +5"))
