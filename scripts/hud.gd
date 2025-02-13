extends CanvasLayer

@onready var game_manager: Node = %GameManager
@onready var player: CharacterBody2D = %Player

@onready var health_bar: TextureProgressBar = $Main/HealthBar
@onready var health_value: Label = $Main/HealthValue
@onready var health_color_manager: AnimationPlayer = $Main/HealthValue/ColorManager

@onready var exp_bar: TextureProgressBar = $Main/ExpBar
@onready var mana_bar: TextureProgressBar = $Mana/ManaBar
@onready var dash_threshold: Line2D = $Mana/DashThreshold
@onready var magic_slash_threshold: Line2D = $Mana/MagicSlashThreshold

@onready var score_label: Label = $ScoreLabel

var dash_threshold_initial_position: Vector2
var magic_slash_threshold_initial_position: Vector2

func _ready() -> void:
	dash_threshold_initial_position = dash_threshold.position
	magic_slash_threshold_initial_position = magic_slash_threshold.position

func _process(_delta: float) -> void:
	# get player stats
	health_bar.value = int((player.health / float(player.max_health)) * health_bar.max_value)
	exp_bar.value = int((player.experience / float(player.next_level_experience)) * exp_bar.max_value)
	
	# update health value
	health_value.text = str(health_bar.value)
	
	# draw the value green is health is full
	if health_bar.value == health_bar.max_value:
		health_color_manager.play("green")
	else:
		health_color_manager.play("white")
	
	# magic slash threshold indicator
	magic_slash_threshold.position.x = magic_slash_threshold_initial_position.x + (player.MAGIC_SLASH_MANA / float(player.max_mana)) * mana_bar.max_value
	# dash threshold indicator
	dash_threshold.position.x = dash_threshold_initial_position.x + (player.DASH_MANA / float(player.max_mana)) * mana_bar.max_value
		
	# get player mana
	mana_bar.value = int((player.mana / float(player.max_mana)) * mana_bar.max_value)
	
	
	score_label.text = "Stars: " + str(game_manager.score)
