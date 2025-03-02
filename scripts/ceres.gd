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

@onready var ceres_slash: Area2D = $CeresSlash

@onready var spawn_wait_timer: Timer = $SpawnWaitTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_end_timer: Timer = $SpawnEndTimer
@onready var defeated_timer: Timer = $DefeatedTimer
@onready var defeated_end_timer: Timer = $DefeatedEndTimer

var target_orb_scene: Resource = preload("res://scenes/fx/ceres_target_orb.tscn")
var impact_orb_scene: Resource = preload("res://scenes/fx/ceres_impact_orb.tscn")
var speed_orb_scene: Resource = preload("res://scenes/items/speed_orb.tscn")

const SPEED = 300.0
const STRENGTH = 4

const MAX_HEALTH = 150
const EXP_DROP_VALUE = 7

enum State {Default, Defeated, Fainted, Attacking}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var health := MAX_HEALTH

# variables
var active := false

func spawn() -> void:
	spawn_wait_timer.start()

func _ready() -> void:
	active = false
	sprite.visible = false
	hurtbox.set_deferred("disabled", true)

func _process(_delta: float) -> void:
	handle_flip_h()
	
	# debug
	if active:
		if Input.is_action_just_pressed("magic_slash") \
		and ceres_slash.animation_player.current_animation == "":
			if sprite.flip_h:
				ceres_slash.start("left")
			else:
				ceres_slash.start("right")
				
			var target_orb: Area2D = target_orb_scene.instantiate().init(get_middle_position(), player)
			add_child(target_orb)
			
			var impact_orb: Area2D = impact_orb_scene.instantiate().init(Vector2(4348, -248))
			add_child(impact_orb)
	
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
	return not effects_player.current_animation == "blink"

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
		health = 0
		state = State.Defeated
		velocity.y = 0
		death_sound.play()
		
		# exp drops
		Global.create_multiple_exp_drop(EXP_DROP_VALUE, position, 250)
		
		# stop drawing hud
		hud.display_boss = false
		
		# boss defeated: end of fight animation
		defeated_timer.start()
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

func _on_teleport_timer_timeout() -> void:
	if anim == Anim.idle:
		play_animation("teleport_start")
	elif anim == Anim.teleport_start:
		play_animation("teleport_end")

func _on_spawn_wait_timer_timeout() -> void:
	play_animation("teleport_end")
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	play_animation("idle")
	spawn_end_timer.start()
	
	# hud
	Global.boss = self
	hud.display_boss = true
	hud.boss_name.text = "Ceres"

func _on_spawn_end_timer_timeout() -> void:
	state = State.Default
	active = true
	hurtbox.set_deferred("disabled", false)

func _on_defeated_timer_timeout() -> void:
	play_animation("defeated")
	defeated_end_timer.start()

func _on_defeated_end_timer_timeout() -> void:
	state = State.Fainted
	add_child(speed_orb_scene.instantiate())
