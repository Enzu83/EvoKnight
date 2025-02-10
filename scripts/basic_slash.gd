extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cooldown: Timer = $Cooldown

var active: bool = false

func reset() -> void:
	animation_player.play("RESET")
	active = false

func start(direction: int) -> void:
	active = true
	cooldown.start()
	
	if Input.is_action_just_pressed("up"):
		animation_player.play("up")
	elif Input.is_action_just_pressed("down"):
		animation_player.play("down")
	elif Input.is_action_just_pressed("left"):
		animation_player.play("left")
	elif Input.is_action_just_pressed("right"):
		animation_player.play("right")
	# Default direction
	elif direction > 0:
		animation_player.play("right")
	else:
		animation_player.play("left")

func _on_timer_timeout() -> void:
	reset()
