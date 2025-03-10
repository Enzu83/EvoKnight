extends CanvasLayer

@onready var left_cursor: AnimatedSprite2D = $Menu/LeftCursor
@onready var right_cursor: AnimatedSprite2D = $Menu/RightCursor

@onready var select_sound: AudioStreamPlayer = $Menu/SelectSound

@onready var resume_button: Label = $Menu/ResumeButton
@onready var quit_button: Label = $Menu/QuitButton

# cursor navigation
var pause_options: Array

var cursor_index: int

func _ready() -> void:
	visible = false
	cursor_index = 0
	
	pause_options = [
		resume_button,
		quit_button,
	]

func _process(_delta: float) -> void:
	# can't pause on the title screen
	# and can't pause while leveling up
	if Input.is_action_just_pressed("pause") \
	and Global.current_level != 0 \
	and not Global.level_up.visible and not Global.end_recap.visible:
		toggle_pause()
	
	# pause menu is active
	elif visible:
		handle_cursors()
		handle_click()

func handle_cursors() -> void:
	var selected_button: Node = pause_options[cursor_index]

	# cursors position
	left_cursor.position.x = selected_button.position.x - 14
	left_cursor.position.y = selected_button.position.y + 10
	
	right_cursor.position.x = selected_button.position.x + selected_button.size.x + 14
	right_cursor.position.y = selected_button.position.y + 10
	
	# up/down cursors navigation
	if Input.is_action_just_pressed("up"):
		cursor_index = posmod(cursor_index - 1, pause_options.size())
		select_sound.play()
	
	elif Input.is_action_just_pressed("down"):
		cursor_index = posmod(cursor_index + 1, pause_options.size())
		select_sound.play()

func handle_click() -> void:
	# select an option
	if Input.is_action_just_pressed("confirm"):
		# resume
		if cursor_index == 0:
			toggle_pause()
		
		# quit
		elif cursor_index == 1:
			get_tree().quit()

func toggle_pause() -> void:
	cursor_index = 0
	
	if not visible:
		visible = true
		get_tree().paused = true
	else:
		visible = false
		get_tree().paused = false
