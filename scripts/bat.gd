extends Area2D

const SPEED = 100
const STRENGTH = 3 # damage caused by the enemy
const MAX_HEALTH = 5
const EXP_GIVEN = 3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var chase_cooldown: Timer = $ChaseCooldown

@onready var hurt_sound: AudioStreamPlayer = $HurtSound

@onready var player: CharacterBody2D = %Player


var chase := false # enable chasing the player
var target: CharacterBody2D = null # chase target

var health := 5

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
		
		# move toward the middle of the target's hurtbox
		position += position.direction_to(target.get_middle_position()) * SPEED * delta

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player:
		body.hurt(STRENGTH)

func hurt(damage: int) -> void:
	if health > damage:
		health -= damage
		hurt_sound.play()
	else:
		fainted()
		

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		player.experience += EXP_GIVEN
		animation_player.play("death")

func _on_detector_body_entered(body: Node2D) -> void:
	if body == player:
		chase_cooldown.start()
		chase = true
		target = body


func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		chase_cooldown.stop()
		chase = false
		target = null


func _on_chase_cooldown_timeout() -> void:	
	chase = !chase # invert chase state
