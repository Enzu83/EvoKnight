extends CharacterBody2D

@onready var player: Player = %Player

@onready var hud: CanvasLayer = %HUD

@onready var sprite: Sprite2D = $Sprite
@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_sound: AudioStreamPlayer = $AttackSound

@onready var teleport_timer: Timer = $TeleportTimer
@onready var teleport_wait_timer: Timer = $TeleportWaitTimer

@onready var attack_phantom_timer: Timer = $AttackPhantomTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_duration: Timer = $AttackDuration
@onready var attack_end_timer: Timer = $AttackEndTimer

const RENO_PHANTOM = preload("res://scenes/chars/reno_phantom.tscn")

const SPEED = 300.0
const EXP_DROP_VALUE = 2

var strength := 4
var attack_strength := 7

enum State {Default, Defeated, Teleporting, Attacking}
enum Anim {idle, attack, teleport_start, teleport_end, defeated}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var max_health := 120
var health := max_health

# variables
var active := false

var teleport_position := [
	Vector2(4148, -168),
	Vector2(4428, -168),
	
	Vector2(4148, -252),
	Vector2(4428, -252),
	
	Vector2(4148, -322),
	Vector2(4428, -322),
]

func _ready() -> void:
	active = false
	#sprite.visible = false
	hurtbox.set_deferred("disabled", true)
	
	if Global.reno_defeated:
		sprite.visible = false

func _physics_process(_delta: float) -> void:
	if state == State.Default:
		handle_flip_h()
		velocity.x = 0
	
	# set attack velocity
	elif state == State.Attacking and sprite.frame >= 10 and velocity.x == 0:
		if position.x < 4288:
			velocity.x = SPEED
			attack_hitbox.scale.x = 1
			sprite.flip_h = false
		else:
			velocity.x = -SPEED
			attack_hitbox.scale.x = -1
			sprite.flip_h = true

	move_and_slide()

func handle_flip_h() -> void:
	# flip to match the direction
	if position.x < player.position.x:
		attack_hitbox.scale.x = 1
		sprite.flip_h = false
	elif position.x > player.position.x:
		attack_hitbox.scale.x = -1
		sprite.flip_h = true

func play_animation(anim_name: String) -> void:
	# play the animation if it's no the current one
	if anim != Anim.get(anim_name):
		animation_player.play(anim_name)
		anim = Anim.get(anim_name)

func is_hurtable() -> bool:
	return not effects_player.current_animation == "blink"

func hurt(damage: int, _attack: Area2D) -> bool:
	if is_hurtable():
		# boss is still alive
		if health > damage:
			health -= damage
			hurt_sound.play()
			hurtbox.set_deferred("disabled", true)
			hurt_invicibility_timer.start()
			effects_player.play("blink")
		
		# boss is dead
		else:
			fainted()

	return not is_hurtable()

func fainted() -> void:
	if state != State.Defeated:
		health = 0
		state = State.Defeated
		death_sound.play()
		hurtbox.set_deferred("disabled", true)
		play_animation("defeated")
		teleport_timer.stop()
		teleport_wait_timer.stop()

		attack_phantom_timer.stop()
		attack_timer.stop()
		attack_duration.stop()
		attack_end_timer.stop()
		
		# exp drops
		Global.create_multiple_exp_drop(EXP_DROP_VALUE, position, 250)
		
		# stop drawing hud
		hud.display_boss = false

func get_middle_position() -> Vector2:
	return position - Vector2(0, wall_collider.shape.get_rect().size.y)

func spawn() -> void:
	active = true
	hurtbox.set_deferred("disabled", false)
	
	state = State.Default
	
	# hud
	Global.boss = self
	hud.display_boss = true
	hud.boss_name.text = "Reno"
	
	teleport_timer.start()

func spawn_phantom() -> void:
	var horizontal_speed: float
	
	if position.x < 4288:
		horizontal_speed = SPEED
	else:
		horizontal_speed = -SPEED
	
	add_child(RENO_PHANTOM.instantiate().init(get_middle_position(), horizontal_speed))

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(strength)

func _on_hurt_invicibility_timer_timeout() -> void:
	if state != State.Teleporting:
		hurtbox.set_deferred("disabled", false)
		
	effects_player.stop()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(attack_strength)

func _on_teleport_timer_timeout() -> void:
	state = State.Teleporting
	play_animation("teleport_start")
	teleport_wait_timer.start()

func _on_teleport_wait_timer_timeout() -> void:
	# teleport to the furthest position from the player's position
	var new_position: Vector2 = teleport_position[0]
	
	for possible_position in teleport_position:
		if (possible_position - player.position).length() > (new_position - player.position).length():
			new_position = possible_position
	
	position = new_position
	
	play_animation("teleport_end")
	state = State.Default
	attack_phantom_timer.start()
	
func _on_attack_phantom_timer_timeout() -> void:
	spawn_phantom()
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	state = State.Attacking
	attack_sound.play()
	play_animation("attack")
	attack_duration.start()

func _on_attack_duration_timeout() -> void:
	state = State.Default
	play_animation("idle")
	attack_end_timer.start()
	

func _on_attack_end_timer_timeout() -> void:
	teleport_timer.start()
