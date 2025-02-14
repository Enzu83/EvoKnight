extends CanvasLayer

@onready var health_bar: TextureProgressBar = $Main/HealthBar
@onready var health_value: Label = $Main/HealthValue
@onready var health_color_manager: AnimationPlayer = $Main/HealthValue/ColorManager

@onready var exp_bar: TextureProgressBar = $Main/ExpBar
@onready var mana_bar: TextureProgressBar = $Mana/ManaBar

@onready var dash_threshold: Line2D = $Mana/DashThreshold
@onready var dash_icon: TextureRect = $Mana/DashIcon

@onready var magic_slash_threshold: Line2D = $Mana/MagicSlashThreshold
@onready var magic_slash_icon: TextureRect = $Mana/MagicSlashIcon

@onready var score: TextureRect = $Score
@onready var score_label: Label = $Score/ScoreLabel

@onready var boss_bar: TextureRect = $BossBar
@onready var boss_health_bar: TextureProgressBar = $BossBar/HealthBar

enum DisplayMode {None, Collectable, Boss}
var mode := DisplayMode.None

var player: CharacterBody2D = null
var boss: CharacterBody2D = null

var dash_threshold_initial_position: Vector2
var magic_slash_threshold_initial_position: Vector2

func _ready() -> void:
	dash_threshold_initial_position = dash_threshold.position
	magic_slash_threshold_initial_position = magic_slash_threshold.position
	
	dash_icon.texture = Global.dash_icon
	magic_slash_icon.texture = Global.magic_slash_icon

func _process(_delta: float) -> void:
	player = Global.player
	boss = Global.boss
	
	# get player stats
	health_bar.value = int((player.health / float(player.max_health)) * health_bar.max_value)
	exp_bar.value = int((player.experience / float(player.next_level_experience)) * exp_bar.max_value)
	
	# update health value
	health_value.text = str(player.health)
	
	# draw the value green is health is full
	if health_bar.value == health_bar.max_value:
		health_color_manager.play("green")
	else:
		health_color_manager.play("white")
	
	# dash threshold indicator
	dash_threshold.position.x = dash_threshold_initial_position.x + (player.DASH_MANA / float(player.max_mana)) * mana_bar.max_value
	
	# dash icon displayed if it can be perfomed
	if player.can_dash and player.state == player.State.Default and player.mana >= player.DASH_MANA:
		dash_icon.visible = true
	else:
		dash_icon.visible = false
		
	# magic slash threshold indicator
	magic_slash_threshold.position.x = magic_slash_threshold_initial_position.x + (player.MAGIC_SLASH_MANA / float(player.max_mana)) * mana_bar.max_value
	
	# magic slash icon displayed if it can be casted
	if player.state == player.State.Default and not player.magic_slash.active and player.mana >= player.MAGIC_SLASH_MANA:
		magic_slash_icon.visible = true
	else:
		magic_slash_icon.visible = false
	
	# get player mana
	mana_bar.value = int((player.mana / float(player.max_mana)) * mana_bar.max_value)
	
	hide_all() # hide all specific ui before make some of them visible
	
	if mode == DisplayMode.Collectable:
		draw_collectable_ui()
	elif mode == DisplayMode.Boss:
		draw_boss_ui()
	
func hide_all() -> void:
	score.visible = false
	boss_bar.visible = false

func draw_collectable_ui() -> void:
	score.visible = true
	score_label.text = str(Global.stars) + "/" + str(Global.total_stars)

func draw_boss_ui() -> void:
	boss_bar.visible = true
	boss_health_bar.value = int((boss.health / float(boss.MAX_HEALTH)) * boss_health_bar.max_value)
