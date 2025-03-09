extends Node2D

@onready var title: TextureRect = $Title/Title
@onready var version_label: Label = $Title/VersionLabel
@onready var clear_sprite: AnimatedSprite2D = $Title/ClearSprite

@onready var left_cursor: AnimatedSprite2D = $Menu/LeftCursor
@onready var right_cursor: AnimatedSprite2D = $Menu/RightCursor
@onready var select_sound: AudioStreamPlayer = $Menu/SelectSound

@onready var start_button: Label = $Menu/Main/StartButton
@onready var options_button: Label = $Menu/Main/OptionsButton
@onready var quit_button: Label = $Menu/Main/QuitButton

@onready var skin_button: Label = $Menu/Options/SkinButton
@onready var screen_size_button: Label = $Menu/Options/ScreenSizeButton
@onready var controls_button: Label = $Menu/Options/ControlsButton

@onready var player_skin: Sprite2D = $Menu/Options/PlayerSkin
@onready var skin_left_cursor: AnimatedSprite2D = $Menu/Options/PlayerSkin/LeftCursor
@onready var skin_right_cursor: AnimatedSprite2D = $Menu/Options/PlayerSkin/RightCursor
@onready var skin_color_label: Label = $Menu/Options/PlayerSkin/ColorLabel

@onready var player_controls_info: Label = $PlayerControlsInfo
@onready var extra_controls_info: Label = $ExtraControlsInfo

# states of the menu
var state := 0

# menu options for each state
var menu_options := {}

# position of cursors for each state
var cursor_indexes := {}

# skins
var player_skin_list := [
	"res://assets/sprites/chars/player/spr_cherry_red.png",
	"res://assets/sprites/chars/player/spr_cherry_blue.png",
	"res://assets/sprites/chars/player/spr_cherry_green.png",
	"res://assets/sprites/chars/player/spr_cherry_purple.png",
]

var color_list := ["red", "blue", "green", "purple"]

var colors := {
	"red": Color(67 / 255.0, 163 / 255.0, 245 / 255.0, 1.0),
	"blue": Color(245 / 255.0, 72 / 255.0, 67 / 255.0, 1.0),
	"green": Color(245 / 255.0, 67 / 255.0, 104 / 255.0, 1.0),
	"purple": Color(67 / 255.0, 245 / 255.0, 208 / 255.0, 1.0),
}

# skins sprite path
var player_sprite_path := "res://assets/sprites/chars/player/"
var slash_sprite_path := "res://assets/sprites/fx/slash/"
var ui_icon_path := "res://assets/sprites/ui/icons/"

var selected_skin: int = 0

func handle_main_menu() -> void:
	title.visible = true
	version_label.visible = true
	
	left_cursor.visible = true
	right_cursor.visible = true
	
	start_button.visible = true
	options_button.visible = true
	quit_button.visible = true
	
	# click on a button
	if Input.is_action_just_pressed("confirm"):
		# start the game
		if cursor_indexes[state] == 0:
			start_game()
		
		# enter options menu
		elif cursor_indexes[state] == 1:
			state = 1
			select_sound.play()
		
		# quit the game
		elif cursor_indexes[state] == 2:
			quit_game()

func handle_options_menu() -> void:
	title.visible = true
	version_label.visible = true
	
	left_cursor.visible = true
	right_cursor.visible = true
	
	skin_button.visible = true
	screen_size_button.visible = true
	controls_button.visible = true
	
	# click on a button
	if Input.is_action_just_pressed("confirm"):
		# start the game
		if cursor_indexes[state] == 0:
			state = 2
			select_sound.play()
		
		# enter options menu
		elif cursor_indexes[state] == 1:
			state = 3
			select_sound.play()
			
		# quit the game
		elif cursor_indexes[state] == 2:
			state = 4
			select_sound.play()
	
	elif Input.is_action_just_pressed("back"):
		state = 0
		select_sound.play()

