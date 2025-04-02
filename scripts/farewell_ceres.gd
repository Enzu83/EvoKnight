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

var target_orb_scene: Resource = preload("res://scenes/fx/ceres_target_orb.tscn")
var impact_orb_scene: Resource = preload("res://scenes/fx/ceres_impact_orb.tscn")
var magic_slash_scene: Resource = preload("res://scenes/fx/ceres_slash.tscn")
var speed_orb_scene: Resource = preload("res://scenes/items/speed_orb.tscn")

var phantom_scene: Resource = preload("res://scenes/chars/farewell_ceres_phantom.tscn")


const SPEED = 300.0
const STRENGTH = 6

const HEALTH_BARS = 4

enum State {Default, Defeated, Attacking, Stall}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var max_health := 20#250

var health := max_health
var health_bar := HEALTH_BARS-1

# variables
var active := false

func _ready() -> void:
	active = false

func _physics_process(_delta: float) -> void:
	handle_flip_h()
	
	handle_shield()
	
	move_and_slide()

func handle_shield() -> void:
	shield.visible = state == State.Stall

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
			effects_player.play("blink")
		
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
