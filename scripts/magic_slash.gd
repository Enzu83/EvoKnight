extends Area2D

const SPEED = 300
const STRENGTH = 10

@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var duration: Timer = $Duration
@onready var slash_sound: AudioStreamPlayer = $SlashSound

@onready var player: CharacterBody2D = $".."

var active: bool = false
var direction := 0

func reset() -> void:
	animation_player.play("RESET")
	direction = 0
	active = false

func start(orientation) -> void:
	position = player.position # player position is the reference
	active = true
	duration.start()
	slash_sound.play()
	
	# left or right
	if orientation == "left":
		direction = -1
	elif orientation == "right":
		direction = 1
	
	animation_player.play(orientation)

func _ready() -> void:
	sprite.texture = Global.magic_slash_sprite

func _process(delta: float) -> void:
	# move the magic slash
	if active:
		position.x += direction * SPEED * delta
	else:
		position = player.get_middle_position()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.hurt(STRENGTH * player.strength, self)

func _on_duration_timeout() -> void:
	animation_player.play("fade_out")
