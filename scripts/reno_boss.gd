extends Area2D

@onready var music: AudioStreamPlayer = %Music
@onready var boss_music: AudioStreamPlayer = %BossMusic

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

@onready var reno: CharacterBody2D = $Reno

@onready var electric_sound: AudioStreamPlayer = $ElectricSound
@onready var electric_arcs: Node2D = $ElectricArcs
@onready var fight_electric_arcs: Node2D = $FightElectricArcs

@onready var wait_before_camera_timer: Timer = $WaitBeforeCameraTimer

const UPGRADE = preload("res://scenes/items/upgrade.tscn")

enum State {None, Wait, BossSpawn, Fight, FightEnd}

var state: State

var camera_limit_left: int
var camera_limit_right: int
var camera_limit_top: int
var camera_limit_bottom: int

func _ready() -> void:
	state = State.None
	
	if Global.reno_defeated:
		queue_free()

func _physics_process(_delta: float) -> void:
	# initiate the fight
	if state == State.BossSpawn and reno.active:
		state = State.Fight
		boss_music.play()
		player.state = player.State.Default
	
	# end fight animation
	elif state == State.Fight and reno.state == reno.State.Defeated:
		state = State.FightEnd
		boss_music.stop()
		fight_electric_arcs.queue_free()
		get_parent().add_child(UPGRADE.instantiate().init(2, reno.position, Vector2(4288, -248))) # shield
	
	# free the room
	elif state == State.FightEnd and reno.state == reno.State.Defeated and player.shield_enabled:
		Global.reno_defeated = true
		music.play()
		Global.electric_arc_enabled = false
		electric_sound.play()
		
		player.state = player.State.Default
		
		# previous camera view
		camera.limit_left = camera_limit_left
		camera.limit_right = camera_limit_right
		camera.limit_top = camera_limit_top
		camera.limit_bottom = camera_limit_bottom
		
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	# start the fight
	if state == State.None \
	and not Global.reno_defeated:
		state = State.Wait
		Global.electric_arc_enabled = false
		
		fight_electric_arcs.visible = true
		electric_arcs.visible = true
		fight_electric_arcs.process_mode = Node.PROCESS_MODE_INHERIT
		electric_arcs.process_mode = Node.PROCESS_MODE_INHERIT
		
		electric_sound.play()
		music.stop()
		
		# stop the player
		player.state = player.State.Stop
		player.velocity.x = 0
		player.direction = 0
		player.phantom_cooldown.stop()
		
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
		
		wait_before_camera_timer.start()

func _on_wait_before_camera_timer_timeout() -> void:
	state = State.BossSpawn
	player.state = player.State.Default
	reno.spawn()

func _on_end_fight_timer_timeout() -> void:
	Global.reno_defeated = true
	music.play()
	Global.electric_arc_enabled = false
	electric_sound.play()
	
	player.state = player.State.Default
	
	# previous camera view
	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	camera.limit_top = camera_limit_top
	camera.limit_bottom = camera_limit_bottom
	
	queue_free()
