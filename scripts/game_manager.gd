extends Node

var score = 0
var max_score = 0

func add_point():
	score += 1

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
