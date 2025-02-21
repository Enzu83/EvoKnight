extends Area2D

const SPEED = 130
const STRENGTH = 4

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var wind_spirit: Area2D = $".."
@onready var tornado_sound: AudioStreamPlayer2D = $TornadoSound
@onready var duration: Timer = $Duration

var active: bool = false
var direction := 0

func stop_animation() -> void:
	animation_player.play("RESET")

func reset() -> void:
	duration.stop()
	direction = 0
	active = false

func start(orientation: String) -> void:
	position = wind_spirit.position # wind spirit position is the reference
	active = true
	tornado_sound.play()
	duration.start()
	
	# left or right
	if orientation == "left":
		direction = -1
	elif orientation == "right":
		direction = 1
	
	animation_player.play(orientation)

func _process(delta: float) -> void:
	# move the magic slash
	if active:
		position.x += direction * SPEED * delta
	else:
		position = wind_spirit.get_middle_position()

func _on_body_entered(body: Node2D) -> void:
	if body == wind_spirit.player and wind_spirit.player.is_hurtable():
		wind_spirit.player.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	effects_player.play("fade_out")

func _on_effects_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		effects_player.play("RESET")
