extends Area2D

@onready var music: AudioStreamPlayer = %Music

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func end_level() -> void:
	music.stop()
	Global.end_recap.start()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		animation_player.play("pickup")
