extends Area2D

const OFFSET = 10
const STRENGTH = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cooldown: Timer = $Cooldown
@onready var player: CharacterBody2D = $".."

var active: bool = false

func reset() -> void:
	animation_player.play("RESET")
	active = false

func start(orientation: String) -> void:
	active = true
	cooldown.start()
	animation_player.play(orientation)

func _on_cooldown_timeout() -> void:
	reset()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.hurt(STRENGTH * player.strength)
