extends Node

var score = 0

@onready var hud: CanvasLayer = %HUD


func _ready() -> void:
	pass

func add_point():
	score += 1
