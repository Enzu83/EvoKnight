extends Area2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

@onready var music: AudioStreamPlayer = %Music
@onready var boss_music: AudioStreamPlayer = %BossMusic

@onready var farewell_ceres: CharacterBody2D = $FarewellCeres

@onready var trigger: CollisionShape2D = $Trigger

var state := 0

var camera_limit_left: int
var camera_limit_right: int
var camera_limit_top: int
var camera_limit_bottom: int

func _physics_process(_delta: float) -> void:
	if state > 0:
		# update hud current health bar
		hud.current_boss_health_bar = farewell_ceres.health_bar
		
		# check when fighting phase is over
		if farewell_ceres.state == farewell_ceres.State.Stall:
			state += 1
			
			farewell_ceres.state = farewell_ceres.State.Default # (debug)

func _on_area_entered(_area: Area2D) -> void:
	# init the fight
	if state == 0:
		state = 1
		#player.state = player.State.Stop
		player.sprite.flip_h = false
		
		# hud
		Global.boss = farewell_ceres
		hud.display_boss = true
		hud.current_boss_health_bar = farewell_ceres.health_bar
		hud.boss_name.text = "Ceres"
		
		# lock camera
		camera_limit_left = camera.limit_left
		camera_limit_right = camera.limit_right
		camera_limit_top = camera.limit_top
		camera_limit_bottom = camera.limit_bottom
		
		# fix camera limit
		camera.limit_left = 15576
		camera.limit_right = 16002
		camera.limit_top = -1760
		camera.limit_bottom = -1456
		
		# musics
		music.stop()
		boss_music.play()
