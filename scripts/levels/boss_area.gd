extends Node2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var boss_mirror: CharacterBody2D = $BossMirror

@onready var heart_respawn_timer: Timer = $HeartRespawnTimer

var heart: Resource = preload("res://scenes/items/heart.tscn")

var left_heart: Area2D = null
var right_heart: Area2D = null

func respawn_hearts() -> void:
	if not is_instance_valid(left_heart):
		left_heart = heart.instantiate()
		left_heart.position = Vector2(-110, -64)
		left_heart.heal_value = 4
		add_child(left_heart)
		
	if not is_instance_valid(right_heart):
		right_heart = heart.instantiate()
		right_heart.position = Vector2(110, -64)
		right_heart.heal_value = 4
		add_child(right_heart)

func _ready() -> void:
	Global.current_level = 2
	Global.player = player
	Global.boss = boss_mirror
	
	# create hearts
	respawn_hearts()

func _on_heart_respawn_timer_timeout() -> void:
	respawn_hearts()
