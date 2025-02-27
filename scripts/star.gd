extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	Global.add_star_to_total(self)
	
	if Global.is_star_collected(self):
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	Global.add_star_to_pending(self)
	animation_player.play("pickup")
