extends Area2D

@onready var sprite: Sprite2D = $Sprite
@onready var activation_cooldown: Timer = $ActivationCooldown
@onready var activation_sound: AudioStreamPlayer = $ActivationSound

var can_change_state := true # slight cooldown before changing the state of the lever

func _process(_delta: float) -> void:
	# lever state corresponds to the electric arcs state
	if Global.electric_arc_enabled:
		sprite.frame = 0
	else:
		sprite.frame = 1

func _on_hitbox_area_entered(_area: Area2D) -> void:
	if can_change_state:
		Global.electric_arc_enabled = !Global.electric_arc_enabled
		can_change_state = false
		activation_cooldown.start()
		activation_sound.play()

func _on_activation_cooldown_timeout() -> void:
	can_change_state = true
