extends Node2D

@onready var respawn_cooldown: Timer = $RespawnCooldown

const HEART = preload("res://scenes/items/heart.tscn")

@export var heal_value := 4
@export var cooldown := 20.0

var can_spawn_heart := true

func _ready() -> void:
	spawn_heart()
	respawn_cooldown.wait_time = cooldown

func _physics_process(_delta: float) -> void:
	if can_spawn_heart:
		spawn_heart()
	
	# if there's no heart (only the timer as its child) : start the timer
	elif get_child_count() == 1 and respawn_cooldown.is_stopped():
		respawn_cooldown.start()

func spawn_heart() -> void:
	can_spawn_heart = false
	
	var heart := HEART.instantiate()
	heart.heal_value = heal_value
	add_child(heart)

func _on_respawn_cooldown_timeout() -> void:
	can_spawn_heart = true
