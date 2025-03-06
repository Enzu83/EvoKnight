extends Area2D

@onready var music: AudioStreamPlayer = %Music
@onready var boss_music: AudioStreamPlayer = %BossMusic

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

@onready var ceres: CharacterBody2D = $Ceres

@onready var electric_sound: AudioStreamPlayer = $ElectricSound

@onready var wait_before_camera_timer: Timer = $WaitBeforeCameraTimer
@onready var end_fight_timer: Timer = $EndFightTimer

enum State {None, Wait, BossSpawn, Fight, FightEnd, Finish}

var state: State

var camera_limit_left: int
var camera_limit_right: int
var camera_limit_top: int
var camera_limit_bottom: int

func _ready() -> void:
	state = State.None

func _process(_delta: float) -> void:
	# initiate the fight
	if state == State.BossSpawn and ceres.active:
		state = State.Fight
		boss_music.play()
		player.state = player.State.Default
	
	# end fight animation
	elif state == State.Fight and ceres.state == ceres.State.Defeated:
		state = State.FightEnd
		boss_music.stop()
	
	# free the room
	elif state == State.FightEnd and ceres.state == ceres.State.Fainted:
		state = State.Finish
		end_fight_timer.start()

func _on_area_entered(_area: Area2D) -> void:
	# start the fight
	if state == State.None \
	and not Global.ceres_defeated:
		state = State.Wait
		Global.electric_arc_enabled = true
		electric_sound.play()
		music.stop()
		
		# stop the player
		player.state = player.State.Stop
		player.velocity.x = 0
		player.direction = 0
		player.phantom_cooldown.stop()
		
		# camera moves to the center of the room
		wait_before_camera_timer.start()


func _on_wait_before_camera_timer_timeout() -> void:
	state = State.BossSpawn
	
	# store current camera limit
	camera_limit_left = camera.limit_left
	camera_limit_right = camera.limit_right
	camera_limit_top = camera.limit_top
	camera_limit_bottom = camera.limit_bottom
	
	# fix camera limit
	camera.limit_left = 4181
	camera.limit_right = 4501
	camera.limit_top = -416
	camera.limit_bottom = -136
	
	ceres.spawn()

func _on_end_fight_timer_timeout() -> void:
	Global.ceres_defeated = true
	music.play()
	Global.electric_arc_enabled = false
	electric_sound.play()
	
	player.state = player.State.Default
	
	# previous camera view
	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	camera.limit_top = camera_limit_top
	camera.limit_bottom = camera_limit_bottom
