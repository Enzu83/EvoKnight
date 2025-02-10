extends Area2D

const OFFSET = 10

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cooldown: Timer = $Cooldown

var active: bool = false

func reset() -> void:
	animation_player.play("RESET")
	active = false

func start(orientation: String) -> void:
	cooldown.start()
	animation_player.play(orientation)

func _on_cooldown_timeout() -> void:
	reset()

func _on_body_entered(body: Node2D) -> void:
	body.hurt()
