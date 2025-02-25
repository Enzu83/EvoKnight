extends CharacterBody2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox/Hurtbox
@onready var hurt_invicibility_timer: Timer = $Hurtbox/HurtInvicibilityTimer
@onready var hurt_sound: AudioStreamPlayer = $Hurtbox/HurtSound
@onready var death_sound: AudioStreamPlayer = $Hurtbox/DeathSound

const SPEED = 300.0
const STRENGTH = 5

const MAX_HEALTH = 120
const EXP_DROP_VALUE = 6

enum State {Default, Fainted, Attacking, Dashing}
enum Anim {idle, attack, teleport}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var health := MAX_HEALTH

func _physics_process(_delta: float) -> void:
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
	if state != State.Fainted:
		health = 0
		state = State.Fainted
		velocity.y = 0
		death_sound.play()
		
		# exp drops
		Global.create_multiple_exp_drop(EXP_DROP_VALUE, position, 250)
		
		queue_free()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body == player and player.is_hurtable():
		player.hurt(STRENGTH)

func _on_hurt_invicibility_timer_timeout() -> void:
	# don't reactivate hitbox if teleporting
	if anim != Anim.teleport:
		hurtbox.set_deferred("disabled", false)

	effects_player.stop()

func _on_teleport_timer_timeout() -> void:
	if anim == Anim.idle:
		play_animation("teleport")
	elif anim == Anim.teleport:
		hurtbox.set_deferred("disabled", false)
		play_animation("idle")
