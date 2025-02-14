extends Control

@onready var cursor: AnimatedSprite2D = $Cursor
@onready var select_sound: AudioStreamPlayer2D = $SelectSound

@onready var play_button: Label = $PlayButton
@onready var skin_button: Label = $SkinButton

@onready var player_skin: Sprite2D = $PlayerSkin
@onready var skin_left_cursor: AnimatedSprite2D = $PlayerSkin/LeftCursor
@onready var skin_right_cursor: AnimatedSprite2D = $PlayerSkin/RightCursor

enum Menu {Main, Skin}
var menu := Menu.Main

var cursor_main_position := Vector2(123, 131)
var selected_button: Label

var player_skin_list = [
	"res://assets/sprites/chars/player/spr_cherry.png",
	"res://assets/sprites/chars/player/spr_cherry_blue.png",
	"res://assets/sprites/chars/player/spr_cherry_green.png",
	"res://assets/sprites/chars/player/spr_cherry_purple.png",
]
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
			Global.player_sprite = load(player_skin_list[selected_skin])
			
			# go to the level
			get_tree().change_scene_to_file("res://scenes/levels/game.tscn")
		
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
	
	elif Input.is_action_just_pressed("back") or Input.is_action_just_pressed("confirm"):
		menu = Menu.Main
		select_sound.play()

func _ready() -> void:
	player_skin.visible = false
	selected_button = play_button

func _process(_delta: float) -> void:
	if menu == Menu.Main:
		handle_button_selection()
		handle_click_button()
		
		cursor.position = cursor_main_position
		cursor.position.y = selected_button.position.y + 7 # update cursor position

	elif menu == Menu.Skin:
		handle_skin_selection()

		player_skin.frame = selected_skin