func handle_skin_selection() -> void:
	title.visible = true
	version_label.visible = true
	
	player_skin.visible = true
	
	if Input.is_action_just_pressed("left"):
		selected_skin = posmod(selected_skin - 1, player_skin_list.size())
		select_sound.play()

	elif Input.is_action_just_pressed("right"):
		selected_skin = posmod(selected_skin + 1, player_skin_list.size())
		select_sound.play()
	
	elif Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("back"):
		state = 1
		select_sound.play()
	
	# update sprite and label
	player_skin.frame = selected_skin
	skin_color_label.text = color_list[selected_skin][0].to_upper() + color_list[selected_skin].right(-1)
	skin_color_label.set("theme_override_colors/font_color", colors[color_list[selected_skin]])

func handle_cursors() -> void:
	# cursors position
	var selected_button: Label = menu_options[state][cursor_indexes[state]]
	
	left_cursor.position.x = selected_button.position.x - 14
	left_cursor.position.y = selected_button.position.y + 10
	
	right_cursor.position.x = selected_button.position.x + selected_button.size.x + 14
	right_cursor.position.y = selected_button.position.y + 10
	
	# up/down cursors navigation
	if Input.is_action_just_pressed("up") and cursor_indexes[state] > 0:
		cursor_indexes[state] -= 1
		select_sound.play()
	
	elif Input.is_action_just_pressed("down") and cursor_indexes[state] < menu_options[state].size()-1:
		cursor_indexes[state] += 1
		select_sound.play()

func start_game() -> void:
	# apply skin
	var color: String = color_list[selected_skin]
	
	Global.player_sprite = load(player_sprite_path + "spr_cherry_" + color + ".png")
	Global.basic_slash_sprite = load(slash_sprite_path + "spr_basic_slash_" + color + ".png")
	Global.magic_slash_sprite = load(slash_sprite_path + "spr_magic_slash_" + color + ".png")
	Global.magic_slash_icon = load(ui_icon_path + "spr_magic_slash_icon_" + color + ".png")
	Global.dash_icon = load(ui_icon_path + "spr_dash_icon_" + color + ".png")

	Global.player_color = colors[color]
	
	# init game info
	Global.init_stars()
	Global.init_player_stats()
	Global.set_elapsed_time_reference()
	
	# init boss defeated state
	Global.big_bat_defeated = false
	Global.ceres_defeated = false
	
	# go to the next scene
	Global.next_level()

func quit_game() -> void:
	get_tree().quit()

func _ready() -> void:
	# init menu variables
	menu_options = {
		0: [start_button, options_button, quit_button],
		1: [skin_button, screen_size_button, controls_button],
	}
	
	cursor_indexes = {
		0: 0,
		1: 0,
	}
	
	# changed title screen if the game is cleared
	if Global.cleared:
		title.modulate = Color.YELLOW
		clear_sprite.visible = true
		
		start_button.set("theme_override_colors/font_color", Color.YELLOW)
		options_button.set("theme_override_colors/font_color", Color.YELLOW)
		quit_button.set("theme_override_colors/font_color", Color.YELLOW)
		
		skin_button.set("theme_override_colors/font_color", Color.YELLOW)
		screen_size_button.set("theme_override_colors/font_color", Color.YELLOW)
		controls_button.set("theme_override_colors/font_color", Color.YELLOW)
		
		player_controls_info.set("theme_override_colors/font_color", Color.YELLOW)
		extra_controls_info.set("theme_override_colors/font_color", Color.YELLOW)
		version_label.set("theme_override_colors/font_color", Color.YELLOW)

func hide_all() -> void:
	title.visible = false
	version_label.visible = false
	
	left_cursor.visible = false
	right_cursor.visible = false
	
	start_button.visible = false
	options_button.visible = false
	quit_button.visible = false
	
	skin_button.visible = false
	screen_size_button.visible = false
	controls_button.visible = false
	
	player_skin.visible = false

func _process(_delta: float) -> void:
	# hide all labels
	hide_all()
	
	# main menu
	if state == 0:
		handle_cursors()
		handle_main_menu()

	# options menu
	elif state == 1:
		handle_cursors()
		handle_options_menu()
	
	elif state == 2:
		handle_skin_selection()
	
	# debug
	if Input.is_action_just_pressed("exp"):
		get_viewport().size = Vector2(1920, 1080)
		get_window().move_to_center()
