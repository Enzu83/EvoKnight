extends Area2D

const SPEED = 150

const EXP_DROP_VALUE = 3

@onready var boss_music: AudioStreamPlayer

@onready var hud: CanvasLayer

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_player: AnimationPlayer = $EffectsPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hurt_invicibility_timer: Timer = $HurtInvicibilityTimer

@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var start_fight_timer: Timer = $StartFightTimer
@onready var wait_timer: Timer = $WaitTimer
@onready var attack_wait_timer: Timer = $AttackWaitTimer

var left_spot: Vector2
var right_spot: Vector2
var attack_spot: Vector2

var player: CharacterBody2D

enum State {Sleep, LeftIdle, RightIdle, LeftAttack, RightAttack, Fainted}
var state := State.Sleep
var attack_move := false # indicates if the bat moves toward the attack spot
var wait := false # indicates if the bat can perform moves
var attack_wait := false # can attack

var max_health := 140
var health := max_health
var strength = 4 # damage caused by the enemy
var hit := false # enemy stun if hit by an attack, can't chase during this period

@export var boss := false

@export var flip_sprite := false

var drop := true

func _ready() -> void:
	add_to_group("enemies")

	if boss:
		boss_music = %BossMusic
		hud = %HUD
		
		left_spot = $LeftSpot.position
		right_spot = $RightSpot.position
		attack_spot = $AttackSpot.position
	
	# regular enemy starts already wake up
	else:
		animation_player.play("idle")
		start_fight_timer.start(0.01)
		
		left_spot = position + Vector2(-128, 0)
		right_spot = position + Vector2(128, 0)
		attack_spot = position + Vector2(0, 96)

func _physics_process(delta: float) -> void:
	if Global.player != null:
		player = Global.player
	
	if not wait:
		# move to left spot
		if state == State.LeftIdle:
			scale.x = 2
			# check if the bat reached the left spot
			if move_to(left_spot, delta * SPEED) \
			and not attack_wait:
				# attack from left to right
				attack_wait = true
				attack_wait_timer.start()
				
		# move to right spot
		elif state == State.RightIdle:
			scale.x = -2
			# check if the bat reached the right spot
			if move_to(right_spot, delta * SPEED) \
			and not attack_wait:
				# attack from right to left
				attack_wait = true
				attack_wait_timer.start()
			
	# move to attack spot
	if not attack_wait and \
	(state == State.LeftAttack or state == State.RightAttack) \
	and attack_move:
		if move_to(attack_spot, 1.5 * delta * SPEED) \
		and animation_player.current_animation != "attack_end":
			# bat is at attack spot
			animation_player.play("attack_end")

func move_to(target_position: Vector2, speed: float) -> bool:
	position.x = move_toward(position.x, target_position.x, speed)
	position.y = move_toward(position.y, target_position.y, speed)
	
	return position == target_position

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(strength)

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
		animation_player.pause()
		effects_player.play("death")
		death_sound.play()
		
		if boss:
			hud.display_boss = false
		
		# exp drops
		if drop:
			Global.create_multiple_exp_drop(EXP_DROP_VALUE, position, 250)

func move_to_attack_spot() -> void:
	attack_move = true

func end_attack() -> void:
	animation_player.play("idle")
	
	if state == State.LeftAttack:
		state = State.RightIdle
	elif state == State.RightAttack:
		state = State.LeftIdle
	
	wait = true
	wait_timer.start()

func _on_hurt_invicibility_timer_timeout() -> void:
	hit = false
	hurtbox.set_deferred("disabled", false)
	effects_player.play("RESET")

func _on_start_fight_timer_timeout() -> void:
	state = State.RightIdle
	
	if boss:
		animation_player.play("idle")
		Global.boss = self
		hud.display_boss = true
		hud.boss_name.text = "Big Bat"
		player.state = player.State.Default
		boss_music.play()
	
func _on_wait_timer_timeout() -> void:
	wait = false

func _on_attack_wait_timer_timeout() -> void:
	attack_wait = false
	
	if state == State.LeftIdle:
		state = State.LeftAttack
		animation_player.play("attack_start")
	elif state == State.RightIdle:
		state = State.RightAttack
		animation_player.play("attack_start")
