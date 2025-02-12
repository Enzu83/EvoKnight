extends CanvasLayer

@onready var game_manager: Node = %GameManager
@onready var player: CharacterBody2D = %Player

@onready var health_bar: TextureProgressBar = $Main/HealthBar
@onready var exp_bar: TextureProgressBar = $Main/ExpBar
@onready var mana_bar: TextureProgressBar = $Mana/ManaBar
@onready var mana_threshold: Line2D = $Mana/ManaThreshold

@onready var score_label: Label = $ScoreLabel

var mana_threshold_initial_position: Vector2

func _ready() -> void:
	mana_threshold_initial_position = mana_threshold.position

func _process(_delta: float) -> void:
	health_bar.value = int((player.health / float(player.max_health)) * health_bar.max_value)
	exp_bar.value = int((player.experience / float(player.next_level_experience)) * exp_bar.max_value)
	
	# magic slash threshold indicator
	mana_threshold.position.x = mana_threshold_initial_position.x + (player.MAGIC_SLASH_MANA / float(player.max_mana)) * mana_bar.max_value
	mana_bar.value = int((player.mana / float(player.max_mana)) * mana_bar.max_value)
	
	
	score_label.text = "Stars: " + str(game_manager.score)
