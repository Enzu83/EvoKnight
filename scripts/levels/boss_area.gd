extends Node2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var dark_cherry: CharacterBody2D = $DarkCherry

@onready var camera: Camera2D = %Camera
@onready var music: AudioStreamPlayer = %Music

@onready var fake_wall_timer: Timer = $FakeWallTimer
@onready var fake_wall: StaticBody2D = $FakeWall
@onready var break_wall_sound: AudioStreamPlayer = $BreakWallSound

const UPGRADE = preload("res://scenes/items/upgrade.tscn")

var boss_defeated := false

func _ready() -> void:
	Global.current_level = 3
	Global.player = player
	player.state = player.State.Stop
	
	Global.boss = dark_cherry
	
	hud.display_collectable = false
	hud.display_boss = false

func _physics_process(_delta: float) -> void:
	if not boss_defeated and dark_cherry.state == dark_cherry.State.Fainted:
		add_child(UPGRADE.instantiate().init(1, dark_cherry.position + Vector2(0, -16), Vector2(0, -70))) # charged slash
		music.stop()
		boss_defeated = true
		fake_wall_timer.start()
		
func _on_fake_wall_timer_timeout() -> void:
	camera.limit_right = 390
	break_wall_sound.play()
	fake_wall.queue_free()
