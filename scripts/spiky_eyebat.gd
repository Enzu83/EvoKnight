extends CharacterBody2D

const SPEED = 50
const MAX_FALLING_VELOCITY = 0

const DROP_RATE = 1
const HEAL_DROP_VALUE = 4
const EXP_DROP_VALUE = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var clang_sound: AudioStreamPlayer = $ClangSound

@onready var player: CharacterBody2D = %Player

@export var flip_sprite := false

var drop := true

var max_health := 20
var health := max_health
var strength := 3

var hit := false # enemy stun if hit by an attack, can't chase during this period

func _ready() -> void:
	animated_sprite.flip_h = flip_sprite
	velocity.x = SPEED
	velocity.y = 0

func handle_velocity(_delta: float) -> void:
	if ray_cast_left.is_colliding():
		velocity.x = SPEED
	elif ray_cast_right.is_colliding():
		velocity.x = -SPEED

func handle_flip_h() -> void:
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

func _physics_process(delta: float) -> void:
	handle_velocity(delta)
	handle_flip_h()
	
	if not hit:
		move_and_slide()

func hurt(damage: int, attack: Area2D) -> bool:
	# check if the attack can hit the cloporte
	var is_hit = false

	if attack == player.basic_slash:
		var attack_orientation = player.basic_slash.direction
		if attack_orientation != "down":
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
			hit = true
		else:
			fainted()
		
	# clang between basic slash and cloporte
	else:
		clang_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		
	if attack == player.magic_slash:
		return false
	else:
		return is_hit

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		animation_player.play("death")
		death_sound.play()
		
		# chance to drop heart/exp
		if drop:
			Global.create_drop(DROP_RATE, HEAL_DROP_VALUE, EXP_DROP_VALUE, position, Vector2.ZERO)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(strength)

func _on_hurt_invicibility_timer_timeout() -> void:
	hit = false
	hurtbox.set_deferred("disabled", false)
	animation_player.play("RESET")
