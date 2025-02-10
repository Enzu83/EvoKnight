extends Area2D

const SPEED = 70

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")

func _on_body_entered(body: Node2D) -> void:
	print("bat: body hurt")
	body.hurt()

func hurt() -> void:
	print("hurt")
