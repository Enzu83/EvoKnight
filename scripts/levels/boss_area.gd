extends Node2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var boss_mirror: CharacterBody2D = $BossMirror


func _ready() -> void:
	Global.player = player
	Global.boss = boss_mirror
	
	hud.mode = hud.DisplayMode.Boss
	
