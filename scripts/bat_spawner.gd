extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer

var bat_scene: Resource = preload("res://scenes/chars/bat.tscn")

func start_spawn() -> void:
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var bat: Area2D = bat_scene.instantiate()
	bat.top_level = true
	bat.position = position
	add_child(bat)
