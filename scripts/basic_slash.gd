extends Area2D

const STRENGTH = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var duration: Timer = $Duration

@onready var player: CharacterBody2D = $".."

var active: bool = false

func reset() -> void:
	active = false

func start(orientation: String) -> void:
	active = true
	duration.start()
	
	animation_player.play(orientation)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.hurt(STRENGTH * player.strength)
		
		# make player bounce on the enemy
		if animation_player.current_animation == "down":
			player.handle_bounce()

func _on_duration_timeout() -> void:
	reset()
