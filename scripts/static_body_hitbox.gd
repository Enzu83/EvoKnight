extends Area2D

@onready var body: StaticBody2D = $".."

func _ready() -> void:
	add_to_group("enemies")

func hurt(damage: int, attack: Area2D) -> bool:
	return body.hurt(damage, attack)
