extends Area2D

const OFFSET = 10

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cooldown: Timer = $Cooldown
@onready var slash_sound: AudioStreamPlayer = $SlashSound

var active: bool = false

func reset() -> void:
	animation_player.play("RESET")
	active = false

func start(orientation: String) -> void:
	active = true
	cooldown.start()
	animation_player.play(orientation)
	slash_sound.play()

func _on_cooldown_timeout() -> void:
	reset()

func _on_body_entered(body: Node2D) -> void:
	body.hurt()
