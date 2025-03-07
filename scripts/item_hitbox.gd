extends Area2D

@onready var item: Node2D = $".."

func _on_hitbox_area_entered(area: Area2D) -> void:
	item.pick_up(area)

func _on_hitbox_body_entered(body: Node2D) -> void:
	item.pick_up_body(body)
