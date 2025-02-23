extends Node2D

@onready var title: TextureRect = $Title

@onready var cursor: AnimatedSprite2D = $Cursor
@onready var select_sound: AudioStreamPlayer = $SelectSound

@onready var play_button: Label = $PlayButton
@onready var skin_button: Label = $SkinButton

@onready var player_skin: Sprite2D = $PlayerSkin
@onready var skin_left_cursor: AnimatedSprite2D = $PlayerSkin/LeftCursor
@onready var skin_right_cursor: AnimatedSprite2D = $PlayerSkin/RightCursor

@onready var clear_sprite: AnimatedSprite2D = $ClearSprite

@onready var player_controls_info: Label = $PlayerControlsInfo
@onready var extra_controls_info: Label = $ExtraControlsInfo

enum Menu {Main, Skin}
var menu := Menu.Main

var cursor_main_position := Vector2(120, 134)
var selected_button: Label

var player_skin_list := [
	"res://assets/sprites/chars/player/spr_cherry_red.png",
	"res://assets/sprites/chars/player/spr_cherry_blue.png",
	"res://assets/sprites/chars/player/spr_cherry_green.png",
	"res://assets/sprites/chars/player/spr_cherry_purple.png",
]

var color_list := ["red", "blue", "green", "purple"]

var colors := {
	"red": Color(67, 163, 245, 1),
	"blue": Color(245, 72, 67, 1),
	"green": Color(245, 67, 104, 1),
	"purple": Color(67, 245, 208, 1),
}

# clear screen
var yellow_title := preload("res://assets/sprites/other/spr_title_yellow.png")
var yellow_color := Color(1, 1, 0)

# skins color
var player_sprite_path := "res://assets/sprites/chars/player/"
var slash_sprite_path := "res://assets/sprites/fx/slash/"
var ui_icon_path := "res://assets/sprites/ui/icons/"

var selected_skin: int = 0

func handle_button_selection() -> void:
	cursor.visible = true
	play_button.visible = true
	skin_button.visible = true
	
	player_skin.visible = false
	skin_left_cursor.visible = false
	skin_right_cursor.visible = false
	
	if Input.is_action_just_pressed("up") and selected_button != play_button:
		selected_button = play_button
		select_sound.play()
	
	elif Input.is_action_just_pressed("down") and selected_button != skin_button:
		selected_button = skin_button
		select_sound.play()

func handle_click_button() -> void:
	if Input.is_action_just_pressed("confirm"):
		if selected_button == play_button:
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
			
			# go to the next scene
			Global.next_level()
		
		elif selected_button == skin_button:
			menu = Menu.Skin
			select_sound.play()

func handle_skin_selection() -> void:
	cursor.visible = false
	play_button.visible = false
	skin_button.visible = false
	
	player_skin.visible = true
	skin_left_cursor.visible = true
	skin_right_cursor.visible = true
	
	if Input.is_action_just_pressed("left"):
		selected_skin = posmod(selected_skin - 1, player_skin_list.size())
		select_sound.play()

	elif Input.is_action_just_pressed("right"):
		selected_skin = posmod(selected_skin + 1, player_skin_list.size())
		select_sound.play()
	
	elif Input.is_action_just_pressed("confirm"):
		menu = Menu.Main
		select_sound.play()

func _ready() -> void:
	player_skin.visible = false
	selected_button = play_button
	
	# changed title screen if the game is cleared
	if Global.cleared:
		title.texture = yellow_title
		clear_sprite.visible = true
		play_button.set("theme_override_colors/font_color", yellow_color)
		skin_button.set("theme_override_colors/font_color", yellow_color)
		player_controls_info.set("theme_override_colors/font_color", yellow_color)
		extra_controls_info.set("theme_override_colors/font_color", yellow_color)

func _process(_delta: float) -> void:
	# navigate the menu
	if menu == Menu.Main:
		handle_button_selection()
		handle_click_button()
		
		cursor.position = cursor_main_position
		cursor.position.y = selected_button.position.y + 10 # update cursor position

	elif menu == Menu.Skin:
		handle_skin_selection()

		player_skin.frame = selected_skin
