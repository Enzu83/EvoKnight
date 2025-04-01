extends Area2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

@onready var music: AudioStreamPlayer = %Music
@onready var boss_music: AudioStreamPlayer = %BossMusic

@onready var farewell_ceres: CharacterBody2D = $FarewellCeres
@onready var stall_position: Node2D = $StallPosition

@onready var trigger: CollisionShape2D = $Trigger
@onready var fake_wall: StaticBody2D = $FakeWall

@onready var lower_left_platform: AnimatableBody2D = $LowerLeftPlatform
@onready var lower_middle_left_platform: AnimatableBody2D = $LowerMiddleLeftPlatform
@onready var lower_middle_right_platform: AnimatableBody2D = $LowerMiddleRightPlatform
@onready var lower_right_platform: AnimatableBody2D = $LowerRightPlatform
@onready var middle_left_platform: AnimatableBody2D = $MiddleLeftPlatform
@onready var middle_right_platform: AnimatableBody2D = $MiddleRightPlatform
@onready var upper_left_platform: AnimatableBody2D = $UpperLeftPlatform
@onready var upper_right_platform: AnimatableBody2D = $UpperRightPlatform

@onready var mob_list: Node2D = $MobList

@onready var dark_cherry_spawn_timer: Timer = $DarkCherrySpawnTimer

const MOB_SPAWNER = preload("res://scenes/other/mob_spawner.tscn")
var dark_cherry_scene: Resource = preload("res://scenes/chars/dark_cherry.tscn")
var dark_cherry_spawn_counter := 0

var state := 0 # odd: classic fight, even: wave fight
var wave_state := 0

var camera_limit_left: int
var camera_limit_right: int
var camera_limit_top: int
var camera_limit_bottom: int

func _physics_process(_delta: float) -> void:
	if state > 0:
		# update hud current health bar
		hud.current_boss_health_bar = farewell_ceres.health_bar
		
		update_state()
		
		handle_platforms_with_state()
		
		handle_enemy_wave()

func update_state() -> void:
	# advance to wave phase when ceres is stalling
	if farewell_ceres.state == farewell_ceres.State.Stall \
	and state % 2 == 1:
		state += 1
		wave_state = 0
		dark_cherry_spawn_timer.start()

func handle_platforms_with_state() -> void:
	if state == 1:
		set_platform_process(lower_left_platform, true)
		set_platform_process(lower_middle_left_platform, true)
		set_platform_process(lower_middle_right_platform, true)
		set_platform_process(lower_right_platform, true)
		
		set_platform_process(middle_left_platform, true)
		set_platform_process(middle_right_platform, true)
		
		set_platform_process(upper_left_platform, true)
		set_platform_process(upper_right_platform, true)
	
	elif state == 2:
		set_platform_process(lower_left_platform, true)
		set_platform_process(lower_middle_left_platform, true)
		set_platform_process(lower_middle_right_platform, true)
		set_platform_process(lower_right_platform, true)
		
		set_platform_process(middle_left_platform, false)
		set_platform_process(middle_right_platform, false)
		
		set_platform_process(upper_left_platform, false)
		set_platform_process(upper_right_platform, false)

func set_platform_process(platform: Node2D, enable: bool) -> void:
	if enable:
		platform.process_mode = Node.PROCESS_MODE_INHERIT
		platform.visible = true
	else:
		platform.process_mode = Node.PROCESS_MODE_DISABLED
		platform.visible = false

func handle_enemy_wave() -> void:
	# set ceres position to the top of the room
	if state > 0 and state % 2 == 0:
		farewell_ceres.position = stall_position.position
	
	# first wave
	if state == 2:
		pass

func spawn_enemy(spawn_position: Vector2, mob_name: String) -> void:
	var mob_spawner = MOB_SPAWNER.instantiate()
	mob_spawner.position = spawn_position
	mob_spawner.set_mob("res://scenes/chars/" + mob_name + ".tscn")
	mob_list.add_child(mob_spawner)

func spawn_dark_cherry(spawn_position: Vector2, flip_sprite: bool) -> void:
	var dark_cherry = dark_cherry_scene.instantiate()
	dark_cherry.position = spawn_position
	dark_cherry.MAX_HEALTH = 1
	dark_cherry.flip_sprite_at_spawn = flip_sprite
	mob_list.add_child(dark_cherry)

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

func _on_dark_cherry_spawn_timer_timeout() -> void:
	if dark_cherry_spawn_counter == 0:
		spawn_dark_cherry(Vector2(15660, -1472), false)
	else:
		spawn_dark_cherry(Vector2(15916, -1472), true)
		
	dark_cherry_spawn_counter = posmod(dark_cherry_spawn_counter + 1, 2)
