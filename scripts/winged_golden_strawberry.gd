extends Area2D


@onready var player: Player = %Player
@onready var music: AudioStreamPlayer = %Music

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const MAX_HEIGHT = -1450
var speed := 0

var flee := false
var min_height: float

func end_level() -> void:
	music.stop()
	Global.end_recap.start()
	queue_free()

func _ready() -> void:
	min_height = position.y

func _physics_process(delta: float) -> void:
	# escape from the player
	if flee:
		speed += 5
		position.y = max(position.y - speed * delta, MAX_HEIGHT)
		position.y = min(position.y, player.get_middle_position().y - 48)
		position.y = min(position.y, min_height)


func _on_body_entered(body: Node2D) -> void:
	if body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		animation_player.play("pickup")
