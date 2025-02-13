extends AnimatedSprite2D

@onready var cursor: AnimatedSprite2D = $"."
@onready var play_button: Label = %PlayButton
@onready var skin_button: Label = %SkinButton
@onready var cursor_sound: AudioStreamPlayer2D = $CursorSound

var selected_button: Label
var player_sprite_path: String

func handle_button_selection() -> void:
	if Input.is_action_just_pressed("up") and selected_button != play_button:
		selected_button = play_button
		cursor_sound.play()
	elif Input.is_action_just_pressed("down") and selected_button != skin_button:
		selected_button = skin_button
		cursor_sound.play()

func handle_choose() -> void:
	if Input.is_action_just_pressed("jump"):
		if selected_button == play_button:
			Global.player_sprite = load(player_sprite_path)
			
			# go to the level
			get_tree().change_scene_to_file("res://scenes/levels/game.tscn")
		elif selected_button == skin_button:
			print("choose skin")

func _ready() -> void:
	selected_button = play_button

func _process(_delta: float) -> void:
	handle_button_selection()
	
	# update cursor position
	position.y = selected_button.position.y + 7
	
	handle_choose()
