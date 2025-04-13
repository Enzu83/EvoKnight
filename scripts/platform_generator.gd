extends Node2D

@onready var new_platform_timer: Timer = $NewPlatformTimer

const LARGE_PLATFORM = preload("res://scenes/platforms/large_platform.tscn")


@export var direction := Vector2.LEFT
@export var speed = 40.0
@export var total_platforms := 6

var platform_list: Array

func _ready() -> void:
	# leave a gap between each platform that has the length of a platform
	new_platform_timer.start(72.0 / speed)

func _physics_process(delta: float) -> void:
	for platform in platform_list:
		platform.position += direction * speed * delta

func _on_new_platform_timer_timeout() -> void:
	# remove the first-in platform if the array is full
	if platform_list.size() == total_platforms:
		platform_list.pop_front().queue_free()
	
	# add a new platform
	var new_platform = LARGE_PLATFORM.instantiate()
	platform_list.append(new_platform)
	add_child(new_platform)
	
