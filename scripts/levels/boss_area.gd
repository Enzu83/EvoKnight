extends Node2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var boss_mirror: CharacterBody2D = $BossMirror

func _ready() -> void:
	Global.current_level = 3
	Global.player = player
	player.state = player.State.Stop
	
	Global.boss = boss_mirror
