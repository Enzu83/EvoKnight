extends Area2D

const SPEED = 130
const STRENGTH = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var wind_spirit: Area2D = $".."
@onready var tornado_sound: AudioStreamPlayer2D = $TornadoSound
@onready var duration: Timer = $Duration

var active: bool = false
var direction := 0

func reset() -> void:
	animation_player.call_deferred("play", "RESET")
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
	if body == wind_spirit.player:
		wind_spirit.player.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	effects_player.play("fade_out")
