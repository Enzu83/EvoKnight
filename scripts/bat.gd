extends Area2D

const SPEED = 80
const STRENGTH = 3 # damage caused by the enemy
const MAX_HEALTH = 12
const EXP_GIVEN = 3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hurt_invicibility_timer: Timer = $HurtInvicibilityTimer

@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var player: CharacterBody2D = %Player


var chase := false # enable chasing the player
var target: CharacterBody2D = null # chase target
var health := MAX_HEALTH
var hit := false # enemy stun if hit by an attack, can't chase during this period

func _ready() -> void:
	add_to_group("enemies") 

func _physics_process(delta: float) -> void:
	# go toward the target
	if chase and target != null:
		# flip the sprite to match the direction
		if position.x < target.position.x:
			animated_sprite.flip_h = false
		elif position.x > target.position.x:
			animated_sprite.flip_h = true
		
		# move toward the middle of the target's hurtbox
		if not hit:
			position += position.direction_to(target.get_middle_position()) * SPEED * delta

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)

func hurt(damage: int, _attack: Area2D) -> void:
	if health > damage:
		health -= damage
		hurt_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		animation_player.play("hit")
		hit = true
	else:
		fainted()
		

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		player.experience += EXP_GIVEN
		animation_player.play("death")
		death_sound.play()

func _on_detector_body_entered(body: Node2D) -> void:
	if body == player:
		chase = true
		target = body

func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		chase = false
		target = null

func _on_hurt_invicibility_timer_timeout() -> void:
	hit = false
	hurtbox.set_deferred("disabled", false)
	animation_player.play("RESET")
