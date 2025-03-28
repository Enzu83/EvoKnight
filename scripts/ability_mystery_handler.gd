extends Area2D

func reset() -> void:
	for ability_mystery in get_children():
		if ability_mystery is not CollisionShape2D:
			ability_mystery.reset()

func disable_all() -> void:
	for ability_mystery in get_children():
		if ability_mystery is not CollisionShape2D:
			ability_mystery.disable = true
			ability_mystery.reveal()

func _on_area_entered(_area: Area2D) -> void:
	reset()
