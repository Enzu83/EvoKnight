extends CanvasLayer

@onready var game_manager: Node = %GameManager
@onready var player: CharacterBody2D = %Player

@onready var health_bar: TextureProgressBar = $Stats/HealthBar
@onready var exp_bar: TextureProgressBar = $Stats/ExpBar
@onready var score_label: Label = $ScoreLabel

func _process(_delta: float) -> void:
	health_bar.value = int((player.health / float(player.max_health)) * health_bar.max_value)
	exp_bar.value = 0 * exp_bar.max_value
	
	score_label.text = "Stars: " + str(game_manager.score)

func set_health_bar(value: int) -> void:
	health_bar.value = value

func set_relative_health_bar(value: int) -> void:
	health_bar.value += value

func set_exp_bar(value: int) -> void:
	exp_bar.value = value

func set_relative_exp_bar(value: int) -> void:
	exp_bar.value += value
