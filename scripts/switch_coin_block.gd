extends StaticBody2D

@onready var end_point: Node2D = $EndPoint

@onready var coin_sprite: AnimatedSprite2D = $CoinSprite
@onready var clear_sound: AudioStreamPlayer = $ClearSound

const SPEED = 50.0

var activated := false
var activated_position: Vector2

func check_activation() -> bool:
	for child in get_children():
		if child is SwitchCoin and not child.activated:
			return false
	
	return true

func _ready() -> void:
	activated_position = position + end_point.position

func _physics_process(delta: float) -> void:
	if not activated and check_activation():
		activated = true
		clear_sound.play()
		coin_sprite.play("activated")
	
	elif activated:
		position = position.move_toward(activated_position, delta * SPEED)
