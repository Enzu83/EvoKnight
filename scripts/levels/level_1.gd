extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var player: Player = %Player

func _ready() -> void:
	Global.current_level = 1
	Global.player = player
	hud.mode = hud.DisplayMode.Collectable

	if Global.respawn_position != Vector2.INF:
		player.position = Global.respawn_position
