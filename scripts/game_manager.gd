extends Node

var score = 0

@onready var score_label: Label = $ScoreLabel
@onready var hud: CanvasLayer = %HUD

func _ready() -> void:
	

func add_point():
	score += 1
	score_label.text = "Score: " + str(score)
