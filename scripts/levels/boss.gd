extends Node2D

@onready var hud: CanvasLayer = %HUD

func _ready() -> void:
	hud.mode = hud.DisplayMode.Boss
