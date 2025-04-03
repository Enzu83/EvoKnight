extends CharacterBody2D

@onready var farewell_ceres: CharacterBody2D = $".."
@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var initial_position: Vector2

func init(initial_position_: Vector2) -> Node2D:
	initial_position = initial_position_
	return self

func _ready() -> void:
	position = initial_position
	animation_player.play("idle", farewell_ceres.animation_player.current_animation_position)

	handle_flip_h()

func _physics_process(_delta: float) -> void:
	sprite.texture = farewell_ceres.sprite.texture
	sprite.frame = farewell_ceres.sprite.frame

	handle_flip_h()

func handle_flip_h() -> void:
	# flip the sprite to match the direction
	if position.x <  farewell_ceres.player.position.x:
		sprite.flip_h = false
	elif position.x >  farewell_ceres.player.position.x:
		sprite.flip_h = true

func hurt(_damage: int, _attack: Area2D) -> bool:
	queue_free()
	return false

func _on_clone_duration_timeout() -> void:
	queue_free()
