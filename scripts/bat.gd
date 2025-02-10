extends Area2D

const SPEED = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var chase_cooldown: Timer = $ChaseCooldown

var chase := false # enable chasing the player
var target: CharacterBody2D = null # chase target

func _ready() -> void:
	add_to_group("enemies") 

func _physics_process(delta: float) -> void:
	# go toward the target
	if chase and target != null:
		# flip the sprite to match the direction
		if position.x < target.position.x:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
		
		# move toward the target
		position += position.direction_to(target.position) * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	# hurt the player
	if body.is_in_group("players"):
		body.hurt()
	

func hurt() -> void:
	animation_player.play("death")


func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		chase_cooldown.start()
		chase = true
		target = body


func _on_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		chase_cooldown.stop()
		chase = false
		target = null


func _on_chase_cooldown_timeout() -> void:	
	chase = !chase # invert chase state
