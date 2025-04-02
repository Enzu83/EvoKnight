extends Node2D

var mob_scene: Resource

var flip_sprite := false

func set_mob(mob_path: String) -> void:
	mob_scene = load(mob_path)

func spawn() -> void:
	var mob: Node2D = mob_scene.instantiate()
	mob.position = position
	mob.flip_sprite = flip_sprite
	
	get_parent().add_child(mob)
	queue_free()
