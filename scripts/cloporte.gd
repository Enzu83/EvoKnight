extends CharacterBody2D

const SPEED = 40
const STRENGTH = 4
const MAX_HEALTH = 10
const EXP_GIVEN = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var player: CharacterBody2D = %Player

var health := MAX_HEALTH

func _ready() -> void:
	animated_sprite.flip_h = false
	velocity.x = SPEED

func handle_velocity(delta: float) -> void:
	if ray_cast_left.is_colliding():
		velocity.x = SPEED
	elif ray_cast_right.is_colliding():
		velocity.x = -SPEED
	
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_flip_h() -> void:
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

func _physics_process(delta: float) -> void:
	handle_velocity(delta)
	handle_flip_h()
	move_and_slide()

func hurt(damage: int, attack: Area2D) -> void:
	# check if the attack can hit the cloporte
	var is_hit = false

	if attack == player.basic_slash:
		var attack_orientation =  player.basic_slash.animation_player.current_animation
		if attack_orientation == "up" or (attack_orientation == "left" and not animated_sprite.flip_h) or (attack_orientation == "right" and animated_sprite.flip_h):
			is_hit = true
			
	elif attack == player.magic_slash:
		is_hit = true
	
	if is_hit:
		if health > damage:
			health -= damage
			hurt_sound.play()
			hurtbox.set_deferred("disabled", true)
			hurt_invicibility_timer.start()
			animation_player.play("hit")
		else:
			fainted()
		

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		player.experience += EXP_GIVEN
		animation_player.play("death")
		death_sound.play()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	animation_player.play("RESET")
