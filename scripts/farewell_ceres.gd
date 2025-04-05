extends CharacterBody2D

@onready var player: Player = %Player

@onready var sprite: Sprite2D = $Sprite
@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var shield: AnimatedSprite2D = $Shield

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var teleport_sound: AudioStreamPlayer = $TeleportSound
@onready var test_orb: Timer = $TestOrb

var target_orb_scene: Resource = preload("res://scenes/fx/ceres_target_orb.tscn")
var impact_orb_scene: Resource = preload("res://scenes/fx/ceres_impact_orb.tscn")
var magic_slash_scene: Resource = preload("res://scenes/fx/ceres_slash.tscn")
var speed_orb_scene: Resource = preload("res://scenes/items/speed_orb.tscn")

var phantom_scene: Resource = preload("res://scenes/chars/farewell_ceres_phantom.tscn")

const CERES_ORB = preload("res://scenes/fx/ceres_orb.tscn")
const CERES_FOLLOWING_ORB = preload("res://scenes/fx/ceres_following_orb.tscn")
const CERES_ROTATING_ORB = preload("res://scenes/fx/ceres_rotating_orb.tscn")

const FAREWELL_CERES_CLONE = preload("res://scenes/chars/farewell_ceres_clone.tscn")

const SPEED = 300.0
const STRENGTH = 6

const HEALTH_BARS = 4

enum State {Default, Defeated, Attacking, Stall}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var max_health := 250

var health := max_health
var health_bar := HEALTH_BARS-1

# variables
var active := false

func _ready() -> void:
	active = false

func _physics_process(_delta: float) -> void:
	handle_flip_h()
	
	move_and_slide()

func start() -> void:
	active = true
	test_orb.start()

func handle_flip_h() -> void:
	# flip the sprite to match the direction
	if position.x < player.position.x:
		sprite.flip_h = false
	elif position.x > player.position.x:
		sprite.flip_h = true

func play_animation(anim_name: String) -> void:
	# play the animation if it's no the current one
	if anim != Anim.get(anim_name):
		animation_player.play(anim_name)
		anim = Anim.get(anim_name)

func is_hurtable() -> bool:
	return not shield.visible and not effects_player.current_animation == "blink"

func hurt(damage: int, _attack: Area2D) -> bool:
	var is_hurt := is_hurtable()
	
	if is_hurt:
		# ceres still has hp
		if health > damage:
			health -= damage
			hurt_sound.play()
			hurtbox.set_deferred("disabled", true)
			hurt_invicibility_timer.start()
			effects_player.play("blink")
		
		# ceres loses an health bar
		else:
			fainted()

	return is_hurt

func fainted() -> void:
	if state != State.Defeated:
		# some left health bars
		if health_bar > 0:
			health = max_health
			health_bar -= 1
			state = State.Stall
			teleport_sound.play()

			hurtbox.set_deferred("disabled", true)
			hurt_invicibility_timer.start()
			position.y -= 300 # hide from the player
		
		# no more health bars left
		else:
			health = 0
			state = State.Defeated
			death_sound.play()
			
			# boss defeated: end of fight animation
			player.state = player.State.Stop
			player.velocity.x = 0
			player.direction = 0
			player.phantom_cooldown.stop()

func get_middle_position() -> Vector2:
	return position - Vector2(0, wall_collider.shape.get_rect().size.y)

func circle_orb_attack() -> void:
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(14, 14), 0, true))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(20, 0), 0, false))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(14, -14), 0, false))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(0, -20), 0, false))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(-14, -14), 0, false))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(-20, 0), 0, false))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(-14, 14), 0, false))
	add_child(CERES_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(0, 20), 0, false))

func spaced_floor_orb_attack(begin: int = 0, end: int = 9) -> void:
	var fire := false
	
	for i in range(begin, end):
		add_child(CERES_ORB.instantiate()
						   .init(Vector2(15600 + 47 * i, -1788), Vector2(15600 + 47 * i, -1480), 0, not fire)
						   .second_target(Vector2(15600 + 47 * i, -1736)) # draw a target at the top of the area to indicate the spawn of falling orbs
		)
		fire = true

func following_orb_attack() -> void:
	add_child(CERES_FOLLOWING_ORB.instantiate().init(get_middle_position(), player))

func left_horizontal_orb_attack(hole_begin: int, hole_end: int) -> void:
	var fire := false
	
	for i in range(17):
		# spawn orbs everywhere except the hole area
		if i < hole_begin or i > hole_end:
			# only the first orb makes a sound
			add_child(CERES_ORB.instantiate().init(Vector2(15568, -1736 + 16 * i), Vector2(15600, -1736 + 16 * i), 0, not fire))
			fire = true

func right_horizontal_orb_attack(hole_begin: int, hole_end: int) -> void:
	var fire := false
	
	for i in range(17):
		# spawn orbs everywhere except the hole area
		if i < hole_begin or i > hole_end:
			# only the first orb makes a sound
			add_child(CERES_ORB.instantiate().init(Vector2(16008, -1736 + 16 * i), Vector2(15976, -1736 + 16 * i), 0, not fire))
			fire = true

func rotating_orb_shield_attack(clockwise: bool) -> void:
	add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(0, 40), 0, 10, true, clockwise, 300))
	add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(-34, -20), 0, 10, true, clockwise, 300))
	add_child(CERES_ROTATING_ORB.instantiate().init(get_middle_position(), get_middle_position() + Vector2(34, -20), 0, 10, true, clockwise, 300))


func rotating_orb_attack(clockwise: bool, rotation_position: Vector2, rotation_increment_position: Vector2) -> void:
	var fire := false
	
	for i in range(15):
		add_child(CERES_ROTATING_ORB.instantiate().init(
			get_middle_position(), # spawning position
			get_middle_position() + rotation_position + i * rotation_increment_position, # rotation starting position
			0.05 * i, 10, # wait time before moving at the start
			not fire,  # sound or not
			clockwise, # rotation direction
			60, # speed of the rotation
			2.0 - 0.05 * i) # wait before rotation (inverse of starting wait time to time all the orbs)
		)
		fire = true

func spawn_clone(clone_position: Vector2) -> void:
	add_child(FAREWELL_CERES_CLONE.instantiate().init(clone_position))

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)

func _on_hurt_invicibility_timer_timeout() -> void:
	if state != State.Stall:
		hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_phantom_cooldown_timeout() -> void:
	if velocity.length() > 0:
		add_child(phantom_scene.instantiate())

func _on_test_orb_timeout() -> void:
	pass
	#circle_orb_attack()
	#spaced_floor_orb_attack()
	#left_horizontal_orb_attack(6, 9)
	#right_horizontal_orb_attack(12, 14)
	rotating_orb_attack(false, Vector2(0, 32), Vector2(0, 16))
	rotating_orb_attack(false, Vector2(0, -32), Vector2(0, -16))
	rotating_orb_attack(false, Vector2(-32, 0), Vector2(-16, 0))
	rotating_orb_attack(false, Vector2(32, 0), Vector2(16, 0))
	#spawn_clone(Vector2(15710, -1544))
	#spawn_clone(Vector2(15866, -1544))
	#spawn_clone(position)
	#following_orb_attack()
