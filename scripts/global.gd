extends Node

# level manager
var current_level := 0
var level_paths = [
	"res://scenes/levels/title_screen.tscn",
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/boss_area.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
]

# player skin
var color_list := ["red", "blue", "green", "purple"]

var colors := {
	"red": Color(211 / 255.0, 47 / 255.0, 63 / 255.0, 1.0),
	"blue": Color(91 / 255.0, 123 / 255.0, 227 / 255.0, 1.0),
	"green": Color(47 / 255.0, 211 / 255.0, 66 / 255.0, 1.0),
	"purple": Color(211 / 255.0, 47 / 255.0, 192 / 255.0, 1.0),
	"dark": Color(67 / 255.0, 67 / 255.0, 67 / 255.0),
}

var player_sprite_path := "res://assets/sprites/chars/player/"
var slash_sprite_path := "res://assets/sprites/fx/slash/"
var ui_icon_path := "res://assets/sprites/ui/icons/"


var player_sprite: Resource
var basic_slash_sprite: Resource
var charged_slash_effect_sprite: Resource
var magic_slash_sprite: Resource
var magic_slash_icon: Resource
var dash_icon: Resource

var player_color: String

# stars
var pending_stars: Array # stars are not really collected until a checkpoint is gotten
var collected_stars: Array
var total_stars: Array

# entities
var player: CharacterBody2D = null
var respawn_position: Vector2 = Vector2.INF
var boss: Node2D = null

# events that pause the game
var paused := false

var pause_menu: CanvasLayer = load("res://scenes/other/pause.tscn").instantiate()
var level_up: CanvasLayer = load("res://scenes/other/level_up.tscn").instantiate()
var end_recap: CanvasLayer = load("res://scenes/other/end_recap.tscn").instantiate()

# screen fade out animation
var fade_out_scene: Resource = preload("res://scenes/other/fade_out.tscn")

# drops
var heart_drop_scene: Resource = preload("res://scenes/items/heart_drop.tscn")
var exp_drop_scene: Resource = preload("res://scenes/items/exp_drop.tscn")

# display sprite if the game is cleared
var cleared := false

# player info
var player_max_health := 10
var player_health := player_max_health

var player_level := 1
var player_level_experience := [0, 0, 50, 70, 85, 100]
var player_experience := 0

# [max_health_increase, max_mana_increase, strength_increase]
var player_level_stats_increase := {
	"max_health": [0, 0, 3, 2, 2, 3],
	"strength": [0, 0, 1, 1, 0, 1],
	"defense": [0, 0, 0, 1, 1, 0]
}

var player_dash_enabled := true

var player_mana_enabled := true
var player_max_mana := 400
var player_mana := 0
var player_mana_recovery_rate := 0

var player_strength := 1
var player_defense := 0

var player_bigger_slash := false

# player upgrades per level - check for pick up
var level_upgrade: Array

# elapsed time (ms)
var elapsed_time_reference := 0

# electric arc state
var electric_arc_enabled := true

var electric_arc_auto_enabled := false
var electric_arc_auto_timer := Timer.new()

var electric_arc_stream: Resource = load("res://assets/sfx/snd_lever.wav")
var electric_arc_sound := AudioStreamPlayer.new()

# dash block
var dash_block_activated := false

# boss defeated
var big_bat_defeated := false
var ceres_defeated := false

func _ready() -> void:
	add_child(pause_menu)
	add_child(level_up)
	add_child(end_recap)
	init_stars()
	init_player_stats()
	set_player_color(color_list[0]) # default skin: red

	init_level_upgrade()
	
	init_auto_switch_electric_arc()
	init_dash_block()
	
	# game rendering
	init_screen_size()

func _process(_delta: float) -> void:
	# debug inputs
	if Input.is_action_just_pressed("reset"):
		reset_level()
	elif Input.is_action_just_pressed("previous_level"):
		previous_level()
	elif Input.is_action_just_pressed("next_level"):
		next_level()
	elif Input.is_action_pressed("exp") and player != null:
		player.gain_exp(1)
	
	# pause tree
	if pause_menu.visible or level_up.visible or end_recap.visible:
		get_tree().paused = true
	else:
		get_tree().paused = false
	
