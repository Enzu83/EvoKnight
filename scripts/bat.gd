extends Area2D

const SPEED = 80

const DROP_RATE = 1
const HEAL_DROP_VALUE = 4
const EXP_DROP_VALUE = 3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hurt_invicibility_timer: Timer = $HurtInvicibilityTimer

@onready var death_sound: AudioStreamPlayer = $DeathSound

var player: CharacterBody2D

var home_position: Vector2
var chase := false # enable chasing the player
var max_health := 12
var health := max_health
var strength := 3 # damage caused by the enemy

var hit := false # enemy stun if hit by an attack, can't chase during this period

@export var flip_sprite := false

var drop := true

func _ready() -> void:
	add_to_group("enemies")
	animated_sprite.flip_h = flip_sprite
	home_position = position

func _physics_process(delta: float) -> void:
	if Global.player != null:
		player = Global.player
	
	# go toward the target
	if chase and player != null:
		# move toward the middle of the target's hurtbox
		if not hit:
			position = position.move_toward(player.get_middle_position(), SPEED * delta)

	# go back to home
	elif not chase:
		position = position.move_toward(home_position, SPEED * delta)
		
	# flip the sprite to match the direction
	if not chase and (position - home_position).length() > 0:
		if position.x < home_position.x:
			animated_sprite.flip_h = false
		elif position.x > home_position.x:
			animated_sprite.flip_h = true
	
	elif player != null:
		if position.x < player.position.x:
			animated_sprite.flip_h = false
		elif position.x > player.position.x:
			animated_sprite.flip_h = true

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(strength)

func hurt(damage: int, _attack: Area2D) -> bool:
	if health > damage:
		health -= damage
		hurt_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		animation_player.play("hit")
		hit = true
	else:
		fainted()
	
	return true

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		animation_player.play("death")
		death_sound.play()
		
		# chance to drop heart/exp
		if drop:
			Global.create_drop(DROP_RATE, HEAL_DROP_VALUE, EXP_DROP_VALUE, position, Vector2.ZERO)

func _on_detector_body_entered(body: Node2D) -> void:
	if body == player:
		chase = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		chase = false

func _on_hurt_invicibility_timer_timeout() -> void:
	hit = false
	hurtbox.set_deferred("disabled", false)
	animation_player.play("RESET")
