extends Area2D

const SPEED = 250
const STRENGTH = 6

@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var duration: Timer = $Duration
@onready var slash_sound: AudioStreamPlayer = $SlashSound

@onready var ceres: CharacterBody2D = $".."

var active: bool = false
var direction := 0

func reset() -> void:
	sprite.visible = false
	direction = 0
	active = false

func start(orientation) -> void:
	position = ceres.position # ceres position is the reference
	active = true
	duration.start()
	slash_sound.play()
	
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
		position = ceres.get_middle_position()
	
	# stop attacking if ceres is defeated
	if ceres.state == ceres.State.Fainted \
	or ceres.state == ceres.State.Defeated:
		hide()


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == ceres.player and ceres.player.is_hurtable():
		body.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	animation_player.play("fade_out")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		animation_player.play("RESET")