func init_stars() -> void:
	pending_stars = []
	collected_stars = []
	total_stars = []

	for _i in range(level_paths.size()):
		collected_stars.append([])
		total_stars.append([])

func init_player_stats() -> void:
	player_max_health = 10
	player_health = player_max_health

	player_level = 1
	player_experience = 0

	player_dash_enabled = true

	player_mana_enabled = true
	player_max_mana = 400
	player_mana = 0
	player_mana_recovery_rate = 0

	player_strength = 1
	player_defense = 0
	
	player_bigger_slash = false

func init_level_upgrade() -> void:
	level_upgrade.resize(level_paths.size())
	level_upgrade.fill(false)

func init_auto_switch_electric_arc() -> void:
	# electric arc auto switch timer & sound
	electric_arc_auto_timer.wait_time = 2.0
	electric_arc_auto_timer.one_shot = false
	electric_arc_auto_timer.autostart = true
	electric_arc_auto_timer.paused = true
	electric_arc_auto_timer.connect("timeout", _on_electric_arc_auto_timer_timeout)
	
	electric_arc_sound.stream = electric_arc_stream
	electric_arc_sound.bus = "SFX"
	
	add_child(electric_arc_auto_timer)
	add_child(electric_arc_sound)

func toggle_electric_arc_auto_switch() -> void:
	electric_arc_auto_timer.paused = !electric_arc_auto_timer.paused

func _on_electric_arc_auto_timer_timeout() -> void:
	electric_arc_sound.play()
	electric_arc_auto_enabled = !electric_arc_auto_enabled

func init_dash_block() -> void:
	dash_block_activated = false

func toggle_dash_block() -> void:
	dash_block_activated = !dash_block_activated

func init_screen_size() -> void:
	get_viewport().size = DisplayServer.screen_get_size()
	get_window().move_to_center()

func set_elapsed_time_reference() -> void:
	elapsed_time_reference = Time.get_ticks_msec()

func get_elapsed_time() -> int:
	return Time.get_ticks_msec() - elapsed_time_reference

func add_star_to_total(star: Area2D) -> void:
	if not total_stars[current_level].has(star.position):
		total_stars[current_level].append(star.position)

func add_star_to_collected(star: Area2D) -> void:
	if not collected_stars[current_level].has(star.position):
		collected_stars[current_level].append(star.position)

func add_star_to_pending(star: Area2D) -> void:
	pending_stars.append(star.position)

func collect_pending_stars() -> void:
	for star_position in pending_stars:
		collected_stars[current_level].append(star_position)
	
	pending_stars = []

func is_star_collected(star: Area2D) -> bool:
	return collected_stars[current_level].has(star.position)

func get_total_stars() -> int:
	var stars := 0
	
	for i in range(total_stars.size()):
		stars += total_stars[i].size()
	
	return stars

func get_collected_stars() -> int:
	var stars := 0
	
	for i in range(collected_stars.size()):
		stars += collected_stars[i].size()
	
	return stars

func get_pending_stars() -> int:
	return pending_stars.size()

func get_level_stars() -> int:
	return collected_stars[current_level].size()

func get_level_total_stars() -> int:
	return total_stars[current_level].size()

func get_collected_upgrades() -> int:
	var collected_upgrades = 0
	
	for upgrade in level_upgrade:
		if upgrade:
			collected_upgrades += 1
	
	return collected_upgrades

func get_total_upgrades() -> int:
	# one per level - 4 levels in total
	return 4

func collect_level_upgrade() -> void:
	level_upgrade[current_level] = true

func get_level_upgrade_state() -> bool:
	return level_upgrade[current_level]

