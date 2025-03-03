extends Area2D

const SPEED = 250
const STRENGTH = 8

@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var duration: Timer = $Duration
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var wait_timer: Timer = $WaitTimer

@onready var ceres: CharacterBody2D = $".."

var heart_drop_scene: Resource = preload("res://scenes/items/heart_drop.tscn")
var dropped_heart := true

var active: bool = false
var direction := 0

func _ready() -> void:
	# ceres position is the reference
	position = ceres.position
	position.x += 16 * direction
	
	wait_timer.start()

func _process(delta: float) -> void:
	# move the magic slash
	if active:
		position.x += direction * SPEED * delta
	
	# target icons and initial position
	else:
		# ceres position is the reference
		position = ceres.position
		position.x += 16 * direction
		
		# ceres direction sets the direction of the slash
		if ceres.sprite.flip_h:
			direction = -1
		else:
			direction = 1
	
	if not dropped_heart \
	and ((position.x <= 4150 and direction == -1) \
	or (position.x >= 4426 and direction == 1)):
		dropped_heart = true
		
		var heart_drop: CharacterBody2D = heart_drop_scene.instantiate().init(3, Vector2(position.x, position.y - 16), Vector2.ZERO, true)
		get_tree().current_scene.add_child(heart_drop)
	
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

func _on_wait_timer_timeout() -> void:
	active = true
	
	if direction == -1:
		animation_player.play("left")
	elif direction == 1:
		animation_player.play("right")
	
	duration.start()
	slash_sound.play()
