extends Node2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var dark_cherry: CharacterBody2D = $DarkCherry

func _ready() -> void:
	Global.current_level = 3
	Global.player = player
	player.state = player.State.Stop
	
	Global.boss = dark_cherry
	
	hud.display_collectable = false
	hud.display_boss = false
