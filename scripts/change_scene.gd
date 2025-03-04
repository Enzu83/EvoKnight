extends Area2D

func check_for_next_level(body: Node2D) -> void:
	if body == Global.player \
	and body.state != body.State.Fainted:
		Global.player_health = Global.player_max_health
		Global.next_level()

func _on_body_entered(body: Node2D) -> void:
	check_for_next_level(body)

func _on_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	check_for_next_level(body)
