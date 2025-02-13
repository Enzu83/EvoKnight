extends Area2D

@onready var cloporte: CharacterBody2D = $".."

func _ready() -> void:
	add_to_group("enemies")

func hurt(damage: int, attack: Area2D) -> void:
	cloporte.hurt(damage, attack)
