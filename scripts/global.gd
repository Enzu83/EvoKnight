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
var boss: CharacterBody2D = null

# pause menu
var pause_menu : CanvasLayer = load("res://scenes/other/pause.tscn").instantiate()
var paused := false

func _ready() -> void:
	init_stars()
	add_child(pause_menu)

func _process(_delta: float) -> void:
	# debug inputs
	if Input.is_action_just_pressed("reset"):
		reset()
	elif Input.is_action_just_pressed("previous_level"):
		previous_level()
	elif Input.is_action_just_pressed("next_level"):
		next_level()

func init_stars() -> void:
	stars = 0
	total_stars = 0

func reset() -> void:
	init_stars()
	get_tree().call_deferred("reload_current_scene")

func goto_level(level_id: int) -> void:
	current_level = level_id
	reset()
	respawn_position = Vector2.INF # reset checkpoint position
	get_tree().call_deferred("change_scene_to_file", level_paths[current_level])


func next_level() -> void:
	if current_level < level_paths.size() - 1:
		goto_level(current_level + 1)

func previous_level() -> void:
	if current_level > 0:
		goto_level(current_level - 1)
