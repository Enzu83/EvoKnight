extends CanvasLayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var animation_timer: Timer = $AnimationTimer

@onready var stat_increase_display: TextureRect = $StatIncreaseDisplay
@onready var health_increase: Label = $StatIncreaseDisplay/HealthIncrease
@onready var strength_increase: Label = $StatIncreaseDisplay/StrengthIncrease
@onready var defense_increase: Label = $StatIncreaseDisplay/DefenseIncrease

func start(health, strength, defense) -> void:
	visible = true
	stat_increase_display.visible = false
	animated_sprite.play("default")
	animation_timer.start()
	
	health_increase.text = str(health)
	strength_increase.text = str(strength)
	defense_increase.text = str(defense)

func stop() -> void:
	stat_increase_display.visible = false
	visible = false
	get_tree().paused = false

func _process(_delta: float) -> void:
	if stat_increase_display.visible \
	and (Input.is_action_just_pressed("basic_slash") \
	or Input.is_action_just_pressed("dash") \
	or Input.is_action_just_pressed("magic_slash")):
		stop()

func _on_animation_timer_timeout() -> void:
	stat_increase_display.visible = true
