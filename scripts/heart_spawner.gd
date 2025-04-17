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

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# draw circle arc to indicate when the heart will respawn
	if get_child_count() == 1:
		var points_arc = PackedVector2Array()
		points_arc.push_back(Vector2.ZERO)
		
		var angle := 2 * PI * (1 - respawn_cooldown.time_left / respawn_cooldown.wait_time)
		
		for i in range(17):
			var angle_point = i * (angle) / 16 - PI / 2
			points_arc.push_back(6 * Vector2(cos(angle_point), sin(angle_point)))
		
		draw_polygon(points_arc, PackedColorArray([Color.GRAY]))

func spawn_heart() -> void:
	can_spawn_heart = false
	
	var heart := HEART.instantiate()
	heart.heal_value = heal_value
	add_child(heart)

func _on_respawn_cooldown_timeout() -> void:
	can_spawn_heart = true
