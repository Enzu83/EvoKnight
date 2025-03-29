extends Area2D

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var activation_cooldown: Timer = $ActivationCooldown
@onready var activation_sound: AudioStreamPlayer = $ActivationSound

@onready var deactivation_timer: Timer = $DeactivationTimer

@onready var timer_block: StaticBody2D = $TimerBlock

@export var duration := 1.0

var active := false
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
	
	deactivation_timer.wait_time = duration

func _on_hitbox_area_entered(basic_slash: Area2D) -> void:
	# check if the slash is oriented toward the lever
	# and if the lever is inactive
	if can_change_state \
	and basic_slash.direction != direction:
		active = true
		can_change_state = false
		animation_player.stop()
		animation_player.play("active")
		timer_block.open()
		
		activation_cooldown.start()
		activation_sound.play()
		
		deactivation_timer.start()

func _on_activation_cooldown_timeout() -> void:
	can_change_state = true

func _on_deactivation_timer_timeout() -> void:
	active = false
	activation_sound.play()
	
	animation_player.play("inactive")
	timer_block.close()
