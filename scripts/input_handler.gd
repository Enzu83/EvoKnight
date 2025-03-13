extends Control

@onready var await_label: Label = $AwaitLabel
@onready var dot_label_timer: Timer = $DotLabelTimer
@onready var await_timer: Timer = $AwaitTimer
@onready var stop_wait_timer: Timer = $StopWaitTimer

var active := false

var current_input_key: Control
var dot_in_label := 0

func _ready() -> void:
	current_input_key = null

func start(input_key: Control) -> void:
	current_input_key = input_key
	active = true
	visible = true
	await_label.text = "Awaiting for input"
	dot_in_label = 0
	dot_label_timer.start()
	await_timer.start()

func stop() -> void:
	current_input_key = null
	visible = false
	await_label.text = ""
	dot_label_timer.stop()
	await_timer.stop()
	stop_wait_timer.start()
	
func _input(event: InputEvent) -> void:
	# only if the input handler is active and check the user's inputs
	if visible and event is InputEventKey:
		if event.pressed:
			# check if the input has been correctly added (if it's not already an input)
			if current_input_key.add_input(event):
				stop()

func _on_await_timer_timeout() -> void:
	if visible:
		stop()

func _on_dot_label_timer_timeout() -> void:
	dot_in_label = posmod(dot_in_label + 1, 3)
	await_label.text = "Awaiting for input" + ".".repeat(dot_in_label + 1)
	
func _on_stop_wait_timer_timeout() -> void:
	active = false
