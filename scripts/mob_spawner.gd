extends Node2D

var mob_scene: Resource

func set_mob(mob_path: String) -> void:
	mob_scene = load(mob_path)

func spawn() -> void:
	get_parent().add_child(mob_scene.instantiate())
	queue_free()
