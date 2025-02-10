extends Area2D

@onready var timer: Timer = $Timer
@onready var death_sound: AudioStreamPlayer = $DeathSound

func _on_body_entered(body: Node2D) -> void:
	if not body.fainted:
		death_sound.play()
		body.get_node("AnimatedSprite2D").play("faint")
		body.fainted = true
		timer.start()
	

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
