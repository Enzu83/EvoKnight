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

const SPEED = 300.0
const EXP_DROP_VALUE = 2

var strength := 4
var attack_strength := 7

enum State {Default, Defeated, Attacking}
enum Anim {idle, attack, defeated}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var max_health := 1#100
var health := max_health

# variables
var active := false

func _ready() -> void:
	active = false
	#sprite.visible = false
	hurtbox.set_deferred("disabled", true)
	
	if Global.reno_defeated:
		sprite.visible = false

func _physics_process(_delta: float) -> void:
	handle_flip_h()

func handle_flip_h() -> void:
	# flip the sprite to match the direction
	if position.x < player.position.x:
		scale.x = 1
	elif position.x > player.position.x:
		scale.x = -1

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

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(strength)

func _on_hurt_invicibility_timer_timeout() -> void:
	hurtbox.set_deferred("disabled", false)
	effects_player.stop()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(attack_strength)
