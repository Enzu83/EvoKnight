extends Area2D

@onready var sprite: Sprite2D = $Sprite
@onready var activation_cooldown: Timer = $ActivationCooldown
@onready var activation_sound: AudioStreamPlayer = $ActivationSound

var can_change_state := true # slight cooldown before changing the state of the lever
var direction: String # direction from which the level can't be activated

func _ready() -> void:
	# up
	if posmod(round(rotation_degrees), 360) == 0:
		direction = "up"
	# right
	elif posmod(round(rotation_degrees), 360) == 90:
		direction = "right"
	# down
	elif posmod(round(rotation_degrees), 360) == 180:
		direction = "down"
	# left
	elif posmod(round(rotation_degrees), 360) == 270:
		direction = "left"

func _process(_delta: float) -> void:
	# lever state corresponds to the electric arc auto switch timer
	if Global.electric_arc_auto_timer.paused:
		sprite.frame = 0
	else:
		sprite.frame = 1

func _on_hitbox_area_entered(basic_slash: Area2D) -> void:
	# check if the slash is oriented toward the lever
	if can_change_state \
	and basic_slash.direction != direction:
		Global.toggle_electric_arc_auto_switch()
		
		can_change_state = false
		activation_cooldown.start()
		activation_sound.play()

func _on_activation_cooldown_timeout() -> void:
	can_change_state = true
