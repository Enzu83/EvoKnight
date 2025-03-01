extends CharacterBody2D

@onready var player: Player = %Player

@onready var hud: CanvasLayer = %HUD

@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

@onready var spawn_wait_timer: Timer = $SpawnWaitTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_end_timer: Timer = $SpawnEndTimer
@onready var defeated_timer: Timer = $DefeatedTimer
@onready var defeated_end_timer: Timer = $DefeatedEndTimer

var speed_orb_scene: Resource = preload("res://scenes/items/speed_orb.tscn")

const SPEED = 300.0
const STRENGTH = 5

const MAX_HEALTH = 1#150
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

func _physics_process(_delta: float) -> void:
	if active:
		pass

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

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body == player and player.is_hurtable():
		player.hurt(STRENGTH)

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_teleport_timer_timeout() -> void:
	if anim == Anim.idle:
		play_animation("teleport_start")
	elif anim == Anim.teleport_start:
		play_animation("teleport_end")

func _on_spawn_wait_timer_timeout() -> void:
	sprite.visible = true
	play_animation("teleport_end")
	spawn_timer.start()
	
	# hud
	Global.boss = self
	hud.display_boss = true
	hud.boss_name.text = "Ceres"

func _on_spawn_timer_timeout() -> void:
	play_animation("idle")
	spawn_end_timer.start()

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
