extends Node2D

@onready var message: Label = $Message
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var text: String

func init(text_: String) -> Node2D:
	text = text_
	return self

func _ready() -> void:
	message.position.y -= 24
	message.text = text
	
func _on_duration_timer_timeout() -> void:
	animation_player.play("vanish")
