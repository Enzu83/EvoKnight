extends AnimatedSprite2D

@onready var play_button: Label = %PlayButton
@onready var quit_button: Label = %QuitButton
@onready var cursor_sound: AudioStreamPlayer2D = $CursorSound

var selected_button: Label

func handle_button_selection() -> void:
	if Input.is_action_just_pressed("up") and selected_button != play_button:
		selected_button = play_button
		cursor_sound.play()
	elif Input.is_action_just_pressed("down") and selected_button != quit_button:
		selected_button = quit_button
		cursor_sound.play()

func handle_choose() -> void:
	if Input.is_action_just_pressed("jump"):
		if selected_button == play_button:
			# go to level
			get_tree().change_scene_to_file("res://scenes/levels/game.tscn")
		elif selected_button == quit_button:
			# exit game
			get_tree().quit()

func _ready() -> void:
	selected_button = play_button

func _process(_delta: float) -> void:
	handle_button_selection()
	
	# update cursor position
	position.y = selected_button.position.y + 7
	
	handle_choose()
