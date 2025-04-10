extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var mana_value := 100

func _ready() -> void:
	if Global.mana_orb_collected:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop \
	and body.mana < body.max_mana:
		body.restore_mana(mana_value)
		animation_player.play("pickup")
