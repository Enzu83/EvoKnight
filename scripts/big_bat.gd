extends Area2D

const SPEED = 80
const STRENGTH = 4 # damage caused by the enemy
const MAX_HEALTH = 80
const EXP_GIVEN = 3

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hurt_invicibility_timer: Timer = $HurtInvicibilityTimer

@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var player: CharacterBody2D = %Player
@onready var hud: CanvasLayer = %HUD

enum State {Sleep, Fight, Fainted}
var state := State.Sleep

var health := MAX_HEALTH
var hit := false # enemy stun if hit by an attack, can't chase during this period

func _ready() -> void:
	add_to_group("enemies") 

func _physics_process(_delta: float) -> void:
	# flip the sprite to match the direction
	if position.x < player.position.x:
		sprite.flip_h = false
	elif position.x > player.position.x:
		sprite.flip_h = true

func _process(_delta: float) -> void:
	pass

func start_fight() -> void:
	state = State.Fight
	animation_player.play("idle")
	Global.boss = self
	hud.display_boss = true
	hud.boss_name.text = "Big Bat"
	player.state = player.State.Default

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(STRENGTH)

func hurt(damage: int, _attack: Area2D) -> bool:
	if health > damage:
		health -= damage
		hurt_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		effects_player.play("hit")
		hit = true
	else:
		fainted()
	
	return true

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		player.gain_exp(EXP_GIVEN)
		effects_player.play("death")
		death_sound.play()
		hud.display_boss = false

func _on_hurt_invicibility_timer_timeout() -> void:
	hit = false
	hurtbox.set_deferred("disabled", false)
	effects_player.play("RESET")
