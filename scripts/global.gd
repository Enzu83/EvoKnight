extends Node

# level manager
var current_level := 0
var level_paths = [
	"res://scenes/levels/title_screen.tscn",
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/boss_area.tscn",
]

# player skin
var player_sprite: Resource = load("res://assets/sprites/chars/player/spr_cherry_red.png")
var basic_slash_sprite: Resource = load("res://assets/sprites/fx/slash/spr_basic_slash_red.png")
var magic_slash_sprite: Resource = load("res://assets/sprites/fx/slash/spr_magic_slash_red.png")
var magic_slash_icon: Resource = load("res://assets/sprites/ui/icons/spr_magic_slash_icon_red.png")
var dash_icon: Resource = load("res://assets/sprites/ui/icons/spr_dash_icon_red.png")

var player_color: Color
var stars: int
var total_stars: int

# entities
var player: CharacterBody2D = null
var respawn_position: Vector2 = Vector2.INF
var boss: Node2D = null

# events that pauses the game
var paused := false

var pause_menu: CanvasLayer = load("res://scenes/other/pause.tscn").instantiate()
var level_up: CanvasLayer = load("res://scenes/other/level_up.tscn").instantiate()

# player info
var player_max_health := 10
var player_health := player_max_health

var player_level := 1
var player_level_experience := [0, 0, 50, 70, 85, 100]
var player_experience := 0

# [max_health_increase, max_mana_increase, strength_increase]
var player_level_stats_increase := {
	"max_health": [0, 0, 3, 2, 2, 3],
	"strength": [0, 0, 1, 1, 0, 1],
	"defense": [0, 0, 0, 1, 1, 0]
}

var player_max_mana := 400
var player_mana := 0

var player_strength := 1
var player_defense := 0

func _ready() -> void:
	init_stars_score()
	add_child(pause_menu)
	add_child(level_up)

func _process(_delta: float) -> void:
	
	# debug inputs
	if Input.is_action_just_pressed("reset"):
		reset_level()
	elif Input.is_action_just_pressed("previous_level"):
		previous_level()
	elif Input.is_action_just_pressed("next_level"):
		next_level()
	elif Input.is_action_pressed("exp") and player != null:
		player.gain_exp(1)
	
	# pause tree
	if pause_menu.visible or level_up.visible:
		get_tree().paused = true
	else:
		get_tree().paused = false

func init_stars_score() -> void:
	stars = 0
	total_stars = 0

func reset_level() -> void:
	init_stars_score()
	get_tree().call_deferred("reload_current_scene")
	
	if player != null:
		player.init_info()

func goto_level(level_id: int) -> void:
	current_level = level_id
	reset_level()
	respawn_position = Vector2.INF # reset checkpoint position
	get_tree().call_deferred("change_scene_to_file", level_paths[current_level])

func next_level() -> void:
	if current_level < level_paths.size() - 1:
		goto_level(current_level + 1)

func previous_level() -> void:
	if current_level > 0:
		goto_level(current_level - 1)

func store_player_info() -> void:
	player_max_health = player.max_health
	player_health = player.health
	
	player_level = player.level
	player_experience = player.experience

	player_max_mana = player.max_mana
	player_mana = player.mana

	player_strength = player.strength
	player_defense = player.defense
