extends CanvasLayer

@onready var intro_timer: Timer = $IntroTimer
@onready var intro_sound: AudioStreamPlayer = $IntroSound

@onready var state_timer: Timer = $StateTimer
@onready var display_sound: AudioStreamPlayer = $DisplaySound

@onready var time: Control = $Time
@onready var stars: Control = $Stars

@onready var time_elapsed: Label = $Time/TimeElapsed
@onready var stars_collected: Label = $Stars/StarsCollected

# 0: nothing
# 1: time played
# 2: stars collected
# 3: close recap
var state := 0

var elapsed_time: int
var collected_stars: int
var total_stars: int

func start() -> void:
	visible = true
	state = 0
	intro_timer.start()
	intro_sound.play()
	
	# game info
	elapsed_time = Global.get_elapsed_time()
	collected_stars = Global.get_collected_stars()
	total_stars = Global.get_total_stars()
	
	# apply info to labels
	time_elapsed.text = elapsed_time_to_text()
	stars_collected.text = str(collected_stars) + "/" + str(total_stars)

func elapsed_time_to_text() -> String:
	var milliseconds: int = elapsed_time % 1000
	@warning_ignore("integer_division")
	var seconds: int = (elapsed_time / 1000) % 60
	@warning_ignore("integer_division")
	var minutes: int = (elapsed_time / 60000) % 60
	
	return "{0}m{1}s{2}ms".format([str(minutes), str(seconds), str(milliseconds)])
func _process(_delta: float) -> void:
	if state == 3 and Input.is_action_just_pressed("confirm"):
		state = 0
		visible = false
		time.visible = false
		stars.visible = false
		get_tree().paused = false
		
		Global.cleared = true
		Global.goto_level(0)

func _on_intro_timer_timeout() -> void:
	state_timer.start()

func _on_state_timer_timeout() -> void:
	# time
	if state == 0:
		state = 1
		display_sound.play()
		time.visible = true
	
	# stars
	elif state == 1:
		state = 2
		display_sound.play()
		stars.visible = true
	
	# end timer
	elif state == 2:
		state = 3
		state_timer.stop()
