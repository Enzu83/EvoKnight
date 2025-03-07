extends CanvasLayer

@onready var cursor: AnimatedSprite2D = $Menu/Cursor
@onready var select_sound: AudioStreamPlayer = $Menu/SelectSound
@onready var resume_button: Label = $Menu/ResumeButton
@onready var quit_button: Label = $Menu/QuitButton

enum State {Resume, Quit}
var state: State

# cursor navigation
var cursor_position := [
	Vector2(154, 136),
	Vector2(154, 170),
]

var cursor_index: int


func _ready() -> void:
	visible = false
	state = State.Resume
	cursor_index = 0

func _process(_delta: float) -> void:
	# can't pause on the title screen
	# and can't pause while leveling up
	if Input.is_action_just_pressed("pause") \
	and Global.current_level != 0 \
	and not Global.level_up.visible and not Global.end_recap.visible:
		toggle_pause()
	
	# pause menu is active
	elif visible:
		handle_cursor_navigation()
		handle_click()
		
		cursor.position = cursor_position[cursor_index]

func handle_cursor_navigation() -> void:
	if Input.is_action_just_pressed("up") and cursor_index > 0:
		cursor_index -= 1
		select_sound.play()
	
	elif Input.is_action_just_pressed("down") and cursor_index < cursor_position.size()-1:
		cursor_index += 1
		select_sound.play()

func handle_click() -> void:
	# select an option
	if Input.is_action_just_pressed("confirm"):
		if cursor_index == 0:
			toggle_pause()
		elif cursor_index == 1:
			get_tree().quit()

func toggle_pause() -> void:
	state = State.Resume
	cursor_index = 0
	
	if not visible:
		visible = true
		get_tree().paused = true
	else:
		visible = false
		get_tree().paused = false
