extends CanvasLayer

@onready var cursor: AnimatedSprite2D = $Menu/Cursor
@onready var select_sound: AudioStreamPlayer = $Menu/SelectSound
@onready var resume_button: Label = $Menu/ResumeButton
@onready var quit_button: Label = $Menu/QuitButton

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and Global.current_level != 0:
		toggle_pause()
	
	# pause menu is active
	elif visible:
		handle_menu()

func handle_menu() -> void:
	if (Input.is_action_just_pressed("basic_slash") \
	or Input.is_action_just_pressed("dash") \
	or Input.is_action_just_pressed("magic_slash")):
		if cursor.position.y == resume_button.position.y + 10:
			toggle_pause()
		elif cursor.position.y == quit_button.position.y + 10:
			get_tree().quit()
	
	elif Input.is_action_just_pressed("up") \
	and cursor.position.y != resume_button.position.y + 10:
		cursor.position.y = resume_button.position.y + 10
		select_sound.play()
	
	elif Input.is_action_just_pressed("down") \
	and cursor.position.y != quit_button.position.y + 10:
		cursor.position.y = quit_button.position.y + 10
		select_sound.play()

func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = !get_tree().paused