func reset_level() -> void:
	# reset player skin
	if player != null and player.ability_disabled:
		set_player_color(player_color)
		player_dash_enabled = true
		player_mana_enabled = true
	
	# reset specific level variables
	electric_arc_enabled = true
	electric_arc_auto_timer.start()
	electric_arc_auto_timer.paused = true
	
	dash_block_activated = false
	
	# loose collected stars without checkpoint
	pending_stars = []
	
	get_tree().call_deferred("reload_current_scene")
	
	if player != null:
		player.init_info()
	
	add_child(fade_out_scene.instantiate())

func goto_level(level_id: int) -> void:
	# add pending stars to collected ones
	collect_pending_stars()
	
	current_level = level_id
	reset_level()
	respawn_position = Vector2.INF # reset checkpoint position

	get_tree().call_deferred("change_scene_to_file", level_paths[current_level])

func next_level() -> void:
	if current_level < level_paths.size() - 1:
		goto_level(current_level + 1)

func previous_level() -> void:
	if current_level > 0:
		goto_level(current_level - 1)

func set_player_color(color: String, temporary: bool = false) -> void:
	if not temporary:
		player_color = color
	
	player_sprite = load(player_sprite_path + "spr_cherry_" + color + ".png")
	basic_slash_sprite = load(slash_sprite_path + "spr_basic_slash_" + color + ".png")
	charged_slash_effect_sprite = load(slash_sprite_path + "spr_charged_slash_effect_" + color + ".png")
	magic_slash_sprite = load(slash_sprite_path + "spr_magic_slash_" + color + ".png")
	magic_slash_icon = load(ui_icon_path + "spr_magic_slash_icon_" + color + ".png")
	dash_icon = load(ui_icon_path + "spr_dash_icon_" + color + ".png")

func store_player_info() -> void:
	player_max_health = player.max_health
	player_health = player.health
	
	player_level = player.level
	player_experience = player.experience
	
	player_dash_enabled = player.dash_enabled

	player_mana_enabled = player.mana_enabled
	player_max_mana = player.max_mana
	player_mana = player.mana
	player_mana_recovery_rate = player.mana_recovery_rate

	player_strength = player.strength
	player_defense = player.defense
	
	player_bigger_slash = player.bigger_slash

func create_heart_drop(heal_value: int,initial_position: Vector2, initial_velocity: Vector2) -> void:
	var heart_drop: CharacterBody2D = heart_drop_scene.instantiate().init(heal_value, initial_position, initial_velocity)
	get_tree().current_scene.call_deferred("add_child", heart_drop)

func create_exp_drop(exp_value: int,initial_position: Vector2, initial_velocity: Vector2) -> void:
	var exp_drop: CharacterBody2D = exp_drop_scene.instantiate().init(exp_value, initial_position, initial_velocity)
	get_tree().current_scene.call_deferred("add_child", exp_drop)

func create_drop(drop_rate: float, heal_value: int, exp_value: int, initial_position: Vector2, initial_velocity: Vector2) -> void:
	# chance to drop something
	if randf() <= drop_rate:

		# more chance to drop a heart if the player's health is low
		if randf() < 1 - player.health / float(player.max_health):
			create_heart_drop(heal_value, initial_position, initial_velocity)

		# exp drop
		else:
			create_exp_drop(exp_value, initial_position, initial_velocity)

func create_multiple_exp_drop(exp_value: int, initial_position: Vector2, speed: float) -> void:
	# 8-direction exp drop
	create_exp_drop(exp_value, initial_position, speed * Vector2(-1, -1) * 0.8) # up left
	create_exp_drop(exp_value, initial_position, speed * Vector2( 0, -1)) # up
	create_exp_drop(exp_value, initial_position, speed * Vector2( 1, -1) * 0.8) # up right
	create_exp_drop(exp_value, initial_position, speed * Vector2( 1,  0)) # right
	create_exp_drop(exp_value, initial_position, speed * Vector2( 1,  1) * 0.8) # down right
	create_exp_drop(exp_value, initial_position, speed * Vector2( 0,  1)) # down
	create_exp_drop(exp_value, initial_position, speed * Vector2(-1,  1) * 0.8) # down left
	create_exp_drop(exp_value, initial_position, speed * Vector2(-1,  0)) # left
