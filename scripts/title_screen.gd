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
@onready var resolution_button: Label = $Menu/Options/ResolutionButton
@onready var controls_button: Label = $Menu/Options/ControlsButton
@onready var options_back_button: Label = $Menu/Options/BackButton

@onready var player_skin: Label = $Menu/Skin/PlayerSkin
@onready var player_skin_sprite: Sprite2D = $Menu/Skin/PlayerSkin/Sprite
@onready var skin_color_label: Label = $Menu/Skin/PlayerSkin/ColorLabel
@onready var skin_confirm_button: Label = $Menu/Skin/ConfirmButton
@onready var skin_back_button: Label = $Menu/Skin/BackButton

@onready var resolution_label: Label = $Menu/Resolution/ResolutionLabel
@onready var resolution_confirm_button: Label = $Menu/Resolution/ConfirmButton
@onready var resolution_back_button: Label = $Menu/Resolution/BackButton

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
	"red": Color(211 / 255.0, 47 / 255.0, 63 / 255.0, 1.0),
	"blue": Color(91 / 255.0, 123 / 255.0, 227 / 255.0, 1.0),
	"green": Color(47 / 255.0, 211 / 255.0, 66 / 255.0, 1.0),
	"purple": Color(211 / 255.0, 47 / 255.0, 192 / 255.0, 1.0),
}

var player_sprite_path := "res://assets/sprites/chars/player/"
var slash_sprite_path := "res://assets/sprites/fx/slash/"
var ui_icon_path := "res://assets/sprites/ui/icons/"

var selected_skin := 0
var pending_selected_skin := 0

# resolution
var resolution_sizes = [
	Vector2(0, 0),
	Vector2(3840, 2160),
	Vector2(3200, 1800),
	Vector2(2560, 1440),
	Vector2(1920, 1080),
	Vector2(1600, 900),
	Vector2(1366, 768),
	Vector2(1280, 720),
	Vector2(1024, 576),
	Vector2(960, 540),
	Vector2(854, 480),
	Vector2(640, 360),
	Vector2(480, 270),
	Vector2(320, 180),
]

var selected_resolution := 0
var pending_selected_resolution := 0

func handle_main_menu() -> void:
	title.visible = true
	version_label.visible = true
	
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
	
	skin_button.visible = true
	resolution_button.visible = true
	controls_button.visible = true
	options_back_button.visible = true
	
	# click on a button
	if Input.is_action_just_pressed("confirm"):
		# skin selection
		if cursor_indexes[state] == 0:
			# pending skin (the one displayed but not confirmed yet)
			pending_selected_skin = selected_skin
			
			state = 2
			select_sound.play()
		
		# screen size options
		elif cursor_indexes[state] == 1:
			pending_selected_resolution = selected_resolution
			
			state = 3
			select_sound.play()
			
		# controls mapping
		elif cursor_indexes[state] == 2:
			state = 4
			select_sound.play()
		
		# back to main menu
		elif cursor_indexes[state] == 3:
			cursor_indexes[state] = 0
			
			state = 0
			select_sound.play()

func handle_skin_selection() -> void:
	title.visible = true
	version_label.visible = true
	
	player_skin.visible = true
	skin_color_label.visible = true
	skin_confirm_button.visible = true
	skin_back_button.visible = true
	
	# change skin
	if cursor_indexes[state] == 0:
		if Input.is_action_just_pressed("left"):
			pending_selected_skin = posmod(pending_selected_skin - 1, player_skin_list.size())
			select_sound.play()

		elif Input.is_action_just_pressed("right"):
			pending_selected_skin = posmod(pending_selected_skin + 1, player_skin_list.size())
			select_sound.play()
	
	# update sprite and label
	player_skin_sprite.frame = pending_selected_skin
	skin_color_label.text = color_list[pending_selected_skin][0].to_upper() + color_list[pending_selected_skin].right(-1)
	skin_color_label.set("theme_override_colors/font_color", colors[color_list[pending_selected_skin]])
	
	# click on a button
	if Input.is_action_just_pressed("confirm"):
		# confirm skin
		if cursor_indexes[state] == 1:
			selected_skin = pending_selected_skin
			
			cursor_indexes[state] = 0
			
			state = 1
			select_sound.play()
			
		# don't update skin
		elif cursor_indexes[state] == 2:
			cursor_indexes[state] = 0
			
			state = 1
			select_sound.play()

