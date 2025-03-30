extends CharacterBody2D

@onready var player: Player = %Player

@onready var sprite: Sprite2D = $Sprite
@onready var wall_collider: CollisionShape2D = $WallCollider

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

var target_orb_scene: Resource = preload("res://scenes/fx/ceres_target_orb.tscn")
var impact_orb_scene: Resource = preload("res://scenes/fx/ceres_impact_orb.tscn")
var magic_slash_scene: Resource = preload("res://scenes/fx/ceres_slash.tscn")
var speed_orb_scene: Resource = preload("res://scenes/items/speed_orb.tscn")

var phantom: Resource = preload("res://scenes/chars/farewell_ceres_phantom.tscn")


const SPEED = 300.0
const STRENGTH = 6

const MAX_HEALTH = 20#250
const HEALTH_BARS = 4

enum State {Default, Defeated, Attacking, Stall}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var health := MAX_HEALTH
var health_bar := HEALTH_BARS-1

# variables
var active := false

func _ready() -> void:
	active = false
	velocity.x = -80
	velocity.y = -100

func _physics_process(delta: float) -> void:
	handle_flip_h()
	velocity.x = move_toward(velocity.y, 0, 40 * delta)
	velocity.y = move_toward(velocity.y, 0, 50 * delta)
	
	move_and_slide()

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
	return state != State.Stall and not effects_player.current_animation == "blink"

func hurt(damage: int, _attack: Area2D) -> bool:
	if is_hurtable():
		# boss is still alive
		if health > damage:
			health -= damage
			velocity.x *= 0.5
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
		if health_bar > 0:
			health = MAX_HEALTH
			health_bar -= 1
			state = State.Stall
			hurt_sound.play()
		
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
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_phantom_cooldown_timeout() -> void:
	if velocity.length() > 0:
		add_child(phantom.instantiate())
