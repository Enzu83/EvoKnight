extends CanvasLayer


func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and Global.current_level != 0:
		toggle_pause()
	
	# pause menu is active
	elif visible:
		handle_menu()

func handle_menu() -> void:
	pass

func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = !get_tree().paused
