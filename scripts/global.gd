extends Node

var player_sprite: Resource = load("res://assets/sprites/chars/player/spr_cherry.png")
var player_color: Color
var stars: int
var total_stars: int

var player: CharacterBody2D = null
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
