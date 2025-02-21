extends CanvasLayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var animation_timer: Timer = $AnimationTimer
@onready var stat_up_timer: Timer = $StatUpTimer

@onready var level_up_sound: AudioStreamPlayer = $LevelUpSound
@onready var stat_up_sound: AudioStreamPlayer = $StatUpSound

@onready var stat_increase_display: TextureRect = $StatIncreaseDisplay
@onready var stat_display_player: AnimationPlayer = $StatDisplayPlayer


@onready var health_increase: Label = $StatIncreaseDisplay/HealthIncrease
@onready var strength_increase: Label = $StatIncreaseDisplay/StrengthIncrease
@onready var defense_increase: Label = $StatIncreaseDisplay/DefenseIncrease

# 0: animation
# 1: health increase
# 2: strength increase
# 3: defense increase
# 4: wait for input
var state := 0

var health_value: int
var strength_value: int
var defense_value: int

func start(health, strength, defense) -> void:
	visible = true
	state = 0
	animated_sprite.play("default")
	animation_timer.start()
	level_up_sound.play()
	
	health_increase.text = "+" + str(health)
	health_value = health
	
	strength_increase.text = "+" + str(strength)
	strength_value = strength
	
	defense_increase.text = "+" + str(defense)
	defense_value = defense

func stop() -> void:
	health_increase.visible = false
	strength_increase.visible = false
	defense_increase.visible = false
	
	stat_display_player.play("RESET")
	
	visible = false
	get_tree().paused = false

func _process(_delta: float) -> void:
	# check for input
	if state == 4 and (Input.is_action_just_pressed("basic_slash") \
	or Input.is_action_just_pressed("dash") \
	or Input.is_action_just_pressed("magic_slash")):
		stop()

func _on_animation_timer_timeout() -> void:
	state = 1
	stat_display_player.play("move")

func _on_stat_up_timer_timeout() -> void:
	# health increase
	if state == 1:
		state = 2
		if health_value > 0:
			health_increase.visible = true
			stat_up_sound.play()
	
	# strength increase
	elif state == 2:
		state = 3
		if strength_value > 0:
			strength_increase.visible = true
			stat_up_sound.play()
	
	# defense increase
	elif state == 3:
		state = 4
		if defense_value > 0:
			defense_increase.visible = true
			stat_up_sound.play()
		
		stat_up_timer.stop()
