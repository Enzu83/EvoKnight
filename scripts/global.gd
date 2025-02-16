extends Node

var player_sprite: Resource = load("res://assets/sprites/chars/player/spr_cherry_red.png")
var basic_slash_sprite: Resource = load("res://assets/sprites/fx/slash/spr_basic_slash_red.png")
var magic_slash_sprite: Resource = load("res://assets/sprites/fx/slash/spr_magic_slash_red.png")
var magic_slash_icon: Resource = load("res://assets/sprites/ui/icons/spr_magic_slash_icon_red.png")
var dash_icon: Resource = load("res://assets/sprites/ui/icons/spr_dash_icon_red.png")

var player_color: Color
var stars: int
var total_stars: int

var player: CharacterBody2D = null
var respawn_position: Vector2 = Vector2.INF
var boss: CharacterBody2D = null

func _ready() -> void:
	stars = 0
	total_stars = 0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		reset()

func reset() -> void:
	_ready()
	get_tree().reload_current_scene()
