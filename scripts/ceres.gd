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

@onready var spawn_wait_timer: Timer = $SpawnWaitTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_end_timer: Timer = $SpawnEndTimer
@onready var defeated_timer: Timer = $DefeatedTimer
@onready var defeated_end_timer: Timer = $DefeatedEndTimer

@onready var teleport_timer: Timer = $TeleportTimer
@onready var teleport_wait_timer: Timer = $TeleportWaitTimer

@onready var attack_timer: Timer = $AttackTimer

var target_orb_scene: Resource = preload("res://scenes/fx/ceres_target_orb.tscn")
var impact_orb_scene: Resource = preload("res://scenes/fx/ceres_impact_orb.tscn")
var magic_slash_scene: Resource = preload("res://scenes/fx/ceres_slash.tscn")
var speed_orb_scene: Resource = preload("res://scenes/items/speed_orb.tscn")

const SPEED = 300.0
const STRENGTH = 5
const EXP_DROP_VALUE = 7

enum State {Default, Defeated, Fainted, Attacking, Stall}
enum Anim {idle, defeated, teleport_start, teleport_end}

# boss state and actions
var state := State.Default # handle all states of the boos
var anim := Anim.idle # handle the current animation to be played

# stats
var max_health := 230
var health := max_health

# variables
var active := false

var teleport_position := [
	Vector2(4288, -168),
	Vector2(4288, -168),
	Vector2(4144, -168),
	Vector2(4144, -252),
	Vector2(4432, -168),
	Vector2(4432, -252),
]

# cycles before launching a slash
var cycles_before_slash := 2

func spawn() -> void:
	spawn_wait_timer.start()

func _ready() -> void:
	active = false
	sprite.visible = false
	hurtbox.set_deferred("disabled", true)

func _physics_process(_delta: float) -> void:
	if player.position.x >= 4152 \
	and player.position.x <= 4424:
		handle_flip_h()

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
		
		# stop teleportation
		teleport_timer.stop()
		teleport_wait_timer.stop()
		
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
	
	teleport_timer.start() # time before ceres teleports to another spot
	attack_timer.start()

func _on_defeated_timer_timeout() -> void:
	play_animation("defeated")
	defeated_end_timer.start()

func _on_defeated_end_timer_timeout() -> void:
	state = State.Fainted
	#add_child(speed_orb_scene.instantiate())

func _on_teleport_timer_timeout() -> void:
	# stop blink animation
	effects_player.stop()
	effects_player.clear_queue()
	effects_player.play("RESET")
	
	play_animation("teleport_start")
	teleport_wait_timer.start()

func _on_teleport_wait_timer_timeout() -> void:
	# teleport to another available location
	var available_teleport_position: Array
	
	for possible_position in teleport_position:
		# another location than the current one and not too close to the player's position
		if not possible_position == position \
		and (possible_position - player.position).length() >= 64:
			available_teleport_position.append(possible_position)
	
	var index := randi_range(0, len(available_teleport_position)-1)
	position = available_teleport_position[index]

	play_animation("teleport_end")
	teleport_timer.start()
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	# attack some time after teleporting
	if position == teleport_position[0]:
		for i in range(3):
			var impact_orb: Area2D = impact_orb_scene.instantiate().init(Vector2(4362 + 32 * i, -168), 50 * i)
			add_child(impact_orb)
			
			var impact_orb_2: Area2D = impact_orb_scene.instantiate().init(Vector2(4214 - 32 * i, -168), 50 * i)
			add_child(impact_orb_2)

	elif position == teleport_position[1]:
		for i in range(4):
			var impact_orb: Area2D = impact_orb_scene.instantiate().init(Vector2(4338 + 32 * i, -248), 50 * i)
			add_child(impact_orb)
			
			var impact_orb_2: Area2D = impact_orb_scene.instantiate().init(Vector2(4238 - 32 * i, -248), 50 * i)
			add_child(impact_orb_2)
	
	else:
		for i in range(2):
			var impact_orb: Area2D = impact_orb_scene.instantiate().init(Vector2(4280 + 16 * i, -288), 0)
			add_child(impact_orb)
			
			var impact_orb_2: Area2D = impact_orb_scene.instantiate().init(Vector2(4280 + 16 * i, -212), 0)
			add_child(impact_orb_2)
	
	# attack some time after teleporting
	var target_orb: Area2D = target_orb_scene.instantiate().init(self, player)
	add_child(target_orb)
	
	# magic slash
	cycles_before_slash -= 1
	
	if cycles_before_slash == 0:
		cycles_before_slash = 4
		
		var magic_slash: Area2D = magic_slash_scene.instantiate()
		add_child(magic_slash)
		
