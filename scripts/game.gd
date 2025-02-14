extends Node2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player

func _ready() -> void:
	Global.player = player

	hud.mode = hud.DisplayMode.Collectable
