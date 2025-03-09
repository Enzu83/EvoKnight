extends Area2D

const STRENGTH = 4
const MANA_RECOVERY_FACTOR = 10

@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var player: CharacterBody2D = $".."

var active: bool = false
var direction: String
var reference_position: Vector2

func reset() -> void:
	active = false
	scale = Vector2.ONE
	position = reference_position
	animation_player.call_deferred("play", "RESET")

func start(orientation: String) -> void:
	direction = orientation
	
	active = true
	animation_player.play("active")

func handle_slash_direction() -> void:
	rotation_degrees = 0
	scale = Vector2.ONE
	var offset := Vector2.ZERO
	
	# flip horizontally the attack to match the player's direction
	if direction == "up":
		rotation_degrees = -90
		offset.y = -10
		
		if player.sprite.flip_h:
			scale.y = -1
			offset.x = -2
		else:
			scale.y = 1
			offset.x = 2
	
	elif direction == "down":
		rotation_degrees = 90
		offset.y = 6
		
		if player.sprite.flip_h:
			scale.y = -1
			offset.x = 2
		else:
			scale.y = 1
			offset.x = -2
	
	# horizontal slash only based on player's sprite
	elif player.sprite.flip_h:
		rotation_degrees = 0
		offset.x = -4
		
		if player.sprite.flip_h:
			scale.x = -1
		else:
			scale.x = 1

	else:
		rotation_degrees = 0
		offset.x = 4
		
		if player.sprite.flip_h:
			scale.x = -1
		else:
			scale.x = 1
	
	position = reference_position + offset

func _ready() -> void:
	reference_position = position
	sprite.texture = Global.basic_slash_sprite

func _process(_delta: float) -> void:
	if active:
		handle_slash_direction()
	
	if player.state == player.State.Fainted:
		hide()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.hurt(STRENGTH + player.strength, self):
			# restore mana only if the slash hurt the enemy
			player.restore_mana(MANA_RECOVERY_FACTOR * STRENGTH + player.strength)
		
		# make player bounce on the enemy
		if direction == "down":
			player.handle_bounce()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "RESET":
		animation_player.play("RESET")
