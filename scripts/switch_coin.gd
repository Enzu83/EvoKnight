extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var activate_sound: AudioStreamPlayer = $ActivateSound

var activated := false

func activate() -> void:
	if not activated:
		activated = true
		animated_sprite.play("activated")
		activate_sound.play()

func _on_body_entered(_body: Node2D) -> void:
	activate()

func _on_area_entered(_area: Area2D) -> void:
	activate()