func handle_resolution() -> void:
	title.visible = true
	version_label.visible = true
	
	resolution_label.visible = true
	resolution_confirm_button.visible = true
	resolution_back_button.visible = true
	
	# change resolution
	if cursor_indexes[state] == 0:
		if Input.is_action_just_pressed("left"):
			pending_selected_resolution = posmod(pending_selected_resolution - 1, resolution_sizes.size())
			select_sound.play()

		elif Input.is_action_just_pressed("right"):
			pending_selected_resolution = posmod(pending_selected_resolution + 1, resolution_sizes.size())
			select_sound.play()
		
		if pending_selected_resolution == 0:
			resolution_label.text = "Fullscreen"
		else:
			resolution_label.text = str(resolution_sizes[pending_selected_resolution].x) + "x" + str(resolution_sizes[pending_selected_resolution].y)

	# click on a button
	if Input.is_action_just_pressed("confirm"):
		# confirm resolution
		if cursor_indexes[state] == 1:
			selected_resolution = pending_selected_resolution
			
			if selected_resolution == 0:
				get_viewport().size = DisplayServer.screen_get_size()
			else:
				get_viewport().size = resolution_sizes[selected_resolution]

			get_window().move_to_center()
			
			select_sound.play()
		# don't update resolution
		elif cursor_indexes[state] == 2:
			cursor_indexes[state] = 0
			
			state = 1
			select_sound.play()

func handle_cursors() -> void:
	left_cursor.visible = true
	right_cursor.visible = true
	
	var selected_button: Node = menu_options[state][cursor_indexes[state]]

	# cursors position
	left_cursor.position.x = selected_button.position.x - 14
	left_cursor.position.y = selected_button.position.y + 10
	
	right_cursor.position.x = selected_button.position.x + selected_button.size.x + 14
	right_cursor.position.y = selected_button.position.y + 10
	
	# flip the sprite if the skin sprite or resolution label is selected
	if selected_button == player_skin \
	or selected_button == resolution_label:
		left_cursor.flip_h = true
		right_cursor.flip_h = true
	else:
		left_cursor.flip_h = false
		right_cursor.flip_h = false
	
	# up/down cursors navigation
	if Input.is_action_just_pressed("up"):
		cursor_indexes[state] = posmod(cursor_indexes[state] - 1, menu_options[state].size())
		select_sound.play()
	
	elif Input.is_action_just_pressed("down"):
		cursor_indexes[state] = posmod(cursor_indexes[state] + 1, menu_options[state].size())
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
		1: [skin_button, resolution_button, controls_button, options_back_button],
		2: [player_skin, skin_confirm_button, skin_back_button],
		3: [resolution_label, resolution_confirm_button, resolution_back_button],
	}
	
	cursor_indexes = {
		0: 0,
		1: 0,
		2: 0,
		3: 0
	}
	
	# changed title screen if the game is cleared
	if Global.cleared:
		title.modulate = Color.YELLOW
		clear_sprite.visible = true
		
		start_button.set("theme_override_colors/font_color", Color.YELLOW)
		options_button.set("theme_override_colors/font_color", Color.YELLOW)
		quit_button.set("theme_override_colors/font_color", Color.YELLOW)
		
		skin_button.set("theme_override_colors/font_color", Color.YELLOW)
		resolution_button.set("theme_override_colors/font_color", Color.YELLOW)
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
	resolution_button.visible = false
	controls_button.visible = false
	options_back_button.visible = false
	
	player_skin.visible = false
	skin_color_label.visible = false
	skin_confirm_button.visible = false
	skin_back_button.visible = false
	
	resolution_label.visible = false
	resolution_confirm_button.visible = false
	resolution_back_button.visible = false

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
	
	# skins
	elif state == 2:
		handle_cursors()
		handle_skin_selection()
	
	# screen size
	elif state == 3:
		handle_cursors()
		handle_resolution()
	
	# controls
	elif state == 4:
		state = 1
