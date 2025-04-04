extends Area2D

@onready var body: CharacterBody2D = $".."

func _ready() -> void:
	add_to_group("enemies")

func hurt(damage: int, attack: Area2D) -> bool:
	return body.hurt(damage, attack)
